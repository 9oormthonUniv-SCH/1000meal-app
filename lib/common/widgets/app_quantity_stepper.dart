import 'package:flutter/material.dart';
import 'package:meal_app/util/typography.dart';

import 'app_button.dart';

/// 재고 관리 페이지: 좌우 +/- 버튼 + 중앙 수량 입력. 텍스트 입력 후 적용 버튼으로 반영.
class AppQuantityStepper extends StatefulWidget {
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

  @override
  State<AppQuantityStepper> createState() => _AppQuantityStepperState();
}

class _AppQuantityStepperState extends State<AppQuantityStepper> {
  /// 텍스트를 직접 입력했고 아직 적용하지 않은 상태일 때만 적용 버튼 표시
  bool _isDirty = false;

  static const Color _disabledColor = Color(0xFFBDBDBD);

  void _onChanged(String v) {
    widget.onChanged(v);
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _onCommit() {
    widget.onCommit();
    if (_isDirty) setState(() => _isDirty = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final textColor = widget.valueColor ?? (enabled ? const Color(0xFF1A1A1A) : _disabledColor);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _CircleButton(label: '–', onTap: widget.onMinus, disabled: !enabled),
        const SizedBox(width: 18),
        SizedBox(
          width: 100,
          height: 40,
          child: TextField(
            controller: widget.controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: AppTypography.fontFamily,
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
            onChanged: _onChanged,
            onSubmitted: (_) => _onCommit(),
            onEditingComplete: _onCommit,
          ),
        ),
        const SizedBox(width: 14),
        _CircleButton(label: '+', onTap: widget.onPlus, disabled: !enabled),
        if (_isDirty) ...[
          const SizedBox(width: 10),
          SizedBox(
            height: 40,
            child: AppButton(
              label: '적용',
              variant: AppButtonVariant.primaryBlue,
              backgroundColor: const Color(0xFF54AAFF),
              foregroundColor: Colors.white,
              height: 40,
              minWidth: 70,
              onPressed: enabled ? _onCommit : null,
            ),
          ),
        ],
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
