import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/events/post_status_bus.dart';
import '../../../core/events/posts_refresh_bus.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/posts_repository.dart';

enum PostsFilter { all, scheduled, published, draft, failed }

class PostsState extends Equatable {
  const PostsState({
    this.filter = PostsFilter.all,
    this.query = '',
    this.posts = const [],
    this.loading = false,
    this.refreshing = false,
    this.usedFallback = false,
    this.error,
  });

  final PostsFilter filter;
  final String query;
  final List<PostModel> posts;
  final bool loading;
  final bool refreshing;
  final bool usedFallback;
  final String? error;

  PostsState copyWith({
    PostsFilter? filter,
    String? query,
    List<PostModel>? posts,
    bool? loading,
    bool? refreshing,
    bool? usedFallback,
    String? error,
    bool clearError = false,
  }) =>
      PostsState(
        filter: filter ?? this.filter,
        query: query ?? this.query,
        posts: posts ?? this.posts,
        loading: loading ?? this.loading,
        refreshing: refreshing ?? this.refreshing,
        usedFallback: usedFallback ?? this.usedFallback,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props =>
      [filter, query, posts, loading, refreshing, usedFallback, error];
}

class PostsCubit extends Cubit<PostsState> {
  PostsCubit({PostsRepository? repository})
      : _repo = repository ?? PostsRepository(),
        super(const PostsState()) {
    load();
    _refreshSub =
        PostsRefreshBus.instance.stream.listen((_) => refreshSilently());
    _statusSub = PostStatusBus.instance.stream.listen(_onPostStatus);
  }

  final PostsRepository _repo;
  List<PostModel> _source = [];
  StreamSubscription<void>? _refreshSub;
  StreamSubscription<PostStatusUpdate>? _statusSub;

  @override
  Future<void> close() {
    _refreshSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }

  void _onPostStatus(PostStatusUpdate update) {
    if (isClosed || update.status == null) return;
    final i = _source.indexWhere((p) => p.id == update.postId);
    if (i < 0) return;
    if (_source[i].status == update.status) return;
    _source[i] = _source[i].copyWith(status: update.status);
    _apply();
  }

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(refreshing: true, clearError: true));
    } else {
      emit(state.copyWith(loading: true, clearError: true));
    }

    try {
      _source = await _repo.fetchPosts();
      emit(
        state.copyWith(
          loading: false,
          refreshing: false,
          usedFallback: false,
          clearError: true,
        ),
      );
      _apply();
    } on ApiException catch (e) {
      AppLogger.w('Posts API failed', e);
      _source = [];
      emit(
        state.copyWith(
          loading: false,
          refreshing: false,
          usedFallback: false,
          error: e.message,
        ),
      );
      _apply();
    } catch (e, st) {
      AppLogger.e('Posts load failed', e, st);
      _source = [];
      emit(
        state.copyWith(
          loading: false,
          refreshing: false,
          usedFallback: false,
          error: 'Could not load posts.',
        ),
      );
      _apply();
    }
  }

  Future<void> refreshSilently() async {
    try {
      _source = await _repo.fetchPosts();
      if (isClosed) return;
      _apply();
    } catch (e) {
      AppLogger.d('Posts silent refresh: $e');
    }
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
    var list = List<PostModel>.from(_source);
    list = switch (state.filter) {
      PostsFilter.all => list,
      PostsFilter.scheduled => list
          .where(
            (p) =>
                p.status == PostStatus.scheduled ||
                p.status == PostStatus.publishing,
          )
          .toList(),
      PostsFilter.published => list
          .where(
            (p) =>
                p.status == PostStatus.published ||
                p.status == PostStatus.partial,
          )
          .toList(),
      PostsFilter.draft =>
        list.where((p) => p.status == PostStatus.draft).toList(),
      PostsFilter.failed => list
          .where(
            (p) =>
                p.status == PostStatus.failed ||
                p.status == PostStatus.partial,
          )
          .toList(),
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
