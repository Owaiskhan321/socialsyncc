import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/keyboard_dismiss.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_snackbar.dart';
import 'register_presenter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> implements RegisterView {
  late final RegisterPresenter _presenter;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presenter = RegisterPresenter();
    _presenter.attach(this);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _presenter.dispose();
    super.dispose();
  }

  @override
  void showMessage(String message) {
    if (!mounted) return;
    AppSnackBar.error(context, message);
  }

  @override
  void onRegisterSuccess(String message, String email) {
    if (!mounted) return;
    AppSnackBar.success(context, message);
    AppLogger.navigation('register', 'otp-verify');
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.push(
        '/otp-verify?email=${Uri.encodeComponent(email)}&purpose=verify',
      );
    });
  }

  @override
  void goLogin() {
    if (!mounted) return;
    AppLogger.navigation('register', 'login');
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _presenter.cubit as RegisterCubit,
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
                    KeyboardDismiss.hide(context);
                    context.pop();
                  }),
                  const SizedBox(height: 32),
                  const Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join 5,000+ brands on SocialSyncc',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.gray500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppInput(
                    controller: _nameCtrl,
                    icon: Icons.person_outline_rounded,
                    label: 'Full name',
                    hint: 'Alex Morgan',
                    onChanged: _presenter.onFullNameChanged,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: _emailCtrl,
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    hint: 'you@company.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: _presenter.onEmailChanged,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: _phoneCtrl,
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    hint: '+923001234567',
                    keyboardType: TextInputType.phone,
                    onChanged: _presenter.onPhoneChanged,
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<RegisterCubit, RegisterState>(
                    builder: (context, state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppInput(
                            controller: _passwordCtrl,
                            icon: Icons.lock_outline_rounded,
                            label: 'Password',
                            hint: 'Create a strong password',
                            obscure: state.obscurePassword,
                            onChanged: _presenter.onPasswordChanged,
                          ),
                          const SizedBox(height: 12),
                          _PasswordStrengthBars(strength: state.strength),
                          const SizedBox(height: 16),
                          AppInput(
                            controller: _confirmCtrl,
                            icon: Icons.lock_outline_rounded,
                            label: 'Confirm password',
                            hint: 'Re-enter your password',
                            obscure: state.obscureConfirm,
                            onChanged: _presenter.onConfirmPasswordChanged,
                          ),
                          if (state.confirmPassword.isNotEmpty) ...[
                            const SizedBox(height: 8),
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
                                    fontSize: 12,
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
                  const SizedBox(height: 20),
                  BlocBuilder<RegisterCubit, RegisterState>(
                    builder: (context, state) {
                      return GestureDetector(
                        onTap: _presenter.toggleTerms,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                color: state.agreedToTerms
                                    ? AppColors.primary
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: state.agreedToTerms
                                      ? AppColors.primary
                                      : AppColors.gray300,
                                  width: 1.5,
                                ),
                              ),
                              child: state.agreedToTerms
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: AppColors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.gray500,
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  BlocBuilder<RegisterCubit, RegisterState>(
                    builder: (context, state) {
                      return AppButton(
                        label: 'Create Account',
                        loading: state.loading,
                        onPressed: state.loading
                            ? null
                            : () {
                                KeyboardDismiss.hide(context);
                                _presenter.createAccount();
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        KeyboardDismiss.hide(context);
                        _presenter.goLogin();
                      },
                      child: const Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 14, color: AppColors.gray500),
                          children: [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
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

class _PasswordStrengthBars extends StatelessWidget {
  const _PasswordStrengthBars({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final filled = i < strength;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
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
