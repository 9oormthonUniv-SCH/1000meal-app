import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../auth/models/role.dart';
import '../../auth/repositories/auth_repository.dart';
import '../viewmodels/mypage_view_model.dart';

/// 로그인/비로그인 마이페이지 상단 카드 공통 레이아웃 (위치·크기 통일)
const EdgeInsets _profileCardMargin = EdgeInsets.only(left: 16, right: 16, top: 8);
const EdgeInsets _profileCardPadding = EdgeInsets.all(16);
const BoxDecoration _profileCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(14)),
  boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
);

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
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '마이페이지',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        // 알림 버튼: 미구현으로 숨김 (FCM 도입 후 복구)
        actions: const [],
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
      color: const Color(0xFFF3F4F6),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: _profileCardMargin,
                padding: _profileCardPadding,
                decoration: _profileCardDecoration,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '오늘순밥 로그인 및 회원가입',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '가게의 오픈·마감 소식을 실시간으로 알려드려요',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 24),
                    ],
                  ),
                ),
              ),
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
    final badgeBg = isStudent ? const Color(0xFFFF623F) : const Color(0xFF2563EB);
    final badgeFg = Colors.white;
    final badgeText = isStudent ? '학생' : '관리자';

    return Container(
      color: const Color(0xFFF3F4F6),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              margin: _profileCardMargin,
              padding: _profileCardPadding,
              decoration: _profileCardDecoration,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF9CA3AF), size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me.username,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          me.email,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(fontSize: 12, color: badgeFg, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _MenuItem(
                  label: '회원정보 수정',
                  onTap: () => Navigator.of(context).pushNamed('/change-email'),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 22),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MenuItem(
                  label: '비밀번호 변경',
                  onTap: () => Navigator.of(context).pushNamed('/find-account', arguments: 'pw'),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 22),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MenuItem(
                  label: '로그아웃',
                  onTap: () async {
                    await vm.logout();
                    if (!context.mounted) return;
                    // 로그아웃 후 마이페이지 탭에 머물면 me=null 상태로 무한 로딩될 수 있으므로 홈(0)으로 이동
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false, arguments: 0);
                  },
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 22),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MenuItem(
                  label: '회원탈퇴',
                  labelColor: const Color(0xFFEF4444),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => const _DeleteAccountDialog(),
                    );
                    if (ok != true) return;
                    final success = await vm.deleteAccount();
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(vm.errorMessage ?? '회원 탈퇴에 실패했습니다. 다시 시도해주세요.')),
                      );
                    }
                  },
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 22),
                ),
              ],
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
                style: TextStyle(fontSize: 14, color: labelColor ?? const Color(0xFF111827)),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: const Text(
        '탈퇴하면 모든 기록이 사라집니다\n정말 탈퇴하시겠습니까?',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.4),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('탈퇴하기', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF737373),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('취소', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


