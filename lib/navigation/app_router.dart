import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/logger/app_logger.dart';
import '../presentation/auth/auth_success/auth_success_page.dart';
import '../presentation/auth/forgot_password/forgot_password_page.dart';
import '../presentation/auth/login/login_page.dart';
import '../presentation/auth/otp_verify/otp_verify_page.dart';
import '../presentation/auth/otp_verify/otp_verify_presenter.dart';
import '../presentation/auth/register/register_page.dart';
import '../presentation/auth/reset_password/reset_password_page.dart';
import '../presentation/auth/splash/splash_page.dart';
import '../presentation/auth/welcome/welcome_page.dart';
import '../presentation/app/create_post/create_post_page.dart';
import '../presentation/app/notifications/notifications_page.dart';
import '../presentation/app/platforms/platforms_page.dart';
import '../presentation/app/platform_detail/platform_detail_page.dart';
import '../presentation/app/post_detail/post_detail_page.dart';
import '../presentation/app/profile/profile_page.dart';
import '../presentation/app/settings/settings_page.dart';
import '../presentation/app/subscription/subscription_page.dart';
import '../presentation/app/oauth/oauth_connect_page.dart';
import '../presentation/shell/main_shell.dart';
import '../core/deeplink/deep_link_config.dart';
import '../core/deeplink/deep_link_service.dart';
import '../core/network/session_storage.dart';
import '../core/widgets/app_exit_guard.dart';
import 'app_launch_transition.dart';
import 'auth_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: SessionStorage.authListenable,
    redirect: (context, state) async {
      // OAuth browser return: socialsyncc://oauth/callback?... (incl. Facebook #_=_).
      // Must redirect before GoRouter shows "Page Not Found".
      final oauthUri = _oauthUriFromState(state);
      if (oauthUri != null) {
        DeepLinkService.instance.handleUri(oauthUri);
        return '/platforms';
      }

      final location = state.matchedLocation;
      if (location == '/splash') return null;

      final loggedIn = await SessionStorage.isLoggedIn();

      if (loggedIn && AuthRoutes.isGuestAuthScreen(location)) {
        return '/home';
      }
      if (!loggedIn && AuthRoutes.isProtected(location)) {
        return '/welcome';
      }
      return null;
    },
    errorBuilder: (context, state) {
      final oauthUri = _oauthUriFromState(state);
      if (oauthUri != null) {
        DeepLinkService.instance.handleUri(oauthUri);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/platforms');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Page Not Found',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  '${state.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Home'),
                ),
              ],
            ),
          ),
        ),
      );
    },
    observers: [_LoggerNavigatorObserver()],
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          enableExpand: false,
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          enableExpand: false,
          child: const AppExitGuard(child: WelcomePage()),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: '/otp-verify',
        name: 'otp-verify',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final purposeParam = state.uri.queryParameters['purpose'] ?? 'verify';
          final purpose = purposeParam == 'reset'
              ? OtpPurpose.resetPassword
              : OtpPurpose.verifyEmail;
          return buildAppLaunchPage(
            context: context,
            state: state,
            child: OtpVerifyPage(email: email, purpose: purpose),
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final otp = state.uri.queryParameters['otp'] ?? '';
          return buildAppLaunchPage(
            context: context,
            state: state,
            child: ResetPasswordPage(email: email, otp: otp),
          );
        },
      ),
      GoRoute(
        path: '/auth-success',
        name: 'auth-success',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          child: const AuthSuccessPage(),
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          enableExpand: false,
          child: const AppExitGuard(child: MainShell()),
        ),
      ),
      GoRoute(
        path: '/create',
        name: 'create',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          child: const CreatePostPage(),
        ),
      ),
      GoRoute(
        path: '/posts/:id',
        name: 'post-detail',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return buildAppLaunchPage(
            context: context,
            state: state,
            child: PostDetailPage(postId: id),
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          child: const NotificationsPage(),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          child: const ProfilePage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          child: const SettingsPage(),
        ),
      ),
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          child: const SubscriptionPage(),
        ),
      ),
      GoRoute(
        path: '/oauth-connect',
        name: 'oauth-connect',
        pageBuilder: (context, state) {
          final extra = state.extra;
          String url = '';
          String title = 'Connect account';
          if (extra is Map) {
            url = extra['url']?.toString() ?? '';
            title = extra['title']?.toString() ?? title;
          }
          return buildAppLaunchPage(
            context: context,
            state: state,
            child: OAuthConnectPage(url: url, title: title),
          );
        },
      ),
      GoRoute(
        path: '/platforms',
        name: 'platforms',
        pageBuilder: (context, state) => buildAppLaunchPage(
          context: context,
          state: state,
          child: const PlatformsPage(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            name: 'platform-detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? 'facebook';
              return buildAppLaunchPage(
                context: context,
                state: state,
                child: PlatformDetailPage(platformId: id),
              );
            },
          ),
        ],
      ),
    ],
  );
}

Uri? _oauthUriFromState(GoRouterState state) {
  final candidates = <String>[
    state.uri.toString(),
    state.matchedLocation,
    state.uri.path,
    if (state.error != null) '${state.error}',
  ];
  for (final raw in candidates) {
    if (raw.isEmpty) continue;
    // Strip Facebook's leftover fragment noise if embedded in the string.
    final cleaned = raw.replaceAll('#_=_', '').replaceAll('#=', '');
    final parsed = Uri.tryParse(cleaned);
    if (parsed != null && DeepLinkConfig.isOAuthCallback(parsed)) {
      return parsed;
    }
    if (cleaned.toLowerCase().contains('oauth/callback')) {
      final fallback = Uri.tryParse(cleaned);
      if (fallback != null) return fallback;
    }
  }
  return null;
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
