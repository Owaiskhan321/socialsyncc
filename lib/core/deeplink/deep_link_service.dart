import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../logger/app_logger.dart';
import 'deep_link_config.dart';

/// Listens for custom-scheme / app-link redirects from the browser.
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  final _oauthController = StreamController<OAuthDeepLinkResult>.broadcast();
  StreamSubscription<Uri>? _sub;
  var _started = false;

  /// OAuth callback stream (browser → app).
  Stream<OAuthDeepLinkResult> get onOAuthCallback => _oauthController.stream;

  Future<void> start() async {
    if (_started || kIsWeb) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) handleUri(initial);
    } catch (e, st) {
      AppLogger.w('Deep link initial failed', e, st);
    }

    _sub = _appLinks.uriLinkStream.listen(
      handleUri,
      onError: (Object e, StackTrace st) {
        AppLogger.w('Deep link stream error', e, st);
      },
    );
    AppLogger.i('DeepLinkService started');
  }

  /// Public so GoRouter redirect can forward OAuth callbacks here.
  void handleUri(Uri uri) {
    AppLogger.i('Deep link received: $uri');
    if (!DeepLinkConfig.isOAuthCallback(uri)) return;
    final result = OAuthDeepLinkResult.fromUri(uri);
    AppLogger.event('oauth_deeplink', {
      'platform': result.platform,
      'success': result.success,
    });
    if (!_oauthController.isClosed) {
      _oauthController.add(result);
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _oauthController.close();
    _started = false;
  }
}
