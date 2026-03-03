import 'package:flutter/material.dart';

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
    final bg = isOpen ? const Color(0xFF93C5FD) : Colors.white;
    final fg = isOpen ? Colors.white : const Color(0xFF9CA3AF);
    final toggleTrack = isOpen ? Colors.white : const Color(0xFFD1D5DB);
    final toggleThumb = isOpen ? const Color(0xFF93C5FD) : Colors.white;

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
            boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Stack(
            children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? '영업 중' : '영업 종료',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isOpen ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 6),
                if (loading) Text('처리 중...', style: TextStyle(fontSize: 12, color: fg)),
              ],
            ),
            Positioned(
              bottom: 10,
              right: 10,
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
                    alignment: isOpen ? Alignment.centerRight : Alignment.centerLeft,
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
