import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meal_app/widgets/StoreSection.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../features/auth/models/role.dart';
import '../features/auth/repositories/auth_repository.dart';
import 'TabBar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeTabType _selectedTab = HomeTabType.todayMeal;

  Future<void> _handleProfileTap(BuildContext context) async {
    final repo = context.read<AuthRepository>();
    final nav = Navigator.of(context);

    final token = await repo.getAccessToken();
    if (!context.mounted) return;

    if (token == null || token.isEmpty) {
      nav.pushNamedAndRemoveUntil('/login', (r) => false);
      return;
    }

    try {
      final me = await repo.getMe();
      if (!context.mounted) return;
      if (me.role == Role.admin) {
        nav.pushNamed('/admin');
      } else {
        nav.pushNamed('/mypage');
      }
    } catch (e) {
      // 토큰이 만료/무효인 경우 등: 토큰 클리어 후 로그인으로
      if (!context.mounted) return;
      if (kDebugMode) {
        debugPrint('프로필 이동 preflight(getMe) 실패: $e');
      }
      nav.pushNamedAndRemoveUntil('/login', (r) => false);
      // best-effort logout (do not block UI / navigation)
      unawaited(repo.logout());
    }
  }

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
              if (kDebugMode) debugPrint("알림 클릭");
            },
            icon: SvgPicture.asset(
              'assets/icon/alarm.svg',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        // 화면 크기에 따라 레이아웃 조정
        builder: (context, constraints) {
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
                      onPressed: () {
                        if (kDebugMode) debugPrint("새로고침");
                      },
                      icon: Icon(Icons.refresh, color: Colors.grey),
                      highlightColor: Colors.orange.withValues(alpha: 0.2),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: HomeSegmentedTabBar(
                    selected: _selectedTab,
                    onChanged: (value) {
                      setState(() {
                        _selectedTab = value;
                      });
                    },
                  ),
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
