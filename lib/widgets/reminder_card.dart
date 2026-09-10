import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// One reminder in the Reminders list — a proper card (icon badge, title,
// time/date, a status pill) instead of a plain ListTile, so the moment
// that matters most (is this upcoming, missed, or done?) reads as a
// distinct colored pill rather than plain inline text.
class ReminderCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String timeLabel;
  final String dateLabel;
  final String statusLabel;
  final Color statusColor;
  final Widget trailing;

  const ReminderCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.timeLabel,
    required this.dateLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // A two-row layout rather than one wide Row: the title only has to
    // share space with the icon badge, not with the trailing actions too,
    // so a longer type name never gets squeezed into an awkward mid-word
    // wrap just because "Mark as done" happens to be showing.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.title),
                    const SizedBox(height: 4),
                    Text(
                      '$timeLabel  •  $dateLabel',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.label.copyWith(
                    color: statusColor,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              trailing,
            ],
          ),
        ],
      ),
    );
  }
}
