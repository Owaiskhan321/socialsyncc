import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';

class CreatePostState extends Equatable {
  const CreatePostState({
    this.step = 0,
    this.title = '',
    this.caption = '',
    this.selectedPlatforms = const {},
    this.scheduleNow = true,
    this.scheduleDate = 'Jan 22, 2024',
    this.scheduleTime = '10:00 AM',
  });

  final int step;
  final String title;
  final String caption;
  final Set<String> selectedPlatforms;
  final bool scheduleNow;
  final String scheduleDate;
  final String scheduleTime;

  CreatePostState copyWith({
    int? step,
    String? title,
    String? caption,
    Set<String>? selectedPlatforms,
    bool? scheduleNow,
    String? scheduleDate,
    String? scheduleTime,
  }) =>
      CreatePostState(
        step: step ?? this.step,
        title: title ?? this.title,
        caption: caption ?? this.caption,
        selectedPlatforms: selectedPlatforms ?? this.selectedPlatforms,
        scheduleNow: scheduleNow ?? this.scheduleNow,
        scheduleDate: scheduleDate ?? this.scheduleDate,
        scheduleTime: scheduleTime ?? this.scheduleTime,
      );

  bool get canNext => switch (step) {
        0 => title.trim().isNotEmpty && caption.trim().isNotEmpty,
        1 => selectedPlatforms.isNotEmpty,
        2 => true,
        _ => true,
      };

  @override
  List<Object?> get props => [
        step,
        title,
        caption,
        selectedPlatforms,
        scheduleNow,
        scheduleDate,
        scheduleTime,
      ];
}

class CreatePostCubit extends Cubit<CreatePostState> {
  CreatePostCubit() : super(const CreatePostState());

  void setTitle(String v) => emit(state.copyWith(title: v));
  void setCaption(String v) => emit(state.copyWith(caption: v));

  void togglePlatform(String id) {
    final next = Set<String>.from(state.selectedPlatforms);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    emit(state.copyWith(selectedPlatforms: next));
  }

  void setScheduleNow(bool v) => emit(state.copyWith(scheduleNow: v));
  void setScheduleDate(String v) => emit(state.copyWith(scheduleDate: v));
  void setScheduleTime(String v) => emit(state.copyWith(scheduleTime: v));

  void next() {
    if (!state.canNext || state.step >= 3) return;
    AppLogger.event('create_next', {'step': state.step + 1});
    emit(state.copyWith(step: state.step + 1));
  }

  void back() {
    if (state.step <= 0) return;
    emit(state.copyWith(step: state.step - 1));
  }

  void goToStep(int step) {
    if (step < 0 || step > 3) return;
    emit(state.copyWith(step: step));
  }
}
