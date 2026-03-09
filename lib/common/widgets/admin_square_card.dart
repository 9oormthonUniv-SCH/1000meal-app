import 'package:flutter/material.dart';
import '../../../util/typography.dart';
import '../../../util/colors.dart';

/// 관리자 페이지: 재고 관리 박스 (default/active 스타일 없음, 동일한 박스 + trailing)
class AdminSquareCard extends StatelessWidget {
  const AdminSquareCard({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.headline4.copyWith()),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.gray5,
                      ),
                    ),
                  ],
                ],
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: trailing ?? const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
