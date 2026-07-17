import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/keyboard_dismiss.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/repositories/app_data.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final heroH = (h * 0.42).clamp(280.0, 360.0);

    return KeyboardDismissScope(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: heroH,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: AppData.welcomeHeroUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.gray100),
                      errorWidget: (context, url, error) => Container(color: AppColors.gray200),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.transparent, AppColors.white],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.layers_rounded, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'OmniPost',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 24),
                      const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                            height: 1.2,
                          ),
                          children: [
                            TextSpan(text: 'Your social media,\n'),
                            TextSpan(
                              text: 'unified.',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 12),
                      const Text(
                        'Connect all your platforms and publish stunning content from one beautiful interface.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray500,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        children: ['5,000+ brands', '8 platforms', 'Trusted globally']
                            .map(
                              (t) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    t,
                                    style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                      const Spacer(),
                      AppButton(
                        label: 'Get Started',
                        onPressed: () {
                          AppLogger.navigation('welcome', 'register');
                          context.push('/register');
                        },
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Sign In',
                        variant: AppBtnVariant.outline,
                        onPressed: () {
                          AppLogger.navigation('welcome', 'login');
                          context.push('/login');
                        },
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
