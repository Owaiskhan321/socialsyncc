import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/mobile_header.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../data/models/api_models.dart';
import 'platform_detail_cubit.dart';

class PlatformDetailPage extends StatelessWidget {
  const PlatformDetailPage({super.key, required this.platformId});

  final String platformId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlatformDetailCubit(platformId: platformId),
      child: const _PlatformDetailView(),
    );
  }
}

class _PlatformDetailView extends StatelessWidget {
  const _PlatformDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlatformDetailCubit, PlatformDetailState>(
      listenWhen: (a, b) => a.error != b.error && b.error != null,
      listener: (context, state) {
        if (state.error != null) AppSnackBar.error(context, state.error!);
      },
      builder: (context, state) {
        final platform = state.platform;
        final account =
            state.socialAccounts.isNotEmpty ? state.socialAccounts.first : null;

        return Scaffold(
          backgroundColor: AppColors.gray50,
          body: SafeArea(
            child: Column(
              children: [
                MobileHeader(
                  title: platform.name,
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/platforms');
                    }
                  },
                ),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<PlatformDetailCubit>().load(),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                            children: [
                              _HeaderCard(
                                platformId: platform.id,
                                platformName: platform.name,
                                connected: state.connected,
                                account: account,
                              ).animate().fadeIn().scale(
                                    begin: const Offset(0.97, 0.97),
                                  ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Posts',
                                      value: '${state.postCount}',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Status',
                                      value: state.connected ? 'Active' : 'Off',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Resources',
                                      value: '${state.resources.length}',
                                    ),
                                  ),
                                ],
                              ),
                              if (account != null) ...[
                                const SizedBox(height: 24),
                                const Text(
                                  'Account details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gray900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _DetailsCard(account: account)
                                    .animate()
                                    .fadeIn(delay: 60.ms),
                              ],
                              if (state.resources.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                const Text(
                                  'Resources',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gray900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...state.resources.asMap().entries.map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.gray100),
                                      ),
                                      child: Text(
                                        e.value.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.gray900,
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: (50 * e.key).ms),
                                  );
                                }),
                              ],
                              if (!state.connected) ...[
                                const SizedBox(height: 24),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.gray100),
                                  ),
                                  child: const Text(
                                    'No account connected yet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.gray400),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              if (state.connected)
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        label: 'Disconnect',
                                        loading: state.busy,
                                        variant: AppBtnVariant.secondary,
                                        onPressed: state.busy
                                            ? null
                                            : () => context
                                                .read<PlatformDetailCubit>()
                                                .disconnect(),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                AppButton(
                                  label: state.busy ? 'Opening…' : 'Connect',
                                  loading: state.busy,
                                  onPressed: state.busy
                                      ? null
                                      : () => context
                                          .read<PlatformDetailCubit>()
                                          .connect(),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.platformId,
    required this.platformName,
    required this.connected,
    this.account,
  });

  final String platformId;
  final String platformName;
  final bool connected;
  final SocialAccount? account;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          if (account?.profileImage != null &&
              account!.profileImage!.startsWith('http'))
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: CachedNetworkImage(
                imageUrl: account!.profileImage!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    PlatformIcon(id: platformId, size: 80),
              ),
            )
          else
            PlatformIcon(id: platformId, size: 64),
          const SizedBox(height: 14),
          Text(
            account?.name ?? platformName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlatformIcon(id: platformId, size: 18),
              const SizedBox(width: 6),
              Text(
                platformName,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (account?.username != null && account!.username!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              account!.username!,
              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            connected ? (account?.status ?? 'active') : 'Not connected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: connected ? AppColors.success : AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.account});

  final SocialAccount account;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          _DetailRow(label: 'Display name', value: account.name),
          _DetailRow(
            label: 'Username',
            value: account.username?.isNotEmpty == true ? account.username! : '—',
          ),
          _DetailRow(
            label: 'Platform',
            value: account.platformName ?? account.provider,
          ),
          _DetailRow(label: 'Status', value: account.status),
          _DetailRow(
            label: 'Connected at',
            value: _formatDate(account.connectedAt),
          ),
          _DetailRow(
            label: 'Last synced',
            value: _formatDate(account.lastSyncedAt),
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    return DateFormat('MMM d, yyyy · h:mm a').format(dt);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
          ),
        ],
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}
