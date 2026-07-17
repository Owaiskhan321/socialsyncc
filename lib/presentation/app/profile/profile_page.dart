import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mobile_header.dart';
import '../../../data/repositories/app_data.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = [
      (Icons.settings_outlined, 'Settings', '/settings'),
      (Icons.hub_outlined, 'Connected Platforms', '/platforms'),
      (Icons.workspace_premium_outlined, 'Subscription', '/subscription'),
      (Icons.help_outline, 'Help & Support', null),
      (Icons.logout, 'Sign Out', '/welcome'),
    ];

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            MobileHeader(
              title: 'Profile',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.blue200, width: 2),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: AppData.avatarUrl,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(width: 88, height: 88, color: AppColors.gray200),
                              errorWidget: (_, __, ___) => Container(
                                width: 88,
                                height: 88,
                                color: AppColors.blue100,
                                child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
                        const SizedBox(height: 14),
                        const Text(
                          'Alex Johnson',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'alex@omnipost.app',
                          style: TextStyle(fontSize: 13, color: AppColors.gray500),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.blue50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.blue100),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium, size: 14, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Professional Plan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...menu.asMap().entries.map((e) {
                    final item = e.value;
                    final isDanger = item.$2 == 'Sign Out';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          AppLogger.navigation('profile', item.$3 ?? 'none');
                          if (item.$3 == null) return;
                          if (item.$3 == '/welcome') {
                            context.go('/welcome');
                          } else {
                            context.push(item.$3!);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.gray100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDanger ? AppColors.red50 : AppColors.gray50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.$1,
                                  size: 18,
                                  color: isDanger ? AppColors.danger : AppColors.gray700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.$2,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDanger ? AppColors.danger : AppColors.gray900,
                                  ),
                                ),
                              ),
                              if (!isDanger)
                                const Icon(Icons.chevron_right, color: AppColors.gray300),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (60 * e.key).ms).slideX(begin: 0.04, end: 0),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
