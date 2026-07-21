import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/events/posts_refresh_bus.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/posts_repository.dart';

class PostDetailState extends Equatable {
  const PostDetailState({
    this.post,
    this.loading = true,
    this.deleting = false,
    this.publishing = false,
    this.deleted = false,
    this.justPublished = false,
    this.statusBecamePublished = false,
    this.error,
  });

  final PostModel? post;
  final bool loading;
  final bool deleting;
  final bool publishing;
  final bool deleted;
  final bool justPublished;
  final bool statusBecamePublished;
  final String? error;

  PostDetailState copyWith({
    PostModel? post,
    bool? loading,
    bool? deleting,
    bool? publishing,
    bool? deleted,
    bool? justPublished,
    bool? statusBecamePublished,
    String? error,
    bool clearError = false,
    bool clearJustPublished = false,
    bool clearStatusBecamePublished = false,
  }) =>
      PostDetailState(
        post: post ?? this.post,
        loading: loading ?? this.loading,
        deleting: deleting ?? this.deleting,
        publishing: publishing ?? this.publishing,
        deleted: deleted ?? this.deleted,
        justPublished: clearJustPublished
            ? false
            : (justPublished ?? this.justPublished),
        statusBecamePublished: clearStatusBecamePublished
            ? false
            : (statusBecamePublished ?? this.statusBecamePublished),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [
        post,
        loading,
        deleting,
        publishing,
        deleted,
        justPublished,
        statusBecamePublished,
        error,
      ];
}

class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit({
    required String postId,
    PostsRepository? repository,
  })  : _postId = postId,
        _repo = repository ?? PostsRepository(),
        super(const PostDetailState()) {
    load();
  }

  final String _postId;
  final PostsRepository _repo;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const _maxPollAttempts = 20; // ~40s at 2s interval

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollAttempts = 0;
  }

  void _maybeStartPolling(PostModel post) {
    if (post.status == PostStatus.publishing) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    if (_pollTimer != null) return;
    _pollAttempts = 0;
    AppLogger.d('Post detail: polling for Published status');
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    if (isClosed || _postId.isEmpty) {
      _stopPolling();
      return;
    }
    _pollAttempts++;
    if (_pollAttempts > _maxPollAttempts) {
      _stopPolling();
      return;
    }
    try {
      final post = await _repo.fetchPost(_postId);
      if (isClosed) return;
      final wasPublishing = state.post?.status == PostStatus.publishing;
      emit(
        state.copyWith(
          post: post,
          statusBecamePublished: wasPublishing &&
              post.status == PostStatus.published,
        ),
      );
      if (post.status == PostStatus.published ||
          post.status == PostStatus.failed) {
        _stopPolling();
        PostsRefreshBus.instance.ping();
      } else if (post.status != PostStatus.publishing) {
        _stopPolling();
      }
    } catch (e) {
      AppLogger.d('Post status poll failed: $e');
    }
  }

  Future<void> load() async {
    if (isClosed) return;
    if (_postId.isEmpty) {
      emit(state.copyWith(loading: false, error: 'Post not found.'));
      return;
    }
    emit(
      state.copyWith(
        loading: true,
        clearError: true,
        clearJustPublished: true,
        clearStatusBecamePublished: true,
      ),
    );
    try {
      final post = await _repo.fetchPost(_postId);
      if (isClosed) return;
      emit(state.copyWith(post: post, loading: false));
      _maybeStartPolling(post);
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, error: e.message));
    } catch (e, st) {
      AppLogger.e('Post detail failed', e, st);
      if (!isClosed) {
        emit(state.copyWith(loading: false, error: 'Could not load post.'));
      }
    }
  }

  Future<bool> publishDraft() async {
    if (isClosed || state.publishing || state.deleting || _postId.isEmpty) {
      return false;
    }
    final current = state.post;
    if (current == null || current.status != PostStatus.draft) return false;

    emit(
      state.copyWith(
        publishing: true,
        clearError: true,
        clearJustPublished: true,
        clearStatusBecamePublished: true,
      ),
    );
    try {
      final updated = await _repo.publishPost(_postId);
      if (isClosed) return false;
      PostsRefreshBus.instance.ping();

      PostModel? refreshed;
      try {
        refreshed = await _repo.fetchPost(_postId);
      } catch (_) {}
      if (isClosed) return false;

      final next = refreshed ??
          updated ??
          PostModel(
            id: current.id,
            title: current.title,
            caption: current.caption,
            platforms: current.platforms,
            status: PostStatus.publishing,
            publishAt: current.publishAt,
            thumbnail: current.thumbnail,
            scheduledDate: current.scheduledDate,
          );

      emit(
        state.copyWith(
          publishing: false,
          justPublished: true,
          post: next,
          statusBecamePublished: next.status == PostStatus.published,
        ),
      );
      _maybeStartPolling(next);
      return true;
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(publishing: false, error: e.message));
      }
      return false;
    } catch (e, st) {
      AppLogger.e('Post publish failed', e, st);
      if (!isClosed) {
        emit(state.copyWith(publishing: false, error: 'Could not publish post.'));
      }
      return false;
    }
  }

  Future<bool> deletePost() async {
    if (isClosed || state.deleting || state.publishing || _postId.isEmpty) {
      return false;
    }
    _stopPolling();
    emit(state.copyWith(deleting: true, clearError: true));
    try {
      await _repo.deletePost(_postId);
      if (isClosed) return false;
      PostsRefreshBus.instance.ping();
      emit(state.copyWith(deleting: false, deleted: true));
      return true;
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(deleting: false, error: e.message));
      }
      return false;
    } catch (e, st) {
      AppLogger.e('Post delete failed', e, st);
      if (!isClosed) {
        emit(state.copyWith(deleting: false, error: 'Could not delete post.'));
      }
      return false;
    }
  }
}
