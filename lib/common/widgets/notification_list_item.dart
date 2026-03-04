import 'package:flutter/material.dart';

/// 알림 페이지 내 각 알림 항목. 읽음/안읽음에 따라 배경색 변경.
class NotificationListItem extends StatelessWidget {
  const NotificationListItem({
    super.key,
    required this.title,
    this.body,
    this.timeRight,
    this.isRead = false,
    this.leading,
    this.onTap,
  });

  final String title;
  final String? body;
  /// 우측 상단 표시 (예: "몇 분 전")
  final String? timeRight;
  final bool isRead;
  final Widget? leading;
  final VoidCallback? onTap;

  /// 읽음: 흰색 배경, 안읽음: 오렌지 50
  static const Color _readBg = Colors.white;
  static const Color _unreadBg = Color(0xFFFFF7ED);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isRead ? _readBg : _unreadBg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        if (timeRight != null && timeRight!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeRight!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (body != null && body!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
