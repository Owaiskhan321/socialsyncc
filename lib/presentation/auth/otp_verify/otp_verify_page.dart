import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/keyboard_dismiss.dart';
import '../../../core/widgets/app_button.dart';
import 'otp_verify_presenter.dart';

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({super.key});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> implements OtpVerifyView {
  late final OtpVerifyPresenter _presenter;
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _presenter = OtpVerifyPresenter();
    _presenter.attach(this);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void goResetPassword() {
    if (!mounted) return;
    AppLogger.navigation('otp-verify', 'reset-password');
    context.push('/reset-password');
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Paste handling
      final chars = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < 6 && i < chars.length; i++) {
        _ctrls[i].text = chars[i];
        _presenter.onDigitChanged(i, chars[i]);
      }
      final focusIdx = (chars.length).clamp(0, 5);
      _nodes[focusIdx].requestFocus();
      return;
    }

    _presenter.onDigitChanged(index, value);
    if (value.isNotEmpty && index < 5) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _AuthBackButton(onTap: () => context.pop()),
                const SizedBox(height: 40),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    size: 26,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
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
                BlocBuilder<OtpVerifyCubit, OtpVerifyState>(
                  builder: (context, state) {
                    return Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.gray500,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'We sent a verification code to '),
                          TextSpan(
                            text: state.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                BlocBuilder<OtpVerifyCubit, OtpVerifyState>(
                  builder: (context, state) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        final filled = state.digits[i].isNotEmpty;
                        return SizedBox(
                          width: 48,
                          height: 56,
                          child: TextField(
                            controller: _ctrls[i],
                            focusNode: _nodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.gray50,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: filled
                                      ? AppColors.primary
                                      : AppColors.gray200,
                                  width: filled ? 1.5 : 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: filled
                                      ? AppColors.primary
                                      : AppColors.gray200,
                                  width: filled ? 1.5 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (v) => _onChanged(i, v),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Verify Code',
                  onPressed: _presenter.verifyCode,
                ),
                const SizedBox(height: 24),
                Center(
                  child: BlocBuilder<OtpVerifyCubit, OtpVerifyState>(
                    builder: (context, state) {
                      if (state.canResend) {
                        return GestureDetector(
                          onTap: _presenter.resendCode,
                          child: const Text(
                            'Resend code',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
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
        child: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.gray700),
      ),
    );
  }
}
