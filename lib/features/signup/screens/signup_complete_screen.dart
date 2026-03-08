import 'package:flutter/material.dart';

import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_button.dart';
import '../../../util/colors.dart';
import '../../../util/typography.dart';

/// 회원가입 완료 화면. 체크 아이콘 + 안내 문구 + 로그인으로 돌아가기 버튼.
class SignupCompleteScreen extends StatelessWidget {
  static const routeName = '/signup/complete';

  const SignupCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarCommon(
        title: '',
        showBack: true,
        onBackPressed: () => _goToLogin(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '회원가입이 완료되었습니다!\n더 편리한 서비스를 즐겨보세요',
                        textAlign: TextAlign.center,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.gray7,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 28 / 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: AppButton(
                label: '로그인 화면으로 돌아가기',
                variant: AppButtonVariant.primary,
                large: true,
                onPressed: () => _goToLogin(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _goToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }
}
