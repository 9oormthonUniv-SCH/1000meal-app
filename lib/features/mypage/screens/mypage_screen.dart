import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/models/role.dart';
import '../viewmodels/mypage_view_model.dart';

class MyPageScreen extends StatefulWidget {
  static const routeName = '/mypage';

  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<MyPageViewModel>().load();
      if (!mounted) return;
      final vm = context.read<MyPageViewModel>();
      if (vm.shouldRelogin) {
        await vm.logout();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyPageViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: vm.loading && vm.me == null
          ? const Center(child: CircularProgressIndicator())
          : _Body(vm: vm),
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
    final badgeBg = isStudent ? const Color(0xFFFFEDD5) : const Color(0xFFDBEAFE);
    final badgeFg = isStudent ? const Color(0xFFEA580C) : const Color(0xFF2563EB);
    final badgeText = isStudent ? '학생' : '관리자';

    return Container(
      color: const Color(0xFFF3F4F6),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
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
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(badgeText, style: TextStyle(fontSize: 12, color: badgeFg, fontWeight: FontWeight.w700)),
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
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MenuItem(
                  label: '비밀번호 변경',
                  onTap: () => Navigator.of(context).pushNamed('/find-account', arguments: 'pw'),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MenuItem(
                  label: '로그아웃',
                  onTap: () async {
                    await vm.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                  },
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
  const _MenuItem({required this.label, required this.onTap, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Text(
          label,
          style: TextStyle(fontSize: 14, color: labelColor ?? const Color(0xFF374151)),
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


