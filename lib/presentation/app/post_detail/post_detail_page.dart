import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/mobile_header.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_data.dart';
import 'post_detail_cubit.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PostDetailCubit(postId: postId),
      child: const _PostDetailView(),
    );
  }
}

class _PostDetailView extends StatelessWidget {
  const _PostDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostDetailCubit, PostDetailState>(
      listenWhen: (a, b) =>
          (a.error != b.error && b.error != null) ||
          (!a.deleted && b.deleted) ||
          (!a.justPublished && b.justPublished) ||
          (!a.statusBecamePublished && b.statusBecamePublished),
      listener: (context, state) {
        if (state.error != null) AppSnackBar.error(context, state.error!);
        if (state.statusBecamePublished) {
          AppSnackBar.success(context, 'Post published');
        } else if (state.justPublished) {
          AppSnackBar.success(context, 'Publishing…');
        }
        if (state.deleted) {
          AppSnackBar.success(context, 'Post deleted');
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go('/home');
          }
        }
      },
      builder: (context, state) {
        final post = state.post;
        return Scaffold(
          backgroundColor: AppColors.gray50,
          body: SafeArea(
            child: Column(
              children: [
                MobileHeader(
                  title: 'Post',
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : post == null
                          ? Center(
                              child: TextButton(
                                onPressed: () =>
                                    context.read<PostDetailCubit>().load(),
                                child: const Text('Retry'),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () =>
                                  context.read<PostDetailCubit>().load(),
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                                children: [
                                  if (post.thumbnail != null &&
                                      post.thumbnail!.startsWith('http'))
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: CachedNetworkImage(
                                        imageUrl: post.thumbnail!,
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          height: 220,
                                          color: AppColors.gray100,
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          height: 220,
                                          color: AppColors.gray100,
                                          child: const Icon(
                                            Icons.image_outlined,
                                            color: AppColors.gray400,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ).animate().fadeIn(),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.gray100),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                post.title,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.gray900,
                                                ),
                                              ),
                                            ),
                                            StatusBadge(status: post.status),
                                          ],
                                        ),
                                        if (post.publishAt != null) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.schedule,
                                                size: 14,
                                                color: AppColors.gray400,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                post.publishAt!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.gray500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 14),
                                        Text(
                                          post.caption.isEmpty
                                              ? 'No caption'
                                              : post.caption,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.45,
                                            color: post.caption.isEmpty
                                                ? AppColors.gray400
                                                : AppColors.gray800,
                                          ),
                                        ),
                                        if (post.platforms.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Platforms',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.gray700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: post.platforms
                                                .map(
                                                  (id) => Container(
                                                    padding: const EdgeInsets.fromLTRB(
                                                      8,
                                                      6,
                                                      12,
                                                      6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.gray50,
                                                      borderRadius:
                                                          BorderRadius.circular(20),
                                                      border: Border.all(
                                                        color: AppColors.gray200,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        PlatformIcon(id: id, size: 22),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          AppData.platformName(id),
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                            color: AppColors.gray800,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                        if (post.id.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            'ID: ${post.id}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.gray400,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ).animate().fadeIn(delay: 60.ms),
                                  const SizedBox(height: 24),
                                  if (post.status == PostStatus.draft) ...[
                                    AppButton(
                                      label: state.publishing
                                          ? 'Publishing…'
                                          : 'Publish now',
                                      loading: state.publishing,
                                      onPressed: state.publishing || state.deleting
                                          ? null
                                          : () => context
                                              .read<PostDetailCubit>()
                                              .publishDraft(),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  AppButton(
                                    label: state.deleting ? 'Deleting…' : 'Delete post',
                                    variant: AppBtnVariant.danger,
                                    loading: state.deleting,
                                    onPressed: state.deleting || state.publishing
                                        ? null
                                        : () => _confirmDelete(context),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This will permanently delete the post. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<PostDetailCubit>().deletePost();
    }
  }
}
