import 'package:flutter/material.dart';

import '../decline_detector.dart';
import '../dashboard_theme.dart';

// The headline card — placed above the weekly stats on purpose. A 7-day
// accuracy number answers "how did they do this week"; this answers the
// actually harder and more useful question, "is something changing over
// the weeks that a caregiver or doctor should know about." That's the
// difference between an activity tracker and an early-warning tool.
class CognitiveTrendCard extends StatelessWidget {
  final CognitiveTrend trend;

  const CognitiveTrendCard({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (trend.direction) {
      TrendDirection.declining => (Icons.trending_down_rounded, DashboardColors.warning),
      TrendDirection.improving => (Icons.trending_up_rounded, DashboardColors.good),
      TrendDirection.stable => (Icons.trending_flat_rounded, DashboardColors.accent),
      TrendDirection.insufficientData => (Icons.hourglass_top_rounded, DashboardColors.inkMuted),
    };

    return DashboardCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('COGNITIVE TREND', style: DashboardTextStyles.label),
                const SizedBox(height: 6),
                Text(trend.message, style: DashboardTextStyles.body),
                if (trend.direction != TrendDirection.insufficientData) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Based on ${trend.sessionsAnalyzed} sessions over '
                    '${trend.daysSpanned} days',
                    style: DashboardTextStyles.monoSmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
