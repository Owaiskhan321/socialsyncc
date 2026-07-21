import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logger/app_logger.dart';
import 'api_constants.dart';
import 'api_exception.dart';

/// Lightweight HTTP client for SocialSyncc APIs.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> _jsonHeaders({bool jsonBody = true}) => {
        if (jsonBody) 'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final base = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl
        : '${ApiConstants.baseUrl}/';
    final clean = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$base$clean');
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(queryParameters: queryParameters);
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _uri(path, queryParameters);
    AppLogger.i('GET $uri');

    try {
      final response = await _client
          .get(uri, headers: _jsonHeaders(jsonBody: false))
          .timeout(ApiConstants.timeout);
      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e, st) {
      AppLogger.e('Network error', e, st);
      throw ApiException('Network error. Please check your connection.');
    }
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _uri(path, queryParameters);
    AppLogger.i('POST $uri');
    AppLogger.d('Body: $body');

    try {
      final response = await _client
          .post(
            uri,
            headers: _jsonHeaders(),
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

  Future<ApiResponse> delete(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _uri(path, queryParameters);
    AppLogger.i('DELETE $uri');

    try {
      final response = await _client
          .delete(uri, headers: _jsonHeaders(jsonBody: false))
          .timeout(ApiConstants.timeout);
      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e, st) {
      AppLogger.e('Network error', e, st);
      throw ApiException('Network error. Please check your connection.');
    }
  }

  Future<ApiResponse> postForm(
    String path, {
    Map<String, String>? fields,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _uri(path, queryParameters);
    AppLogger.i('POST (form) $uri');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_jsonHeaders(jsonBody: false));
      request.headers.remove('Content-Type');
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamed = await request.send().timeout(ApiConstants.timeout);
      final response = await http.Response.fromStream(streamed);
      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e, st) {
      AppLogger.e('Network error', e, st);
      throw ApiException('Network error. Please check your connection.');
    }
  }

  Future<ApiResponse> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _uri(path, queryParameters);
    AppLogger.i('POST (multipart) $uri');
    AppLogger.d(
      'Multipart fields: $fields | '
      'files: ${files?.map((f) => f.filename).toList() ?? []}',
    );

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_jsonHeaders(jsonBody: false));
      request.headers.remove('Content-Type');
      if (fields != null) request.fields.addAll(fields);
      if (files != null) request.files.addAll(files);

      final streamed = await request.send().timeout(ApiConstants.timeout);
      final response = await http.Response.fromStream(streamed);
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = _extractError(json) ?? apiResponse.message;
      throw ApiException(msg, statusCode: response.statusCode);
    }
    // Empty 2xx bodies (e.g. DELETE 204) are success.
    if (response.body.isEmpty) return apiResponse;
    // 2xx with processing/postId payloads are success even if `success` flag is absent.
    if (!apiResponse.success &&
        !(json.containsKey('postId') ||
            json.containsKey('id') ||
            (json['status']?.toString().toLowerCase() == 'processing'))) {
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
