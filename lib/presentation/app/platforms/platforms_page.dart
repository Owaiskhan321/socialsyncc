import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/mobile_header.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../data/models/api_models.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../navigation/app_launch_transition.dart';
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
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            Expanded(
              child: BlocConsumer<PlatformsCubit, PlatformsState>(
                listenWhen: (a, b) => a.error != b.error && b.error != null,
                listener: (context, state) {
                  if (state.error != null) {
                    AppSnackBar.error(context, state.error!);
                  }
                },
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final repo = SocialRepository();
                  return RefreshIndicator(
                    onRefresh: () => context.read<PlatformsCubit>().load(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        Text(
                          '${state.connectedIds.length} of ${state.platforms.length} platforms',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...state.platforms.asMap().entries.map((e) {
                          final p = e.value;
                          final connected = state.connectedIds.contains(p.id);
                          final accounts = repo.accountsForPlatform(
                            p.id,
                            state.connectedAccounts,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PlatformCard(
                              platform: p,
                              connected: connected,
                              account: accounts.isNotEmpty ? accounts.first : null,
                              onManage: (src) {
                                AppLogger.navigation('platforms', 'detail');
                                src.pushFromSource(
                                  '/platforms/${p.id}',
                                  borderRadius: 16,
                                );
                              },
                              onToggle: () =>
                                  context.read<PlatformsCubit>().toggleConnect(p.id),
                              busy: state.busyPlatformId == p.id,
                            )
                                .animate()
                                .fadeIn(delay: (40 * e.key).ms)
                                .slideY(begin: 0.05, end: 0),
                          );
                        }),
                      ],
                    ),
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
    this.account,
    this.busy = false,
  });

  final PlatformModel platform;
  final bool connected;
  final SocialAccount? account;
  final ValueChanged<BuildContext> onManage;
  final VoidCallback onToggle;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final comingSoon = platform.isComingSoon;
    final creditLabel = platform.creditCost <= 0
        ? 'Free'
        : '${platform.creditCost} cr';

    return Opacity(
      opacity: comingSoon ? 0.72 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (connected && account?.profileImage != null)
                  _ProfileAvatar(
                    url: account!.profileImage,
                    fallbackId: platform.id,
                  )
                else
                  PlatformIcon(id: platform.id, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              platform.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _AvailabilityPill(comingSoon: comingSoon),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (comingSoon)
                        const Text(
                          'Coming soon',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else if (connected && account != null) ...[
                        Text(
                          account!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray800,
                          ),
                        ),
                        if (account!.username != null &&
                            account!.username!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            account!.username!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        const Text(
                          'Connected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ] else
                        Text(
                          connected ? 'Connected' : 'Not connected',
                          style: TextStyle(
                            fontSize: 12,
                            color: connected
                                ? AppColors.success
                                : AppColors.gray400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PlatformIcon(id: platform.id, size: 28),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            creditLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: busy || comingSoon
                        ? null
                        : (connected
                            ? () => onManage(context)
                            : onToggle),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: comingSoon
                            ? AppColors.amber50
                            : connected
                                ? AppColors.gray50
                                : AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: comingSoon || connected
                            ? Border.all(
                                color: comingSoon
                                    ? AppColors.warning.withValues(alpha: 0.35)
                                    : AppColors.gray200,
                              )
                            : null,
                      ),
                      child: busy
                          ? const SizedBox(
                              height: 18,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : Text(
                              comingSoon
                                  ? 'Coming soon'
                                  : connected
                                      ? 'Manage'
                                      : 'Connect',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: comingSoon
                                    ? AppColors.warning
                                    : connected
                                        ? AppColors.gray800
                                        : AppColors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                if (connected && !comingSoon) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: busy ? null : onToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.red50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Disconnect',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.comingSoon});

  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final color = comingSoon ? AppColors.warning : AppColors.success;
    final label = comingSoon ? 'Soon' : 'Live';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: comingSoon ? AppColors.amber50 : AppColors.green50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.url, required this.fallbackId});

  final String? url;
  final String fallbackId;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: CachedNetworkImage(
          imageUrl: url!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => PlatformIcon(id: fallbackId, size: 44),
          placeholder: (_, __) => Container(
            width: 44,
            height: 44,
            color: AppColors.gray100,
          ),
        ),
      );
    }
    return PlatformIcon(id: fallbackId, size: 44);
  }
}
