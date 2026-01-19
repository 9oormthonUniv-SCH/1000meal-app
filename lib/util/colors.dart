import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFF6E3F);

  static const Color background = Color(0xFFF3F4F6);
  static const Color white = Colors.white;

  // 3. Text Colors
  static const Color textMain = Color(0xFF1A1A1A);
  static const Color textSub = Color(0xFF767676);

  // 4. Etc
  static const Color error = Color(0xFFEF4444);

  static List<BoxShadow> get evenShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 16,
      offset: const Offset(0, 0),
    ),
  ];
}
