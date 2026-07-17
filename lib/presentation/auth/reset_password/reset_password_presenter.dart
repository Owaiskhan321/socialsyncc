import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/mvp/mvp_base.dart';

class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.password = '',
    this.confirmPassword = '',
    this.obscurePassword = true,
    this.obscureConfirm = true,
    this.loading = false,
  });

  final String password;
  final String confirmPassword;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool loading;

  bool get hasConfirmInput => confirmPassword.isNotEmpty;
  bool get passwordsMatch =>
      password.isNotEmpty && password == confirmPassword;

  ResetPasswordState copyWith({
    String? password,
    String? confirmPassword,
    bool? obscurePassword,
    bool? obscureConfirm,
    bool? loading,
  }) {
    return ResetPasswordState(
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirm: obscureConfirm ?? this.obscureConfirm,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props =>
      [password, confirmPassword, obscurePassword, obscureConfirm, loading];
}

abstract class ResetPasswordView implements MvpView {
  void goAuthSuccess();
}

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit() : super(const ResetPasswordState());

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
  ResetPasswordPresenter() : super(ResetPasswordCubit());

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

  void resetPassword() {
    if (!state.passwordsMatch) {
      view?.showMessage("Passwords don't match");
      return;
    }
    AppLogger.event('reset_password_submit');
    view?.goAuthSuccess();
  }
}
