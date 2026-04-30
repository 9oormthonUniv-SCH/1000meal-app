import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

import '../../../common/notification/fcm_notification_storage.dart';
import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/notification_list_item.dart';
import '../../../common/widgets/profile_card.dart';
import '../../auth/screens/login_screen.dart';

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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isLoggedInForNotifications) {
      return _buildLoginRequiredView();
    }
    if (_list.isEmpty) {
      return _buildEmptyNotificationView();
    }
    return ListView.builder(
      itemCount: _list.length,
      itemBuilder: (context, index) {
        final item = _list[index];
        final timeRight = _formatTimeAgo(item.createdAt);
        final isRead = _readIds.contains(item.id);
        final storeId = item.data != null && item.data!['storeId'] != null
            ? int.tryParse(item.data!['storeId']!)
            : null;
        return NotificationListItem(
          title: item.title,
          body: item.body,
          timeRight: timeRight,
          isRead: isRead,
          onTap: () => _markAsRead(item.id),
          leading: buildStoreLeadingWidget(storeId, size: 48),
        );
      },
    );
  }

  Widget _buildLoginRequiredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '로그인이 필요해요',
              style: AppTypography.headline4.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '로그인하면 즐겨찾기 한 가게의 알림을 받을 수 있어요',
              style: AppTypography.body4.copyWith(color: AppColors.gray7),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: '로그인 하기',
                variant: AppButtonVariant.primary,
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                height: 52,
                onPressed: () {
                  Navigator.of(context).pushNamed(LoginScreen.routeName);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotificationView() {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '새로운 알림이 없어요',
                  style: AppTypography.headline4.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '가게를 즐겨찾기하면 새 메뉴가 올라올 때와 품절이 임박했을 때 알려드려요',
                  style: AppTypography.body4.copyWith(color: AppColors.gray7),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
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
