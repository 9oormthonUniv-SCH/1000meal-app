import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'fcm_notification_storage.dart';

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel',
  '알림',
  description: '푸시 알림',
  importance: Importance.high,
  playSound: true,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> _saveMessage(RemoteMessage message) async {
  await saveRemoteMessageToStorage(message);
}

/// FCM 포그라운드 수신 시 Android에서 로컬 알림으로 표시하기 위한 초기화.
/// iOS는 main에서 setForegroundNotificationPresentationOptions 호출로 처리.
Future<void> initPushNotificationDisplay() async {
  if (Platform.isAndroid) {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }
}

/// 포그라운드에서 FCM 메시지 수신 시 호출 (main에서 등록)
void setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _saveMessage(message); // fire-and-forget
    if (Platform.isAndroid) {
      final notification = message.notification;
      final title = notification?.title ?? '알림';
      final body = notification?.body ?? '';
      _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            playSound: true,
          ),
        ),
      );
    }
    if (kDebugMode) {
      debugPrint('FCM 포그라운드 수신: ${message.notification?.title}');
    }
  });
}
