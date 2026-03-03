import 'package:flutter/material.dart';

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 28),
          ],
        ),
      ),
    );
  }
}
