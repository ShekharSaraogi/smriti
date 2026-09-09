import 'package:flutter/material.dart';

import '../dashboard_data.dart';
import '../dashboard_theme.dart';

class GameSummaryCard extends StatelessWidget {
  // Matches DifficultyEngine.maxTier in the patient app (lib/difficulty/
  // difficulty_engine.dart) — not imported directly since the dashboard is
  // a deliberately separate mini-app with no dependency on the patient
  // app's internals, just the same well-known tier range.
  static const _maxTier = 5;

  final GameSummary summary;

  const GameSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final color = DashboardColors.gameColors[summary.gameType]!;
    final label = DashboardColors.gameLabels[summary.gameType]!;
    final icon = DashboardColors.gameIcons[summary.gameType]!;
    final accuracyPercent = (summary.last7DayAccuracy * 100).round();

    return DashboardCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                summary.sessionsLast7Days == 0 ? '—' : '$accuracyPercent%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.ink,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Level ${summary.currentTier}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DashboardColors.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            summary.sessionsLast7Days == 0
                ? 'No rounds this week'
                : '${summary.sessionsLast7Days} round'
                    '${summary.sessionsLast7Days == 1 ? '' : 's'} this week',
            style: const TextStyle(
              fontSize: 12,
              color: DashboardColors.inkMuted,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: summary.currentTier / _maxTier),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, animatedFraction, child) =>
                  LinearProgressIndicator(
                value: animatedFraction,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
