import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
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
      appBar: AppBarCommon(
        title: '설정',
        centerTitle: true,
        backEnabled: !disabled,
      ),
      body: Column(
        children: [
          _SettingsItem(
            label: '이메일 변경',
            onTap: disabled
                ? null
                : () => Navigator.of(
                    context,
                  ).pushNamed(ChangeEmailScreen.routeName),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _SettingsItem(
            label: '비밀번호 변경',
            onTap: disabled
                ? null
                : () => Navigator.of(
                    context,
                  ).pushNamed(FindAccountScreen.routeName, arguments: 'pw'),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _SettingsItem(
            label: '로그아웃',
            onTap: disabled
                ? null
                : () async {
                    final ok = await AppConfirmDialog.showYesNo(
                      context,
                      content: '로그아웃 하시겠습니까?',
                      noLabel: '아니요',
                      yesLabel: '네',
                    );
                    if (ok != true) return;
                    await vm.logout();
                    if (!context.mounted) return;
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (r) => false, arguments: 3);
                  },
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _SettingsItem(
            label: '회원탈퇴',
            labelColor: const Color(0xFFEF4444),
            onTap: disabled
                ? null
                : () async {
                    final ok = await AppConfirmDialog.showCustom(
                      context,
                      content: '탈퇴하면 모든 기록이 사라집니다\n정말 탈퇴하시겠습니까?',
                      secondaryLabel: '취소',
                      primaryLabel: '탈퇴하기',
                      primaryOnLeft: true,
                      primaryBg: AppColors.gray2,
                      primaryFg: Colors.red,
                      secondaryBg: AppColors.gray7,
                      secondaryFg: Colors.white,
                    );
                    if (ok != true) return;
                    final success = await vm.deleteAccount();
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        LoginScreen.routeName,
                        (r) => false,
                      );
                    } else {
                      AppSnackBar.show(
                        context,
                        vm.errorMessage ?? '회원 탈퇴에 실패했습니다. 다시 시도해주세요.',
                      );
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
  final FontWeight fontWeight;
  const _SettingsItem({
    required this.label,
    required this.onTap,
    this.labelColor,
    this.fontWeight = FontWeight.w600, // 추후 디자인 qa 후 조정...
  });

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
                style: AppTypography.body3.copyWith(
                  color: labelColor ?? const Color(0xFF111827),
                  fontWeight: fontWeight,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 22),
          ],
        ),
      ),
    );
  }
}
