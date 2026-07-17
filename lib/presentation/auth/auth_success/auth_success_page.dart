import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';

class AuthSuccessPage extends StatelessWidget {
  const AuthSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.green50,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.green100,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Icon(
                      Icons.check_rounded,
                      size: 32,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'All done!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your password has been reset successfully. You can now continue to the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.gray500,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              AppButton(
                label: 'Continue to App',
                onPressed: () {
                  AppLogger.event('auth_success_continue');
                  AppLogger.navigation('auth-success', 'home');
                  context.go('/home');
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Back to Sign In',
                variant: AppBtnVariant.secondary,
                onPressed: () {
                  AppLogger.event('auth_success_back_login');
                  AppLogger.navigation('auth-success', 'login');
                  context.go('/login');
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
