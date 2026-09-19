import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/mvp/mvp_base.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/auth_repository.dart';

enum OtpPurpose { verifyEmail, resetPassword }

class OtpVerifyState extends Equatable {
  const OtpVerifyState({
    this.digits = const ['', '', '', '', '', ''],
    this.resendSeconds = 45,
    this.loading = false,
    this.email = '',
    this.purpose = OtpPurpose.verifyEmail,
  });

  final List<String> digits;
  final int resendSeconds;
  final bool loading;
  final String email;
  final OtpPurpose purpose;

  bool get canResend => resendSeconds <= 0;
  String get code => digits.join();
  bool get isComplete => digits.every((d) => d.isNotEmpty);

  OtpVerifyState copyWith({
    List<String>? digits,
    int? resendSeconds,
    bool? loading,
    String? email,
    OtpPurpose? purpose,
  }) {
    return OtpVerifyState(
      digits: digits ?? this.digits,
      resendSeconds: resendSeconds ?? this.resendSeconds,
      loading: loading ?? this.loading,
      email: email ?? this.email,
      purpose: purpose ?? this.purpose,
    );
  }

  @override
  List<Object?> get props => [digits, resendSeconds, loading, email, purpose];
}

abstract class OtpVerifyView implements MvpView {
  void onVerifySuccess(String message);
  void onVerifyError(String message);
  void goResetPassword(String email, String otp);
}

class OtpVerifyCubit extends Cubit<OtpVerifyState> {
  OtpVerifyCubit({
    required String email,
    OtpPurpose purpose = OtpPurpose.verifyEmail,
  }) : super(OtpVerifyState(email: email, purpose: purpose));

  void setDigit(int index, String value) {
    final next = List<String>.from(state.digits);
    next[index] = value;
    emit(state.copyWith(digits: next));
  }

  void tick() {
    if (state.resendSeconds > 0) {
      emit(state.copyWith(resendSeconds: state.resendSeconds - 1));
    }
  }

  void resetTimer() => emit(state.copyWith(resendSeconds: 45));

  void setLoading(bool v) => emit(state.copyWith(loading: v));
}

class OtpVerifyPresenter extends MvpPresenter<OtpVerifyState, OtpVerifyView> {
  OtpVerifyPresenter({
    required String email,
    OtpPurpose purpose = OtpPurpose.verifyEmail,
    AuthRepository? repository,
  })  : _repo = repository ?? AuthRepository(),
        super(OtpVerifyCubit(email: email, purpose: purpose));

  final AuthRepository _repo;
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

  Future<void> verifyCode() async {
    if (!state.isComplete) {
      view?.showMessage('Please enter the 6-digit code');
      return;
    }
    if (state.email.isEmpty) {
      view?.showMessage('Email is missing. Please go back and try again.');
      return;
    }

    _c.setLoading(true);
    AppLogger.event('otp_verify', {'email': state.email, 'purpose': state.purpose.name});

    try {
      if (state.purpose == OtpPurpose.resetPassword) {
        view?.goResetPassword(state.email, state.code);
        return;
      }

      final result = await _repo.verifyEmail(
        email: state.email,
        otp: state.code,
      );
      view?.onVerifySuccess(
        result.message.isNotEmpty
            ? result.message
            : 'Email verified successfully. You can sign in now.',
      );
    } on ApiException catch (e) {
      view?.onVerifyError(e.message);
    } catch (e, st) {
      AppLogger.e('OTP verify failed', e, st);
      view?.onVerifyError('Verification failed. Please try again.');
    } finally {
      if (!cubit.isClosed) _c.setLoading(false);
    }
  }

  Future<void> resendCode() async {
    if (!state.canResend || state.loading) return;
    if (state.email.isEmpty) {
      view?.showMessage('Email is missing. Please go back and try again.');
      return;
    }

    _c.setLoading(true);
    AppLogger.event('otp_resend', {'email': state.email});

    try {
      final result = await _repo.resendOtp(email: state.email);
      _c.resetTimer();
      _startTimer();
      view?.showMessage(
        result.message.isNotEmpty
            ? result.message
            : 'Code resent to ${state.email}',
      );
    } on ApiException catch (e) {
      view?.showMessage(e.message);
    } catch (e, st) {
      AppLogger.e('OTP resend failed', e, st);
      view?.showMessage('Could not resend code. Please try again.');
    } finally {
      if (!cubit.isClosed) _c.setLoading(false);
    }
  }
}
