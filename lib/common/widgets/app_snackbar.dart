import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 주황색 토스트(스낵바) 공통 스타일.
/// ScaffoldMessenger 대신 [AppSnackBar.show]를 사용하면 됩니다.
abstract class AppSnackBar {
  static const Color _backgroundColor = Color(0xFFF97316);
  static const Duration _defaultDuration = Duration(seconds: 2);

  /// 주황색 스타일로 스낵바 표시.
  static void show(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? _defaultDuration,
      ),
    );
  }
}
