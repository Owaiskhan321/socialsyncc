import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/oauth/oauth_launcher.dart';
import '../../../data/models/api_models.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_data.dart';
import '../../../data/repositories/integrations_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/social_repository.dart';

class PlatformDetailState extends Equatable {
  const PlatformDetailState({
    required this.platform,
    this.socialAccounts = const [],
    this.resources = const [],
    this.postCount = 0,
    this.connected = false,
    this.loading = true,
    this.busy = false,
    this.error,
  });

  final PlatformModel platform;
  final List<SocialAccount> socialAccounts;
  final List<NamedResource> resources;
  final int postCount;
  final bool connected;
  final bool loading;
  final bool busy;
  final String? error;

  PlatformDetailState copyWith({
    PlatformModel? platform,
    List<SocialAccount>? socialAccounts,
    List<NamedResource>? resources,
    int? postCount,
    bool? connected,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
  }) =>
      PlatformDetailState(
        platform: platform ?? this.platform,
        socialAccounts: socialAccounts ?? this.socialAccounts,
        resources: resources ?? this.resources,
        postCount: postCount ?? this.postCount,
        connected: connected ?? this.connected,
        loading: loading ?? this.loading,
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props =>
      [platform, socialAccounts, resources, postCount, connected, loading, busy, error];
}

class PlatformDetailCubit extends Cubit<PlatformDetailState> {
  PlatformDetailCubit({
    required String platformId,
    SocialRepository? socialRepo,
    IntegrationsRepository? integrationsRepo,
    PostsRepository? postsRepo,
  })  : _platformId = platformId,
        _socialRepo = socialRepo ?? SocialRepository(),
        _integrationsRepo = integrationsRepo ?? IntegrationsRepository(),
        _postsRepo = postsRepo ?? PostsRepository(),
        super(
          PlatformDetailState(
            platform: AppData.platformById(platformId) ??
                PlatformModel(
                  id: platformId,
                  name: platformId,
                  color: 0xFF64748B,
                  accounts: const [],
                ),
          ),
        ) {
    load();
  }

  final String _platformId;
  final SocialRepository _socialRepo;
  final IntegrationsRepository _integrationsRepo;
  final PostsRepository _postsRepo;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final social = await _socialRepo.fetchSocialAccounts();
      if (isClosed) return;
      final forPlatform = _socialRepo.accountsForPlatform(_platformId, social);

      List<NamedResource> resources = [];
      try {
        resources = switch (_platformId) {
          'facebook' => await _integrationsRepo.fetchFacebookPages(),
          'pinterest' => await _integrationsRepo.fetchPinterestBoards(),
          'youtube' => await _integrationsRepo.fetchYoutubeChannels(),
          'google' => await _integrationsRepo.fetchGoogleBusinessProfiles(),
          _ => const [],
        };
      } catch (e) {
        AppLogger.d('Platform resources unavailable: $e');
      }

      if (isClosed) return;

      var postCount = 0;
      try {
        final posts = await _postsRepo.fetchPosts();
        postCount = posts.where((p) => p.platforms.contains(_platformId)).length;
      } catch (_) {}

      if (isClosed) return;

      final base = AppData.platformById(_platformId) ?? state.platform;
      emit(
        state.copyWith(
          loading: false,
          platform: PlatformModel(
            id: base.id,
            name: base.name,
            color: base.color,
            accounts: forPlatform.map((a) => a.name).toList(),
          ),
          socialAccounts: forPlatform,
          resources: resources,
          postCount: postCount,
          connected: forPlatform.isNotEmpty,
        ),
      );
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, error: e.message));
    } catch (e, st) {
      AppLogger.e('Platform detail failed', e, st);
      if (!isClosed) {
        emit(state.copyWith(loading: false, error: 'Could not load platform details.'));
      }
    }
  }

  Future<void> connect() async {
    if (isClosed) return;
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final url = await _socialRepo.fetchOAuthConnectUrl(_platformId);
      if (isClosed) return;
      await OAuthLauncher.open(
        url: url,
        title: 'Connect ${state.platform.name}',
      );
      if (isClosed) return;
      await load();
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false, error: e.message));
    } catch (e, st) {
      AppLogger.e('Connect failed', e, st);
      if (!isClosed) emit(state.copyWith(busy: false, error: 'Connect failed.'));
    }
    if (!isClosed) emit(state.copyWith(busy: false));
  }

  Future<void> disconnect() async {
    if (isClosed) return;
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _socialRepo.disconnect(_platformId);
      if (isClosed) return;
      await load();
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false, error: e.message));
    } catch (e, st) {
      AppLogger.e('Disconnect failed', e, st);
      if (!isClosed) {
        emit(state.copyWith(busy: false, error: 'Disconnect failed.'));
      }
    }
    if (!isClosed) emit(state.copyWith(busy: false));
  }
}
