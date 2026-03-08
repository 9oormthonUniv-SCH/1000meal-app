import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

import '../../../common/notification/fcm_notification_storage.dart';
import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/notification_list_item.dart';

/// 알림 화면 (웹 notification 페이지와 동일: 수신 알림 목록 + 설정 안내)
class NotificationSettingsScreen extends StatefulWidget {
  static const routeName = '/notification-settings';

  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  List<StoredFcmNotification> _list = [];
  bool _loading = true;
  bool _isLoggedInForNotifications = false;
  final Set<String> _readIds = {};

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final accountKey = await getCurrentAccountKeyForNotifications();
      if (accountKey == null || accountKey.isEmpty) {
        if (!mounted) return;
        setState(() {
          _list = [];
          _readIds.clear();
          _isLoggedInForNotifications = false;
          _loading = false;
        });
        return;
      }
      final notifications = await readStoredFcmNotifications();
      final readIds = await readFcmNotificationReadIds();
      if (!mounted) return;
      setState(() {
        _list = notifications;
        _readIds.clear();
        _readIds.addAll(readIds);
        _isLoggedInForNotifications = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _markAsRead(String id) {
    setState(() => _readIds.add(id));
    addFcmNotificationReadId(id);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarCommon(
        showBack: true,
        title: '알림',
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.black),
            onPressed: _loading ? null : () => _load(),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Text(
                      _isLoggedInForNotifications ? '아직 받은 알림이 없습니다.' : '로그인 후 알림을 확인할 수 있습니다.',
                      style: AppTypography.body4.copyWith(color: AppColors.gray7),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _list.length,
                      itemBuilder: (context, index) {
                        final item = _list[index];
                        final timeRight = _formatTimeAgo(item.createdAt);
                        final isRead = _readIds.contains(item.id);
                        return NotificationListItem(
                          title: item.title,
                          body: item.body,
                          timeRight: timeRight,
                          isRead: isRead,
                          onTap: () => _markAsRead(item.id),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppColors.gray3,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  /// "몇 분 전", "몇 시간 전", "몇 일 전" 형식
  String _formatTimeAgo(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 31) return '${diff.inDays}일 전';
      return '${diff.inDays ~/ 30}달 전';
    } catch (_) {
      return '';
    }
  }
}
