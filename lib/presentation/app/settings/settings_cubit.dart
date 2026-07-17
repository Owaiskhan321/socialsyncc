import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.pushNotifications = true,
    this.emailDigest = true,
    this.failureAlerts = true,
    this.darkMode = false,
    this.autoSchedule = true,
  });

  final bool pushNotifications;
  final bool emailDigest;
  final bool failureAlerts;
  final bool darkMode;
  final bool autoSchedule;

  SettingsState copyWith({
    bool? pushNotifications,
    bool? emailDigest,
    bool? failureAlerts,
    bool? darkMode,
    bool? autoSchedule,
  }) =>
      SettingsState(
        pushNotifications: pushNotifications ?? this.pushNotifications,
        emailDigest: emailDigest ?? this.emailDigest,
        failureAlerts: failureAlerts ?? this.failureAlerts,
        darkMode: darkMode ?? this.darkMode,
        autoSchedule: autoSchedule ?? this.autoSchedule,
      );

  @override
  List<Object?> get props => [
        pushNotifications,
        emailDigest,
        failureAlerts,
        darkMode,
        autoSchedule,
      ];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void togglePush(bool v) {
    AppLogger.event('settings_push', {'value': v});
    emit(state.copyWith(pushNotifications: v));
  }

  void toggleEmail(bool v) => emit(state.copyWith(emailDigest: v));
  void toggleFailures(bool v) => emit(state.copyWith(failureAlerts: v));
  void toggleDark(bool v) => emit(state.copyWith(darkMode: v));
  void toggleAutoSchedule(bool v) => emit(state.copyWith(autoSchedule: v));
}
