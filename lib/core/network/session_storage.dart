import 'package:shared_preferences/shared_preferences.dart';

import '../logger/app_logger.dart';
import '../network/api_client.dart';

/// Persists auth session (token + user email).
class SessionStorage {
  SessionStorage._();

  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';
  static const _nameKey = 'auth_name';

  static Future<void> saveSession({
    required String token,
    String? email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (email != null) await prefs.setString(_emailKey, email);
    if (name != null) await prefs.setString(_nameKey, name);
    AppLogger.i('Session saved');
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

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    AppLogger.i('Session cleared');
  }

  static Future<void> hydrateClient(ApiClient client) async {
    final token = await getToken();
    client.setToken(token);
  }
}
