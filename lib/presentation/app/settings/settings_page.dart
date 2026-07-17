import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mobile_header.dart';
import 'settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            MobileHeader(
              title: 'Settings',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  final cubit = context.read<SettingsCubit>();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      _SectionLabel('Notifications')
                          .animate()
                          .fadeIn(),
                      _SettingsCard(
                        children: [
                          _ToggleRow(
                            title: 'Push notifications',
                            subtitle: 'Get alerts when posts go live',
                            value: state.pushNotifications,
                            onChanged: cubit.togglePush,
                          ),
                          const _Divider(),
                          _ToggleRow(
                            title: 'Email digest',
                            subtitle: 'Weekly performance summary',
                            value: state.emailDigest,
                            onChanged: cubit.toggleEmail,
                          ),
                          const _Divider(),
                          _ToggleRow(
                            title: 'Failure alerts',
                            subtitle: 'Notify when publishing fails',
                            value: state.failureAlerts,
                            onChanged: cubit.toggleFailures,
                          ),
                        ],
                      ).animate().fadeIn(delay: 60.ms),
                      const SizedBox(height: 20),
                      const _SectionLabel('Preferences'),
                      _SettingsCard(
                        children: [
                          _ToggleRow(
                            title: 'Dark mode',
                            subtitle: 'Coming soon',
                            value: state.darkMode,
                            onChanged: cubit.toggleDark,
                          ),
                          const _Divider(),
                          _ToggleRow(
                            title: 'Smart auto-schedule',
                            subtitle: 'Suggest best posting times',
                            value: state.autoSchedule,
                            onChanged: cubit.toggleAutoSchedule,
                          ),
                        ],
                      ).animate().fadeIn(delay: 120.ms),
                      const SizedBox(height: 20),
                      const _SectionLabel('Account'),
                      _SettingsCard(
                        children: [
                          _NavRow(title: 'Edit profile', onTap: () {}),
                          const _Divider(),
                          _NavRow(title: 'Change password', onTap: () {}),
                          const _Divider(),
                          _NavRow(title: 'Privacy policy', onTap: () {}),
                        ],
                      ).animate().fadeIn(delay: 180.ms),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.gray500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.gray100, indent: 14, endIndent: 14);
  }
}
