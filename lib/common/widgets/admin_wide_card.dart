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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 4),
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
