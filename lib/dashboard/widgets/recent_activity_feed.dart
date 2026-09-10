import 'package:flutter/material.dart';

import '../dashboard_data.dart';
import '../dashboard_theme.dart';

// The individual events behind every aggregated number elsewhere on the
// dashboard — each row is one real game_sessions row synced from the
// phone. This is what makes the dashboard read as live telemetry rather
// than a static report: a caregiver (or anyone watching) can see the
// actual moment-by-moment activity, not just an average that already
// happened somewhere else.
class RecentActivityFeed extends StatelessWidget {
  final List<SessionEntry> entries;
  final DateTime now;

  const RecentActivityFeed({super.key, required this.entries, required this.now});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('RECENT ACTIVITY', style: DashboardTextStyles.label),
              ),
              Text(
                '${entries.length} EVENT${entries.length == 1 ? '' : 'S'}',
                style: DashboardTextStyles.monoSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No sessions synced yet — play a round on the phone to '
                'see it appear here.',
                style: DashboardTextStyles.bodyMuted,
              ),
            )
          else
            for (var i = 0; i < entries.length; i++)
              _ActivityRow(
                entry: entries[i],
                now: now,
                isLatest: i == 0,
                isLast: i == entries.length - 1,
              ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final SessionEntry entry;
  final DateTime now;
  final bool isLatest;
  final bool isLast;

  const _ActivityRow({
    required this.entry,
    required this.now,
    required this.isLatest,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = DashboardColors.gameColors[entry.gameType] ?? DashboardColors.accent;
    final icon = DashboardColors.gameIcons[entry.gameType] ?? Icons.circle;
    final label = DashboardColors.gameLabels[entry.gameType] ?? entry.gameType;
    final justSynced = isLatest && now.difference(entry.timestamp).inSeconds < 90;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: DashboardColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: DashboardTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (justSynced) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: DashboardColors.live.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: DashboardColors.live,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${entry.correctAnswers}/${entry.totalAnswers} correct  •  '
                  '${entry.responseTimeSeconds.toStringAsFixed(1)}s avg  •  '
                  'Lv ${entry.difficultyTier}',
                  style: DashboardTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(entry.accuracy * 100).round()}%',
            style: DashboardTextStyles.monoSmall.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DashboardColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: Text(
              _relativeTime(entry.timestamp, now),
              textAlign: TextAlign.right,
              style: DashboardTextStyles.monoSmall,
            ),
          ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime then, DateTime now) {
    final diff = now.difference(then);
    if (diff.inSeconds < 5) return 'now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
