import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/mobile_header.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../data/repositories/app_data.dart';

class PlatformDetailPage extends StatelessWidget {
  const PlatformDetailPage({super.key, required this.platformId});

  final String platformId;

  @override
  Widget build(BuildContext context) {
    final platform = AppData.platformById(platformId) ?? AppData.platforms.first;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            MobileHeader(
              title: platform.name,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.gray100),
                    ),
                    child: Column(
                      children: [
                        PlatformIcon(id: platform.id, size: 64)
                            .animate()
                            .fadeIn()
                            .scale(begin: const Offset(0.9, 0.9)),
                        const SizedBox(height: 14),
                        Text(
                          platform.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${platform.accounts.length} connected account${platform.accounts.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(label: 'Posts', value: '24'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniStat(label: 'Reach', value: '12.4k'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniStat(label: 'Engagement', value: '3.8%'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Accounts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
                  ),
                  const SizedBox(height: 12),
                  ...platform.accounts.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AccountCard(
                        name: e.value,
                        platformId: platform.id,
                        isPrimary: e.key == 0,
                      ).animate().fadeIn(delay: (60 * e.key).ms),
                    );
                  }),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Add account',
                    variant: AppBtnVariant.outline,
                    icon: Icons.add,
                    onPressed: () => AppLogger.event('platform_add_account', {'id': platform.id}),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Reconnect',
                    variant: AppBtnVariant.secondary,
                    onPressed: () => AppLogger.event('platform_reconnect', {'id': platform.id}),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.platformId,
    required this.isPrimary,
  });

  final String name;
  final String platformId;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          PlatformIcon(id: platformId, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900),
                ),
                const SizedBox(height: 2),
                Text(
                  isPrimary ? 'Primary · Connected' : 'Connected',
                  style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Active',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
