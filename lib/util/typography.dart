import 'package:flutter/material.dart';

/// 확정 디자인 시스템 타이포그래피 (Pretendard, 자간 -2.5%)
/// Headline 1~5, Subtitle 1~2, Body 1~4, Caption 1~2
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Pretendard';

  /// 자간 -2.5% → letterSpacing = fontSize * -0.025
  static double letterSpacingFor(double fontSize) => fontSize * -0.025;

  // ---------- Headline ----------
  static TextStyle get headline1 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        height: 34 / 24,
        letterSpacing: letterSpacingFor(24),
      );
  static TextStyle get headline2 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 34 / 20,
        letterSpacing: letterSpacingFor(20),
      );
  static TextStyle get headline3 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        height: 34 / 18,
        letterSpacing: letterSpacingFor(18),
      );
  static TextStyle get headline4 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 28 / 18,
        letterSpacing: letterSpacingFor(18),
      );
  static TextStyle get headline5 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 18,
        height: 28 / 18,
        letterSpacing: letterSpacingFor(18),
      );

  // ---------- Subtitle ----------
  static TextStyle get subtitle1 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 34 / 16,
        letterSpacing: letterSpacingFor(16),
      );
  static TextStyle get subtitle2 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 34 / 16,
        letterSpacing: letterSpacingFor(16),
      );

  // ---------- Body ----------
  static TextStyle get body1 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 34 / 15,
        letterSpacing: letterSpacingFor(15),
      );
  static TextStyle get body2 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 15,
        height: 34 / 15,
        letterSpacing: letterSpacingFor(15),
      );
  static TextStyle get body3 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 22 / 14,
        letterSpacing: letterSpacingFor(14),
      );
  static TextStyle get body4 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 22 / 14,
        letterSpacing: letterSpacingFor(14),
      );

  // ---------- Caption ----------
  static TextStyle get caption1 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        height: 22 / 12,
        letterSpacing: letterSpacingFor(12),
      );
  static TextStyle get caption2 => TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 22 / 12,
        letterSpacing: letterSpacingFor(12),
      );
}
