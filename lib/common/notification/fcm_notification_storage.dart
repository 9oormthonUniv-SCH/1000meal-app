import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FCM으로 수신한 알림을 로컬에 저장 (웹의 fcm_notifications_v1와 동일 용도).
class StoredFcmNotification {
  final String id;
  final String title;
  final String body;
  final String createdAt;
  final Map<String, String>? data;

  StoredFcmNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt,
        if (data != null) 'data': data,
      };

  factory StoredFcmNotification.fromJson(Map<String, dynamic> json) {
    return StoredFcmNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      data: json['data'] is Map ? Map<String, String>.from(json['data'] as Map) : null,
    );
  }
}

const String _key = 'fcm_notifications_v1';
const int _maxItems = 50;

Future<List<StoredFcmNotification>> readStoredFcmNotifications() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => StoredFcmNotification.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> appendStoredFcmNotification(StoredFcmNotification noti) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final list = await readStoredFcmNotifications();
    final next = [noti, ...list].take(_maxItems).toList();
    await prefs.setString(_key, jsonEncode(next.map((e) => e.toJson()).toList()));
  } catch (_) {}
}

/// FCM RemoteMessage를 받아 로컬에 저장 (포그라운드/백그라운드/알림 탭 진입 공통).
Future<void> saveRemoteMessageToStorage(RemoteMessage message) async {
  final n = message.notification;
  final title = n?.title ?? '알림';
  final body = n?.body ?? '';
  final noti = StoredFcmNotification(
    id: message.messageId ?? 'msg_${message.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    body: body,
    createdAt: DateTime.now().toIso8601String(),
    data: message.data.isNotEmpty
        ? message.data.map((k, v) => MapEntry(k, v?.toString() ?? ''))
        : null,
  );
  await appendStoredFcmNotification(noti);
}
