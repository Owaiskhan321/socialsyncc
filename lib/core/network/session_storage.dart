import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

import '../logger/app_logger.dart';
import 'api_client.dart';

/// Notifies [GoRouter] when login state changes.
class AuthSessionListenable extends ChangeNotifier {
  void notifySessionChanged() => notifyListeners();
}

/// Persists auth session (token + user email).
class SessionStorage {
  SessionStorage._();

  static final AuthSessionListenable authListenable = AuthSessionListenable();

  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';
  static const _nameKey = 'auth_name';
  static const _fcmTokenKey = 'fcm_token';
  static const _userIdKey = 'auth_user_id';
  static const _deviceIdKey = 'device_id';

  static Future<void> saveSession({
    required String token,
    String? email,
    String? name,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (email != null) await prefs.setString(_emailKey, email);
    if (name != null) await prefs.setString(_nameKey, name);
    if (userId != null) await prefs.setString(_userIdKey, userId);
    AppLogger.i('Session saved');
    authListenable.notifySessionChanged();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> saveFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
    AppLogger.d('FCM token saved to preferences');
  }

  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  /// Stable per-install device id for social-login / push payloads.
  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _newUuid();
    await prefs.setString(_deviceIdKey, id);
    return id;
  }

  static String _newUuid() {
    final rnd = DateTime.now().microsecondsSinceEpoch;
    final a = (rnd & 0xffffffff).toRadixString(16).padLeft(8, '0');
    final b = ((rnd >> 16) & 0xffff).toRadixString(16).padLeft(4, '0');
    final c = (0x4000 | (rnd & 0x0fff)).toRadixString(16).padLeft(4, '0');
    final d = (0x8000 | ((rnd >> 8) & 0x3fff)).toRadixString(16).padLeft(4, '0');
    final e = (rnd * 31).toRadixString(16).padLeft(12, '0').substring(0, 12);
    return '$a-$b-$c-$d-$e';
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_userIdKey);
    AppLogger.i('Session cleared');
    authListenable.notifySessionChanged();
  }

  static Future<void> hydrateClient(ApiClient client) async {
    final token = await getToken();
    client.setToken(token);
  }
}
