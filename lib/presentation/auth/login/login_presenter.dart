import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/mvp/mvp_base.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.loading = false,
  });

  final String email;
  final String password;
  final bool obscurePassword;
  final bool loading;

  LoginState copyWith({
    String? email,
    String? password,
    bool? obscurePassword,
    bool? loading,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [email, password, obscurePassword, loading];
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
}

class LoginPresenter extends MvpPresenter<LoginState, LoginView> {
  LoginPresenter({AuthRepository? repository})
      : _repo = repository ?? AuthRepository(),
        super(LoginCubit());

  final AuthRepository _repo;
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
      view?.onLoginSuccess(result.message);
    } on ApiException catch (e) {
      view?.showMessage(e.message);
    } catch (e, st) {
      AppLogger.e('Login failed', e, st);
      view?.showMessage('Sign in failed. Please try again.');
    } finally {
      if (!cubit.isClosed) _c.setLoading(false);
    }
  }

  void forgotPassword() {
    AppLogger.event('login_forgot_password');
    view?.goForgotPassword();
  }

  void continueWithGoogle() {
    AppLogger.event('login_google');
    view?.showMessage('Google sign-in coming soon');
  }

  void continueWithApple() {
    AppLogger.event('login_apple');
    view?.showMessage('Apple sign-in coming soon');
  }

  void goRegister() {
    AppLogger.event('login_go_register');
    view?.goRegister();
  }
}
