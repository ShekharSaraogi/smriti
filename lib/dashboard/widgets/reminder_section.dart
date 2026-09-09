import 'package:flutter/material.dart';

import '../dashboard_data.dart';
import '../dashboard_theme.dart';

class ReminderSection extends StatelessWidget {
  final List<ReminderInfo> upcoming;
  final List<ReminderInfo> missed;

  const ReminderSection({
    super.key,
    required this.upcoming,
    required this.missed,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reminders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DashboardColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          if (missed.isEmpty && upcoming.isEmpty)
            const Text(
              'No reminders yet',
              style: TextStyle(color: DashboardColors.inkMuted),
            ),
          for (final reminder in missed)
            _ReminderRow(reminder: reminder, isMissed: true),
          for (final reminder in upcoming)
            _ReminderRow(reminder: reminder, isMissed: false),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final ReminderInfo reminder;
  final bool isMissed;

  const _ReminderRow({required this.reminder, required this.isMissed});

  @override
  Widget build(BuildContext context) {
    final color = isMissed ? DashboardColors.warning : DashboardColors.good;
    final time = reminder.scheduledTime.toLocal();
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        '  •  ${time.day}/${time.month}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reminder.type[0].toUpperCase() + reminder.type.substring(1),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DashboardColors.ink,
              ),
            ),
          ),
          Text(
            isMissed ? 'Missed — $timeLabel' : timeLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
