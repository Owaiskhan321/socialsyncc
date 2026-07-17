import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/keyboard_dismiss.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import 'reset_password_presenter.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    implements ResetPasswordView {
  late final ResetPasswordPresenter _presenter;
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presenter = ResetPasswordPresenter();
    _presenter.attach(this);
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _presenter.dispose();
    super.dispose();
  }

  @override
  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void goAuthSuccess() {
    if (!mounted) return;
    AppLogger.navigation('reset-password', 'auth-success');
    context.go('/auth-success');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _presenter.cubit as ResetPasswordCubit,
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
                    Icons.shield_outlined,
                    size: 26,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Set new password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your new password must be different from previously used passwords.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.gray500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                  builder: (context, state) {
                    return AppInput(
                      controller: _passwordCtrl,
                      icon: Icons.lock_outline_rounded,
                      label: 'New password',
                      hint: '••••••••',
                      obscure: state.obscurePassword,
                      onChanged: _presenter.onPasswordChanged,
                    );
                  },
                ),
                const SizedBox(height: 16),
                BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppInput(
                          controller: _confirmCtrl,
                          icon: Icons.lock_outline_rounded,
                          label: 'Confirm password',
                          hint: '••••••••',
                          obscure: state.obscureConfirm,
                          onChanged: _presenter.onConfirmChanged,
                        ),
                        if (state.hasConfirmInput) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                state.passwordsMatch
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 16,
                                color: state.passwordsMatch
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                state.passwordsMatch
                                    ? 'Passwords match'
                                    : "Passwords don't match",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: state.passwordsMatch
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Reset Password',
                  onPressed: () {
                    KeyboardDismiss.hide(context);
                    _presenter.resetPassword();
                  },
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
