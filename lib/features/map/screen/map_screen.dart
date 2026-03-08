import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/util/colors.dart';

import '../../../common/widgets/app_bar_common.dart';
import '../../store/models/store_models.dart';
import '../../store/viewmodels/store_list_view_model.dart';
import '../widgets/bottomsheet.dart';
import '../widgets/map_marker_svg_builder.dart';
import '../widgets/refresh.dart';
import '../widgets/zoom_controls.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.onBack});

  /// 탭으로 표시될 때 뒤로가기 대신 호출 (null이면 Navigator.pop)
  final VoidCallback? onBack;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

/// 새로고침 버튼이 하단 모달 카드 위에 떨어질 때 모달 상단과의 간격 (lp)
const double _refreshGapAboveSheet = 12.0;

class _MapScreenState extends State<MapScreen> {
  bool _loaded = false;
  bool _isBottomSheetOpen = false;
  /// 모달이 열려 있을 때의 시트 높이 (하단 safe inset 포함). null이면 모달 닫힘.
  double? _currentSheetHeight;
  bool _buildingMarkerIcons = false;
  KakaoMapController? _mapController;
  DateTime? _lastBottomSheetAt;
  static const Duration _bottomSheetCooldown = Duration(
    milliseconds: 600,
  );
  final Map<String, MarkerIcon> _markerIconCache = {};
  static const int _markerW = 56;
  static const int _markerH = 66;

  String _cacheKey(StoreListItem s) => '${s.id}_${s.remain}';

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

  Future<MarkerIcon> _buildMarkerIcon(StoreListItem store) async {
    return MapMarkerSvgBuilder.buildMarkerIcon(store.remain);
  }

  void _ensureMarkerIcons(List<StoreListItem> stores) {
    if (_buildingMarkerIcons) return;
    final withLatLng = stores.where((s) => s.lat != null && s.lng != null).toList();
    final targets = withLatLng.map(_cacheKey).toSet();
    final missing = withLatLng.where((s) => !_markerIconCache.containsKey(_cacheKey(s))).toList();
    if (missing.isEmpty) return;

    _buildingMarkerIcons = true;
    Future.wait(
      missing.map((s) async {
        final key = _cacheKey(s);
        final icon = await _buildMarkerIcon(s);
        return MapEntry(key, icon);
      }),
    ).then((entries) {
      if (!mounted) return;
      setState(() {
        for (final e in entries) {
          _markerIconCache[e.key] = e.value;
        }
        _markerIconCache.removeWhere((k, _) => !targets.contains(k));
      });
      if (mounted && _mapController != null) {
        _mapController!.clearMarker();
        Future.delayed(const Duration(milliseconds: 200), () async {
          if (!mounted || _mapController == null) return;
          final list = context.read<StoreListViewModel>().items;
          final toApply = _buildMarkersFromItems(list);
          if (toApply.isNotEmpty) {
            await _mapController!.addMarker(markers: toApply);
          }
        });
      }
    }).whenComplete(() => _buildingMarkerIcons = false);
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

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final sheetHeight = storeBottomSheetHeight(store) + bottomInset;
    setState(() {
      _isBottomSheetOpen = true;
      _currentSheetHeight = sheetHeight;
    });
    await showStoreBottomSheet(context, store);
    if (!mounted) return;
    setState(() {
      _isBottomSheetOpen = false;
      _currentSheetHeight = null;
    });
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

  /// 좌표 있는 매장만 마커로 표시. 캐시된 커스텀 아이콘이 있으면 적용.
  List<Marker> _buildMarkersFromItems(List<StoreListItem> items) {
    return items
        .where((s) => s.lat != null && s.lng != null)
        .map((s) {
          final key = _cacheKey(s);
          final icon = _markerIconCache[key];
          return Marker(
            markerId: s.id.toString(),
            latLng: LatLng(s.lat!, s.lng!),
            icon: icon,
            width: icon != null ? _markerW : 24,
            height: icon != null ? _markerH : 30,
          );
        })
        .toList();
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
      backgroundColor: AppColors.white,
      appBar: AppBarCommon(
        toolbarHeight: 50,
        title: '지도',
        centerTitle: true,
        onBackPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = MediaQuery.of(context).padding;
          final bottomInset = padding.bottom;
          const baseBottom = 16.0;
          const refreshOffset = 30.0; // 새로고침 버튼을 조금 위로 (모달 닫혀 있을 때)
          final refreshBottom = _currentSheetHeight != null
              ? _currentSheetHeight! + _refreshGapAboveSheet
              : baseBottom + bottomInset + refreshOffset;
          final zoomBottom = baseBottom + bottomInset;

          return Stack(
            children: [
              Positioned.fill(
                child: KakaoMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!mounted || _mapController == null) return;
                      _mapController!.clearMarker();
                      await Future.delayed(const Duration(milliseconds: 150));
                      if (!mounted || _mapController == null) return;
                      final list = context.read<StoreListViewModel>().items;
                      final currentMarkers = _buildMarkersFromItems(list);
                      if (currentMarkers.isNotEmpty) {
                        await _mapController!.addMarker(markers: currentMarkers);
                      }
                    });
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
                      style: const TextStyle(color: AppColors.error),
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
