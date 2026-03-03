import 'package:flutter/material.dart';

/// 마이페이지/관리자 상단 프로필 카드 공통 레이아웃 (위치·크기·그림자 통일)
const EdgeInsets profileCardMargin = EdgeInsets.only(left: 16, right: 16, top: 8);
const EdgeInsets profileCardPadding = EdgeInsets.all(16);
const BoxDecoration profileCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(14)),
  boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 4))],
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 24),
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

  static const Color _studentBadge = Color(0xFFFF623F);

  @override
  Widget build(BuildContext context) {
    final bg = badgeBgColor ?? _studentBadge;

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
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.person, color: Color(0xFF9CA3AF), size: 30),
              ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// 관리자 페이지: 매장명 + 관리자 뱃지
class AdminProfileCard extends StatelessWidget {
  const AdminProfileCard({
    super.key,
    required this.storeName,
    this.leading,
  });

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
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              storeName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '관리자',
              style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
