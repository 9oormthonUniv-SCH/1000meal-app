import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:provider/provider.dart';

import '../../store/models/store_models.dart';
import '../../store/viewmodels/store_list_view_model.dart';
import '../widgets/bottomsheet.dart';
import '../widgets/refresh.dart';
import '../widgets/zoom_controls.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _loaded = false;
  bool _isBottomSheetOpen = false;
  KakaoMapController? _mapController;
  DateTime? _lastBottomSheetAt;
  static const Duration _bottomSheetCooldown = Duration(
    milliseconds: 600,
  ); //Bottom Sheet 호출 시간 제한

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StoreListViewModel>().load();
    });
  }

  Map<String, StoreListItem> _buildStoreMap(List<StoreListItem> stores) {
    return {for (final store in stores) store.id.toString(): store};
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoreListViewModel>();
    final markers = vm.items
        .where((s) => s.lat != null && s.lng != null)
        .map(
          (s) =>
              Marker(markerId: s.id.toString(), latLng: LatLng(s.lat!, s.lng!)),
        )
        .toList();

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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: KakaoMap(
                onMapCreated: (controller) {
                  _mapController = controller;
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
              bottom: _isBottomSheetOpen ? kStoreBottomSheetHeight + 8 : 16,
              child: Center(child: MapRefreshButton(onPressed: _refresh)),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: MapZoomControls(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
            ),
          ],
        ),
      ),
    );
  }
}
