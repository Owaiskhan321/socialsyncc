import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/network/session_storage.dart';
import '../../../core/network/session_sync.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/mobile_header.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../navigation/app_launch_transition.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  String? _plan;
  int _credits = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await SessionStorage.getName();
    final email = await SessionStorage.getEmail();
    final credits = await SessionStorage.getTotalCredits();
    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _name = name;
        if (email != null) _email = email;
        _credits = credits;
      });
    }
    try {
      await syncUserProfileFromApi();
      final profile = await UserRepository().fetchMe();
      WalletInfo? wallet = profile.wallet;
      try {
        wallet = await UserRepository().fetchWallet();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _name = profile.name;
        _email = profile.email;
        _plan = (profile.plan != null && profile.plan!.trim().isNotEmpty)
            ? profile.plan!.trim()
            : null;
        if (wallet != null) _credits = wallet.totalCredits;
      });
    } catch (_) {}
  }

  Future<void> _showContactSheet() async {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final inquiryCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final repo = ContactRepository();

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Contact support',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                controller: inquiryCtrl,
                decoration: const InputDecoration(labelText: 'Inquiry type'),
              ),
              TextField(
                controller: messageCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  try {
                    final msg = await repo.submit(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      inquiry: inquiryCtrl.text.trim(),
                      message: messageCtrl.text.trim(),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      AppSnackBar.success(ctx, msg);
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      AppSnackBar.error(ctx, e.toString());
                    }
                  }
                },
                child: const Text('Send'),
              ),
            ],
          ),
        );
      },
    );
  }

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
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.blue100,
                            child: Text(
                              _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
                        const SizedBox(height: 14),
                        Text(
                          _name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
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
                              const SizedBox(width: 6),
                              Text(
                                '$_credits credits',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_plan != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _plan!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...menu.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (item.$2 == 'Help & Support') {
                              _showContactSheet();
                              return;
                            }
                            if (item.$2 == 'Sign Out') {
                              SessionStorage.clear();
                              appApiClient.setToken(null);
                              context.go('/welcome');
                              return;
                            }
                            AppLogger.navigation('profile', item.$3 ?? 'none');
                            if (item.$3 != null) {
                              context.pushFromSource(
                                item.$3!,
                                borderRadius: 14,
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Icon(item.$1, size: 20, color: AppColors.gray500),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.$2,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: item.$2 == 'Sign Out'
                                          ? AppColors.danger
                                          : AppColors.gray900,
                                    ),
                                  ),
                                ),
                                if (item.$2 != 'Sign Out')
                                  const Icon(Icons.chevron_right, color: AppColors.gray300),
                              ],
                            ),
                          ),
                        ),
                      ),
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
