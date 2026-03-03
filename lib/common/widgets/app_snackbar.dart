import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 주황색 토스트(스낵바) 공통 스타일.
/// ScaffoldMessenger 대신 [AppSnackBar.show]를 사용하면 됩니다.
abstract class AppSnackBar {
  static const Color _backgroundColor = Color(0xFFF97316);
  static const Duration _defaultDuration = Duration(seconds: 2);

  /// 주황색 스타일로 스낵바 표시.
  /// [centered]가 true면 화면 가운데 오버레이로 표시합니다.
  static void show(
    BuildContext context,
    String message, {
    Duration? duration,
    bool centered = false,
  }) {
    if (centered) {
      _showCentered(context, message, duration ?? _defaultDuration);
      return;
    }
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

  static void _showCentered(BuildContext context, String message, Duration duration) {
    final overlay = Navigator.of(context).overlay;
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(duration, () {
      try {
        entry.remove();
      } catch (_) {}
    });
  }
}
