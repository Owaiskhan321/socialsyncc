import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import 'splash_presenter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> implements SplashView {
  late final SplashPresenter _presenter;

  @override
  void initState() {
    super.initState();
    _presenter = SplashPresenter();
    _presenter.attach(this);
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  void showMessage(String message) {}

  @override
  void goToWelcome() {
    if (!mounted) return;
    AppLogger.navigation('splash', 'welcome');
    context.go('/welcome');
  }

  @override
  void goToHome() {
    if (!mounted) return;
    AppLogger.navigation('splash', 'home');
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _presenter.cubit as SplashCubit,
      child: Scaffold(
        body: GestureDetector(
          onTap: _presenter.continueTap,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.4, -1),
                end: Alignment(0.4, 1),
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.primaryDeep,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                        const SizedBox(height: 20),
                        const Text(
                          'SocialSyncc',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Schedule everywhere.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                        const SizedBox(height: 64),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .fade(begin: 0.3, end: 1, duration: 600.ms, delay: (i * 200).ms)
                                .then()
                                .fade(begin: 1, end: 0.3, duration: 600.ms);
                          }),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 48,
                    child: Center(
                      child: Text(
                        'Tap to continue →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
