import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_data.dart';

enum PostsFilter { all, scheduled, published, draft, failed }

class PostsState extends Equatable {
  const PostsState({
    this.filter = PostsFilter.all,
    this.query = '',
    this.posts = const [],
  });

  final PostsFilter filter;
  final String query;
  final List<PostModel> posts;

  PostsState copyWith({
    PostsFilter? filter,
    String? query,
    List<PostModel>? posts,
  }) =>
      PostsState(
        filter: filter ?? this.filter,
        query: query ?? this.query,
        posts: posts ?? this.posts,
      );

  @override
  List<Object?> get props => [filter, query, posts];
}

class PostsCubit extends Cubit<PostsState> {
  PostsCubit() : super(const PostsState()) {
    _apply();
  }

  void setFilter(PostsFilter filter) {
    AppLogger.event('posts_filter', {'filter': filter.name});
    emit(state.copyWith(filter: filter));
    _apply();
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query));
    _apply();
  }

  void _apply() {
    var list = List<PostModel>.from(AppData.posts);
    list = switch (state.filter) {
      PostsFilter.all => list,
      PostsFilter.scheduled => list.where((p) => p.status == PostStatus.scheduled).toList(),
      PostsFilter.published => list.where((p) => p.status == PostStatus.published).toList(),
      PostsFilter.draft => list.where((p) => p.status == PostStatus.draft).toList(),
      PostsFilter.failed => list.where((p) => p.status == PostStatus.failed).toList(),
    };
    final q = state.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.title.toLowerCase().contains(q) ||
                p.caption.toLowerCase().contains(q),
          )
          .toList();
    }
    emit(state.copyWith(posts: list));
  }
}
