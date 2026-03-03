import 'package:flutter/material.dart';

/// 재고 관리 페이지: 좌우 +/- 버튼 + 중앙 수량 입력
class AppQuantityStepper extends StatelessWidget {
  const AppQuantityStepper({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    required this.controller,
    required this.onChanged,
    required this.onCommit,
    this.enabled = true,
    this.valueColor,
  });

  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCommit;
  final bool enabled;
  final Color? valueColor;

  static const Color _disabledColor = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    final textColor = valueColor ?? (enabled ? const Color(0xFF1A1A1A) : _disabledColor);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _CircleButton(label: '–', onTap: onMinus, disabled: !enabled),
        const SizedBox(width: 14),
        SizedBox(
          width: 88,
          height: 36,
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'Pretendard',
              height: 1.0,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 0.72),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 0.72),
              ),
            ),
            onChanged: onChanged,
            onSubmitted: (_) => onCommit(),
            onEditingComplete: onCommit,
          ),
        ),
        const SizedBox(width: 14),
        _CircleButton(label: '+', onTap: onPlus, disabled: !enabled),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.label, required this.onTap, required this.disabled});

  final String label;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFBDBDBD).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.0)),
        ),
      ),
    );
  }
}
