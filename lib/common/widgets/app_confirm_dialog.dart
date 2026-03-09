import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

import 'app_button.dart';

/// 앱 공통 확인 팝업. 디자인 스펙: 제목/본문 색상, 버튼 배경·텍스트 색상 지정 가능.
/// - [AppConfirmDialog.showYesNo]: 로그아웃, 영업 전/재고 0 등
/// - [AppConfirmDialog.showDiscard]: "저장하지 않고 나가시겠습니까?"
/// - [AppConfirmDialog.showDelete]: "이 동작은 취소할 수 없습니다 / 삭제하시겠습니까?"
/// - [AppConfirmDialog.showCustom]: 회원탈퇴 등 커스텀 문구·버튼
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    this.title,
    required this.content,
    required this.secondaryLabel,
    required this.primaryLabel,
    required this.onSecondary,
    required this.onPrimary,
    this.primaryVariant = AppButtonVariant.primaryBlue,
    this.loading = false,
  });

  final String? title;
  final String content;
  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback onSecondary;
  final VoidCallback onPrimary;
  final AppButtonVariant primaryVariant;
  final bool loading;

  static const Color _grayLine1 = AppColors.gray7;
  static const Color _grayLine2 = AppColors.black;
  static const Color _btnSecondaryBg = AppColors.gray2;
  static const Color _btnSecondaryFg = AppColors.gray7;
  static const Color _btnPrimaryGrayBg = AppColors.gray7;
  static const Color _btnPrimaryGrayFg = AppColors.white;
  static const Color _blueHighlight = AppColors.blue;

  /// 로그아웃: 아니오 F1F1F1/767676, 네 767676/FFFFFF
  static Future<bool?> showYesNo(
    BuildContext context, {
    required String content,
    String? title,
    String noLabel = '아니요',
    String yesLabel = '네',
    Widget? contentWidget,
    Color? secondaryBg,
    Color? secondaryFg,
    Color? primaryBg,
    Color? primaryFg,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogContent(
        title: title,
        content: content,
        contentWidget: contentWidget,
        secondaryLabel: noLabel,
        primaryLabel: yesLabel,
        onSecondary: () => Navigator.of(ctx).pop(false),
        onPrimary: () => Navigator.of(ctx).pop(true),
        primaryVariant: AppButtonVariant.primaryBlue,
        loading: false,
        titleColor: _grayLine2,
        contentColor: _grayLine2,
        contentLine1Color: null,
        contentLine2Color: null,
        secondaryBg: secondaryBg ?? _btnSecondaryBg,
        secondaryFg: secondaryFg ?? _btnSecondaryFg,
        primaryBg: primaryBg ?? _btnPrimaryGrayBg,
        primaryFg: primaryFg ?? _btnPrimaryGrayFg,
        primaryOnLeft: false,
      ),
    );
  }

  /// 변경 사항이 있습니다(767676) / 저장하지 않고 나가시겠습니까?(1A1A1A). 좌측 아니요 F1F1F1/767676, 우측 네 767676/FFFFFF
  static Future<bool?> showDiscard(
    BuildContext context, {
    String title = '변경 사항이 있습니다',
    String content = '저장하지 않고 나가시겠습니까?',
    String cancelLabel = '아니요',
    String leaveLabel = '네',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _DialogContent(
        title: title,
        content: content,
        secondaryLabel: cancelLabel,
        primaryLabel: leaveLabel,
        onSecondary: () => Navigator.of(ctx).pop(false),
        onPrimary: () => Navigator.of(ctx).pop(true),
        primaryVariant: AppButtonVariant.primaryBlue,
        titleColor: _grayLine1,
        contentColor: _grayLine2,
        secondaryBg: _btnSecondaryBg,
        secondaryFg: _btnSecondaryFg,
        primaryBg: _btnPrimaryGrayBg,
        primaryFg: _btnPrimaryGrayFg,
        primaryOnLeft: false,
      ),
    );
  }

  /// 이 동작은 취소할 수 없습니다(767676) / 삭제하시겠습니까?(1A1A1A). 취소 F1F1F1/767676, 삭제 767676/FFFFFF
  static Future<bool?> showDelete(
    BuildContext context, {
    String? title,
    required String content,
    String cancelLabel = '아니요',
    String confirmLabel = '삭제',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _DialogContent(
        title: title,
        content: content,
        secondaryLabel: cancelLabel,
        primaryLabel: confirmLabel,
        onSecondary: () => Navigator.of(ctx).pop(false),
        onPrimary: () => Navigator.of(ctx).pop(true),
        primaryVariant: AppButtonVariant.primaryBlue,
        contentLine1Color: _grayLine1,
        contentLine2Color: _grayLine2,
        secondaryBg: _btnSecondaryBg,
        secondaryFg: _btnSecondaryFg,
        primaryBg: _btnPrimaryGrayBg,
        primaryFg: _btnPrimaryGrayFg,
        primaryOnLeft: false,
      ),
    );
  }

  /// 회원탈퇴 등: 좌측 탈퇴하기 F1F1F1/빨강, 우측 취소 767676/FFFFFF (primaryOnLeft: true)
  static Future<bool?> showCustom(
    BuildContext context, {
    String? title,
    required String content,
    required String secondaryLabel,
    required String primaryLabel,
    AppButtonVariant primaryVariant = AppButtonVariant.primaryBlue,
    bool loading = false,
    bool primaryOnLeft = false,
    Color? titleColor,
    Color? contentColor,
    Color? contentLine1Color,
    Color? contentLine2Color,
    Color? secondaryBg,
    Color? secondaryFg,
    Color? primaryBg,
    Color? primaryFg,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _DialogContent(
        title: title,
        content: content,
        secondaryLabel: secondaryLabel,
        primaryLabel: primaryLabel,
        onSecondary: () => Navigator.of(ctx).pop(false),
        onPrimary: () => Navigator.of(ctx).pop(true),
        primaryVariant: primaryVariant,
        loading: loading,
        primaryOnLeft: primaryOnLeft,
        titleColor: titleColor,
        contentColor: contentColor ?? _grayLine2,
        contentLine1Color: contentLine1Color,
        contentLine2Color: contentLine2Color,
        secondaryBg: secondaryBg ?? _btnSecondaryBg,
        secondaryFg: secondaryFg ?? _btnSecondaryFg,
        primaryBg: primaryBg ?? _btnPrimaryGrayBg,
        primaryFg: primaryFg ?? _btnPrimaryGrayFg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogContent(
      title: title,
      content: content,
      secondaryLabel: secondaryLabel,
      primaryLabel: primaryLabel,
      onSecondary: onSecondary,
      onPrimary: onPrimary,
      primaryVariant: primaryVariant,
      loading: loading,
    );
  }
}

class _DialogContent extends StatelessWidget {
  const _DialogContent({
    this.title,
    required this.content,
    this.contentWidget,
    required this.secondaryLabel,
    required this.primaryLabel,
    required this.onSecondary,
    required this.onPrimary,
    this.primaryVariant = AppButtonVariant.primaryBlue,
    this.loading = false,
    this.titleColor,
    this.contentColor,
    this.contentLine1Color,
    this.contentLine2Color,
    this.secondaryBg,
    this.secondaryFg,
    this.primaryBg,
    this.primaryFg,
    this.primaryOnLeft = false,
  });

  final String? title;
  final String content;
  final Widget? contentWidget;
  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback onSecondary;
  final VoidCallback onPrimary;
  final AppButtonVariant primaryVariant;
  final bool loading;
  final Color? titleColor;
  final Color? contentColor;
  final Color? contentLine1Color;
  final Color? contentLine2Color;
  final Color? secondaryBg;
  final Color? secondaryFg;
  final Color? primaryBg;
  final Color? primaryFg;
  final bool primaryOnLeft;

  @override
  Widget build(BuildContext context) {
    final hasTwoLineStyle = content.contains('\n') && (contentLine1Color != null || contentLine2Color != null);
    final parts = hasTwoLineStyle ? content.split('\n') : null;

    Widget contentChild;
    if (contentWidget != null) {
      contentChild = contentWidget!;
    } else if (parts != null && parts.length >= 2) {
      contentChild = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            parts[0],
            style: AppTypography.body2.copyWith(color: contentLine1Color ?? AppColors.gray7, height: 1.45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            parts[1],
            style: AppTypography.body2.copyWith(color: contentLine2Color ?? AppColors.black, height: 1.45),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      contentChild = Text(
        content,
        style: AppTypography.body2.copyWith(color: contentColor ?? AppColors.gray7, height: 1.45),
        textAlign: TextAlign.center,
      );
    }

    final leftLabel = primaryOnLeft ? primaryLabel : secondaryLabel;
    final leftOnPressed = primaryOnLeft ? onPrimary : onSecondary;
    final rightLabel = primaryOnLeft ? secondaryLabel : primaryLabel;
    final rightOnPressed = primaryOnLeft ? onSecondary : onPrimary;
    final leftBg = primaryOnLeft ? primaryBg : secondaryBg;
    final leftFg = primaryOnLeft ? primaryFg : secondaryFg;
    final rightBg = primaryOnLeft ? secondaryBg : primaryBg;
    final rightFg = primaryOnLeft ? secondaryFg : primaryFg;
    final rightVariant = primaryOnLeft ? AppButtonVariant.secondary : primaryVariant;
    final rightLoading = primaryOnLeft ? false : loading;

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12,48, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null && title!.isNotEmpty) ...[
                Text(
                  title!,
                  style: AppTypography.subtitle1.copyWith(fontWeight: FontWeight.w700, color: titleColor ?? AppColors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              contentChild,
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: leftLabel,
                      variant: AppButtonVariant.secondary,
                      backgroundColor: leftBg,
                      foregroundColor: leftFg,
                      onPressed: loading && primaryOnLeft ? null : leftOnPressed,
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: rightLabel,
                      variant: rightVariant,
                      backgroundColor: rightBg,
                      foregroundColor: rightFg,
                      onPressed: rightLoading ? null : rightOnPressed,
                      height: 48,
                      loading: rightLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
