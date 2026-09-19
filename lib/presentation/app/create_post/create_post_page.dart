import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_aspect_crop.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/local_video_preview.dart';
import '../../../core/widgets/media_fullscreen_viewer.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../core/widgets/resource_dropdown.dart';
import '../../../data/models/api_models.dart';
import '../../../data/repositories/app_data.dart';
import '../../../data/repositories/social_repository.dart';
import 'create_post_cubit.dart';
import 'image_crop_editor_page.dart';
import 'platform_post_preview.dart';

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
                  final submitLabel = state.postStatus.actionLabel;
                  final credits = state.selectedCreditsCost;
                  final creditsLabel = credits <= 0
                      ? 'Free to publish'
                      : '$credits credit${credits == 1 ? '' : 's'} required';
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.step == 1 &&
                          state.selectedPlatforms.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  creditsLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              Text(
                                '${state.selectedPlatforms.length} selected',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      AppButton(
                        label: isLast
                            ? (state.publishing ? 'Saving…' : submitLabel)
                            : 'Next',
                        loading: state.publishing,
                        onPressed: state.publishing
                            ? null
                            : (state.canNext || isLast)
                                ? () async {
                                    if (isLast) {
                                      AppLogger.event('create_publish', {
                                        'postStatus': state.postStatus.apiValue,
                                      });
                                      final ok = await context
                                          .read<CreatePostCubit>()
                                          .publish();
                                      if (!context.mounted) return;
                                      if (ok) {
                                        AppLogger.navigation('create', 'home');
                                        AppSnackBar.success(
                                          context,
                                          state.postStatus.successMessage,
                                        );
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go('/home');
                                        }
                                      } else {
                                        final err = context
                                            .read<CreatePostCubit>()
                                            .state
                                            .error;
                                        AppSnackBar.error(
                                          context,
                                          err ?? 'Publish failed',
                                        );
                                      }
                                    } else {
                                      context.read<CreatePostCubit>().next();
                                    }
                                  }
                                : null,
                      ),
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
    final cubit = context.watch<CreatePostCubit>();
    final media = cubit.state.mediaFiles;
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
        GestureDetector(
          onTap: () => _pickMedia(context),
          child: Container(
            height: media.isEmpty ? 140 : null,
            constraints: media.isEmpty ? null : const BoxConstraints(minHeight: 140),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: media.isEmpty
                ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_outlined, size: 28, color: AppColors.gray400),
                SizedBox(height: 8),
                Text(
                  'Upload media',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Up to 5 images or 1 video (30s) · max 90 MB',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
              ],
            )
                : Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < media.length; i++)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: cubit.isVideoFile(media[i])
                              ? () => openLocalMediaViewer(
                                    context,
                                    files: media,
                                    initialIndex: i,
                                    isVideo: true,
                                  )
                              : () => _openCropEditor(context, i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ColoredBox(
                              color: Colors.black,
                              child: cubit.isVideoFile(media[i])
                                  ? LocalVideoPreview(
                                file: media[i],
                                width: 72,
                                height: 72,
                                borderRadius: 12,
                                showControls: false,
                                fit: BoxFit.contain,
                              )
                                  : Image.file(
                                media[i],
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        if (!cubit.isVideoFile(media[i]))
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.gray900.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.crop_rounded,
                                size: 12,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () =>
                                context.read<CreatePostCubit>().removeMediaAt(i),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.gray900,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: AppColors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (media.length < CreatePostCubit.maxImages &&
                      !cubit.hasVideo)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray300),
                      ),
                      child: const Icon(Icons.add, color: AppColors.gray500),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (media.isNotEmpty && !cubit.hasVideo) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Aspect ratio',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '1:1 or 4:5 for all · tap photo to crop',
                  style: TextStyle(fontSize: 11, color: AppColors.gray400),
                ),
              ),
              if (cubit.state.mediaProcessing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final preset in MediaAspectRatioPreset.values) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _AspectRatioChip(
                      preset: preset,
                      selected: cubit.state.mediaAspectRatio == preset,
                      enabled: !cubit.state.mediaProcessing,
                      onTap: () => context
                          .read<CreatePostCubit>()
                          .setMediaAspectRatio(preset),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickMedia(BuildContext context) async {
    final cubit = context.read<CreatePostCubit>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photos (up to 5)'),
              onTap: () => Navigator.pop(ctx, 'images'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Video (max 30s · 90 MB)'),
              onTap: () => Navigator.pop(ctx, 'video'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    final picker = ImagePicker();
    if (choice == 'images') {
      final remaining = CreatePostCubit.maxImages - cubit.state.mediaFiles.length;
      if (remaining <= 0 || cubit.hasVideo) {
        AppSnackBar.error(
          context,
          cubit.hasVideo
              ? 'Remove the video first to add images.'
              : 'Maximum ${CreatePostCubit.maxImages} images allowed.',
        );
        return;
      }
      final picked = await picker.pickMultiImage(
        imageQuality: 85,
        limit: remaining,
      );
      if (picked.isEmpty || !context.mounted) return;
      final err = await cubit.addMediaFiles(
        picked.map((x) => File(x.path)).toList(),
      );
      if (err != null && context.mounted) AppSnackBar.error(context, err);
      return;
    }

    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: CreatePostCubit.maxVideoDuration,
    );
    if (video == null || !context.mounted) return;
    final err = await cubit.addMediaFiles([File(video.path)], asVideo: true);
    if (err != null && context.mounted) AppSnackBar.error(context, err);
  }

  Future<void> _openCropEditor(BuildContext context, int index) async {
    final cubit = context.read<CreatePostCubit>();
    if (cubit.state.mediaProcessing) return;

    final cropped = await openImageCropEditor(
      context,
      sourceFile: cubit.sourceFileForCropAt(index),
      aspectRatio: cubit.state.mediaAspectRatio.ratio,
      ratioLabel: cubit.state.mediaAspectRatio.label,
    );
    if (cropped != null && context.mounted) {
      cubit.updateMediaCropAt(index, cropped);
    }
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

class _AspectRatioChip extends StatelessWidget {
  const _AspectRatioChip({
    required this.preset,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final MediaAspectRatioPreset preset;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = preset.ratio;
    final frameW = ratio >= 1 ? 22.0 : 16.0;
    final frameH = (frameW / ratio).clamp(12.0, 26.0);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue50 : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.gray200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: frameW,
                height: frameH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.gray400,
                    width: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                preset.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primaryDark : AppColors.gray700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformsStep extends StatelessWidget {
  const _PlatformsStep();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CreatePostCubit>();
    final selected = cubit.state.selectedPlatforms;
    final platforms = cubit.state.availablePlatforms;
    final state = cubit.state;
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
        if (platforms.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: const Text(
              'No connected accounts yet. Connect a platform first to publish.',
              style: TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.4),
            ),
          )
        else
          ...platforms.map((p) {
            final isOn = selected.contains(p.id);
            final creditLabel =
                p.creditCost <= 0 ? 'Free' : '${p.creditCost} cr';
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
                              p.accounts.isEmpty
                                  ? 'Connected'
                                  : p.accounts.join(' · '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOn ? AppColors.white : AppColors.blue50,
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
                      const SizedBox(width: 8),
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
        if ((selected.contains('facebook') || selected.contains('instagram')) &&
            state.facebookPages.isNotEmpty) ...[
          const SizedBox(height: 12),
          ResourceDropdown(
            label: selected.contains('instagram') && !selected.contains('facebook')
                ? 'Meta page (for Instagram)'
                : 'Facebook page',
            platformId: 'facebook',
            items: state.facebookPages,
            selectedId: state.facebookPageId,
            onChanged: (id) =>
                context.read<CreatePostCubit>().setFacebookPageId(id),
          ),
        ],
        if (selected.contains('pinterest') &&
            state.pinterestBoards.isNotEmpty) ...[
          const SizedBox(height: 12),
          ResourceDropdown(
            label: 'Pinterest board',
            platformId: 'pinterest',
            items: state.pinterestBoards,
            selectedId: state.pinterestBoardId,
            onChanged: (id) =>
                context.read<CreatePostCubit>().setPinterestBoardId(id),
          ),
        ],
        if (selected.contains('youtube') &&
            state.youtubeChannels.isNotEmpty) ...[
          const SizedBox(height: 12),
          ResourceDropdown(
            label: 'YouTube channel',
            platformId: 'youtube',
            items: state.youtubeChannels,
            selectedId: state.youtubeChannelId,
            onChanged: (id) =>
                context.read<CreatePostCubit>().setYoutubeChannelId(id),
          ),
        ],
        if (selected.contains('google') && state.googleProfiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          ResourceDropdown(
            label: 'Google Business profile',
            platformId: 'google',
            items: state.googleProfiles,
            selectedId: state.googleBusinessProfileId,
            onChanged: (id) =>
                context.read<CreatePostCubit>().setGoogleBusinessProfileId(id),
          ),
        ],
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
          'Post status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose Draft, publish now, or schedule for later.',
          style: TextStyle(fontSize: 13, color: AppColors.gray500),
        ),
        const SizedBox(height: 16),
        _ScheduleOption(
          title: 'Draft',
          subtitle: 'Save without publishing',
          selected: state.postStatus == CreatePostStatus.draft,
          onTap: () => context
              .read<CreatePostCubit>()
              .setPostStatus(CreatePostStatus.draft),
        ),
        const SizedBox(height: 10),
        _ScheduleOption(
          title: 'Publishing',
          subtitle: 'Go live immediately after review',
          selected: state.postStatus == CreatePostStatus.publishing,
          onTap: () => context
              .read<CreatePostCubit>()
              .setPostStatus(CreatePostStatus.publishing),
        ),
        const SizedBox(height: 10),
        _ScheduleOption(
          title: 'Scheduled',
          subtitle: 'Pick a date and time',
          selected: state.postStatus == CreatePostStatus.scheduled,
          onTap: () => context
              .read<CreatePostCubit>()
              .setPostStatus(CreatePostStatus.scheduled),
        ),
        if (state.postStatus == CreatePostStatus.scheduled) ...[
          const SizedBox(height: 20),
          const Text(
            'Date',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray500),
          ),
          const SizedBox(height: 6),
          _PickerField(
            icon: Icons.calendar_today_outlined,
            value: state.scheduleDateLabel,
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: state.scheduledAt ?? now.add(const Duration(days: 1)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 365 * 2)),
              );
              if (picked != null && context.mounted) {
                final cur = state.scheduledAt ?? now;
                context.read<CreatePostCubit>().setScheduledAt(
                  DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    cur.hour,
                    cur.minute,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 14),
          const Text(
            'Time',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray500),
          ),
          const SizedBox(height: 6),
          _PickerField(
            icon: Icons.access_time,
            value: state.scheduleTimeLabel,
            onTap: () async {
              final cur = state.scheduledAt ?? DateTime.now();
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: cur.hour, minute: cur.minute),
              );
              if (picked != null && context.mounted) {
                context.read<CreatePostCubit>().setScheduledAt(
                  DateTime(
                    cur.year,
                    cur.month,
                    cur.day,
                    picked.hour,
                    picked.minute,
                  ),
                );
              }
            },
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
    final platforms = state.selectedPlatforms.toList();
    final scheduleLabel = switch (state.postStatus) {
      CreatePostStatus.draft => 'Draft',
      CreatePostStatus.publishing => 'Publish now',
      CreatePostStatus.scheduled =>
      '${state.scheduleDateLabel} · ${state.scheduleTimeLabel}',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'Preview & publish',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900),
        ),
        const SizedBox(height: 6),
        Text(
          platforms.isEmpty
              ? 'Select platforms to preview how each post will look.'
              : 'Each card mirrors that platform\'s real feed layout.',
          style: const TextStyle(fontSize: 13, color: AppColors.gray500),
        ),
        const SizedBox(height: 16),
        if (platforms.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: const Text(
              'No platforms selected yet. Go back and choose where to publish.',
              style: TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.4),
            ),
          )
        else
          ...platforms.map(
                (id) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PlatformPostPreviewCard(
                platformId: id,
                platformName: AppData.platformName(id),
                accountLabel: _accountLabelFor(state, id),
                accountHandle: _accountHandleFor(state, id),
                title: state.title,
                caption: state.caption,
                mediaFiles: state.mediaFiles,
                mediaIsVideo: state.mediaIsVideo,
                scheduleLabel: scheduleLabel,
              ),
            ),
          ),
      ],
    );
  }

  static String _accountLabelFor(CreatePostState state, String platformId) {
    String? nameFrom(List<NamedResource> resources, String? selectedId) {
      if (selectedId == null || selectedId.isEmpty) return null;
      for (final r in resources) {
        if (r.id == selectedId) return r.name;
      }
      return null;
    }

    final resourceName = switch (platformId) {
      'facebook' => nameFrom(state.facebookPages, state.facebookPageId),
      'instagram' =>
          nameFrom(state.instagramAccounts, state.instagramId) ??
              nameFrom(state.facebookPages, state.facebookPageId),
      'pinterest' => nameFrom(state.pinterestBoards, state.pinterestBoardId),
      'youtube' => nameFrom(state.youtubeChannels, state.youtubeChannelId),
      'google' =>
          nameFrom(state.googleProfiles, state.googleBusinessProfileId),
      _ => null,
    };
    if (resourceName != null && resourceName.isNotEmpty) return resourceName;

    for (final p in state.availablePlatforms) {
      if (p.id == platformId && p.accounts.isNotEmpty) {
        return p.accounts.first;
      }
    }

    final linked = SocialRepository()
        .accountsForPlatform(platformId, state.connectedAccounts);
    if (linked.isNotEmpty) return linked.first.previewLabel;

    return 'Your account';
  }

  static String _accountHandleFor(CreatePostState state, String platformId) {
    final linked = SocialRepository()
        .accountsForPlatform(platformId, state.connectedAccounts);
    if (linked.isNotEmpty) return linked.first.previewHandle;

    final label = _accountLabelFor(state, platformId);
    if (label == 'Your account') return 'account';
    return label.replaceFirst(RegExp(r'^@'), '');
  }
}