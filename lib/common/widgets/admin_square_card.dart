import 'package:flutter/material.dart';

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Stack(
            children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ],
            ),
            Positioned(bottom: 6, right: 6, child: trailing ?? const SizedBox.shrink()),
          ],
          ),
        ),
      ),
    );
  }
}
