import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/logger/app_logger.dart';
import '../presentation/auth/auth_success/auth_success_page.dart';
import '../presentation/auth/forgot_password/forgot_password_page.dart';
import '../presentation/auth/login/login_page.dart';
import '../presentation/auth/otp_verify/otp_verify_page.dart';
import '../presentation/auth/register/register_page.dart';
import '../presentation/auth/reset_password/reset_password_page.dart';
import '../presentation/auth/splash/splash_page.dart';
import '../presentation/auth/welcome/welcome_page.dart';
import '../presentation/app/create_post/create_post_page.dart';
import '../presentation/app/notifications/notifications_page.dart';
import '../presentation/app/platforms/platforms_page.dart';
import '../presentation/app/platform_detail/platform_detail_page.dart';
import '../presentation/app/profile/profile_page.dart';
import '../presentation/app/settings/settings_page.dart';
import '../presentation/app/subscription/subscription_page.dart';
import '../presentation/shell/main_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    observers: [_LoggerNavigatorObserver()],
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (_, __) => const WelcomePage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/otp-verify',
        name: 'otp-verify',
        builder: (_, __) => const OtpVerifyPage(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (_, __) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/auth-success',
        name: 'auth-success',
        builder: (_, __) => const AuthSuccessPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const MainShell(),
      ),
      GoRoute(
        path: '/create',
        name: 'create',
        builder: (_, __) => const CreatePostPage(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const ProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsPage(),
      ),
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (_, __) => const SubscriptionPage(),
      ),
      GoRoute(
        path: '/platforms',
        name: 'platforms',
        builder: (context, state) => const PlatformsPage(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'platform-detail',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? 'facebook';
              return PlatformDetailPage(platformId: id);
            },
          ),
        ],
      ),
    ],
  );
}

class _LoggerNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.navigation(
      previousRoute?.settings.name ?? previousRoute?.settings.name ?? 'root',
      route.settings.name ?? route.settings.name ?? route.toString(),
    );
  }
}
