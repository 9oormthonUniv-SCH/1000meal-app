import 'package:flutter/material.dart';
import '../../../util/colors.dart';
import '../../../util/typography.dart';

/// 관리자 페이지: 영업 중 / 영업 종료 토글이 달린 카드
class AdminOpenStatusCard extends StatelessWidget {
  const AdminOpenStatusCard({
    super.key,
    required this.isOpen,
    required this.loading,
    this.onToggle,
  });

  final bool isOpen;
  final bool loading;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final bg = isOpen ? AppColors.blue : AppColors.white;
    final fg = isOpen ? AppColors.white : AppColors.gray6;
    final toggleTrack = isOpen ? AppColors.white : AppColors.gray3;
    final toggleThumb = isOpen ? AppColors.blue : AppColors.white;

    return InkWell(
      onTap: loading ? null : onToggle,
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
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
                  Text(
                    isOpen ? '영업 중' : '영업 종료',
                    style: AppTypography.headline4.copyWith(
                      color: isOpen ? AppColors.white : AppColors.gray5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (loading)
                    Text(
                      '처리 중...',
                      style: AppTypography.caption2.copyWith(color: fg),
                    ),
                ],
              ),
              Positioned(
                bottom: 10,
                right: 14,
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: 64,
                    height: 36,
                    decoration: BoxDecoration(
                      color: toggleTrack,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: isOpen
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: toggleThumb,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
