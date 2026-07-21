import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/oauth/oauth_launcher.dart';
import '../../../data/models/api_models.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_data.dart';
import '../../../data/repositories/social_repository.dart';

class PlatformsState extends Equatable {
  const PlatformsState({
    this.platforms = const [],
    this.connectedIds = const {},
    this.connectedAccounts = const [],
    this.disconnectedAccounts = const [],
    this.activeCount = 0,
    this.disconnectedCount = 0,
    this.totalAccounts = 0,
    this.loading = false,
    this.busyPlatformId,
    this.busyAccountId,
    this.error,
    this.usedFallback = false,
  });

  final List<PlatformModel> platforms;
  final Set<String> connectedIds;
  final List<SocialAccount> connectedAccounts;
  final List<SocialAccount> disconnectedAccounts;
  final int activeCount;
  final int disconnectedCount;
  final int totalAccounts;
  final bool loading;
  final String? busyPlatformId;
  final String? busyAccountId;
  final String? error;
  final bool usedFallback;

  PlatformsState copyWith({
    List<PlatformModel>? platforms,
    Set<String>? connectedIds,
    List<SocialAccount>? connectedAccounts,
    List<SocialAccount>? disconnectedAccounts,
    int? activeCount,
    int? disconnectedCount,
    int? totalAccounts,
    bool? loading,
    String? busyPlatformId,
    String? busyAccountId,
    String? error,
    bool? usedFallback,
    bool clearBusy = false,
    bool clearError = false,
  }) =>
      PlatformsState(
        platforms: platforms ?? this.platforms,
        connectedIds: connectedIds ?? this.connectedIds,
        connectedAccounts: connectedAccounts ?? this.connectedAccounts,
        disconnectedAccounts: disconnectedAccounts ?? this.disconnectedAccounts,
        activeCount: activeCount ?? this.activeCount,
        disconnectedCount: disconnectedCount ?? this.disconnectedCount,
        totalAccounts: totalAccounts ?? this.totalAccounts,
        loading: loading ?? this.loading,
        busyPlatformId: clearBusy ? null : (busyPlatformId ?? this.busyPlatformId),
        busyAccountId: clearBusy ? null : (busyAccountId ?? this.busyAccountId),
        error: clearError ? null : (error ?? this.error),
        usedFallback: usedFallback ?? this.usedFallback,
      );

  @override
  List<Object?> get props => [
        platforms,
        connectedIds,
        connectedAccounts,
        disconnectedAccounts,
        activeCount,
        disconnectedCount,
        totalAccounts,
        loading,
        busyPlatformId,
        busyAccountId,
        error,
        usedFallback,
      ];
}

class PlatformsCubit extends Cubit<PlatformsState> {
  PlatformsCubit({SocialRepository? repository})
      : _repo = repository ?? SocialRepository(),
        super(
          PlatformsState(
            platforms: AppData.platforms,
            connectedIds: const {},
            loading: true,
          ),
        ) {
    load();
  }

  final SocialRepository _repo;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final result = await _repo.fetchSocialAccountsResult();
      if (isClosed) return;
      emit(
        state.copyWith(
          platforms: _repo.mergePlatforms(result.connected),
          connectedIds: _repo.connectedPlatformIds(result.connected),
          connectedAccounts: result.connected,
          disconnectedAccounts: result.disconnected,
          activeCount: result.activeCount,
          disconnectedCount: result.disconnectedCount,
          totalAccounts: result.total,
          loading: false,
          usedFallback: false,
        ),
      );
    } on ApiException catch (e) {
      AppLogger.w('Social accounts API failed', e);
      if (!isClosed) {
        emit(
          state.copyWith(
            platforms: AppData.platforms,
            connectedIds: const {},
            connectedAccounts: const [],
            disconnectedAccounts: const [],
            activeCount: 0,
            disconnectedCount: 0,
            totalAccounts: 0,
            loading: false,
            usedFallback: false,
            error: e.message,
          ),
        );
      }
    } catch (e, st) {
      AppLogger.e('Platforms load failed', e, st);
      if (!isClosed) {
        emit(
          state.copyWith(
            platforms: AppData.platforms,
            connectedIds: const {},
            connectedAccounts: const [],
            disconnectedAccounts: const [],
            loading: false,
            usedFallback: false,
            error: 'Could not load connected platforms.',
          ),
        );
      }
    }
  }

  Future<void> toggleConnect(String id) async {
    if (state.busyPlatformId != null || state.busyAccountId != null || isClosed) {
      return;
    }
    emit(state.copyWith(busyPlatformId: id, clearError: true));

    final connected = state.connectedIds.contains(id);
    try {
      if (connected) {
        await _repo.disconnect(id);
        AppLogger.event('platform_disconnect', {'id': id});
      } else {
        final url = await _repo.fetchOAuthConnectUrl(id);
        if (isClosed) return;
        AppLogger.event('platform_connect', {'id': id, 'url': url});
        final platformName =
            state.platforms.where((p) => p.id == id).map((p) => p.name).firstOrNull ?? id;
        await OAuthLauncher.open(
          url: url,
          title: 'Connect $platformName',
        );
      }
      if (isClosed) return;
      await load();
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(error: e.message, clearBusy: true));
    } catch (e, st) {
      AppLogger.e('Platform connect/disconnect failed', e, st);
      if (!isClosed) {
        emit(
          state.copyWith(
            error: connected ? 'Disconnect failed.' : 'Connect failed.',
            clearBusy: true,
          ),
        );
      }
    }
    if (!isClosed) emit(state.copyWith(clearBusy: true));
  }
}
