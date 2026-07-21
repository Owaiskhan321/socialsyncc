import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../logger/app_logger.dart';
import '../network/session_storage.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.d('FCM background: ${message.messageId}');
}

/// Generates FCM token and persists it in SharedPreferences.
abstract final class FcmService {
  static Future<void> initialize() async {
    if (kIsWeb) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    if (Platform.isIOS) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    await _refreshAndStoreToken();

    messaging.onTokenRefresh.listen((token) async {
      AppLogger.i('FCM token refreshed');
      await SessionStorage.saveFcmToken(token);
    });
  }

  static Future<String?> _refreshAndStoreToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await SessionStorage.saveFcmToken(token);
        AppLogger.i('FCM token stored');
      } else {
        AppLogger.w('FCM token empty');
      }
      return token;
    } catch (e, st) {
      AppLogger.e('FCM token failed', e, st);
      return null;
    }
  }

  /// Call after login if token was not ready at cold start.
  static Future<void> ensureTokenStored() => _refreshAndStoreToken();
}
