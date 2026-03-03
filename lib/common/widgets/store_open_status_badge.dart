import 'package:flutter/material.dart';

/// 매장 상세페이지용 "영업중" / "영업 종료" 뱃지. (지도 바텀시트·다른 매장 카드에서도 동일 스타일 사용 가능)
class StoreOpenStatusBadge extends StatelessWidget {
  const StoreOpenStatusBadge({
    super.key,
    required this.isOpen,
    this.labelOpen = '영업중',
    this.labelClosed = '영업 종료',
  });

  final bool isOpen;
  final String labelOpen;
  final String labelClosed;

  static const Color _openBg = Color(0xFFDBEAFE);
  static const Color _openFg = Color(0xFF2563EB);
  static const Color _closedBg = Color(0xFFFEE2E2);
  static const Color _closedFg = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? _openBg : _closedBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? labelOpen : labelClosed,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isOpen ? _openFg : _closedFg,
        ),
      ),
    );
  }
}
