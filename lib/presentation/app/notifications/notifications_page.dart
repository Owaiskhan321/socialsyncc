import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mobile_header.dart';
import '../../../data/models/models.dart';
import 'notifications_cubit.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, state) {
                return MobileHeader(
                  title: 'Notifications',
                  onBack: () => context.pop(),
                  rightSlot: state.unreadCount > 0
                      ? GestureDetector(
                          onTap: context.read<NotificationsCubit>().markAllRead,
                          child: const Icon(Icons.done_all, size: 20, color: AppColors.primary),
                        )
                      : null,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.read<NotificationsCubit>().markAllRead(),
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.items.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => context.read<NotificationsCubit>().load(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(color: AppColors.gray400, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<NotificationsCubit>().load(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final n = state.items[i];
                        return _NotificationCard(
                          notification: n,
                          onTap: () => context.read<NotificationsCubit>().markRead(n.id),
                        ).animate().fadeIn(delay: (50 * i).ms).slideY(begin: 0.05, end: 0);
                      },
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  (IconData, Color, Color) get _style => switch (notification.type) {
        'success' => (Icons.check_circle_outline, AppColors.success, AppColors.green50),
        'failed' => (Icons.error_outline, AppColors.danger, AppColors.red50),
        'expired' => (Icons.link_off, AppColors.warning, AppColors.amber50),
        'billing' => (Icons.credit_card, AppColors.purple, AppColors.purple50),
        'clock' => (Icons.schedule, AppColors.primary, AppColors.blue50),
        _ => (Icons.notifications_outlined, AppColors.gray500, AppColors.gray100),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = _style;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.read ? AppColors.white : AppColors.blue50.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.read ? AppColors.gray100 : AppColors.blue100,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
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
                          notification.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray500, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.time,
                    style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontWeight: FontWeight.w500),
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
