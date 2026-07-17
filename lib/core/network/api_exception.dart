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
    if (json.containsKey('success')) {
      success = json['success'] == true;
    } else if (json['status'] == 'success' || json['status'] == 'ok') {
      success = true;
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
