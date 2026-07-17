import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/mvp/mvp_base.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';

class RegisterState extends Equatable {
  const RegisterState({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.obscurePassword = true,
    this.agreedToTerms = false,
    this.loading = false,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final bool obscurePassword;
  final bool agreedToTerms;
  final bool loading;

  int get strength {
    final len = password.length;
    if (len == 0) return 0;
    if (len < 4) return 1;
    if (len < 8) return 2;
    if (len < 12) return 3;
    return 4;
  }

  RegisterState copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? password,
    bool? obscurePassword,
    bool? agreedToTerms,
    bool? loading,
  }) {
    return RegisterState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props =>
      [fullName, email, phone, password, obscurePassword, agreedToTerms, loading];
}

abstract class RegisterView implements MvpView {
  void onRegisterSuccess(String message);
  void goLogin();
}

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(const RegisterState());

  void setFullName(String v) => emit(state.copyWith(fullName: v));
  void setEmail(String v) => emit(state.copyWith(email: v));
  void setPhone(String v) => emit(state.copyWith(phone: v));
  void setPassword(String v) => emit(state.copyWith(password: v));
  void toggleObscure() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));
  void toggleTerms() =>
      emit(state.copyWith(agreedToTerms: !state.agreedToTerms));
  void setLoading(bool v) => emit(state.copyWith(loading: v));
}

class RegisterPresenter extends MvpPresenter<RegisterState, RegisterView> {
  RegisterPresenter({AuthRepository? repository})
      : _repo = repository ?? AuthRepository(),
        super(RegisterCubit());

  final AuthRepository _repo;
  RegisterCubit get _c => cubit as RegisterCubit;

  void onFullNameChanged(String v) => _c.setFullName(v);
  void onEmailChanged(String v) => _c.setEmail(v);
  void onPhoneChanged(String v) => _c.setPhone(v);
  void onPasswordChanged(String v) => _c.setPassword(v);

  void togglePasswordVisibility() {
    AppLogger.event('register_toggle_password');
    _c.toggleObscure();
  }

  void toggleTerms() {
    AppLogger.event('register_toggle_terms');
    _c.toggleTerms();
  }

  Future<void> createAccount() async {
    final s = state;
    if (s.fullName.trim().isEmpty) {
      view?.showMessage('Please enter your full name');
      return;
    }
    if (s.email.trim().isEmpty || !s.email.contains('@')) {
      view?.showMessage('Please enter a valid email');
      return;
    }
    if (s.phone.trim().isEmpty) {
      view?.showMessage('Please enter your phone number');
      return;
    }
    if (s.password.length < 8) {
      view?.showMessage('Password must be at least 8 characters');
      return;
    }
    if (!s.agreedToTerms) {
      view?.showMessage('Please agree to the Terms of Service');
      return;
    }

    _c.setLoading(true);
    AppLogger.event('register_create_account', {'email': s.email});

    try {
      final result = await _repo.register(
        RegisterRequest(
          name: s.fullName.trim(),
          email: s.email.trim(),
          password: s.password,
          timezone: 'Asia/Karachi',
          phone: s.phone.trim(),
        ),
      );
      view?.onRegisterSuccess(result.message);
    } on ApiException catch (e) {
      view?.showMessage(e.message);
    } catch (e, st) {
      AppLogger.e('Register failed', e, st);
      view?.showMessage('Registration failed. Please try again.');
    } finally {
      if (!cubit.isClosed) _c.setLoading(false);
    }
  }

  void goLogin() {
    AppLogger.event('register_go_login');
    view?.goLogin();
  }
}
