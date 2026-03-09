import 'package:flutter/material.dart';

import '../../util/colors.dart';
import '../../util/typography.dart';

/// 앱 공통 버튼. 피그마 디자인 시스템 적용 전까지 스타일만 통일.
/// - [AppButtonVariant.primary]: 주황 배경 (로그인, 확인, 본인인증 후 가입하기 등)
/// - [AppButtonVariant.primaryBlue]: 파랑 배경 (팝업 "네" 등)
/// - [AppButtonVariant.secondary]: 회색 배경 (팝업 "아니오", "취소" 등)
/// - [AppButtonVariant.destructive]: 빨간 배경 (탈퇴하기 등)
/// - [AppButtonVariant.text]: 배경 없음, 텍스트만 (헤더 취소/삭제/선택 등)
/// - [AppButtonVariant.destructiveFilled]: 빨간 배경 채움 (설정 화면 탈퇴 버튼 등)
enum AppButtonVariant {
  primary,
  primaryBlue,
  secondary,
  destructive,
  destructiveFilled,
  text,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.large = false,
    this.height,
    this.minWidth,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  /// true: 세로 64, 텍스트 text-xl / semibold / Pretendard / leading-8
  final bool large;
  final double? height;
  final double? minWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;

  static Color get _primaryBg => AppColors.orange;
  static Color get _primaryBlueBg => AppColors.blue;
  static Color get _secondaryBg => AppColors.background;
  static Color get _secondaryFg => AppColors.gray7;
  static Color get _destructiveBg => AppColors.error;
  static Color get _destructiveBgLight => AppColors.gray1;
  static Color get _destructiveFg => AppColors.error;

  /// large일 때 버튼 라벨 스타일: white, 20px, semibold, Pretendard, height 32
  static TextStyle _largeLabelStyle(Color fg) => AppTypography.body2.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 32 / 20,
        color: fg,
      );

  @override
  Widget build(BuildContext context) {
    final baseHeight = variant == AppButtonVariant.text ? 40.0 : (large ? 60.0 : 48.0);
    final effectiveHeight = height ?? baseHeight;
    final isDisabled = onPressed == null && !loading;

    if (variant == AppButtonVariant.text) {
      return SizedBox(
        height: effectiveHeight,
        child: TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
foregroundColor: AppColors.gray6,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(label, style: AppTypography.body3.copyWith(color: AppColors.gray6)),
        ),
      );
    }

    Color bg;
    Color fg;
    switch (variant) {
      case AppButtonVariant.primary:
        final base = backgroundColor ?? _primaryBg;
        bg = isDisabled ? base.withValues(alpha: 0.4) : base;
        fg = foregroundColor ?? AppColors.white;
        break;
      case AppButtonVariant.primaryBlue:
        final baseBlue = backgroundColor ?? _primaryBlueBg;
        bg = isDisabled ? baseBlue.withValues(alpha: 0.5) : baseBlue;
        fg = foregroundColor ?? AppColors.white;
        break;
      case AppButtonVariant.secondary:
        bg = backgroundColor ?? _secondaryBg;
        fg = foregroundColor ?? AppColors.gray7;
        break;
      case AppButtonVariant.destructive:
        bg = backgroundColor ?? _destructiveBgLight;
        fg = foregroundColor ?? AppColors.error;
        break;
      case AppButtonVariant.destructiveFilled:
        final baseDest = backgroundColor ?? _destructiveBg;
        bg = isDisabled ? baseDest.withValues(alpha: 0.5) : baseDest;
        fg = foregroundColor ?? AppColors.white;
        break;
      case AppButtonVariant.text:
        bg = Colors.transparent;
        fg = foregroundColor ?? _secondaryFg;
        break;
    }

    final mw = minWidth;
    final width = mw == null ? double.infinity : (mw > 0 ? mw : null);
    return SizedBox(
      height: effectiveHeight,
      width: width,
      child: TextButton(
        onPressed: (loading || isDisabled) ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(variant == AppButtonVariant.destructive ? 18 : 12)),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled) && variant == AppButtonVariant.primary) {
              return (backgroundColor ?? _primaryBg).withValues(alpha: 0.4);
            }
            return bg;
          }),
        ),
        child: loading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Text(
                label,
                style: large ? _largeLabelStyle(fg) : AppTypography.body3.copyWith(color: fg),
              ),
      ),
    );
  }
}
