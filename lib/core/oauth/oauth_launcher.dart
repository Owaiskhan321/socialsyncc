import 'package:flutter/material.dart';

import '../../navigation/app_router.dart';
import '../../presentation/app/oauth/oauth_connect_page.dart';

/// Opens OAuth flow UI (system browser — no WebView).
abstract final class OAuthLauncher {
  static Future<bool> open({
    required String url,
    String title = 'Connect account',
    BuildContext? context,
  }) async {
    final ctx = context ?? rootNavigatorKey.currentContext;
    if (ctx == null || url.isEmpty) return false;

    final result = await Navigator.of(ctx, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => OAuthConnectPage(url: url, title: title),
        fullscreenDialog: true,
      ),
    );
    return result == true;
  }
}
