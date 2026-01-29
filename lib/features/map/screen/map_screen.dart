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
  KakaoMapController? _mapController;

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

  void _handleMarkerTap(String markerId) {
    final stores = context.read<StoreListViewModel>().items;
    final storeMap = _buildStoreMap(stores);
    final store = storeMap[markerId];
    if (store == null || !mounted) return;
    showStoreBottomSheet(context, store);
  }

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
              right: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MapRefreshButton(onPressed: _refresh),
                  const SizedBox(width: 10),
                  MapZoomControls(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
