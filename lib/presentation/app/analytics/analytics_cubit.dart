import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/services/live_data_helpers.dart';

class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.loading = true,
    this.rangeIndex = 1,
    this.analytics = const LiveAnalytics(
      published: 0,
      failed: 0,
      scheduled: 0,
      drafts: 0,
      trend: [],
      freq: [],
      pie: [],
    ),
    this.error,
  });

  final bool loading;
  final int rangeIndex;
  final LiveAnalytics analytics;
  final String? error;

  String get rangeQuery => switch (rangeIndex) {
        0 => '7d',
        2 => '90d',
        _ => '30d',
      };

  AnalyticsState copyWith({
    bool? loading,
    int? rangeIndex,
    LiveAnalytics? analytics,
    String? error,
    bool clearError = false,
  }) =>
      AnalyticsState(
        loading: loading ?? this.loading,
        rangeIndex: rangeIndex ?? this.rangeIndex,
        analytics: analytics ?? this.analytics,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [loading, rangeIndex, analytics, error];
}

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit({PostsRepository? repository})
      : _repo = repository ?? PostsRepository(),
        super(const AnalyticsState()) {
    load();
  }

  final PostsRepository _repo;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final analytics = await _repo.fetchAnalytics(range: state.rangeQuery);
      if (isClosed) return;
      emit(state.copyWith(loading: false, analytics: analytics));
    } on ApiException catch (e) {
      AppLogger.w('Analytics API failed, falling back to posts', e);
      try {
        final posts = await _repo.fetchPosts();
        if (isClosed) return;
        final days = switch (state.rangeIndex) {
          0 => 7,
          2 => 90,
          _ => 30,
        };
        emit(
          state.copyWith(
            loading: false,
            analytics: LiveAnalytics.fromPosts(posts, rangeDays: days),
            error: e.message,
          ),
        );
      } catch (_) {
        if (!isClosed) {
          emit(state.copyWith(loading: false, error: e.message));
        }
      }
    } catch (e, st) {
      AppLogger.e('Analytics failed', e, st);
      if (!isClosed) {
        emit(state.copyWith(loading: false, error: 'Could not load analytics.'));
      }
    }
  }

  Future<void> setRange(int index) async {
    if (state.rangeIndex == index) return;
    AppLogger.event('analytics_range', {'index': index, 'range': switch (index) {
      0 => '7d',
      2 => '90d',
      _ => '30d',
    }});
    emit(state.copyWith(rangeIndex: index));
    await load();
  }
}
