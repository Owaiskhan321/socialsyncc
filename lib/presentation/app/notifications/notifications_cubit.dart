import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_data.dart';

class NotificationsState extends Equatable {
  const NotificationsState({this.items = const []});

  final List<NotificationModel> items;

  int get unreadCount => items.where((n) => !n.read).length;

  @override
  List<Object?> get props => [items];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(NotificationsState(items: List.from(AppData.notifications)));

  void markAllRead() {
    AppLogger.event('notifications_mark_all_read');
    emit(NotificationsState(items: state.items.map((n) => n.copyWith(read: true)).toList()));
  }

  void markRead(String id) {
    emit(
      NotificationsState(
        items: state.items
            .map((n) => n.id == id ? n.copyWith(read: true) : n)
            .toList(),
      ),
    );
  }
}
