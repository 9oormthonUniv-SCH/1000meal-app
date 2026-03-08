import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

class MapRefreshButton extends StatelessWidget {
  final VoidCallback onPressed;

  const MapRefreshButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.gray4, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, size: 12, color: AppColors.gray6),
              const SizedBox(width: 8),
              Text(
                '새로고침',
                style: AppTypography.caption1.copyWith(
                  color: AppColors.gray6,
                  height: 20 / 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
