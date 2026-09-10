import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// One tappable answer choice in Routine Recall — a full-width card (icon +
// label) rather than a plain button, per the "large answer cards" design
// direction. A dedicated widget class mainly so tests can find these
// choices reliably by type, the same way they'd find an ElevatedButton.
class RoutineChoiceCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback? onTap;

  const RoutineChoiceCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sage.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: AppTextStyles.title)),
            ],
          ),
        ),
      ),
    );
  }
}
