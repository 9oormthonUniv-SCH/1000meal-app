import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class KakaoMapWidget extends StatelessWidget {
  final Function(KakaoMapController) onMapCreated;

  const KakaoMapWidget({Key? key, required this.onMapCreated})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: KakaoMap(
        onMapCreated: onMapCreated,
        center: LatLng(36.772, 126.9324),
        markers: [
          Marker(markerId: 'marker_1', latLng: LatLng(36.7697, 126.9316)),
        ],
      ),
    );
  }
}
