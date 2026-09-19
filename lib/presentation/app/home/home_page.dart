import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_video_player.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../core/widgets/platform_status_icons.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/models.dart';
import '../../../navigation/app_launch_transition.dart';
import '../../shell/tab_cubit.dart';
import 'home_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return Column(
              children: [
                _TopBar(
                  greeting: state.greeting,
                  name: state.name,
                  credits: state.totalCredits,
                  onBell: (src) {
                    AppLogger.navigation('home', 'notifications');
                    src.pushFromSource('/notifications', borderRadius: 20);
                  },
                  onAvatar: (src) {
                    AppLogger.navigation('home', 'profile');
                    src.pushFromSource('/profile', borderRadius: 22);
                  },
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => context.read<HomeCubit>().load(),
                    child: state.loading && state.recentPosts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 160),
                              Center(child: CircularProgressIndicator()),
                            ],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                            children: [
                              if (state.error != null) ...[
                                Text(
                                  state.error!,
                                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                              ],
                              _StatsGrid(
                                connected: state.connected,
                                scheduled: state.scheduled,
                                published: state.published,
                                drafts: state.drafts,
                              ).animate().fadeIn(duration: 300.ms),
                              const SizedBox(height: 24),
                              _SectionHeader(
                                title: 'Platforms',
                                action: 'Manage',
                                onAction: (src) {
                                  AppLogger.navigation('home', 'platforms');
                                  src.pushFromSource('/platforms', borderRadius: 12);
                                },
                              ),
                              const SizedBox(height: 12),
                              _PlatformsRow(
                                ids: state.platformIds,
                                platforms: state.platforms,
                              ).animate().fadeIn(delay: 80.ms),
                              const SizedBox(height: 24),
                              _SectionHeader(
                                title: 'Recent Posts',
                                action: 'View all',
                                onAction: (_) {
                                  AppLogger.event('home_view_posts');
                                  context.read<TabCubit>().setTab(1);
                                },
                              ),
                              const SizedBox(height: 12),
                              if (state.recentPosts.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No posts yet — create your first one',
                                      style: TextStyle(color: AppColors.gray400, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                )
                              else
                                ...state.recentPosts.asMap().entries.map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: _PostCard(post: e.value)
                                            .animate()
                                            .fadeIn(delay: (100 + e.key * 60).ms)
                                            .slideY(begin: 0.08, end: 0),
                                      ),
                                    ),
                              const SizedBox(height: 16),
                              const Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _QuickActions(
                                onCreate: (src) {
                                  AppLogger.navigation('home', 'create');
                                  src.pushFromSource('/create', borderRadius: 16);
                                },
                                onCalendar: () {
                                  AppLogger.event('home_calendar');
                                  context.read<TabCubit>().setTab(2);
                                },
                                onAnalytics: () {
                                  AppLogger.event('home_analytics');
                                  context.read<TabCubit>().setTab(3);
                                },
                              ).animate().fadeIn(delay: 200.ms),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.greeting,
    required this.name,
    required this.credits,
    required this.onBell,
    required this.onAvatar,
  });

  final String greeting;
  final String name;
  final int credits;
  final ValueChanged<BuildContext> onBell;
  final ValueChanged<BuildContext> onAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$credits',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (bellCtx) => GestureDetector(
              onTap: () => onBell(bellCtx),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppColors.gray700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Builder(
            builder: (avatarCtx) => GestureDetector(
              onTap: () => onAvatar(avatarCtx),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.blue100,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.connected,
    required this.scheduled,
    required this.published,
    required this.drafts,
  });

  final int connected;
  final int scheduled;
  final int published;
  final int drafts;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(label: 'Connected', value: '$connected', color: AppColors.primary, bg: AppColors.blue50),
      _StatItem(label: 'Scheduled', value: '$scheduled', color: AppColors.warning, bg: AppColors.amber50),
      _StatItem(label: 'Published', value: '$published', color: AppColors.success, bg: AppColors.green50),
      _StatItem(label: 'Drafts', value: '$drafts', color: AppColors.gray700, bg: AppColors.gray100),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: items
          .map(
            (s) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: s.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.insights_rounded, size: 16, color: s.color),
                  ),
                  const Spacer(),
                  Text(
                    s.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatItem {
  const _StatItem({required this.label, required this.value, required this.color, required this.bg});
  final String label;
  final String value;
  final Color color;
  final Color bg;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, required this.onAction});

  final String title;
  final String action;
  final ValueChanged<BuildContext> onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
          ),
        ),
        Builder(
          builder: (actionCtx) => GestureDetector(
            onTap: () => onAction(actionCtx),
            child: Text(
              action,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlatformsRow extends StatelessWidget {
  const _PlatformsRow({
    required this.ids,
    this.platforms = const [],
  });

  final List<String> ids;
  final List<PlatformModel> platforms;

  @override
  Widget build(BuildContext context) {
    final items = platforms.isNotEmpty
        ? platforms
        : ids
            .map(
              (id) => PlatformModel(
                id: id,
                name: id,
                color: 0xFF64748B,
                accounts: const [],
                connected: true,
              ),
            )
            .toList();

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No platforms connected yet',
          style: TextStyle(color: AppColors.gray400, fontWeight: FontWeight.w500),
        ),
      );
    }

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = items[i];
          return Builder(
            builder: (itemCtx) => GestureDetector(
              onTap: () {
                AppLogger.navigation('home', 'platform_detail');
                itemCtx.pushFromSource(
                  '/platforms/${p.id}',
                  borderRadius: 24,
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PlatformIcon(id: p.id, size: 48),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: post.id.isEmpty
          ? null
          : () => context.pushFromSource(
                '/posts/${post.id}',
                borderRadius: 16,
              ),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    post.thumbnail != null && post.thumbnail!.startsWith('http')
                        ? (post.mediaIsVideo
                            ? const VideoMediaPlaceholder(
                                width: 56,
                                height: 56,
                                borderRadius: 12,
                              )
                            : Image.network(
                                post.thumbnail!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 56,
                                  height: 56,
                                  color: AppColors.gray100,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: AppColors.gray400,
                                  ),
                                ),
                              ))
                        : Container(
                            width: 56,
                            height: 56,
                            color: AppColors.gray100,
                            child: const Icon(
                              Icons.image_outlined,
                              color: AppColors.gray400,
                            ),
                          ),
                    if (!post.mediaIsVideo && post.displayMediaUrls.length > 1)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${post.displayMediaUrls.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        StatusBadge(status: post.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              PlatformStatusIcons(
                post: post,
                iconSize: 18,
                spacing: 4,
              ),
              const Spacer(),
              if (post.publishAt != null)
                Text(
                  post.publishAt!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCreate,
    required this.onCalendar,
    required this.onAnalytics,
  });

  final ValueChanged<BuildContext> onCreate;
  final VoidCallback onCalendar;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Builder(
              builder: (src) => _QuickActionTile(
                icon: Icons.edit_outlined,
                label: 'New Post',
                color: AppColors.primary,
                bg: AppColors.blue50,
                onTap: () => onCreate(src),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _QuickActionTile(
              icon: Icons.calendar_today_outlined,
              label: 'Calendar',
              color: AppColors.warning,
              bg: AppColors.amber50,
              onTap: onCalendar,
            ),
          ),
        ),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.bar_chart_rounded,
            label: 'Analytics',
            color: AppColors.purple,
            bg: AppColors.purple50,
            onTap: onAnalytics,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
