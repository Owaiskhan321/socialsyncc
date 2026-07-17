import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_data.dart';

class PlatformsState extends Equatable {
  const PlatformsState({
    this.platforms = const [],
    this.connectedIds = const {},
  });

  final List<PlatformModel> platforms;
  final Set<String> connectedIds;

  PlatformsState copyWith({
    List<PlatformModel>? platforms,
    Set<String>? connectedIds,
  }) =>
      PlatformsState(
        platforms: platforms ?? this.platforms,
        connectedIds: connectedIds ?? this.connectedIds,
      );

  @override
  List<Object?> get props => [platforms, connectedIds];
}

class PlatformsCubit extends Cubit<PlatformsState> {
  PlatformsCubit()
      : super(
          PlatformsState(
            platforms: AppData.platforms,
            connectedIds: AppData.platforms.take(7).map((p) => p.id).toSet(),
          ),
        );

  void toggleConnect(String id) {
    final next = Set<String>.from(state.connectedIds);
    if (next.contains(id)) {
      next.remove(id);
      AppLogger.event('platform_disconnect', {'id': id});
    } else {
      next.add(id);
      AppLogger.event('platform_connect', {'id': id});
    }
    emit(state.copyWith(connectedIds: next));
  }
}
