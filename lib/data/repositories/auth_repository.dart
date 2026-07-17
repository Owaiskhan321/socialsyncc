import '../../core/logger/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/session_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository({ApiClient? client}) : _client = client ?? appApiClient;

  final ApiClient _client;

  Future<AuthResult> register(RegisterRequest request) async {
    AppLogger.event('api_register', {'email': request.email});
    final res = await _client.post(
      ApiConstants.register,
      body: request.toJson(),
    );
    return AuthResult(
      message: res.message.isNotEmpty ? res.message : 'Account created successfully',
      email: request.email,
      name: request.name,
    );
  }

  Future<AuthResult> login(LoginRequest request) async {
    AppLogger.event('api_login', {'email': request.email});
    final res = await _client.post(
      ApiConstants.login,
      body: request.toJson(),
    );

    final token = _readToken(res.data);
    final name = _readString(res.data, const ['name', 'fullName', 'user.name']);

    if (token != null && token.isNotEmpty) {
      _client.setToken(token);
      await SessionStorage.saveSession(
        token: token,
        email: request.email,
        name: name,
      );
    }

    return AuthResult(
      message: res.message.isNotEmpty ? res.message : 'Signed in successfully',
      token: token,
      email: request.email,
      name: name,
    );
  }

  Future<AuthResult> verifyEmail({required String email, required String otp}) async {
    final res = await _client.post(
      ApiConstants.verifyEmail,
      body: {'email': email, 'otp': otp},
    );
    return AuthResult(message: res.message, email: email);
  }

  Future<AuthResult> resendOtp({required String email}) async {
    final res = await _client.post(
      ApiConstants.resendOtp,
      body: {'email': email},
    );
    return AuthResult(message: res.message, email: email);
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await _client.post(
      ApiConstants.resetPassword,
      body: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
    return AuthResult(message: res.message, email: email);
  }

  String? _readToken(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    return _readString(map, const [
      'token',
      'accessToken',
      'access_token',
      'data.token',
      'user.token',
    ]);
  }

  String? _readString(dynamic data, List<String> keys) {
    if (data == null) return null;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);

    for (final key in keys) {
      if (!key.contains('.')) {
        final v = map[key];
        if (v != null && v.toString().isNotEmpty) return v.toString();
        continue;
      }
      dynamic cur = map;
      for (final part in key.split('.')) {
        if (cur is Map && cur.containsKey(part)) {
          cur = cur[part];
        } else {
          cur = null;
          break;
        }
      }
      if (cur != null && cur.toString().isNotEmpty) return cur.toString();
    }

    // Nested user object fallback
    final user = map['user'];
    if (user is Map) {
      final nested = Map<String, dynamic>.from(user);
      for (final k in ['token', 'accessToken', 'name', 'email']) {
        final v = nested[k];
        if (v != null && v.toString().isNotEmpty && keys.any((x) => x.endsWith(k) || x == k)) {
          return v.toString();
        }
      }
    }
    return null;
  }
}
