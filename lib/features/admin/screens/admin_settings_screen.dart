import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/app_snackbar.dart';
import '../../auth/screens/find_account_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../mypage/screens/change_email_screen.dart';
import '../../mypage/viewmodels/mypage_view_model.dart';

class AdminSettingsScreen extends StatelessWidget {
  static const routeName = '/admin/settings';

  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyPageViewModel>();
    final disabled = vm.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '설정',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: disabled ? null : () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          _SettingsItem(
            label: '회원정보 수정',
            onTap: disabled ? null : () => Navigator.of(context).pushNamed(ChangeEmailScreen.routeName),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _SettingsItem(
            label: '비밀번호 변경',
            onTap: disabled ? null : () => Navigator.of(context).pushNamed(FindAccountScreen.routeName, arguments: 'pw'),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _SettingsItem(
            label: '로그아웃',
            onTap: disabled
                ? null
                : () async {
                    await vm.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false, arguments: 3);
                  },
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _SettingsItem(
            label: '회원탈퇴',
            labelColor: const Color(0xFFEF4444),
            onTap: disabled
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => const _DeleteAccountDialog(),
                    );
                    if (ok != true) return;
                    final success = await vm.deleteAccount();
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (r) => false);
                    } else {
                      AppSnackBar.show(context, vm.errorMessage ?? '회원 탈퇴에 실패했습니다. 다시 시도해주세요.');
                    }
                  },
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? labelColor;

  const _SettingsItem({required this.label, required this.onTap, this.labelColor});

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
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 22),
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
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFF6B7280),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('탈퇴'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

