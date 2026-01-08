import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class ZoomControlsWidget extends StatelessWidget {
  final KakaoMapController? mapController;
  final VoidCallback? onFullScreen;

  const ZoomControlsWidget({
    Key? key,
    required this.mapController,
    this.onFullScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: 16,
      child: Column(
        children: [
          const SizedBox(height: 8),
          FloatingActionButton(
            mini: true,
            onPressed: () async {
              if (mapController != null) {
                int currentLevel = await mapController!.getLevel();
                mapController!.setLevel(currentLevel - 1);
              }
            },
            child: const Icon(Icons.add), // 확대 아이콘
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            mini: true,
            onPressed: () async {
              if (mapController != null) {
                int currentLevel = await mapController!.getLevel();
                mapController!.setLevel(currentLevel + 1);
              }
            },
            child: const Icon(Icons.remove), // 축소 아이콘
          ),
        ],
      ),
    );
  }
}
