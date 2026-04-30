import 'package:flutter/material.dart';
import 'package:meal_app/util/typography.dart';
import '../../../util/colors.dart';

/// 관리자 페이지: 메뉴 관리 등 가로 전체 카드 (제목 + 우측 화살표)
class AdminWideCard extends StatelessWidget {
  const AdminWideCard({
    super.key,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: AppTypography.headline4.copyWith()),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.gray6,
                  size: 28,
                ),
          ],
        ),
      ),
    );
  }
}
