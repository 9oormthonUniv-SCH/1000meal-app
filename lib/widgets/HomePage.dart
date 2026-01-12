import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meal_app/widgets/StoreSection.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0, // 스크롤 시 색상 변경 방지
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/icon/Textlogo.png',
          width: 120,
          fit: BoxFit.contain, // 그림 비율 유지하며 잘리기 방지
        ),

        // 뒤로가기 버튼 공간 없애기
        actions: [
          IconButton(
            onPressed: () {
              print("알림 클릭");
            },
            icon: SvgPicture.asset(
              'assets/icon/alarm.svg',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
          IconButton(
            onPressed: () {
              print("프로필 클릭");
            },
            icon: SvgPicture.asset(
              'assets/icon/profile.svg',
              width: 22,
              height: 22,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        // 화면 크기에 따라 레이아웃 조정
        builder: (context, constraints) {
          double mapHeight = 260;
          double remainingHeight = constraints.maxHeight - mapHeight;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '오늘의 천밥',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () => print("새로고침"),
                      icon: Icon(Icons.refresh, color: Colors.grey),
                      highlightColor: Colors.orange.withValues(alpha: 0.2),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [StoreSection(), SizedBox(height: 20)],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
