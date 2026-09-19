import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/keyboard_dismiss.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../navigation/app_launch_transition.dart';
import 'animated_otp_verification.dart';
import 'otp_verify_presenter.dart';

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({
    super.key,
    required this.email,
    this.purpose = OtpPurpose.verifyEmail,
  });

  final String email;
  final OtpPurpose purpose;

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> implements OtpVerifyView {
  late final OtpVerifyPresenter _presenter;
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  OtpAnimationState _anim = OtpAnimationState.input;
  bool _navigating = false;
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _presenter = OtpVerifyPresenter(
      email: widget.email,
      purpose: widget.purpose,
    );
    _presenter.attach(this);
    for (final n in _nodes) {
      n.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _presenter.dispose();
    super.dispose();
  }

  @override
  void showMessage(String message) {
    if (!mounted) return;
    AppSnackBar.error(context, message);
  }

  @override
  void onVerifyError(String message) {
    if (!mounted) return;
    setState(() => _anim = OtpAnimationState.error);
    AppSnackBar.error(context, message);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_anim == OtpAnimationState.error) {
        setState(() => _anim = OtpAnimationState.input);
      }
    });
  }

  @override
  void onVerifySuccess(String message) {
    if (!mounted || _navigating) return;
    // Reset-password flow: skip orbit animation, go next immediately.
    if (widget.purpose == OtpPurpose.resetPassword) {
      return;
    }
    _successMessage = message;
    KeyboardDismiss.hide(context);
    setState(() => _anim = OtpAnimationState.movingToCenter);
  }

  void _onSuccessAnimationComplete() {
    if (!mounted || _navigating) return;
    _navigating = true;
    if (_successMessage.isNotEmpty) {
      AppSnackBar.success(context, _successMessage);
    }
    AppLogger.navigation('otp-verify', 'login');
    context.go('/login');
  }

  @override
  void goResetPassword(String email, String otp) {
    if (!mounted) return;
    AppLogger.navigation('otp-verify', 'reset-password');
    context.pushFromSource(
      '/reset-password?email=${Uri.encodeComponent(email)}&otp=${Uri.encodeComponent(otp)}',
      borderRadius: 20,
    );
  }

  void _onChanged(int index, String value) {
    if (_anim == OtpAnimationState.verifying ||
        _anim == OtpAnimationState.movingToCenter ||
        _anim == OtpAnimationState.orbiting ||
        _anim == OtpAnimationState.collapsing ||
        _anim == OtpAnimationState.success) {
      return;
    }

    if (value.length > 1) {
      final chars = value.replaceAll(RegExp(r'\D'), '');
      // Full OTP paste (≥4 digits). Short multi-char input = last digit only.
      if (chars.length >= 4) {
        for (var i = 0; i < 6 && i < chars.length; i++) {
          _ctrls[i].text = chars[i];
          _presenter.onDigitChanged(i, chars[i]);
        }
        final focusIdx = chars.length.clamp(0, 5);
        _nodes[focusIdx].requestFocus();
      } else {
        final last = chars.isEmpty ? '' : chars[chars.length - 1];
        _ctrls[index].value = TextEditingValue(
          text: last,
          selection: TextSelection.collapsed(offset: last.length),
        );
        _presenter.onDigitChanged(index, last);
        if (last.isNotEmpty && index < 5) {
          _nodes[index + 1].requestFocus();
        }
      }
      return;
    }

    _presenter.onDigitChanged(index, value);
    if (value.isNotEmpty && index < 5) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    if (_navigating) return;
    if (_anim == OtpAnimationState.verifying ||
        _anim == OtpAnimationState.movingToCenter ||
        _anim == OtpAnimationState.success) {
      return;
    }
    KeyboardDismiss.hide(context);

    if (widget.purpose == OtpPurpose.resetPassword) {
      await _presenter.verifyCode();
      return;
    }

    setState(() => _anim = OtpAnimationState.verifying);
    await _presenter.verifyCode();
    if (!mounted) return;
    // If still verifying, API failed without error callback path — reset.
    if (_anim == OtpAnimationState.verifying) {
      setState(() => _anim = OtpAnimationState.input);
    }
  }

  @override
  Widget build(BuildContext context) {
    final successPhase = _anim == OtpAnimationState.movingToCenter ||
        _anim == OtpAnimationState.orbiting ||
        _anim == OtpAnimationState.collapsing ||
        _anim == OtpAnimationState.success;

    return BlocProvider.value(
      value: _presenter.cubit as OtpVerifyCubit,
      child: KeyboardDismissScope(
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _AuthBackButton(onTap: () {
                    if (successPhase) return;
                    KeyboardDismiss.hide(context);
                    context.pop();
                  }),
                  const SizedBox(height: 40),
                  AnimatedOpacity(
                    opacity: successPhase ? 0.35 : 1,
                    duration: const Duration(milliseconds: 280),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: successPhase
                            ? AppColors.green50
                            : AppColors.blue50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        successPhase
                            ? Icons.verified_outlined
                            : Icons.mail_outline_rounded,
                        size: 26,
                        color: successPhase
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _VerificationTextContent(
                    success: successPhase,
                    email: widget.email,
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<OtpVerifyCubit, OtpVerifyState>(
                    builder: (context, state) {
                      return AnimatedOtpVerification(
                        length: 6,
                        controllers: _ctrls,
                        focusNodes: _nodes,
                        digits: state.digits,
                        animationState: _anim,
                        onChanged: _onChanged,
                        onSuccessAnimationComplete: _onSuccessAnimationComplete,
                        onAnimationPhaseChanged: (phase) {
                          if (!mounted) return;
                          if (_anim == phase) return;
                          setState(() => _anim = phase);
                        },
                      );
                    },
                  ),
                  if (_anim == OtpAnimationState.verifying) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ],
                  if (successPhase) ...[
                    const SizedBox(height: 18),
                    Center(
                      child: AnimatedOpacity(
                        opacity: _anim == OtpAnimationState.success ? 1 : 0,
                        duration: const Duration(milliseconds: 350),
                        child: Text(
                          'Verified & Secured 🔒',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (!successPhase) ...[
                    const SizedBox(height: 28),
                    BlocBuilder<OtpVerifyCubit, OtpVerifyState>(
                      builder: (context, state) {
                        return AppButton(
                          label: 'Verify Code',
                          loading: state.loading ||
                              _anim == OtpAnimationState.verifying,
                          onPressed: state.loading ||
                                  _anim == OtpAnimationState.verifying
                              ? null
                              : _verify,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: BlocBuilder<OtpVerifyCubit, OtpVerifyState>(
                        builder: (context, state) {
                          if (state.canResend) {
                            return GestureDetector(
                              onTap: state.loading ||
                                      _anim == OtpAnimationState.verifying
                                  ? null
                                  : () {
                                      KeyboardDismiss.hide(context);
                                      _presenter.resendCode();
                                    },
                              child: Text(
                                'Resend code',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: state.loading
                                      ? AppColors.gray400
                                      : AppColors.primary,
                                ),
                              ),
                            );
                          }
                          return Text(
                            'Resend code in ${state.resendSeconds}s',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gray500,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationTextContent extends StatelessWidget {
  const _VerificationTextContent({
    required this.success,
    required this.email,
  });

  final bool success;
  final String email;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
      child: success
          ? const Column(
              key: ValueKey('success-copy'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified successfully',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Your email has been verified.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.gray500,
                    height: 1.5,
                  ),
                ),
              ],
            )
          : Column(
              key: const ValueKey('input-copy'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check your email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.gray500,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text: 'We sent a 6-digit verification code to ',
                      ),
                      TextSpan(
                        text: email.isEmpty ? 'your email' : email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _AuthBackButton extends StatelessWidget {
  const _AuthBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: const Icon(
          Icons.chevron_left_rounded,
          size: 22,
          color: AppColors.gray700,
        ),
      ),
    );
  }
}
