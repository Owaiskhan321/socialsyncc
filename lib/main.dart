import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'core/deeplink/deep_link_service.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/logger/app_logger.dart';
import 'core/network/api_client_provider.dart';
import 'core/network/session_storage.dart';
import 'core/network/session_sync.dart';
import 'core/realtime/pusher_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await FirebaseBootstrap.initialize();
  await SessionStorage.hydrateClient(appApiClient);
  unawaited(syncUserProfileFromApi());
  unawaited(PusherRealtimeService().connectIfLoggedIn());
  unawaited(DeepLinkService.instance.start());

  AppLogger.i('SocialSyncc starting…');
  runApp(const SocialSynccApp());
}

class SocialSynccApp extends StatefulWidget {
  const SocialSynccApp({super.key});

  @override
  State<SocialSynccApp> createState() => _SocialSynccAppState();
}

class _SocialSynccAppState extends State<SocialSynccApp> {
  late final GoRouter _router = createAppRouter();
  StreamSubscription? _oauthSub;

  @override
  void initState() {
    super.initState();
    _oauthSub = DeepLinkService.instance.onOAuthCallback.listen((result) {
      AppLogger.event('app_oauth_deeplink', {
        'platform': result.platform,
        'success': result.success,
      });
      // Always leave the OAuth deep-link location (or error page) for Platforms.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _router.go('/platforms');
      });
    });
  }

  @override
  void dispose() {
    _oauthSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SocialSyncc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
