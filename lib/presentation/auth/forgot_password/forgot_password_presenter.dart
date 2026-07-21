import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/mvp/mvp_base.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/auth_repository.dart';

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
  void goOtpVerify(String email);
  void goLogin();
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit() : super(const ForgotPasswordState());

  void setEmail(String v) => emit(state.copyWith(email: v));
  void setLoading(bool v) => emit(state.copyWith(loading: v));
}

class ForgotPasswordPresenter
    extends MvpPresenter<ForgotPasswordState, ForgotPasswordView> {
  ForgotPasswordPresenter({AuthRepository? repository})
      : _repo = repository ?? AuthRepository(),
        super(ForgotPasswordCubit());

  final AuthRepository _repo;
  ForgotPasswordCubit get _c => cubit as ForgotPasswordCubit;

  void onEmailChanged(String v) => _c.setEmail(v);

  Future<void> sendResetLink() async {
    final email = state.email.trim();
    if (email.isEmpty || !email.contains('@')) {
      view?.showMessage('Please enter a valid email');
      return;
    }
    if (state.loading) return;

    _c.setLoading(true);
    AppLogger.event('forgot_password_send', {'email': email});

    try {
      // POST /auth/forgot-password { email }
      final result = await _repo.forgotPassword(email: email);
      view?.showMessage(
        result.message.isNotEmpty
            ? result.message
            : 'Reset code sent to $email',
      );
      view?.goOtpVerify(email);
    } on ApiException catch (e) {
      view?.showMessage(e.message);
    } catch (e, st) {
      AppLogger.e('Forgot password failed', e, st);
      view?.showMessage('Could not send reset code. Please try again.');
    } finally {
      if (!cubit.isClosed) _c.setLoading(false);
    }
  }

  void backToSignIn() {
    AppLogger.event('forgot_password_back_login');
    view?.goLogin();
  }
}
