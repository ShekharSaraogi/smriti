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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: DashboardTextStyles.label,
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          // Counts up from 0 on first paint — a small, standard touch that
          // makes the number feel measured rather than printed. Wrapped in
          // a FittedBox so a card squeezed narrower than ideal (a small
          // window, a phone browser) shrinks the number instead of
          // overflowing the card.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) => Text(
                '${animatedValue.round()}$suffix',
                style: DashboardTextStyles.mono.copyWith(color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
