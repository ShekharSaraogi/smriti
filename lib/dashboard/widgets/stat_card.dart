import 'package:flutter/material.dart';

import '../dashboard_theme.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String suffix;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    this.suffix = '',
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          // Counts up from 0 on first paint rather than just appearing —
          // a small, standard touch that makes a stats dashboard feel
          // alive instead of static, especially the first moment it loads.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) => Text(
              '${animatedValue.round()}$suffix',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: DashboardColors.ink,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: DashboardColors.inkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
