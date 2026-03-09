import 'package:flutter/material.dart';

import '../../util/colors.dart';

/// 앱 공통 체크박스. Figma: default = white + border neutral-500, active = orange-400 + white check.
/// activeColor 옵션으로 primary 외 색 지정 가능.
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

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? AppColors.orange,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }
}
