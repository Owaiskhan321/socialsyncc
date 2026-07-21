import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/keyboard_dismiss.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import 'forgot_password_presenter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    implements ForgotPasswordView {
  late final ForgotPasswordPresenter _presenter;
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presenter = ForgotPasswordPresenter();
    _presenter.attach(this);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _presenter.dispose();
    super.dispose();
  }

  @override
  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void goOtpVerify(String email) {
    if (!mounted) return;
    AppLogger.navigation('forgot-password', 'otp-verify');
    context.push(
      '/otp-verify?email=${Uri.encodeComponent(email)}&purpose=reset',
    );
  }

  @override
  void goLogin() {
    if (!mounted) return;
    AppLogger.navigation('forgot-password', 'login');
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _presenter.cubit as ForgotPasswordCubit,
      child: KeyboardDismissScope(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    Icons.lock_outline_rounded,
                    size: 26,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "No worries — enter your email and we'll send you a 6-digit code to reset your password.",
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.gray500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                AppInput(
                  controller: _emailCtrl,
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  hint: 'you@company.com',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _presenter.onEmailChanged,
                ),
                const SizedBox(height: 28),
                BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
                  buildWhen: (a, b) => a.loading != b.loading,
                  builder: (context, state) {
                    return AppButton(
                      label: state.loading ? 'Sending…' : 'Send Reset Code',
                      loading: state.loading,
                      onPressed: state.loading
                          ? null
                          : () {
                              KeyboardDismiss.hide(context);
                              _presenter.sendResetLink();
                            },
                    );
                  },
                ),
                const SizedBox(height: 28),
                Center(
                  child: GestureDetector(
                    onTap: _presenter.backToSignIn,
                    child: const Text(
                      '← Back to sign in',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
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
