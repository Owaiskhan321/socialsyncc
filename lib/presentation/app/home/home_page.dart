import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_data.dart';
import '../../shell/tab_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final recent = AppData.posts.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              onBell: () {
                AppLogger.navigation('home', 'notifications');
                context.push('/notifications');
              },
              onAvatar: () {
                AppLogger.navigation('home', 'profile');
                context.push('/profile');
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  _StatsGrid().animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Platforms',
                    action: 'Manage',
                    onAction: () {
                      AppLogger.navigation('home', 'platforms');
                      context.push('/platforms');
                    },
                  ),
                  const SizedBox(height: 12),
                  _PlatformsRow().animate().fadeIn(delay: 80.ms),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Recent Posts',
                    action: 'View all',
                    onAction: () {
                      AppLogger.event('home_view_posts');
                      context.read<TabCubit>().setTab(1);
                    },
                  ),
                  const SizedBox(height: 12),
                  ...recent.asMap().entries.map(
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
                    onCreate: () {
                      AppLogger.navigation('home', 'create');
                      context.push('/create');
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
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBell, required this.onAvatar});

  final VoidCallback onBell;
  final VoidCallback onAvatar;

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning 👋',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Alex Johnson',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onBell,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.gray700),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onAvatar,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: AppData.avatarUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.gray200),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.blue100,
                  child: const Icon(Icons.person, color: AppColors.primary),
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
  @override
  Widget build(BuildContext context) {
    const items = [
      _StatItem(label: 'Connected', value: '7', color: AppColors.primary, bg: AppColors.blue50),
      _StatItem(label: 'Scheduled', value: '12', color: AppColors.warning, bg: AppColors.amber50),
      _StatItem(label: 'Published', value: '48', color: AppColors.success, bg: AppColors.green50),
      _StatItem(label: 'Drafts', value: '5', color: AppColors.gray700, bg: AppColors.gray100),
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
  final VoidCallback onAction;

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
        GestureDetector(
          onTap: onAction,
          child: Text(
            action,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _PlatformsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final platforms = AppData.platforms.take(8).toList();
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: platforms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = platforms[i];
          return GestureDetector(
            onTap: () {
              AppLogger.navigation('home', 'platform_detail');
              context.push('/platforms/${p.id}');
            },
            child: PlatformIcon(id: p.id, size: 48),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: post.thumbnail != null
                ? CachedNetworkImage(
                    imageUrl: post.thumbnail!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(width: 56, height: 56, color: AppColors.gray100),
                    errorWidget: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.gray100,
                      child: const Icon(Icons.image_outlined, color: AppColors.gray400),
                    ),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    color: AppColors.gray100,
                    child: const Icon(Icons.image_outlined, color: AppColors.gray400),
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
                  style: const TextStyle(fontSize: 12, color: AppColors.gray500, height: 1.35),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...post.platforms.take(4).map(
                          (id) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: PlatformIcon(id: id, size: 18),
                          ),
                        ),
                    const Spacer(),
                    if (post.publishAt != null)
                      Text(
                        post.publishAt!,
                        style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

  final VoidCallback onCreate;
  final VoidCallback onCalendar;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    final actions = <({IconData icon, String label, Color color, Color bg, VoidCallback onTap})>[
      (icon: Icons.edit_outlined, label: 'New Post', color: AppColors.primary, bg: AppColors.blue50, onTap: onCreate),
      (icon: Icons.calendar_today_outlined, label: 'Calendar', color: AppColors.warning, bg: AppColors.amber50, onTap: onCalendar),
      (icon: Icons.bar_chart_rounded, label: 'Analytics', color: AppColors.purple, bg: AppColors.purple50, onTap: onAnalytics),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == actions.length - 1 ? 0 : 8),
              child: GestureDetector(
                onTap: actions[i].onTap,
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
                          color: actions[i].bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(actions[i].icon, size: 18, color: actions[i].color),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        actions[i].label,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
