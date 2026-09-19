import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/events/post_status_bus.dart';
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
    this.platforms = const [],
    this.recentPosts = const [],
    this.credits = 0,
    this.freeCredits = 0,
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
  final List<PlatformModel> platforms;
  final List<PostModel> recentPosts;
  final int credits;
  final int freeCredits;
  final String? error;

  int get totalCredits => credits + freeCredits;

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
    List<PlatformModel>? platforms,
    List<PostModel>? recentPosts,
    int? credits,
    int? freeCredits,
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
        platforms: platforms ?? this.platforms,
        recentPosts: recentPosts ?? this.recentPosts,
        credits: credits ?? this.credits,
        freeCredits: freeCredits ?? this.freeCredits,
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
        platforms,
        recentPosts,
        credits,
        freeCredits,
        error,
      ];
}

class HomeCubit extends Cubit<HomeState> {
  final PostsRepository _postsRepo;
  final SocialRepository _socialRepo;
  final UserRepository _userRepo;
  StreamSubscription<void>? _postsRefreshSub;
  StreamSubscription<PostStatusUpdate>? _statusSub;

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
    _statusSub = PostStatusBus.instance.stream.listen(_onPostStatus);
  }

  @override
  Future<void> close() {
    _postsRefreshSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }

  void _onPostStatus(PostStatusUpdate update) {
    if (isClosed || update.status == null) return;
    final recent = state.recentPosts;
    final i = recent.indexWhere((p) => p.id == update.postId);
    if (i >= 0 && recent[i].status != update.status) {
      final next = List<PostModel>.from(recent);
      next[i] = next[i].copyWith(status: update.status);
      emit(state.copyWith(recentPosts: next));
    }
    if (update.status == PostStatus.published ||
        update.status == PostStatus.partial ||
        update.status == PostStatus.failed) {
      unawaited(refreshPostsSilently());
    }
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true, greeting: greetingForNow()));

    final cachedName = await SessionStorage.getName();
    final cachedCredits = await SessionStorage.getCredits();
    final cachedFree = await SessionStorage.getFreeCredits();
    if (!isClosed) {
      emit(
        state.copyWith(
          name: (cachedName != null && cachedName.isNotEmpty)
              ? cachedName
              : state.name,
          credits: cachedCredits,
          freeCredits: cachedFree,
        ),
      );
    }

    try {
      List<PostModel> posts = const [];
      List<SocialAccount> accounts = const [];
      List<PlatformModel> catalog = const [];
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
      try {
        catalog = await _socialRepo.fetchPlatformCatalog();
      } catch (e) {
        AppLogger.w('Home platforms catalog failed', e);
      }

      String name = state.name;
      String? avatar;
      var credits = state.credits;
      var freeCredits = state.freeCredits;
      try {
        final profile = await _userRepo.fetchMe();
        name = profile.name;
        avatar = profile.avatarUrl;
        if (profile.wallet != null) {
          credits = profile.wallet!.credits;
          freeCredits = profile.wallet!.freeCredits;
        }
        final token = await SessionStorage.getToken();
        if (token != null && token.isNotEmpty) {
          await SessionStorage.saveSession(
            token: token,
            name: profile.name,
            email: profile.email,
            userId: profile.id,
            credits: credits,
            freeCredits: freeCredits,
          );
        }
      } catch (e) {
        AppLogger.d('Home profile optional: $e');
      }

      try {
        final wallet = await _userRepo.fetchWallet();
        credits = wallet.credits;
        freeCredits = wallet.freeCredits;
      } catch (e) {
        AppLogger.d('Home wallet optional: $e');
      }

      final connectedIds = _socialRepo.connectedPlatformIds(accounts);
      final analytics = LiveAnalytics.fromPosts(posts);
      final connectedPlatforms = catalog.isNotEmpty
          ? catalog
              .map(
                (p) => p.copyWith(
                  connected: p.connected || connectedIds.contains(p.id),
                  accounts: _socialRepo
                      .accountsForPlatform(p.id, accounts)
                      .map((a) => a.name)
                      .toList(),
                ),
              )
              .where((p) => connectedIds.contains(p.id) && !p.isComingSoon)
              .toList()
          : _socialRepo
              .mergePlatforms(accounts)
              .where((p) => p.accounts.isNotEmpty)
              .toList();
      final platformIds = connectedPlatforms.map((p) => p.id).toList();

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
          platformIds: platformIds,
          platforms: connectedPlatforms,
          recentPosts: posts.take(5).toList(),
          credits: credits,
          freeCredits: freeCredits,
          clearError: true,
        ),
      );
    } on ApiException catch (e) {
      AppLogger.w('Home live load failed', e);
      if (!isClosed) {
        emit(state.copyWith(loading: false, error: e.message, platformIds: const [], platforms: const []));
      }
    } catch (e, st) {
      AppLogger.e('Home load failed', e, st);
      if (!isClosed) {
        emit(
          state.copyWith(
            loading: false,
            error: 'Could not load dashboard.',
            platformIds: const [],
            platforms: const [],
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
