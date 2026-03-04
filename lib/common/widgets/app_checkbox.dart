import 'package:flutter/material.dart';

/// 앱 공통 체크박스. 피그마 디자인 시스템 적용 전까지 스타일 통일.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor;

  static const Color _defaultActive = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? _defaultActive,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }
}
