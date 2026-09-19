import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/keyboard_dismiss.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/social_logos.dart';
import '../../../navigation/app_launch_transition.dart';
import 'login_presenter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> implements LoginView {
  late final LoginPresenter _presenter;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presenter = LoginPresenter();
    _presenter.attach(this);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _presenter.dispose();
    super.dispose();
  }

  @override
  void showMessage(String message) {
    if (!mounted) return;
    AppSnackBar.error(context, message);
  }

  @override
  void onLoginSuccess(String message) {
    if (!mounted) return;
    AppSnackBar.success(context, message);
    AppLogger.navigation('login', 'home');
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      context.go('/home');
    });
  }

  @override
  void goForgotPassword() {
    if (!mounted) return;
    AppLogger.navigation('login', 'forgot-password');
    context.pushFromSource('/forgot-password', borderRadius: 12);
  }

  @override
  void goRegister() {
    if (!mounted) return;
    AppLogger.navigation('login', 'register');
    context.pushFromSource('/register', borderRadius: 12);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _presenter.cubit as LoginCubit,
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
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to your account',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.gray500,
                      height: 1.4,
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
                  const SizedBox(height: 16),
                  BlocBuilder<LoginCubit, LoginState>(
                    builder: (context, state) {
                      return AppInput(
                        controller: _passwordCtrl,
                        icon: Icons.lock_outline_rounded,
                        label: 'Password',
                        hint: '••••••••',
                        obscure: state.obscurePassword,
                        onChanged: _presenter.onPasswordChanged,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Builder(
                      builder: (src) => GestureDetector(
                        onTap: () {
                          KeyboardDismiss.hide(context);
                          src.pushFromSource(
                            '/forgot-password',
                            borderRadius: 8,
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  BlocBuilder<LoginCubit, LoginState>(
                    builder: (context, state) {
                      return AppButton(
                        label: 'Sign In',
                        loading: state.loading,
                        onPressed: state.loading || state.socialLoading
                            ? null
                            : () {
                          KeyboardDismiss.hide(context);
                          _presenter.signIn();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const _OrDivider(label: 'or continue with'),
                  const SizedBox(height: 20),
                  BlocBuilder<LoginCubit, LoginState>(
                    builder: (context, state) {
                      final googleLoading =
                          state.socialProvider == SocialSignInProvider.google;
                      final appleLoading =
                          state.socialProvider == SocialSignInProvider.apple;
                      final disabled = state.loading || state.socialLoading;

                      if (Platform.isIOS) {
                        return Row(
                          children: [
                            Expanded(
                              child: _SocialOutlineButton(
                                label: 'Google',
                                leading: const GoogleLogo(size: 20),
                                loading: googleLoading,
                                onTap: disabled ? null : () {
                                  KeyboardDismiss.hide(context);
                                  _presenter.continueWithGoogle();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SocialOutlineButton(
                                label: 'Apple',
                                leading: const AppleLogo(size: 22),
                                loading: appleLoading,
                                onTap: disabled ? null : () {
                                  KeyboardDismiss.hide(context);
                                  _presenter.continueWithApple();
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      return _SocialOutlineButton(
                        label: 'Continue with Google',
                        leading: const GoogleLogo(size: 20),
                        loading: googleLoading,
                        fullWidth: true,
                        onTap: disabled ? null : () {
                          KeyboardDismiss.hide(context);
                          _presenter.continueWithGoogle();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Builder(
                      builder: (src) => GestureDetector(
                        onTap: () {
                          KeyboardDismiss.hide(context);
                          src.pushFromSource('/register', borderRadius: 10);
                        },
                        child: const Text.rich(
                          TextSpan(
                            style: TextStyle(fontSize: 14, color: AppColors.gray500),
                            children: [
                              TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Create one',
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

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.gray200, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.gray400),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.gray200, thickness: 1)),
      ],
    );
  }
}

class _SocialOutlineButton extends StatelessWidget {
  const _SocialOutlineButton({
    required this.label,
    required this.leading,
    required this.onTap,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onTap;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            leading,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Opacity(opacity: 0.55, child: child);
    }
    return GestureDetector(onTap: onTap, child: child);
  }
}
