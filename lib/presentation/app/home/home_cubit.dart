import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/events/posts_refresh_bus.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/session_storage.dart';
import '../../../data/models/api_models.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/live_data_helpers.dart';

class HomeState extends Equatable {
  const HomeState({
    this.loading = true,
    this.name = 'User',
    this.avatarUrl,
    this.greeting = 'Hello',
    this.connected = 0,
    this.scheduled = 0,
    this.published = 0,
    this.drafts = 0,
    this.platformIds = const [],
    this.recentPosts = const [],
    this.error,
  });

  final bool loading;
  final String name;
  final String? avatarUrl;
  final String greeting;
  final int connected;
  final int scheduled;
  final int published;
  final int drafts;
  final List<String> platformIds;
  final List<PostModel> recentPosts;
  final String? error;

  HomeState copyWith({
    bool? loading,
    String? name,
    String? avatarUrl,
    String? greeting,
    int? connected,
    int? scheduled,
    int? published,
    int? drafts,
    List<String>? platformIds,
    List<PostModel>? recentPosts,
    String? error,
    bool clearError = false,
  }) =>
      HomeState(
        loading: loading ?? this.loading,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        greeting: greeting ?? this.greeting,
        connected: connected ?? this.connected,
        scheduled: scheduled ?? this.scheduled,
        published: published ?? this.published,
        drafts: drafts ?? this.drafts,
        platformIds: platformIds ?? this.platformIds,
        recentPosts: recentPosts ?? this.recentPosts,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [
        loading,
        name,
        avatarUrl,
        greeting,
        connected,
        scheduled,
        published,
        drafts,
        platformIds,
        recentPosts,
        error,
      ];
}

class HomeCubit extends Cubit<HomeState> {
  final PostsRepository _postsRepo;
  final SocialRepository _socialRepo;
  final UserRepository _userRepo;
  StreamSubscription<void>? _postsRefreshSub;

  HomeCubit({
    PostsRepository? postsRepo,
    SocialRepository? socialRepo,
    UserRepository? userRepo,
  })  : _postsRepo = postsRepo ?? PostsRepository(),
        _socialRepo = socialRepo ?? SocialRepository(),
        _userRepo = userRepo ?? UserRepository(),
        super(HomeState(greeting: greetingForNow())) {
    load();
    _postsRefreshSub =
        PostsRefreshBus.instance.stream.listen((_) => refreshPostsSilently());
  }

  @override
  Future<void> close() {
    _postsRefreshSub?.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true, greeting: greetingForNow()));

    final cachedName = await SessionStorage.getName();
    if (cachedName != null && cachedName.isNotEmpty && !isClosed) {
      emit(state.copyWith(name: cachedName));
    }

    try {
      List<PostModel> posts = const [];
      List<SocialAccount> accounts = const [];
      try {
        posts = await _postsRepo.fetchPosts();
      } catch (e) {
        AppLogger.w('Home posts failed', e);
      }
      try {
        accounts = await _socialRepo.fetchSocialAccounts();
      } catch (e) {
        AppLogger.w('Home accounts failed', e);
      }

      String name = state.name;
      String? avatar;
      try {
        final profile = await _userRepo.fetchMe();
        name = profile.name;
        avatar = profile.avatarUrl;
        final token = await SessionStorage.getToken();
        if (token != null && token.isNotEmpty) {
          await SessionStorage.saveSession(
            token: token,
            name: profile.name,
            email: profile.email,
            userId: profile.id,
          );
        }
      } catch (e) {
        AppLogger.d('Home profile optional: $e');
      }

      final connectedIds = _socialRepo.connectedPlatformIds(accounts);
      final analytics = LiveAnalytics.fromPosts(posts);

      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          name: name,
          avatarUrl: avatar,
          connected: connectedIds.length,
          scheduled: analytics.scheduled,
          published: analytics.published,
          drafts: analytics.drafts,
          platformIds: connectedIds.isNotEmpty
              ? connectedIds.toList()
              : AppDataPlatformIds.all,
          recentPosts: posts.take(5).toList(),
          clearError: true,
        ),
      );
    } on ApiException catch (e) {
      AppLogger.w('Home live load failed', e);
      if (!isClosed) {
        emit(state.copyWith(loading: false, error: e.message, platformIds: AppDataPlatformIds.all));
      }
    } catch (e, st) {
      AppLogger.e('Home load failed', e, st);
      if (!isClosed) {
        emit(
          state.copyWith(
            loading: false,
            error: 'Could not load dashboard.',
            platformIds: AppDataPlatformIds.all,
          ),
        );
      }
    }
  }

  /// Background refresh of recent posts / counts (no loading spinner).
  Future<void> refreshPostsSilently() async {
    try {
      final posts = await _postsRepo.fetchPosts();
      if (isClosed) return;
      final analytics = LiveAnalytics.fromPosts(posts);
      emit(
        state.copyWith(
          scheduled: analytics.scheduled,
          published: analytics.published,
          drafts: analytics.drafts,
          recentPosts: posts.take(5).toList(),
        ),
      );
    } catch (e) {
      AppLogger.d('Home silent posts refresh: $e');
    }
  }
}

/// Static platform id list for empty-connected UI (icons only).
abstract final class AppDataPlatformIds {
  static const all = [
    'facebook',
    'instagram',
    'threads',
    'linkedin',
    // 'linkedin_organization',
    'tiktok',
    'x',
    'pinterest',
    'youtube',
    'google',
  ];
}
