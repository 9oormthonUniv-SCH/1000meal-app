import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

/// 매장 상세페이지용 "영업 중" / "영업 종료". (지도 바텀시트·다른 매장 카드에서도 동일 스타일)
/// 피그마: 영업 중 = text-orange-400 text-xs font-semibold, 영업 종료 = neutral
class StoreOpenStatusBadge extends StatelessWidget {
  const StoreOpenStatusBadge({
    super.key,
    required this.isOpen,
    this.labelOpen = '영업 중',
    this.labelClosed = '영업 종료',
  });

  final bool isOpen;
  final String labelOpen;
  final String labelClosed;

  @override
  Widget build(BuildContext context) {
    return Text(
      isOpen ? labelOpen : labelClosed,
      style: AppTypography.caption1.copyWith(
        color: isOpen ? AppColors.orange : AppColors.gray7,
        fontSize: 12,
        height: 20 / 12,
      ),
    );
  }
}
