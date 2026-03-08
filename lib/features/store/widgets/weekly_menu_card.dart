import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';

class WeeklyMenuCard extends StatelessWidget {
  final String dateLabel;
  final String dayLabel;
  final List<String> items;

  const WeeklyMenuCard({
    super.key,
    required this.dateLabel,
    required this.dayLabel,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final safeItems = items.where((e) => e.trim().isNotEmpty).toList(growable: false);
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                ),
              ),
              Text(
                dayLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 10),
          Expanded(
            child: safeItems.isEmpty
                ? const Align(
                    alignment: Alignment.topLeft,
                    child: Text('메뉴 없음', style: TextStyle(color: Color(0xFF9CA3AF))),
                  )
                : ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: safeItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => Text(
                        safeItems[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
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
