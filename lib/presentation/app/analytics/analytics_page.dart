import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/services/live_data_helpers.dart';
import 'analytics_cubit.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnalyticsCubit(),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

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
              child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
                buildWhen: (a, b) => a.rangeIndex != b.rangeIndex,
                builder: (context, state) {
                  return Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Analytics',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      _RangePicker(
                        selected: state.rangeIndex,
                        onChanged: context.read<AnalyticsCubit>().setRange,
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final a = state.analytics;
                  return RefreshIndicator(
                    onRefresh: () => context.read<AnalyticsCubit>().load(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(state.error!, style: const TextStyle(color: AppColors.danger)),
                          ),
                        _StatRow(analytics: a).animate().fadeIn(duration: 280.ms),
                        const SizedBox(height: 16),
                        _ChartCard(
                          title: 'Publishing Trend',
                          subtitle: 'Published vs failed',
                          child: SizedBox(height: 200, child: _TrendChart(data: a.trend)),
                        ).animate().fadeIn(delay: 80.ms),
                        const SizedBox(height: 16),
                        _ChartCard(
                          title: 'Platform Mix',
                          subtitle: 'Share of posts by network',
                          child: SizedBox(height: 200, child: _PieChart(data: a.pie)),
                        ).animate().fadeIn(delay: 140.ms),
                        const SizedBox(height: 16),
                        _ChartCard(
                          title: 'Posting Frequency',
                          subtitle: 'Posts per weekday',
                          child: SizedBox(height: 200, child: _BarChart(data: a.freq)),
                        ).animate().fadeIn(delay: 200.ms),
                        if (a.timezone != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Timezone: ${a.timezone}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
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

class _RangePicker extends StatelessWidget {
  const _RangePicker({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['7d', '30d', '90d'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final on = selected == i;
          return GestureDetector(
            onTap: () {
              AppLogger.event('analytics_range', {'index': i});
              onChanged(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: on ? AppColors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: on
                    ? [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: on ? AppColors.gray900 : AppColors.gray500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.analytics});

  final LiveAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final change = analytics.totalPostsChangePercent;
    final changeLabel = change == 0
        ? null
        : change > 0
            ? '+$change%'
            : '$change%';

    final stats = [
      (
        'Total',
        '${analytics.totalPosts}',
        AppColors.gray800,
        AppColors.gray100,
        changeLabel,
      ),
      (
        'Published',
        '${analytics.published}',
        AppColors.success,
        AppColors.green50,
        analytics.publishedPercent > 0 ? '${analytics.publishedPercent}%' : null,
      ),
      (
        'Scheduled',
        '${analytics.scheduled}',
        AppColors.primary,
        AppColors.blue50,
        null,
      ),
      (
        'Failed',
        '${analytics.failed}',
        AppColors.danger,
        AppColors.red50,
        null,
      ),
    ];

    return Column(
      children: [
        Row(
          children: stats.take(2).map((s) => _statCard(s, isLast: s == stats[1])).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: stats.skip(2).map((s) => _statCard(s, isLast: s == stats.last)).toList(),
        ),
      ],
    );
  }

  Widget _statCard(
    (String, String, Color, Color, String?) s, {
    required bool isLast,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: isLast ? 0 : 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: s.$4,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.trending_up, size: 14, color: s.$3),
                  ),
                  if (s.$5 != null) ...[
                    const Spacer(),
                    Text(
                      s.$5!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: s.$3,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                s.$2,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              Text(
                s.$1,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.data});

  final List<TrendPoint> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data yet', style: TextStyle(color: AppColors.gray400)));
    }
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.gray100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: const TextStyle(fontSize: 10, color: AppColors.gray400),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[i].date,
                    style: const TextStyle(fontSize: 10, color: AppColors.gray400),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].pub)],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          LineChartBarData(
            spots: [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].fail)],
            isCurved: true,
            color: AppColors.danger,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  const _PieChart({required this.data});

  final List<PieSlice> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No platform data yet', style: TextStyle(color: AppColors.gray400)));
    }
    final total = data.fold<double>(0, (s, e) => s + e.value);
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: data
                  .map(
                    (s) => PieChartSectionData(
                      value: s.value,
                      color: Color(s.color),
                      radius: 28,
                      title: '',
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: data.map((s) {
              final pct = total == 0 ? 0 : ((s.value / total) * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: Color(s.color), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data});

  final List<FreqPoint> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data yet', style: TextStyle(color: AppColors.gray400)));
    }
    final maxY = data.map((e) => e.v).fold<double>(1, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxY < 4 ? 4 : maxY + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.gray100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[i].day,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.gray400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].v,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: AppColors.primaryLight,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
