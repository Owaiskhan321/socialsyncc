import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_data.dart';

class CalendarState extends Equatable {
  const CalendarState({
    this.year = 2024,
    this.month = 1,
    this.selectedDay = 20,
  });

  final int year;
  final int month;
  final int selectedDay;

  List<CalEvent> get selectedEvents => AppData.calEvents[selectedDay] ?? const [];

  CalendarState copyWith({int? year, int? month, int? selectedDay}) => CalendarState(
        year: year ?? this.year,
        month: month ?? this.month,
        selectedDay: selectedDay ?? this.selectedDay,
      );

  @override
  List<Object?> get props => [year, month, selectedDay];
}

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit() : super(const CalendarState());

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
