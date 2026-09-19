/// Central API configuration for SocialSyncc backend.
abstract final class ApiConstants {
  static const String baseUrl = 'https://api.socialsyncc.com/';

  // Auth
  static const String register = 'auth/register';
  static const String login = 'auth/login';
  static const String verifyEmail = 'auth/verify-email';
  static const String forgotPassword = 'auth/forgot-password';
  /// Apidog: POST /resend-otp { email }
  static const String resendOtp = 'resend-otp';
  static const String resetPassword = 'auth/reset-password';
  static const String socialLogin = 'auth/social-login';
  static const String me = 'auth/me';

  // Posts
  static const String posts = 'posts';
  static String postById(String id) => 'posts/$id';
  static const String postsPublish = 'posts/publish';
  static const String postsAnalytics = 'posts/analytics';

  // Social / OAuth
  static const String socialAccounts = 'social-accounts';
  static const String oauthConnect = 'oauth/connect';
  static const String oauthDisconnect = 'oauth/disconnect';
  static const String platforms = 'platforms';
  static const String wallet = 'wallet';

  // Platform resources
  static const String facebookPages = 'meta/facebook-pages';
  static const String pinterestBoards = 'pinterest/boards';
  static const String youtubeChannels = 'google/youtube-channels';
  static const String googleBusinessProfiles = 'google/business-profiles';

  // Misc
  static const String contact = 'contact';
  static const String pusherAuth = 'pusher/auth';

  static const Duration timeout = Duration(seconds: 60);
}

/// Client-safe Pusher config (secret stays on server).
abstract final class PusherConfig {
  static const String appId = '2177698';
  static const String key = 'aedf9eb0a66d53d39610';
  static const String cluster = 'ap2';
}
