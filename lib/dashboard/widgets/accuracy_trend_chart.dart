import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../dashboard_data.dart';
import '../dashboard_theme.dart';

class AccuracyTrendChart extends StatelessWidget {
  final List<DailyPoint> points;

  const AccuracyTrendChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].accuracy * 100),
    ];
    final today = points.last;
    final todayLabel = today.accuracy == 0 && today.sessionCount == 0
        ? '—'
        : '${(today.accuracy * 100).round()}%';

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('7-DAY ACCURACY', style: DashboardTextStyles.label),
              ),
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  color: DashboardColors.live,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                'TODAY $todayLabel',
                style: DashboardTextStyles.monoSmall.copyWith(
                  color: DashboardColors.live,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: DashboardColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: DashboardTextStyles.monoSmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final day = points[index].day;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _weekdayLabel(day.weekday),
                            style: DashboardTextStyles.bodyMuted.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => DashboardColors.surfaceRaised,
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.round()}%',
                        DashboardTextStyles.monoSmall.copyWith(
                          color: DashboardColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: DashboardColors.accent,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      // Today's point (the last one) stands out from the
                      // rest — it's the number that actually matters most
                      // to a caregiver checking in right now.
                      getDotPainter: (spot, percent, bar, index) {
                        final isToday = index == points.length - 1;
                        return FlDotCirclePainter(
                          radius: isToday ? 5 : 3,
                          color: isToday
                              ? DashboardColors.live
                              : DashboardColors.accent,
                          strokeWidth: isToday ? 3 : 0,
                          strokeColor:
                              DashboardColors.live.withValues(alpha: 0.25),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DashboardColors.accent.withValues(alpha: 0.22),
                          DashboardColors.accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _weekdayLabel(int weekday) {
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return labels[weekday - 1];
  }
}
