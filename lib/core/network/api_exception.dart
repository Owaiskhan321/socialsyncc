class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiResponse {
  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  final bool success;
  final String message;
  final dynamic data;
  final int? statusCode;

  factory ApiResponse.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    final bool success;
    final status = (json['status'] ?? '').toString().toLowerCase();
    if (json.containsKey('success')) {
      success = json['success'] == true;
    } else if (status == 'success' ||
        status == 'ok' ||
        status == 'processing' ||
        status == 'queued' ||
        status == 'pending') {
      success = true;
    } else if (json['postId'] != null || json['id'] != null) {
      // Create-post style payloads often omit `success`.
      success = statusCode != null && statusCode >= 200 && statusCode < 300;
    } else {
      success = statusCode != null && statusCode >= 200 && statusCode < 300;
    }
    final message = (json['message'] ??
            json['msg'] ??
            json['error'] ??
            (success ? 'Success' : 'Something went wrong'))
        .toString();
    return ApiResponse(
      success: success,
      message: message,
      data: json['data'] ?? json['result'] ?? json,
      statusCode: statusCode,
    );
  }
}
