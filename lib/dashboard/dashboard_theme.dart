import 'package:flutter/material.dart';

// The caregiver dashboard's visual identity — a clean, light "operations
// console" look: a cool off-white workspace background, crisp white
// cards with soft shadows, one confident indigo accent, and monospace
// numerals wherever a number is a live measurement rather than copy. The
// monospace convention and the "last synced" live pulse are what keep
// this from reading as another generic light-purple-gradient template —
// they're borrowed from real monitoring dashboards (Grafana, Datadog,
// Stripe), not decoration.
class DashboardColors {
  DashboardColors._();

  static const background = Color(0xFFF3F5FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const border = Color(0xFFE3E6F0);
  static const ink = Color(0xFF161B33);
  static const inkMuted = Color(0xFF6B7190);

  // The one signal color — "live" telemetry green, used sparingly (the
  // pulse dot, the live badge, positive deltas) so it stays meaningful.
  static const live = Color(0xFF0EA968);
  static const accent = Color(0xFF4F46E5);
  static const streak = Color(0xFFD97706);
  static const good = Color(0xFF0EA968);
  static const warning = Color(0xFFDC2626);

  static const gameColors = {
    'memory_match': Color(0xFF7C3AED),
    'pattern_voice': Color(0xFF0D9488),
    'attention_sweep': Color(0xFFD97706),
    'routine_recall': Color(0xFFE11D48),
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

class DashboardTextStyles {
  DashboardTextStyles._();

  static const _display = 'Sora';
  static const _body = 'IBMPlexSans';
  static const _mono = 'JetBrainsMono';

  static const headline = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    color: DashboardColors.ink,
    height: 1.2,
  );

  static const title = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    color: DashboardColors.ink,
  );

  static const body = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: DashboardColors.ink,
    height: 1.4,
  );

  static const bodyMuted = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    color: DashboardColors.inkMuted,
  );

  static const label = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    color: DashboardColors.inkMuted,
    letterSpacing: 0.6,
  );

  // Every measured number in the dashboard (stat values, chart labels,
  // timestamps) uses this — tabular figures so digits line up in columns
  // when they change, and a monospace face because that's the visual
  // shorthand for "this is instrument output," not copy.
  static const mono = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w700,
    fontSize: 30,
    color: DashboardColors.ink,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.0,
  );

  static const monoSmall = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    color: DashboardColors.inkMuted,
    fontFeatures: [FontFeature.tabularFigures()],
  );
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardColors.border),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
