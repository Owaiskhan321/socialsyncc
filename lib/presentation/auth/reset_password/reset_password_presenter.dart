import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/mvp/mvp_base.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/auth_repository.dart';

class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.password = '',
    this.confirmPassword = '',
    this.obscurePassword = true,
    this.obscureConfirm = true,
    this.loading = false,
    this.email = '',
    this.otp = '',
  });

  final String password;
  final String confirmPassword;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool loading;
  final String email;
  final String otp;

  bool get hasConfirmInput => confirmPassword.isNotEmpty;
  bool get passwordsMatch =>
      password.isNotEmpty && password == confirmPassword;

  ResetPasswordState copyWith({
    String? password,
    String? confirmPassword,
    bool? obscurePassword,
    bool? obscureConfirm,
    bool? loading,
    String? email,
    String? otp,
  }) {
    return ResetPasswordState(
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirm: obscureConfirm ?? this.obscureConfirm,
      loading: loading ?? this.loading,
      email: email ?? this.email,
      otp: otp ?? this.otp,
    );
  }

  @override
  List<Object?> get props => [
        password,
        confirmPassword,
        obscurePassword,
        obscureConfirm,
        loading,
        email,
        otp,
      ];
}

abstract class ResetPasswordView implements MvpView {
  void goAuthSuccess();
}

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit({String email = '', String otp = ''})
      : super(ResetPasswordState(email: email, otp: otp));

  void setPassword(String v) => emit(state.copyWith(password: v));
  void setConfirmPassword(String v) => emit(state.copyWith(confirmPassword: v));
  void toggleObscurePassword() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));
  void toggleObscureConfirm() =>
      emit(state.copyWith(obscureConfirm: !state.obscureConfirm));
  void setLoading(bool v) => emit(state.copyWith(loading: v));
}

class ResetPasswordPresenter
    extends MvpPresenter<ResetPasswordState, ResetPasswordView> {
  ResetPasswordPresenter({
    required String email,
    required String otp,
    AuthRepository? repository,
  })  : _repo = repository ?? AuthRepository(),
        super(ResetPasswordCubit(email: email, otp: otp));

  final AuthRepository _repo;
  ResetPasswordCubit get _c => cubit as ResetPasswordCubit;

  void onPasswordChanged(String v) => _c.setPassword(v);
  void onConfirmChanged(String v) => _c.setConfirmPassword(v);

  void togglePasswordVisibility() {
    AppLogger.event('reset_toggle_password');
    _c.toggleObscurePassword();
  }

  void toggleConfirmVisibility() {
    AppLogger.event('reset_toggle_confirm');
    _c.toggleObscureConfirm();
  }

  Future<void> resetPassword() async {
    if (state.password.trim().length < 6) {
      view?.showMessage('Password must be at least 6 characters');
      return;
    }
    if (!state.passwordsMatch) {
      view?.showMessage("Passwords don't match");
      return;
    }
    if (state.email.isEmpty || state.otp.isEmpty) {
      view?.showMessage('Reset session expired. Please start again.');
      return;
    }
    if (state.loading) return;

    _c.setLoading(true);
    AppLogger.event('reset_password_submit', {'email': state.email});

    try {
      // POST /auth/reset-password { email, otp, newPassword }
      final result = await _repo.resetPassword(
        email: state.email,
        otp: state.otp,
        newPassword: state.password.trim(),
      );
      view?.showMessage(
        result.message.isNotEmpty
            ? result.message
            : 'Password reset successfully',
      );
      view?.goAuthSuccess();
    } on ApiException catch (e) {
      view?.showMessage(e.message);
    } catch (e, st) {
      AppLogger.e('Reset password failed', e, st);
      view?.showMessage('Could not reset password. Please try again.');
    } finally {
      if (!cubit.isClosed) _c.setLoading(false);
    }
  }
}
