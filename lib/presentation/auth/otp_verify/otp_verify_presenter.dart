import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/mvp/mvp_base.dart';

class OtpVerifyState extends Equatable {
  const OtpVerifyState({
    this.digits = const ['', '', '', '', '', ''],
    this.resendSeconds = 45,
    this.loading = false,
    this.email = 'alex@acme.com',
  });

  final List<String> digits;
  final int resendSeconds;
  final bool loading;
  final String email;

  bool get canResend => resendSeconds <= 0;
  String get code => digits.join();
  bool get isComplete => digits.every((d) => d.isNotEmpty);

  OtpVerifyState copyWith({
    List<String>? digits,
    int? resendSeconds,
    bool? loading,
    String? email,
  }) {
    return OtpVerifyState(
      digits: digits ?? this.digits,
      resendSeconds: resendSeconds ?? this.resendSeconds,
      loading: loading ?? this.loading,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [digits, resendSeconds, loading, email];
}

abstract class OtpVerifyView implements MvpView {
  void goResetPassword();
}

class OtpVerifyCubit extends Cubit<OtpVerifyState> {
  OtpVerifyCubit() : super(const OtpVerifyState());

  void setDigit(int index, String value) {
    final next = List<String>.from(state.digits);
    next[index] = value;
    emit(state.copyWith(digits: next));
  }

  void setDigits(List<String> digits) => emit(state.copyWith(digits: digits));

  void tick() {
    if (state.resendSeconds > 0) {
      emit(state.copyWith(resendSeconds: state.resendSeconds - 1));
    }
  }

  void resetTimer() => emit(state.copyWith(resendSeconds: 45));

  void setLoading(bool v) => emit(state.copyWith(loading: v));
}

class OtpVerifyPresenter extends MvpPresenter<OtpVerifyState, OtpVerifyView> {
  OtpVerifyPresenter() : super(OtpVerifyCubit());

  OtpVerifyCubit get _c => cubit as OtpVerifyCubit;
  Timer? _timer;

  @override
  void onAttached() {
    _startTimer();
  }

  @override
  void onDetached() {
    _timer?.cancel();
    _timer = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!cubit.isClosed) _c.tick();
    });
  }

  void onDigitChanged(int index, String value) {
    final digit = value.isEmpty ? '' : value.substring(value.length - 1);
    _c.setDigit(index, digit);
  }

  void verifyCode() {
    AppLogger.event('otp_verify', {'code': state.code});
    view?.goResetPassword();
  }

  void resendCode() {
    if (!state.canResend) return;
    AppLogger.event('otp_resend');
    _c.resetTimer();
    _startTimer();
    view?.showMessage('Code resent to ${state.email}');
  }
}
