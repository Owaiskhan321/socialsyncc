import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logger/app_logger.dart';
import 'api_constants.dart';
import 'api_exception.dart';

/// Lightweight HTTP client for OmniPost APIs.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path) {
    final base = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl
        : '${ApiConstants.baseUrl}/';
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$base$clean');
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path);
    AppLogger.i('POST $uri');
    AppLogger.d('Body: $body');

    try {
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConstants.timeout);

      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e, st) {
      AppLogger.e('Network error', e, st);
      throw ApiException('Network error. Please check your connection.');
    }
  }

  ApiResponse _parse(http.Response response) {
    AppLogger.d('Status: ${response.statusCode} Body: ${response.body}');

    Map<String, dynamic> json = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        } else {
          json = {'data': decoded, 'message': 'Success'};
        }
      } catch (_) {
        json = {'message': response.body};
      }
    }

    final apiResponse = ApiResponse.fromJson(json, statusCode: response.statusCode);

    if (response.statusCode < 200 || response.statusCode >= 300 || !apiResponse.success) {
      final msg = _extractError(json) ?? apiResponse.message;
      throw ApiException(msg, statusCode: response.statusCode);
    }

    return apiResponse;
  }

  String? _extractError(Map<String, dynamic> json) {
    final message = json['message'] ?? json['error'] ?? json['msg'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) return message.first.toString();

    final errors = json['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
    if (errors is List && errors.isNotEmpty) return errors.first.toString();
    return null;
  }
}
