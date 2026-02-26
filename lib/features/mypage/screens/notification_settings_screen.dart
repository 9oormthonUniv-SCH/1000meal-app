import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../common/notification/fcm_notification_storage.dart';
import '../../../common/widgets/app_snackbar.dart';

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
  String? _fcmToken;
  NotificationSettings? _settings;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final notifications = await readStoredFcmNotifications();
      final token = await FirebaseMessaging.instance.getToken();
      NotificationSettings? settings;
      if (Platform.isIOS) {
        settings = await FirebaseMessaging.instance.getNotificationSettings();
      }
      if (!mounted) return;
      setState(() {
        _list = notifications;
        _fcmToken = token;
        _settings = settings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '알림',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF374151)),
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
                      '아직 받은 알림이 없습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: _list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _list[index];
                        final time = _formatTime(item.createdAt);
                        return Container(
                          color: const Color(0xFFFFF7ED), // orange-50
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.body,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (Platform.isIOS && _settings != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '권한: ${_authorizationStatusText(_settings!.authorizationStatus)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: () {
                            AppSnackBar.show(
                              context,
                              Platform.isIOS
                                  ? '설정 > 알림에서 이 앱 알림을 켜주세요.'
                                  : '설정 > 앱 > 오늘순밥 > 알림에서 허용해 주세요.',
                            );
                          },
                          icon: const Icon(Icons.settings, size: 20),
                          label: const Text('앱 설정에서 알림 허용하기'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF97316),
                            side: const BorderSide(color: Color(0xFFF97316)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('MM.dd HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _authorizationStatusText(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return '허용됨';
      case AuthorizationStatus.denied:
        return '거부됨';
      case AuthorizationStatus.notDetermined:
        return '미선택';
      case AuthorizationStatus.provisional:
        return '임시 허용';
    }
  }
}
