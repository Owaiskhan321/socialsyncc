import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/models.dart';
import 'posts_cubit.dart';

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PostsCubit(),
      child: const _PostsView(),
    );
  }
}

class _PostsView extends StatelessWidget {
  const _PostsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: AppColors.gray100)),
              ),
              child: const Text(
                'Posts',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                onChanged: context.read<PostsCubit>().setQuery,
                style: const TextStyle(fontSize: 14, color: AppColors.gray900),
                decoration: InputDecoration(
                  hintText: 'Search posts...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.gray400),
                  filled: true,
                  fillColor: AppColors.gray50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                ),
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: BlocBuilder<PostsCubit, PostsState>(
                buildWhen: (a, b) => a.filter != b.filter,
                builder: (context, state) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: PostsFilter.values.map((f) {
                        final selected = state.filter == f;
                        final label = switch (f) {
                          PostsFilter.all => 'All',
                          PostsFilter.scheduled => 'Scheduled',
                          PostsFilter.published => 'Published',
                          PostsFilter.draft => 'Draft',
                          PostsFilter.failed => 'Failed',
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => context.read<PostsCubit>().setFilter(f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primary : AppColors.gray50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? AppColors.primary : AppColors.gray200,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? AppColors.white : AppColors.gray500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<PostsCubit, PostsState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<PostsCubit>().load(refresh: true),
                    child: state.posts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'No posts found',
                                  style: TextStyle(
                                    color: AppColors.gray400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                            itemCount: state.posts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              return _PostListCard(post: state.posts[i])
                                  .animate()
                                  .fadeIn(delay: (40 * i).ms)
                                  .slideY(begin: 0.06, end: 0);
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

class _PostListCard extends StatelessWidget {
  const _PostListCard({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: post.id.isEmpty
          ? null
          : () => context.push('/posts/${post.id}'),
      child: Container(
      padding: const EdgeInsets.all(14),
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
                child: post.thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: post.thumbnail!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(width: 64, height: 64, color: AppColors.gray100),
                        errorWidget: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.gray100,
                          child: const Icon(Icons.image_outlined, color: AppColors.gray400),
                        ),
                      )
                    : Container(
                        width: 64,
                        height: 64,
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
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        StatusBadge(status: post.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.gray500, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...post.platforms.map(
                (id) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: PlatformIcon(id: id, size: 22),
                ),
              ),
              const Spacer(),
              if (post.publishAt != null)
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.gray400),
                    const SizedBox(width: 4),
                    Text(
                      post.publishAt!,
                      style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
