import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/deeplink/deep_link_config.dart';
import '../../../core/deeplink/deep_link_service.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/mobile_header.dart';

/// Opens OAuth in the system browser; returns via deep link or Done button.
class OAuthConnectPage extends StatefulWidget {
  const OAuthConnectPage({
    super.key,
    required this.url,
    this.title = 'Connect account',
  });

  final String url;
  final String title;

  @override
  State<OAuthConnectPage> createState() => _OAuthConnectPageState();
}

class _OAuthConnectPageState extends State<OAuthConnectPage>
    with WidgetsBindingObserver {
  var _opening = false;
  var _opened = false;
  var _finishing = false;
  String? _error;
  StreamSubscription<OAuthDeepLinkResult>? _deeplinkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deeplinkSub = DeepLinkService.instance.onOAuthCallback.listen(_onDeepLink);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openBrowser());
  }

  @override
  void dispose() {
    _deeplinkSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onDeepLink(OAuthDeepLinkResult result) {
    if (!mounted || _finishing) return;
    _finishing = true;
    AppLogger.event('oauth_page_deeplink', {
      'platform': result.platform,
      'success': result.success,
    });

    if (result.success) {
      AppSnackBar.success(context, 'Connected successfully');
      context.pop(true);
    } else {
      AppSnackBar.error(
        context,
        result.message?.isNotEmpty == true
            ? result.message!
            : 'Connection failed',
      );
      context.pop(false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _opened && mounted) {
      AppLogger.event('oauth_browser_resumed');
    }
  }

  Future<void> _openBrowser() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(widget.url);
      AppLogger.i('Opening OAuth URL in browser');

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback) {
          throw Exception('No browser available to open the login page.');
        }
      }

      if (mounted) {
        setState(() {
          _opened = true;
          _opening = false;
        });
      }
    } catch (e, st) {
      AppLogger.e('OAuth browser launch failed', e, st);
      if (mounted) {
        setState(() {
          _opening = false;
          _error = e.toString().contains('channel-error')
              ? 'Please fully restart the app (stop + run), then try Connect again.'
              : 'Could not open browser. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            MobileHeader(
              title: widget.title,
              onBack: () => context.pop(false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.open_in_browser_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _opened ? 'Finish in your browser' : 'Opening browser…',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'After you approve access, you will be redirected back into SocialSyncc automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.gray500,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                    ],
                    const Spacer(),
                    if (_opening)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: CircularProgressIndicator(),
                      ),
                    AppButton(
                      label: _opened ? 'Done — I connected' : 'Open browser',
                      loading: _opening,
                      onPressed: _opening
                          ? null
                          : () {
                              if (_opened) {
                                context.pop(true);
                              } else {
                                _openBrowser();
                              }
                            },
                    ),
                    if (_opened) ...[
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Open browser again',
                        variant: AppBtnVariant.secondary,
                        onPressed: _opening ? null : _openBrowser,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
