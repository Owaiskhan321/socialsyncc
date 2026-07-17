import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mobile_header.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../data/models/models.dart';
import 'platforms_cubit.dart';

class PlatformsPage extends StatelessWidget {
  const PlatformsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlatformsCubit(),
      child: const _PlatformsView(),
    );
  }
}

class _PlatformsView extends StatelessWidget {
  const _PlatformsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            MobileHeader(
              title: 'Platforms',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: BlocBuilder<PlatformsCubit, PlatformsState>(
                builder: (context, state) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      Text(
                        '${state.connectedIds.length} of ${state.platforms.length} connected',
                        style: const TextStyle(fontSize: 13, color: AppColors.gray500, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 14),
                      ...state.platforms.asMap().entries.map((e) {
                        final p = e.value;
                        final connected = state.connectedIds.contains(p.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PlatformCard(
                            platform: p,
                            connected: connected,
                            onManage: () {
                              AppLogger.navigation('platforms', 'detail');
                              context.push('/platforms/${p.id}');
                            },
                            onToggle: () => context.read<PlatformsCubit>().toggleConnect(p.id),
                          ).animate().fadeIn(delay: (50 * e.key).ms).slideY(begin: 0.05, end: 0),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.platform,
    required this.connected,
    required this.onManage,
    required this.onToggle,
  });

  final PlatformModel platform;
  final bool connected;
  final VoidCallback onManage;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              PlatformIcon(id: platform.id, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      connected
                          ? '${platform.accounts.length} account${platform.accounts.length == 1 ? '' : 's'} connected'
                          : 'Not connected',
                      style: TextStyle(
                        fontSize: 12,
                        color: connected ? AppColors.success : AppColors.gray400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: connected ? onManage : onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: connected ? AppColors.gray50 : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      border: connected ? Border.all(color: AppColors.gray200) : null,
                    ),
                    child: Text(
                      connected ? 'Manage' : 'Connect',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: connected ? AppColors.gray800 : AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (connected) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.red50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Disconnect',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
