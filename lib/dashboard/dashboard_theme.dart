import 'package:flutter/material.dart';

// A small, deliberate palette for the caregiver dashboard — distinct from
// the rest of the app, which stays plain Material on purpose for elderly
// patients. Caregivers are a different audience: comfortable with a
// screen, looking for a quick read on trends, not a simple tap target.
class DashboardColors {
  DashboardColors._();

  static const background = Color(0xFFF3F5FB);
  static const surface = Colors.white;
  static const ink = Color(0xFF1F2247);
  static const inkMuted = Color(0xFF6B7094);

  static const primary = Color(0xFF5B5FEF);
  static const primaryDeep = Color(0xFF3D3FB0);
  static const streak = Color(0xFFFF9F43);
  static const good = Color(0xFF2ED8A7);
  static const warning = Color(0xFFEE5A6F);

  static const gameColors = {
    'memory_match': Color(0xFF6C5CE7),
    'pattern_voice': Color(0xFF00B4A6),
    'attention_sweep': Color(0xFFFF9F43),
    'routine_recall': Color(0xFFEE5A6F),
  };

  static const gameLabels = {
    'memory_match': 'Memory Match',
    'pattern_voice': 'Pattern & Voice',
    'attention_sweep': 'Attention Sweep',
    'routine_recall': 'Routine Recall',
  };

  static const gameIcons = {
    'memory_match': Icons.grid_view_rounded,
    'pattern_voice': Icons.mic_rounded,
    'attention_sweep': Icons.center_focus_strong_rounded,
    'routine_recall': Icons.checklist_rounded,
  };
}

class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.ink.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
