import 'package:flutter/material.dart';
import '../util/colors.dart';

enum HomeTabType { todayMeal, notice }

class HomeSegmentedTabBar extends StatelessWidget {
  final HomeTabType selected;
  final ValueChanged<HomeTabType> onChanged;

  const HomeSegmentedTabBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 오늘의 천밥 | 공지사항 탭 버튼
        _TabPillButton(
          label: '오늘의 천밥',
          isSelected: selected == HomeTabType.todayMeal,
          onTap: () => onChanged(HomeTabType.todayMeal),
        ),
        const SizedBox(width: 8),
        _TabPillButton(
          label: '공지사항',
          isSelected: selected == HomeTabType.notice,
          onTap: () => onChanged(HomeTabType.notice), // 추후 공지사항 페이지 생성
        ),
      ],
    );
  }
}

class _TabPillButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabPillButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected
        ? AppColors.primary
        : const Color(0xFFD9D9D9);
    final Color textColor = isSelected ? AppColors.primary : AppColors.textSub;

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        height: 31,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
