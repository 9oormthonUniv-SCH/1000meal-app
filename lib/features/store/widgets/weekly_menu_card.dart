import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

class WeeklyMenuCard extends StatelessWidget {
  final String dateLabel;
  final String dayLabel;
  final List<String> items;
  final bool isSelected;
  final int? showRemain;

  const WeeklyMenuCard({
    super.key,
    required this.dateLabel,
    required this.dayLabel,
    required this.items,
    this.isSelected = false,
    this.showRemain,
  });

  @override
  Widget build(BuildContext context) {
    final safeItems = items.where((e) => e.trim().isNotEmpty).toList(growable: false);
    final borderColor = isSelected ? AppColors.orange : AppColors.gray3;
    final dateDayColor = isSelected ? AppColors.orange : AppColors.gray7;

    return Container(
      width: 164,
      height: 320,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: AppTypography.caption2.copyWith(
                  color: dateDayColor,
                  height: 20 / 12,
                ),
              ),
              Text(
                dayLabel,
                style: AppTypography.caption2.copyWith(
                  color: dateDayColor,
                  height: 20 / 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 0.5, color: dateDayColor),
          const SizedBox(height: 14),
          Expanded(
            child: safeItems.isEmpty
                ? Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      '메뉴 없음',
                      style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                    ),
                  )
                : Align(
                    alignment: Alignment.topCenter,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: safeItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 1),
                        itemBuilder: (_, i) => Center(
                          child: Text(
                            safeItems[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          
        ],
      ),
    );
  }
}
