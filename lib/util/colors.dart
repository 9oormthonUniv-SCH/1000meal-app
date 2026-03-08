import 'package:flutter/material.dart';

/// 확정 디자인 시스템 색상 팔레트
/// (Main, Sub, Gray, Semantic)
class AppColors {
  AppColors._();

  // ---------- Main ----------
  static const Color orange = Color(0xFFFF6E3F);
  static const Color lightOrange = Color(0xFFFFA588);
  static const Color orangeSelected = Color(0xFFFFF5F0);

  // ---------- Sub ----------
  static const Color blue = Color(0xFF54AAFF);
  static const Color lightBlue = Color(0xFF97CBFE);
  static const Color blueSelected = Color(0xFF83B4E5);

  // ---------- Gray ----------
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray1 = Color(0xFFF7F7F7);
  static const Color gray2 = Color(0xFFF1F1F1);
  static const Color gray3 = Color(0xFFE5E5E5);
  static const Color gray4 = Color(0xFFD3D3D3);
  static const Color gray5 = Color(0xFFBDBDBD);
  static const Color gray6 = Color(0xFFA1A1A1);
  static const Color gray7 = Color(0xFF767676);
  static const Color gray8 = Color(0xFF414141);
  static const Color black = Color(0xFF1A1A1A);

  // ---------- Semantic ----------
  static const Color error = Color(0xFFFF3B30);
  static const Color middle = Color(0xFFFF9500);
  static const Color success = Color(0xFF0DC200);

  // ---------- 호환용 별칭 (기존 코드용) ----------
  static const Color primary = orange;
  static const Color textMain = black;
  static const Color textSub = gray7;

  /// 디자인 시스템에 없는 배경색 (기존 사용처 유지용, 추후 그레이 팔레트로 통일 검토)
  static const Color background = Color(0xFFF3F4F6);

  static List<BoxShadow> get evenShadow => [
        BoxShadow(
          color: black.withValues(alpha: 0.15),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 0),
        ),
      ];
}
