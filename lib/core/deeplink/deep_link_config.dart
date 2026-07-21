/// Deep link contract for mobile ↔ backend OAuth redirect.
///
/// Share this with the backend team.
///
/// ## After OAuth success/failure, redirect the browser to:
///
/// ### Custom scheme (works now — recommended)
/// ```
/// socialsyncc://oauth/callback?platform=meta&status=success
/// socialsyncc://oauth/callback?platform=linkedin&status=success
/// socialsyncc://oauth/callback?platform=meta&status=error&message=access_denied
/// ```
///
/// ### HTTPS App Link (optional later — needs domain assetlinks / AASA)
/// ```
/// https://app.socialsyncc.com/oauth/callback?platform=meta&status=success
/// ```
///
/// ## Query params
/// | Param     | Required | Values                                      |
/// |-----------|----------|---------------------------------------------|
/// | platform  | yes      | google, meta, thread, x, linkedin, linkedin_organization, pinterest, tiktok |
/// | status    | yes      | success \| error                            |
/// | message   | no       | human-readable error text                   |
///
/// ## Example (Node / Express after Meta callback)
/// ```js
/// res.redirect(
///   `socialsyncc://oauth/callback?platform=meta&status=success`
/// );
/// // or on failure:
/// res.redirect(
///   `socialsyncc://oauth/callback?platform=meta&status=error&message=${encodeURIComponent(err.message)}`
/// );
/// ```
abstract final class DeepLinkConfig {
  static const customScheme = 'socialsyncc';
  static const httpsHost = 'app.socialsyncc.com';

  static const oauthCallbackHost = 'oauth';
  static const oauthCallbackPath = '/callback';

  /// Full success redirect the backend should use.
  static String oauthSuccessRedirect(String platform) =>
      '$customScheme://$oauthCallbackHost$oauthCallbackPath'
      '?platform=${Uri.encodeQueryComponent(platform)}&status=success';

  /// Full error redirect the backend should use.
  static String oauthErrorRedirect(String platform, {String? message}) {
    final msg = message == null || message.isEmpty
        ? ''
        : '&message=${Uri.encodeQueryComponent(message)}';
    return '$customScheme://$oauthCallbackHost$oauthCallbackPath'
        '?platform=${Uri.encodeQueryComponent(platform)}&status=error$msg';
  }

  static bool isOAuthCallback(Uri uri) {
    final raw = uri.toString().toLowerCase();
    // GoRouter sometimes receives the full custom-scheme string as location.
    if (raw.contains('oauth/callback') || raw.contains('://oauth')) {
      return true;
    }

    final schemeOk = uri.scheme == customScheme || uri.scheme == 'https' || uri.scheme.isEmpty;
    if (!schemeOk && uri.scheme != 'socialsyncc') return false;
    if (uri.scheme == 'https' && uri.host != httpsHost) return false;

    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    if (host == 'oauth' && (path == '/callback' || path == 'callback' || path.isEmpty)) {
      return true;
    }
    if (path == '/oauth/callback' || path.endsWith('/oauth/callback')) {
      return true;
    }
    return false;
  }

  /// Parse OAuth result even when GoRouter passes a weird location string.
  static Uri? tryParseOAuthLocation(String location) {
    try {
      final uri = Uri.parse(location);
      if (isOAuthCallback(uri)) return uri;
    } catch (_) {}
    return null;
  }
}

class OAuthDeepLinkResult {
  const OAuthDeepLinkResult({
    required this.platform,
    required this.success,
    this.message,
    required this.uri,
  });

  final String platform;
  final bool success;
  final String? message;
  final Uri uri;

  factory OAuthDeepLinkResult.fromUri(Uri uri) {
    final platform = uri.queryParameters['platform'] ?? '';
    final status = (uri.queryParameters['status'] ?? '').toLowerCase();
    final message = uri.queryParameters['message'];
    return OAuthDeepLinkResult(
      platform: platform,
      success: status == 'success' || status == 'ok' || status == 'connected',
      message: message,
      uri: uri,
    );
  }
}
