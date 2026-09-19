import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firebase/fcm_service.dart';
import '../../../core/firebase/social_auth_service.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/mvp/mvp_base.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/session_storage.dart';
import '../../../core/network/session_sync.dart';
import '../../../core/realtime/pusher_service.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';

enum SocialSignInProvider { google, apple }

class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.loading = false,
    this.socialProvider,
  });

  final String email;
  final String password;
  final bool obscurePassword;
  final bool loading;
  final SocialSignInProvider? socialProvider;

  bool get socialLoading => socialProvider != null;

  LoginState copyWith({
    String? email,
    String? password,
    bool? obscurePassword,
    bool? loading,
    SocialSignInProvider? socialProvider,
    bool clearSocial = false,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      loading: loading ?? this.loading,
      socialProvider: clearSocial ? null : (socialProvider ?? this.socialProvider),
    );
  }

  @override
  List<Object?> get props => [email, password, obscurePassword, loading, socialProvider];
}

abstract class LoginView implements MvpView {
  void onLoginSuccess(String message);
  void goForgotPassword();
  void goRegister();
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  void setEmail(String v) => emit(state.copyWith(email: v));
  void setPassword(String v) => emit(state.copyWith(password: v));
  void toggleObscure() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));
  void setLoading(bool v) => emit(state.copyWith(loading: v));
  void setSocial(SocialSignInProvider? p) =>
      emit(state.copyWith(socialProvider: p, clearSocial: p == null));
}

class LoginPresenter extends MvpPresenter<LoginState, LoginView> {
  LoginPresenter({
    AuthRepository? repository,
    SocialAuthService? socialAuth,
  })  : _repo = repository ?? AuthRepository(),
        _social = socialAuth ?? SocialAuthService(),
        super(LoginCubit());

  final AuthRepository _repo;
  final SocialAuthService _social;
  LoginCubit get _c => cubit as LoginCubit;

  void onEmailChanged(String v) => _c.setEmail(v);
  void onPasswordChanged(String v) => _c.setPassword(v);

  void togglePasswordVisibility() {
    AppLogger.event('login_toggle_password');
    _c.toggleObscure();
  }

  Future<void> signIn() async {
    final s = state;
    if (s.email.trim().isEmpty || !s.email.contains('@')) {
      view?.showMessage('Please enter a valid email');
      return;
    }
    if (s.password.isEmpty) {
      view?.showMessage('Please enter your password');
      return;
    }

    _c.setLoading(true);
    AppLogger.event('login_sign_in', {'email': s.email});

    try {
      final result = await _repo.login(
        LoginRequest(email: s.email.trim(), password: s.password),
      );
      await FcmService.ensureTokenStored();
      await syncUserProfileFromApi();
      unawaited(PusherRealtimeService().connectIfLoggedIn());
      final credits = result.wallet?.totalCredits ??
          await SessionStorage.getTotalCredits();
      view?.onLoginSuccess(
        credits > 0
            ? '${result.message} · $credits credits'
            : result.message,
      );
    } on ApiException catch (e) {
      view?.showMessage(e.message);
    } catch (e, st) {
      AppLogger.e('Login failed', e, st);
      view?.showMessage('Sign in failed. Please try again.');
    } finally {
      if (!cubit.isClosed) _c.setLoading(false);
    }
  }

  Future<void> continueWithGoogle() async {
    if (state.loading || state.socialLoading) return;
    _c.setSocial(SocialSignInProvider.google);
    try {
      final result = await _social.signInWithGoogle();
      await FcmService.ensureTokenStored();
      await syncUserProfileFromApi();
      unawaited(PusherRealtimeService().connectIfLoggedIn());
      final credits = result.wallet?.totalCredits ??
          await SessionStorage.getTotalCredits();
      view?.onLoginSuccess(
        credits > 0
            ? '${result.message} · $credits credits'
            : result.message,
      );
    } on SocialAuthException catch (e) {
      if (!e.cancelled) view?.showMessage(e.message);
    } catch (e, st) {
      AppLogger.e('Google sign-in failed', e, st);
      view?.showMessage('Google sign-in failed. Please try again.');
    } finally {
      if (!cubit.isClosed) _c.setSocial(null);
    }
  }

  Future<void> continueWithApple() async {
    if (state.loading || state.socialLoading) return;
    _c.setSocial(SocialSignInProvider.apple);
    try {
      final result = await _social.signInWithApple();
      await FcmService.ensureTokenStored();
      await syncUserProfileFromApi();
      unawaited(PusherRealtimeService().connectIfLoggedIn());
      final credits = result.wallet?.totalCredits ??
          await SessionStorage.getTotalCredits();
      view?.onLoginSuccess(
        credits > 0
            ? '${result.message} · $credits credits'
            : result.message,
      );
    } on SocialAuthException catch (e) {
      if (!e.cancelled) view?.showMessage(e.message);
    } catch (e, st) {
      AppLogger.e('Apple sign-in failed', e, st);
      view?.showMessage('Apple sign-in failed. Please try again.');
    } finally {
      if (!cubit.isClosed) _c.setSocial(null);
    }
  }

  void forgotPassword() {
    AppLogger.event('login_forgot_password');
    view?.goForgotPassword();
  }

  void goRegister() {
    AppLogger.event('login_go_register');
    view?.goRegister();
  }
}
