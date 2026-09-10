import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// The progress line shown at the top of every game ("Round 2 of 5 • Level
// 3", "Pairs found: 1 of 3 • Level 1", ...). Each game builds its own
// exact progress string — this widget only supplies the visual chrome
// (a soft accent pill) around whatever string it's given, so the
// underlying text — and anything a test asserts against it — is unchanged.
class GameHeader extends StatelessWidget {
  final String progressText;
  final Color accent;

  const GameHeader({
    super.key,
    required this.progressText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        progressText,
        textAlign: TextAlign.center,
        style: AppTextStyles.title.copyWith(color: accent, fontSize: 17),
      ),
    );
  }
}
