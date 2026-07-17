import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/mvp/mvp_base.dart';

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.email = '',
    this.loading = false,
  });

  final String email;
  final bool loading;

  ForgotPasswordState copyWith({String? email, bool? loading}) {
    return ForgotPasswordState(
      email: email ?? this.email,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [email, loading];
}

abstract class ForgotPasswordView implements MvpView {
  void goOtpVerify();
  void goLogin();
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit() : super(const ForgotPasswordState());

  void setEmail(String v) => emit(state.copyWith(email: v));
  void setLoading(bool v) => emit(state.copyWith(loading: v));
}

class ForgotPasswordPresenter
    extends MvpPresenter<ForgotPasswordState, ForgotPasswordView> {
  ForgotPasswordPresenter() : super(ForgotPasswordCubit());

  ForgotPasswordCubit get _c => cubit as ForgotPasswordCubit;

  void onEmailChanged(String v) => _c.setEmail(v);

  void sendResetLink() {
    AppLogger.event('forgot_password_send', {'email': state.email});
    view?.goOtpVerify();
  }

  void backToSignIn() {
    AppLogger.event('forgot_password_back_login');
    view?.goLogin();
  }
}
