import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'KakaoMapWidget.dart';
import 'ZoomControlsWidget.dart';

const String kakaoMapJsKey = 'KAKAO_MAP_JS_KEY';

class KakaoMapScreen extends StatefulWidget {
  @override
  State<KakaoMapScreen> createState() => _KakaoMapScreenState();
}

class _KakaoMapScreenState extends State<KakaoMapScreen> {
  KakaoMapController? mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Container(
            width: MediaQuery.of(context).size.width - 40, // 좌우 여백 20씩 뺌
            height: 260, // 이전 높이로 복원
            // 2. 디자인 (그림자 등)
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20), // 컨테이너의 둥근 모서리
              /* boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4), // 그림자 위치
                ),
              ], */
            ),
            child: Stack(
              children: [
                KakaoMapWidget(
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                ),
                ZoomControlsWidget(mapController: mapController),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* 
Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Container(
            width: MediaQuery.of(context).size.width - 40, // 좌우 여백 20씩 뺌
            height: 300, // 원하시는 높이 설정
            // 2. 디자인 (그림자 등)
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20), // 컨테이너의 둥근 모서리
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4), // 그림자 위치
                ),
              ],
            ),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(20), // 위 컨테이너랑 똑같이 맞춤
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ),
      ), */
