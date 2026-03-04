import 'package:flutter/material.dart';

/// 상단 텍스트 2탭 (아이디 찾기 / 비밀번호 찾기 등). 피그마 공통 탭 스타일.
class AppSegmentTabs<T> extends StatelessWidget {
  const AppSegmentTabs({
    super.key,
    required this.value,
    required this.onChanged,
    required this.tabs,
    this.enabled = true,
  });

  final T value;
  final ValueChanged<T>? onChanged;
  final List<AppSegmentTab<T>> tabs;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tab in tabs)
          Expanded(
            child: _SegmentTabTile<T>(
              label: tab.label,
              value: tab.value,
              selected: value == tab.value,
              onTap: enabled && onChanged != null ? () => onChanged!(tab.value) : null,
            ),
          ),
      ],
    );
  }
}

class AppSegmentTab<T> {
  const AppSegmentTab({required this.label, required this.value});
  final String label;
  final T value;
}

class _SegmentTabTile<T> extends StatelessWidget {
  const _SegmentTabTile({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final T value;
  final bool selected;
  final VoidCallback? onTap;

  static const Color _activeColor = Color(0xFFF97316);
  static const Color _inactiveColor = Color(0xFF9CA3AF);
  static const Color _borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? _activeColor : _borderColor,
              width: selected ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? _activeColor : _inactiveColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
