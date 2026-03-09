import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/widgets/StoreSection.dart';
import 'package:meal_app/widgets/app_text_logo.dart';
import '../common/widgets/app_bar_common.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../features/auth/models/role.dart';
import '../common/notification/fcm_notification_storage.dart';
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
  bool _hasUnreadNotifications = false;

  Future<void> _loadHasUnread() async {
    final hasUnread = await hasUnreadFcmNotifications();
    if (mounted && hasUnread != _hasUnreadNotifications) {
      setState(() => _hasUnreadNotifications = hasUnread);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHasUnread();
  }

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
      backgroundColor: AppColors.white,
      appBar: AppBarCommon(
        showBack: false,
        toolbarHeight: 60,
        // Material 3 AppBar는 툴바 좌측에 기본 16dp 여백이 있어, 본문(20)과 맞추려 16px 왼쪽 보정
        titleWidget: Transform.translate(
          offset: const Offset(-16, 0),
          child: const Padding(
            padding: EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppTextLogoWidget(),
            ),
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          Transform.translate(
            offset: const Offset(-5, 0),
            child: IconButton(
              icon: SvgPicture.asset(
                _hasUnreadNotifications
                    ? 'assets/icon/alarm_active.svg'
                    : 'assets/icon/alarm.svg',
                width: 24,
                height: 24,
              ),
              onPressed: () async {
                await Navigator.of(context).pushNamed(NotificationSettingsScreen.routeName);
                if (!mounted) return;
                _loadHasUnread();
              },
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        // 화면 크기에 따라 레이아웃 조정
        builder: (context, constraints) {
          return Column(
            children: [
              // 우측 패딩 80: AppBar 알림 버튼과 새로고침 버튼이 같은 좌우 위치에 오도록
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 5, 0),
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
                                      color: AppColors.blue,
                                    ),
                                  )
                                : SvgPicture.asset(
                                    'assets/icon/refresh.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(AppColors.gray6, BlendMode.srcIn),
                                  ),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
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
                          children: [
                            const SizedBox(height: 16),
                            StoreSection(),
                            const SizedBox(height: 20),
                          ],
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
