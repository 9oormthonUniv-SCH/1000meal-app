import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_button.dart';
import '../../../util/colors.dart';
import '../../../util/typography.dart';

/// "'매장이름'에서 명부를 등록하시겠습니까?" 확인 화면
class QrConfirmScreen extends StatelessWidget {
  final String storeName;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  /// 디버그 빌드에서만 사용. 보낼 qrToken 끝 8자 표시 (개발 시 파싱 검증용).
  final String? debugTokenSuffix;

  const QrConfirmScreen({
    super.key,
    required this.storeName,
    required this.isLoading,
    required this.onBack,
    required this.onConfirm,
    this.debugTokenSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarCommon(
        title: '',
        onBackPressed: onBack,
        backEnabled: !isLoading,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icon/QR_Active.svg',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 24),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTypography.headline5.copyWith(color: AppColors.black),
                        children: [
                          TextSpan(
                            text: "'",
                            style: AppTypography.headline4.copyWith(color: AppColors.orange),
                          ),
                          TextSpan(
                            text: storeName,
                            style: AppTypography.headline4.copyWith(color: AppColors.orange),
                          ),
                          TextSpan(
                            text: "'",
                            style: AppTypography.headline4.copyWith(color: AppColors.orange),
                          ),
                          TextSpan(text: '에서 명부를 등록하시겠습니까?'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '명부 등록은 1일 1회만 가능합니다',
                      style: AppTypography.body4.copyWith(color: AppColors.gray7),
                    ),
                    if (kDebugMode && debugTokenSuffix != null && debugTokenSuffix!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        '보낼 토큰(끝): …$debugTokenSuffix',
                        style: AppTypography.caption2.copyWith(color: AppColors.gray6),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: '확인',
                    variant: AppButtonVariant.primary,
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.white,
                    height: 52,
                    loading: isLoading,
                    onPressed: isLoading ? null : onConfirm,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
