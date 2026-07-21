import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/services/live_data_helpers.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  final List<NotificationModel> items;
  final bool loading;
  final String? error;

  int get unreadCount => items.where((n) => !n.read).length;

  NotificationsState copyWith({
    List<NotificationModel>? items,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [items, loading, error];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({PostsRepository? repository})
      : _repo = repository ?? PostsRepository(),
        super(const NotificationsState(loading: true)) {
    load();
  }

  final PostsRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final posts = await _repo.fetchPosts();
      emit(
        state.copyWith(
          loading: false,
          items: notificationsFromPosts(posts),
        ),
      );
    } on ApiException catch (e) {
      AppLogger.w('Notifications from posts failed', e);
      emit(state.copyWith(loading: false, items: const [], error: e.message));
    } catch (e, st) {
      AppLogger.e('Notifications load failed', e, st);
      emit(state.copyWith(loading: false, items: const [], error: 'Could not load notifications.'));
    }
  }

  void markAllRead() {
    AppLogger.event('notifications_mark_all_read');
    emit(state.copyWith(items: state.items.map((n) => n.copyWith(read: true)).toList()));
  }

  void markRead(String id) {
    emit(
      state.copyWith(
        items: state.items.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
      ),
    );
  }
}
