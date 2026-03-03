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

const String _keyPrefix = 'fcm_notifications_v1_';
const String _keyReadIdsPrefix = 'fcm_notifications_read_ids_';
const String _keyCurrentAccount = 'fcm_current_account_key';
const int _maxItems = 50;

String _keyFor(String accountKey) => '${_keyPrefix}$accountKey';
String _keyReadIdsFor(String accountKey) => '${_keyReadIdsPrefix}$accountKey';

/// 로그인 시 현재 계정 식별자 설정, 로그아웃 시 null로 해제. 알림 저장/조회는 이 계정 키 기준으로 동작.
Future<void> setCurrentAccountKeyForNotifications(String? accountKey) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (accountKey == null || accountKey.isEmpty) {
      await prefs.remove(_keyCurrentAccount);
    } else {
      await prefs.setString(_keyCurrentAccount, accountKey);
    }
  } catch (_) {}
}

Future<String?> getCurrentAccountKeyForNotifications() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentAccount);
  } catch (_) {
    return null;
  }
}

/// 읽은 알림 id 목록 로드 (accountKey 없으면 현재 로그인 계정 기준).
Future<Set<String>> readFcmNotificationReadIds([String? accountKey]) async {
  try {
    final key = accountKey ?? await getCurrentAccountKeyForNotifications();
    if (key == null || key.isEmpty) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyReadIdsFor(key));
    if (raw == null) return {};
    final list = jsonDecode(raw) as List<dynamic>?;
    if (list == null) return {};
    return list.map((e) => e.toString()).toSet();
  } catch (_) {
    return {};
  }
}

/// 읽은 알림 id 추가 저장 (accountKey 없으면 현재 로그인 계정 기준).
Future<void> addFcmNotificationReadId(String id, [String? accountKey]) async {
  try {
    final key = accountKey ?? await getCurrentAccountKeyForNotifications();
    if (key == null || key.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final set = await readFcmNotificationReadIds(key);
    set.add(id);
    await prefs.setString(_keyReadIdsFor(key), jsonEncode(set.toList()));
  } catch (_) {}
}

/// 저장된 알림 목록 로드 (accountKey 없으면 현재 로그인 계정 기준). 비로그인 시 빈 목록.
Future<List<StoredFcmNotification>> readStoredFcmNotifications([String? accountKey]) async {
  try {
    final key = accountKey ?? await getCurrentAccountKeyForNotifications();
    if (key == null || key.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(key));
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

/// 현재 로그인 계정의 알림·읽음 데이터만 삭제 (선택적 호출, 로그아웃 시에는 호출하지 않음).
Future<void> clearCurrentAccountFcmNotifications() async {
  try {
    final key = await getCurrentAccountKeyForNotifications();
    if (key == null || key.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(key));
    await prefs.remove(_keyReadIdsFor(key));
  } catch (_) {}
}

Future<void> appendStoredFcmNotification(StoredFcmNotification noti, [String? accountKey]) async {
  try {
    final key = accountKey ?? await getCurrentAccountKeyForNotifications();
    if (key == null || key.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = await readStoredFcmNotifications(key);
    final next = [noti, ...list].take(_maxItems).toList();
    await prefs.setString(_keyFor(key), jsonEncode(next.map((e) => e.toJson()).toList()));
  } catch (_) {}
}

/// FCM RemoteMessage를 로컬에 저장. 현재 로그인 계정 키가 있을 때만 저장 (다른 계정 알림과 분리).
Future<void> saveRemoteMessageToStorage(RemoteMessage message) async {
  final key = await getCurrentAccountKeyForNotifications();
  if (key == null || key.isEmpty) return;
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
  await appendStoredFcmNotification(noti, key);
}
