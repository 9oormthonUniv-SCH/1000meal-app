import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:meal_app/widgets/StoreSection.dart';
import 'package:meal_app/widgets/app_text_logo.dart';
import '../common/widgets/app_bar_common.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../features/auth/models/role.dart';
import '../features/mypage/screens/notification_settings_screen.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../features/store/viewmodels/store_list_view_model.dart';
import '../features/notice/viewmodels/notice_list_view_model.dart';
import '../features/notice/widgets/notice_list_section.dart';
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
        nav.pushNamedAndRemoveUntil('/', (r) => false, arguments: 3);
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
    final storeVm = context.watch<StoreListViewModel>();
    final noticeVm = context.watch<NoticeListViewModel>();
    final isRefreshing = _selectedTab == HomeTabType.todayMeal
        ? storeVm.loading
        : noticeVm.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarCommon(
        showBack: false,
        toolbarHeight: 60,
        titleWidget: const AppTextLogoWidget(),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF111827),
            ),
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(NotificationSettingsScreen.routeName),
          ),
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
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: HomeSegmentedTabBar(
                          //HomeTabType에 따라서 StoreSection or Notice List
                          selected: _selectedTab,
                          onChanged: (value) {
                            setState(() {
                              _selectedTab = value;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            onPressed: isRefreshing
                                ? null
                                : () {
                                    if (_selectedTab == HomeTabType.notice) {
                                      context
                                          .read<NoticeListViewModel>()
                                          .refresh();
                                      if (kDebugMode) debugPrint("공지사항 새로고침");
                                      return;
                                    }
                                    context
                                        .read<StoreListViewModel>()
                                        .refresh();
                                    if (kDebugMode) debugPrint("오늘의 천밥 새로고침");
                                  },
                            icon: isRefreshing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF54AAFF),
                                    ),
                                  )
                                : const Icon(Icons.refresh, color: Colors.grey),
                            highlightColor: Colors.orange.withValues(
                              alpha: 0.2,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                //렌더링 분기 추가 필요
                child: _selectedTab == HomeTabType.notice
                    ? const NoticeListSection()
                    : SingleChildScrollView(
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
