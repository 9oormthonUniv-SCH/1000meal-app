import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:provider/provider.dart';

import '../../store/models/store_models.dart';
import '../../store/viewmodels/store_list_view_model.dart';
import '../widgets/bottomsheet.dart';
import '../widgets/marker_pin.dart';
import '../widgets/refresh.dart';
import '../widgets/zoom_controls.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.onBack});

  /// 탭으로 표시될 때 뒤로가기 대신 호출 (null이면 Navigator.pop)
  final VoidCallback? onBack;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _loaded = false;
  bool _isBottomSheetOpen = false;
  bool _buildingMarkerIcons = false;
  KakaoMapController? _mapController;
  DateTime? _lastBottomSheetAt;
  static const Duration _bottomSheetCooldown = Duration(
    milliseconds: 600,
  ); //Bottom Sheet 호출 시간 제한
  final Map<String, MarkerIcon> _markerIconCache = {};
  static const double _markerWidth = 34.34;
  static const double _markerHeight = 44;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    // 진입 즉시 로드 시작(홈에서 이미 로드됐어도 notify 시 재빌드되어 핀 갱신됨)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StoreListViewModel>().load();
    });
  }

  Map<String, StoreListItem> _buildStoreMap(List<StoreListItem> stores) {
    return {for (final store in stores) store.id.toString(): store};
  }

  Color _markerColor(int remain) {
    if (remain <= 0) return const Color(0xFFFF3B30);
    if (remain <= 20) return const Color(0xFFFF9500);
    return const Color(0xFF34C759);
  }

  Future<MarkerIcon> _buildMarkerIcon(StoreListItem store) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(_markerWidth, _markerHeight);
    final painter = MarkerPinPainter(
      count: store.remain,
      color: _markerColor(store.remain),
      borderWidth: 1.07,
    );
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _markerWidth.round(),
      _markerHeight.round(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
    return MarkerIcon.fromNetwork(dataUrl);
  }

  void _ensureMarkerIcons(List<StoreListItem> stores) {
    if (_buildingMarkerIcons) return;

    final targets = stores
        .where((s) => s.lat != null && s.lng != null)
        .map((s) => '${s.id}_${s.remain}')
        .toSet();

    final missing = stores.where((store) {
      if (store.lat == null || store.lng == null) return false;
      final key = '${store.id}_${store.remain}';
      return !_markerIconCache.containsKey(key);
    }).toList();

    if (missing.isEmpty) return;

    _buildingMarkerIcons = true;
    Future.wait(
          missing.map((store) async {
            final key = '${store.id}_${store.remain}';
            final icon = await _buildMarkerIcon(store);
            return MapEntry(key, icon);
          }),
        )
        .then((entries) {
          if (!mounted) return;
          setState(() {
            for (final entry in entries) {
              _markerIconCache[entry.key] = entry.value;
            }
            _markerIconCache.removeWhere((key, _) => !targets.contains(key));
          });
          // 지도가 이미 준비된 상태면 여기서 바로 마커 적용 (didUpdateWidget race 회피)
          if (mounted && _mapController != null) {
            final items = context.read<StoreListViewModel>().items;
            final markersToApply = _buildMarkersFromItems(items);
            if (markersToApply.isNotEmpty) {
              _mapController!.addMarker(markers: markersToApply);
            }
          }
        })
        .whenComplete(() => _buildingMarkerIcons = false);
  }

  //마커 클릭 시 해당 매장을 찾고 showStoreBottomSheet 호출 -> 호출 횟수 제한 생각....
  Future<void> _handleMarkerTap(String markerId) async {
    final now = DateTime.now();
    if (_lastBottomSheetAt != null &&
        now.difference(_lastBottomSheetAt!) < _bottomSheetCooldown) {
      return;
    }
    _lastBottomSheetAt = now;

    final stores = context.read<StoreListViewModel>().items;
    final storeMap = _buildStoreMap(stores);
    final store = storeMap[markerId];
    if (store == null || !mounted) return;

    if (_mapController != null && store.lat != null && store.lng != null) {
      final currentCenter = await _mapController!.getCenter();
      final isSameCenter =
          (currentCenter.latitude - store.lat!).abs() < 0.0001 &&
          (currentCenter.longitude - store.lng!).abs() < 0.0001;
      if (isSameCenter) {
        _mapController!.setLevel(2);
      } else {
        final target = LatLng(store.lat! - 0.001, store.lng!);
        _mapController!.panTo(target);
      }
    }

    setState(() => _isBottomSheetOpen = true);
    await showStoreBottomSheet(context, store);
    if (!mounted) return;
    setState(() => _isBottomSheetOpen = false);
  }

  // Zoom in/out functions
  Future<void> _zoomIn() async {
    if (_mapController == null) return;
    final currentLevel = await _mapController!.getLevel();
    _mapController!.setLevel(currentLevel - 1);
  }

  Future<void> _zoomOut() async {
    if (_mapController == null) return;
    final currentLevel = await _mapController!.getLevel();
    _mapController!.setLevel(currentLevel + 1);
  }

  //refresh function
  Future<void> _refresh() async {
    if (!mounted) return;
    await context.read<StoreListViewModel>().load();
  }

  /// 아이콘이 준비된 매장만 Marker 목록으로 만든다. (지도 준비 시점 재적용·build 공용)
  List<Marker> _buildMarkersFromItems(List<StoreListItem> items) {
    return items
        .where((s) => s.lat != null && s.lng != null)
        .where((s) => _markerIconCache['${s.id}_${s.remain}'] != null)
        .map((s) {
      final key = '${s.id}_${s.remain}';
      return Marker(
        markerId: s.id.toString(),
        latLng: LatLng(s.lat!, s.lng!),
        width: _markerWidth.round(),
        height: _markerHeight.round(),
        icon: _markerIconCache[key]!,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoreListViewModel>();
    _ensureMarkerIcons(vm.items);
    final markers = _buildMarkersFromItems(vm.items);

    final center = markers.isNotEmpty
        ? markers.first.latLng
        : LatLng(36.7720, 126.9324);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text(
          '지도',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () {
            final onBack = widget.onBack;
            if (onBack != null) {
              onBack();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = MediaQuery.of(context).padding;
          final bottomInset = padding.bottom;
          const baseBottom = 16.0;
          final refreshBottom = _isBottomSheetOpen
              ? kStoreBottomSheetHeight + 8
              : baseBottom + bottomInset;
          final zoomBottom = baseBottom + bottomInset;

          return Stack(
            children: [
              Positioned.fill(
                child: KakaoMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // 지도 준비 직후: 현재 마커가 있으면 적용
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _mapController == null) return;
                      final list = context.read<StoreListViewModel>().items;
                      final currentMarkers = _buildMarkersFromItems(list);
                      if (currentMarkers.isNotEmpty) {
                        _mapController!.addMarker(markers: currentMarkers);
                      }
                    });
                    // 지도 준비 직후 한 번 새로고침해서, 아직 마커가 없었던 경우에도 didUpdateWidget으로 마커가 그려지게 함
                    if (mounted) _refresh();
                  },
                  onMarkerTap: (markerId, _, __) => _handleMarkerTap(markerId),
                  center: center,
                  markers: markers,
                ),
              ),
              if (vm.loading && vm.items.isEmpty)
                const Center(child: CircularProgressIndicator()),
              if (vm.errorMessage != null && vm.items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: refreshBottom,
                child: Center(child: MapRefreshButton(onPressed: _refresh)),
              ),
              Positioned(
                right: baseBottom + padding.right,
                bottom: zoomBottom,
                child: MapZoomControls(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
              ),
            ],
          );
        },
      ),
    );
  }
}
