import 'package:flutter/material.dart';
import 'package:meal_app/util/typography.dart';
import '../../../util/colors.dart';

/// 마이페이지/관리자 상단 프로필 카드 공통 레이아웃 (위치·크기·그림자 통일)
const EdgeInsets profileCardMargin = EdgeInsets.only(
  left: 16,
  right: 16,
  top: 8,
);
const EdgeInsets profileCardPadding = EdgeInsets.all(16);
BoxDecoration get profileCardDecoration => BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.all(Radius.circular(14)),
  boxShadow: [
    BoxShadow(color: AppColors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
  ],
);

/// 비로그인: 로그인 및 회원가입 CTA 카드
class GuestProfileCard extends StatelessWidget {
  const GuestProfileCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: profileCardMargin,
        padding: profileCardPadding,
        decoration: profileCardDecoration,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTypography.subtitle1.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.gray7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.gray6,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 로그인 후: 회원 이름 + 뱃지(학생/관리자)
class UserProfileCard extends StatelessWidget {
  const UserProfileCard({
    super.key,
    required this.username,
    required this.subtitle,
    required this.badgeText,
    this.badgeBgColor,
    this.leading,
  });

  final String username;
  final String subtitle;
  final String badgeText;
  final Color? badgeBgColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final bg = badgeBgColor ?? AppColors.orange;

    return Container(
      margin: profileCardMargin,
      padding: profileCardPadding,
      decoration: profileCardDecoration,
      child: Row(
        children: [
          leading ??
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.gray3,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.gray6,
                  size: 30,
                ),
              ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: AppTypography.subtitle1.copyWith(
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.gray7,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: AppTypography.caption1.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 관리자 페이지: 매장명 + 관리자 뱃지
class AdminProfileCard extends StatelessWidget {
  const AdminProfileCard({super.key, required this.storeName, this.leading});

  final String storeName;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: profileCardMargin,
      padding: profileCardPadding,
      decoration: profileCardDecoration,
      child: Row(
        children: [
          leading ??
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gray3,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(storeName, style: AppTypography.headline4.copyWith()),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '관리자',
              style: AppTypography.caption1.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
