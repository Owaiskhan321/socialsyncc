/// Central API configuration.
///
/// Paste your Apidog / Postman environment base URL here (must end with `/`).
/// Example: `https://api.yourdomain.com/api/v1/`
abstract final class ApiConstants {
  static const String baseUrl = 'https://api.socialsyncc.com/';

  static const String register = 'auth/register';
  static const String login = 'auth/login';
  static const String verifyEmail = 'auth/verify-email';
  static const String resendOtp = 'auth/resend-otp';
  static const String resetPassword = 'auth/reset-password';

  static const Duration timeout = Duration(seconds: 30);
}
