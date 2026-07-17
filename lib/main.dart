import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'core/logger/app_logger.dart';
import 'core/network/api_client_provider.dart';
import 'core/network/session_storage.dart';
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
    ),
  );

  await SessionStorage.hydrateClient(appApiClient);

  AppLogger.i('OmniPost starting…');
  runApp(const OmniPostApp());
}

class OmniPostApp extends StatefulWidget {
  const OmniPostApp({super.key});

  @override
  State<OmniPostApp> createState() => _OmniPostAppState();
}

class _OmniPostAppState extends State<OmniPostApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OmniPost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
