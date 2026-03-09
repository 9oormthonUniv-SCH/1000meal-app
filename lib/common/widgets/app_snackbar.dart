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

  static OverlayEntry? _shakeOverlayEntry;
  static String? _shakeMessage;
  static final ValueNotifier<int> _shakeTrigger = ValueNotifier(0);

  /// 같은 메시지가 이미 표시 중이면 토스트를 새로 띄우지 않고 기존 토스트에 흔들기 애니메이션만 적용.
  /// QR 연속 스캔 등 중복 알림 방지용.
  static void showWithShake(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    final overlay = Navigator.of(context).overlay;
    if (overlay == null) return;
    final dur = duration ?? _defaultDuration;

    if (_shakeOverlayEntry != null && _shakeMessage == message) {
      _shakeTrigger.value++;
      return;
    }

    _removeShakeOverlay();
    _shakeMessage = message;
    _shakeOverlayEntry = OverlayEntry(
      builder: (ctx) => _ShakeableToast(
        message: message,
        duration: dur,
        shakeTrigger: _shakeTrigger,
        onRemove: () {
          _removeShakeOverlay();
        },
      ),
    );
    overlay.insert(_shakeOverlayEntry!);
  }

  static void _removeShakeOverlay() {
    try {
      _shakeOverlayEntry?.remove();
    } catch (_) {}
    _shakeOverlayEntry = null;
    _shakeMessage = null;
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

class _ShakeableToast extends StatefulWidget {
  final String message;
  final Duration duration;
  final ValueNotifier<int> shakeTrigger;
  final VoidCallback onRemove;

  const _ShakeableToast({
    required this.message,
    required this.duration,
    required this.shakeTrigger,
    required this.onRemove,
  });

  @override
  State<_ShakeableToast> createState() => _ShakeableToastState();
}

class _ShakeableToastState extends State<_ShakeableToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5, end: -4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    widget.shakeTrigger.addListener(_onShakeTrigger);
    Future.delayed(widget.duration, () {
      if (mounted) widget.onRemove();
    });
  }

  void _onShakeTrigger() {
    if (mounted) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    widget.shakeTrigger.removeListener(_onShakeTrigger);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_animation.value, 0),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.message,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
