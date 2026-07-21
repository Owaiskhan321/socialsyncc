import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/events/posts_refresh_bus.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/services/live_data_helpers.dart';

class CalendarState extends Equatable {
  CalendarState({
    int? year,
    int? month,
    int? selectedDay,
    this.posts = const [],
    this.loading = false,
    this.error,
  })  : year = year ?? DateTime.now().year,
        month = month ?? DateTime.now().month,
        selectedDay = selectedDay ?? DateTime.now().day;

  final int year;
  final int month;
  final int selectedDay;
  final List<PostModel> posts;
  final bool loading;
  final String? error;

  Map<int, List<CalEvent>> get eventsByDay => calendarEventsForMonth(
        posts: posts,
        year: year,
        month: month,
      );

  List<CalEvent> get selectedEvents => eventsByDay[selectedDay] ?? const [];

  CalendarState copyWith({
    int? year,
    int? month,
    int? selectedDay,
    List<PostModel>? posts,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      CalendarState(
        year: year ?? this.year,
        month: month ?? this.month,
        selectedDay: selectedDay ?? this.selectedDay,
        posts: posts ?? this.posts,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [year, month, selectedDay, posts, loading, error];
}

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit({PostsRepository? repository})
      : _repo = repository ?? PostsRepository(),
        super(CalendarState()) {
    load();
    _refreshSub =
        PostsRefreshBus.instance.stream.listen((_) => refreshSilently());
  }

  final PostsRepository _repo;
  StreamSubscription<void>? _refreshSub;

  @override
  Future<void> close() {
    _refreshSub?.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final posts = await _repo.fetchPosts();
      emit(state.copyWith(posts: posts, loading: false));
    } on ApiException catch (e) {
      AppLogger.w('Calendar posts failed', e);
      emit(state.copyWith(loading: false, error: e.message, posts: const []));
    } catch (e, st) {
      AppLogger.e('Calendar load failed', e, st);
      emit(state.copyWith(loading: false, error: 'Could not load calendar.', posts: const []));
    }
  }

  Future<void> refreshSilently() async {
    try {
      final posts = await _repo.fetchPosts();
      if (isClosed) return;
      emit(state.copyWith(posts: posts));
    } catch (e) {
      AppLogger.d('Calendar silent refresh: $e');
    }
  }

  void selectDay(int day) {
    AppLogger.event('calendar_select', {'day': day});
    emit(state.copyWith(selectedDay: day));
  }

  void prevMonth() {
    var m = state.month - 1;
    var y = state.year;
    if (m < 1) {
      m = 12;
      y -= 1;
    }
    emit(state.copyWith(year: y, month: m, selectedDay: 1));
  }

  void nextMonth() {
    var m = state.month + 1;
    var y = state.year;
    if (m > 12) {
      m = 1;
      y += 1;
    }
    emit(state.copyWith(year: y, month: m, selectedDay: 1));
  }
}
