import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

import '../../../common/notification/fcm_notification_storage.dart';
import '../../../common/utils/external_link.dart';
import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../../../common/widgets/app_snackbar.dart';
import '../../../common/widgets/profile_card.dart';
import 'notification_settings_screen.dart';
import '../../auth/models/role.dart';
import '../../auth/repositories/auth_repository.dart';
import '../viewmodels/mypage_view_model.dart';

class MyPageScreen extends StatefulWidget {
  static const routeName = '/mypage';

  /// true: 바텀 탭 "마이"에서 진입 (비로그인 시 로그인 유도 화면, 백버튼 없음)
  final bool fromMainTab;

  const MyPageScreen({super.key, this.fromMainTab = false});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  bool _loaded = false;
  bool? _hasToken;
  bool _hasUnreadNotifications = false;

  Future<void> _loadHasUnread() async {
    final hasUnread = await hasUnreadFcmNotifications();
    if (mounted && hasUnread != _hasUnreadNotifications) {
      setState(() => _hasUnreadNotifications = hasUnread);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = context.read<AuthRepository>();
      final token = await repo.getAccessToken();
      if (!mounted) return;
      _hasToken = token != null && token.isNotEmpty;

      if (!_hasToken!) {
        setState(() {});
        return;
      }

      await context.read<MyPageViewModel>().load();
      if (!mounted) return;
      _loadHasUnread();
      if (!mounted) return;
      final vm = context.read<MyPageViewModel>();
      if (vm.shouldRelogin) {
        // Expired/invalid token: treat as guest instead of forcing navigation.
        _hasToken = false;
        unawaited(vm.logout());
        setState(() {});
      } else {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyPageViewModel>();
    final showBack = !widget.fromMainTab;

    if (widget.fromMainTab && _hasToken == null) {
      return _buildScaffold(
        context,
        showBack: showBack,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.fromMainTab && _hasToken == false) {
      return _buildScaffold(
        context,
        showBack: showBack,
        body: const _GuestMyPageBody(),
      );
    }

    // 로그아웃 직후: me는 null인데 _hasToken이 아직 true면 토큰 재확인 후 게스트로 전환
    if (widget.fromMainTab && vm.me == null && _hasToken == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final token = await context.read<AuthRepository>().getAccessToken();
        if (!mounted) return;
        setState(() {
          _hasToken = token != null && token.isNotEmpty;
        });
      });
      return _buildScaffold(
        context,
        showBack: showBack,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.me == null) {
      return _buildScaffold(
        context,
        showBack: showBack,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return _buildScaffold(
      context,
      showBack: showBack,
      body: _Body(vm: vm),
    );
  }

  Scaffold _buildScaffold(BuildContext context, {required bool showBack, required Widget body}) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarCommon(
        showBack: showBack,
        title: '마이페이지',
        centerTitle: false,
        titleSpacing: showBack ? null : 20,
        actions: [
          Transform.translate(
            offset: const Offset(-16, 0),
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
      body: body,
    );
  }
}

/// 비로그인 시: 프로필과 같은 위치·같은 크기의 로그인/회원가입 CTA 카드
class _GuestMyPageBody extends StatelessWidget {
  const _GuestMyPageBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.only(bottom: 20),
            child: GuestProfileCard(
              title: '오늘순밥 로그인 및 회원가입',
              subtitle: '가게의 오픈·마감 소식을 실시간으로 알려드려요',
              onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final MyPageViewModel vm;
  const _Body({required this.vm});

  @override
  Widget build(BuildContext context) {
    final me = vm.me;

    if (me == null) {
      return Center(
        child: Text(vm.errorMessage ?? '불러오기에 실패했습니다.'),
      );
    }

    final isStudent = me.role == Role.student;
    // 이미지 스타일: 학생 = 주황·빨강 배경 + 흰색 글씨, 관리자 = 파랑 계열
    final badgeBg = isStudent ? AppColors.orange : AppColors.blue;
    final badgeText = isStudent ? '학생' : '관리자';
    // 상단 카드 제목: 학생·관리자 모두 이름(displayName) 표시, 그 밑 이메일
    final String cardTitle = me.displayName.isNotEmpty ? me.displayName : '회원';
    final String cardSubtitle = me.email;

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.only(bottom: 20),
            child: UserProfileCard(
              username: cardTitle,
              subtitle: cardSubtitle,
              badgeText: badgeText,
              badgeBgColor: badgeBg,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            color: AppColors.white,
            child: Column(
              children: [
                _MenuItem(
                  label: '이메일 변경',
                  onTap: () => Navigator.of(context).pushNamed('/change-email'),
                  trailing: Icon(Icons.chevron_right, color: AppColors.gray5, size: 22),
                ),
                Divider(height: 1, color: AppColors.gray3),
                _MenuItem(
                  label: '비밀번호 변경',
                  onTap: () => Navigator.of(context).pushNamed('/find-account', arguments: 'pw'),
                  trailing: Icon(Icons.chevron_right, color: AppColors.gray5, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            color: AppColors.white,
            child: _PushAgreeRow(
              value: vm.pushNotificationAgreed,
              onChanged: (v) => vm.setPushNotificationAgreed(v),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            color: AppColors.white,
            child: Column(
              children: [
                if (kDebugMode)
                  _MenuItem(
                    label: '자동 로그인 테스트 (토큰 삭제 후 재진입)',
                    labelColor: AppColors.gray6,
                    onTap: () async {
                      await context.read<AuthRepository>().clearTokensOnly();
                      if (!context.mounted) return;
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                    },
                    trailing: Icon(Icons.chevron_right, color: AppColors.gray5, size: 22),
                  ),
                if (kDebugMode) Divider(height: 1, color: AppColors.gray3),
                _MenuItem(
                  label: '로그아웃',
                  onTap: () async {
                    final ok = await AppConfirmDialog.showYesNo(
                      context,
                      content: '로그아웃 하시겠습니까?',
                      noLabel: '아니요',
                      yesLabel: '네',
                    );
                    if (ok != true) return;
                    await vm.logout();
                    if (!context.mounted) return;
                    // 로그아웃 후 마이페이지 탭에 머물면 me=null 상태로 무한 로딩될 수 있으므로 홈(0)으로 이동
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false, arguments: 0);
                  },
                  trailing: Icon(Icons.chevron_right, color: AppColors.gray5, size: 22),
                ),
                Divider(height: 1, color: AppColors.gray3),
                _MenuItem(
                  label: '회원탈퇴',
                  labelColor: AppColors.error,
                  onTap: () async {
                    final ok = await AppConfirmDialog.showCustom(
                      context,
                      content: '탈퇴하면 모든 기록이 사라집니다\n정말 탈퇴하시겠습니까?',
                      secondaryLabel: '취소',
                      primaryLabel: '탈퇴하기',
                      primaryOnLeft: true,
                      primaryBg: AppColors.gray2,
                      primaryFg: AppColors.error,
                      secondaryBg: AppColors.gray7,
                      secondaryFg: AppColors.white,
                    );
                    if (ok != true) return;
                    final success = await vm.deleteAccount();
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                    } else {
                      AppSnackBar.show(context, vm.errorMessage ?? '회원 탈퇴에 실패했습니다. 다시 시도해주세요.');
                    }
                  },
                  trailing: Icon(Icons.chevron_right, color: AppColors.gray5, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _ContactFooter(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// 마이페이지 하단 문의 정보 (회원탈퇴 밑 빈 공간)
class _ContactFooter extends StatelessWidget {
  const _ContactFooter();

  static const String _email = 'jeong01101095@gmail.com';
  static const String _siteUrl = 'https://1000meal.store';

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.caption2.copyWith(color: AppColors.gray6);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => openExternalUrl('mailto:$_email'),
            borderRadius: BorderRadius.circular(2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text('문의 : jeong01101095@gmail.com', style: style),
            ),
          ),
          Text('  |  ', style: style),
          InkWell(
            onTap: () => openExternalUrl(_siteUrl),
            borderRadius: BorderRadius.circular(2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text('About 오늘순밥', style: style),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Widget? trailing;
  const _MenuItem({required this.label, required this.onTap, this.labelColor, this.trailing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.subtitle1.copyWith(
                  color: labelColor ?? AppColors.black,
                  height: 32 / 16,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// 푸시 알림 동의 토글 행 (비밀번호 변경 / 로그아웃 사이)
class _PushAgreeRow extends StatelessWidget {
  const _PushAgreeRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '푸시 알림 동의',
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.black,
                  height: 32 / 16,
                ),
              ),
            ),
            _AppPushToggle(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// active: 배경 FF6E3F, default: 배경 D9D9D9, 내부 버튼 항상 FFFFFF·동일 크기
class _AppPushToggle extends StatelessWidget {
  const _AppPushToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const Color _activeTrack = AppColors.orange;
  static const Color _defaultTrack = AppColors.gray3;
  static const Color _thumb = AppColors.white;

  static const double _trackWidth = 52;
  static const double _trackHeight = 30;
  static const double _thumbSize = 24;
  static const double _thumbMargin = 3;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _trackWidth,
        height: _trackHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: _trackWidth,
              height: _trackHeight,
              decoration: BoxDecoration(
                color: value ? _activeTrack : _defaultTrack,
                borderRadius: BorderRadius.circular(_trackHeight / 2),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _thumbMargin),
                child: Container(
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: _thumb,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.15),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



