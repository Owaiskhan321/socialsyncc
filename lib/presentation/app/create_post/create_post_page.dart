import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../data/repositories/app_data.dart';
import 'create_post_cubit.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  static const _steps = ['Write', 'Platforms', 'Schedule', 'Preview'];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreatePostCubit(),
      child: const _CreatePostView(),
    );
  }
}

class _CreatePostView extends StatelessWidget {
  const _CreatePostView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final cubit = context.read<CreatePostCubit>();
                      if (cubit.state.step > 0) {
                        cubit.back();
                      } else {
                        context.pop();
                      }
                    },
                    icon: const Icon(Icons.close, color: AppColors.gray700),
                  ),
                  const Expanded(
                    child: Text(
                      'New Post',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            BlocBuilder<CreatePostCubit, CreatePostState>(
              buildWhen: (a, b) => a.step != b.step,
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Row(
                    children: List.generate(CreatePostPage._steps.length, (i) {
                      final active = i <= state.step;
                      final current = i == state.step;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == 3 ? 0 : 6),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: active ? AppColors.primary : AppColors.gray200,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CreatePostPage._steps[i],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                                  color: active ? AppColors.primary : AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<CreatePostCubit, CreatePostState>(
                builder: (context, state) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(state.step),
                      child: switch (state.step) {
                        0 => const _WriteStep(),
                        1 => const _PlatformsStep(),
                        2 => const _ScheduleStep(),
                        _ => const _PreviewStep(),
                      }.animate().fadeIn(duration: 220.ms),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.gray100)),
              ),
              child: BlocBuilder<CreatePostCubit, CreatePostState>(
                builder: (context, state) {
                  final isLast = state.step == 3;
                  return AppButton(
                    label: isLast ? 'Publish' : 'Next',
                    onPressed: state.canNext || isLast
                        ? () {
                            if (isLast) {
                              AppLogger.event('create_publish');
                              AppLogger.navigation('create', 'home');
                              context.go('/home');
                            } else {
                              context.read<CreatePostCubit>().next();
                            }
                          }
                        : null,
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

class _WriteStep extends StatefulWidget {
  const _WriteStep();

  @override
  State<_WriteStep> createState() => _WriteStepState();
}

class _WriteStepState extends State<_WriteStep> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _captionCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<CreatePostCubit>().state;
    _titleCtrl = TextEditingController(text: s.title);
    _captionCtrl = TextEditingController(text: s.caption);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'What do you want to share?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Write your caption and add media for this post.',
          style: TextStyle(fontSize: 13, color: AppColors.gray500),
        ),
        const SizedBox(height: 20),
        const Text(
          'Title',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _titleCtrl,
          onChanged: context.read<CreatePostCubit>().setTitle,
          style: const TextStyle(fontSize: 14, color: AppColors.gray900),
          decoration: _fieldDecoration('Post title'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Caption',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _captionCtrl,
          onChanged: context.read<CreatePostCubit>().setCaption,
          maxLines: 6,
          style: const TextStyle(fontSize: 14, color: AppColors.gray900, height: 1.45),
          decoration: _fieldDecoration('Write your caption...'),
        ),
        const SizedBox(height: 16),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray200),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, size: 28, color: AppColors.gray400),
              SizedBox(height: 8),
              Text(
                'Upload media',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700),
              ),
              SizedBox(height: 4),
              Text(
                'PNG, JPG or MP4 up to 50MB',
                style: TextStyle(fontSize: 12, color: AppColors.gray400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.gray50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _PlatformsStep extends StatelessWidget {
  const _PlatformsStep();

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<CreatePostCubit>().state.selectedPlatforms;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'Choose platforms',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select where this post should be published.',
          style: TextStyle(fontSize: 13, color: AppColors.gray500),
        ),
        const SizedBox(height: 16),
        ...AppData.platforms.map((p) {
          final isOn = selected.contains(p.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => context.read<CreatePostCubit>().togglePlatform(p.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isOn ? AppColors.blue50 : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOn ? AppColors.primary : AppColors.gray200,
                    width: isOn ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    PlatformIcon(id: p.id, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.accounts.length} account${p.accounts.length == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isOn ? Icons.check_circle : Icons.circle_outlined,
                      color: isOn ? AppColors.primary : AppColors.gray300,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ScheduleStep extends StatelessWidget {
  const _ScheduleStep();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CreatePostCubit>().state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'When to publish?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Post now or schedule for later.',
          style: TextStyle(fontSize: 13, color: AppColors.gray500),
        ),
        const SizedBox(height: 16),
        _ScheduleOption(
          title: 'Publish now',
          subtitle: 'Go live immediately after review',
          selected: state.scheduleNow,
          onTap: () => context.read<CreatePostCubit>().setScheduleNow(true),
        ),
        const SizedBox(height: 10),
        _ScheduleOption(
          title: 'Schedule for later',
          subtitle: 'Pick a date and time',
          selected: !state.scheduleNow,
          onTap: () => context.read<CreatePostCubit>().setScheduleNow(false),
        ),
        if (!state.scheduleNow) ...[
          const SizedBox(height: 20),
          const Text(
            'Date',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray500),
          ),
          const SizedBox(height: 6),
          _PickerField(
            icon: Icons.calendar_today_outlined,
            value: state.scheduleDate,
            onTap: () {},
          ),
          const SizedBox(height: 14),
          const Text(
            'Time',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray500),
          ),
          const SizedBox(height: 6),
          _PickerField(
            icon: Icons.access_time,
            value: state.scheduleTime,
            onTap: () {},
          ),
        ],
      ],
    );
  }
}

class _ScheduleOption extends StatelessWidget {
  const _ScheduleOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue50 : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.gray200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.gray300,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.icon, required this.value, required this.onTap});

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.gray400),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray900),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CreatePostCubit>().state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'Preview & publish',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Review how your post will look before publishing.',
          style: TextStyle(fontSize: 13, color: AppColors.gray500),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gray200),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl: AppData.previewImageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 180, color: AppColors.gray100),
                errorWidget: (_, __, ___) => Container(height: 180, color: AppColors.gray100),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.title.isEmpty ? 'Untitled post' : state.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.caption.isEmpty ? 'No caption yet.' : state.caption,
                      style: const TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        ...state.selectedPlatforms.map(
                          (id) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: PlatformIcon(id: id, size: 24),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          state.scheduleNow
                              ? 'Publish now'
                              : '${state.scheduleDate} · ${state.scheduleTime}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
