import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../data/models/models.dart';
import 'calendar_cubit.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalendarCubit(),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: AppColors.gray100)),
              ),
              child: const Text(
                'Calendar',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<CalendarCubit, CalendarState>(
                builder: (context, state) {
                  if (state.loading && state.posts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final events = state.selectedEvents;
                  final monthName = DateFormat.MMMM().format(DateTime(state.year, state.month));
                  return RefreshIndicator(
                    onRefresh: () => context.read<CalendarCubit>().load(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        const _MonthCard().animate().fadeIn(duration: 280.ms),
                        const SizedBox(height: 20),
                        Text(
                          '$monthName ${state.selectedDay}, ${state.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          events.isEmpty
                              ? 'No scheduled posts'
                              : '${events.length} scheduled post${events.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                        ),
                        const SizedBox(height: 12),
                        if (events.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.gray100),
                            ),
                            child: const Text(
                              'Nothing scheduled for this day.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.gray400),
                            ),
                          )
                        else
                          ...events.asMap().entries.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _EventCard(event: e.value)
                                      .animate()
                                      .fadeIn(delay: (60 * e.key).ms)
                                      .slideY(begin: 0.06, end: 0),
                                ),
                              ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        final first = DateTime(state.year, state.month, 1);
        final daysInMonth = DateTime(state.year, state.month + 1, 0).day;
        final startWeekday = first.weekday % 7;
        final monthLabel = DateFormat('MMMM yyyy').format(first);
        final totalCells = startWeekday + daysInMonth;
        final rows = (totalCells / 7).ceil();
        final eventsByDay = state.eventsByDay;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: context.read<CalendarCubit>().prevMonth,
                    icon: const Icon(Icons.chevron_left, color: AppColors.gray700),
                  ),
                  Expanded(
                    child: Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: context.read<CalendarCubit>().nextMonth,
                    icon: const Icon(Icons.chevron_right, color: AppColors.gray700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray400,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              ...List.generate(rows, (row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: List.generate(7, (col) {
                      final idx = row * 7 + col;
                      final day = idx - startWeekday + 1;
                      if (day < 1 || day > daysInMonth) {
                        return const Expanded(child: SizedBox(height: 40));
                      }
                      final selected = day == state.selectedDay;
                      final hasEvents = eventsByDay.containsKey(day);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => context.read<CalendarCubit>().selectDay(day),
                          child: Container(
                            height: 40,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? AppColors.white : AppColors.gray800,
                                  ),
                                ),
                                if (hasEvents)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: selected ? AppColors.white : AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CalEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...event.platforms.map(
                      (id) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: PlatformIcon(id: id, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      event.time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
