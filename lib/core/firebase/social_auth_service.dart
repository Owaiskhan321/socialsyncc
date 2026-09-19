import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../logger/app_logger.dart';
import '../network/api_exception.dart';
import '../network/session_storage.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import 'fcm_service.dart';

class SocialAuthException implements Exception {
  SocialAuthException(this.message, {this.cancelled = false});

  final String message;
  final bool cancelled;

  @override
  String toString() => message;
}

/// Google / Apple → provider `idToken` → `POST auth/social-login`.
class SocialAuthService {
  SocialAuthService({AuthRepository? authRepository})
      : _authRepo = authRepository ?? AuthRepository();

  final AuthRepository _authRepo;

  Future<AuthResult> signInWithGoogle() async {
    AppLogger.event('social_google_sign_in');
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw SocialAuthException('Google Sign-In is not supported on this device.');
    }

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw SocialAuthException('Google sign-in failed: missing ID token.');
      }

      return _exchangeWithBackend(
        provider: 'google',
        idToken: idToken,
        fallbackMessage: 'Signed in with Google',
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw SocialAuthException('Sign in cancelled', cancelled: true);
      }
      throw SocialAuthException(e.description ?? 'Google sign-in failed');
    } on ApiException catch (e) {
      throw SocialAuthException(e.message);
    }
  }

  Future<AuthResult> signInWithApple() async {
    if (!Platform.isIOS) {
      throw SocialAuthException('Apple Sign-In is only available on iOS.');
    }

    AppLogger.event('social_apple_sign_in');

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw SocialAuthException('Apple sign-in failed: missing identity token.');
      }

      return _exchangeWithBackend(
        provider: 'apple',
        idToken: idToken,
        fallbackMessage: 'Signed in with Apple',
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw SocialAuthException('Sign in cancelled', cancelled: true);
      }
      throw SocialAuthException(e.message);
    } on ApiException catch (e) {
      throw SocialAuthException(e.message);
    }
  }

  Future<AuthResult> _exchangeWithBackend({
    required String provider,
    required String idToken,
    required String fallbackMessage,
  }) async {
    await FcmService.ensureTokenStored();
    final deviceId = await SessionStorage.getOrCreateDeviceId();
    final fcmToken = await SessionStorage.getFcmToken();

    final result = await _authRepo.socialLogin(
      SocialLoginRequest(
        provider: provider,
        idToken: idToken,
        timezone: 'Asia/Karachi',
        deviceId: deviceId,
        fcmToken: fcmToken,
      ),
    );

    if (result.token == null || result.token!.isEmpty) {
      throw SocialAuthException('Sign-in failed: no session token from server.');
    }

    AppLogger.i('Backend social login OK ($provider)');
    return AuthResult(
      message: result.message.isNotEmpty ? result.message : fallbackMessage,
      token: result.token,
      email: result.email,
      name: result.name,
      wallet: result.wallet,
    );
  }
}
