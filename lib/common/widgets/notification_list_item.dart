import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

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

  /// 읽음: 흰색 배경, 안읽음: 피그마 bg-red-50 → orangeSelected
  static const Color _readBg = AppColors.white;
  static const Color _unreadBg = AppColors.orangeSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isRead ? _readBg : _unreadBg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 19)],
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
                            style: AppTypography.subtitle1.copyWith(
                              color: AppColors.black,
                              fontSize: 16,
                              height: 32 / 16,
                            ),
                          ),
                        ),
                        if (timeRight != null && timeRight!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeRight!,
                            style: AppTypography.caption2.copyWith(
                              color: AppColors.gray7,
                              height: 20 / 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (body != null && body!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body!,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.gray7,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 32 / 16,
                        ),
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
