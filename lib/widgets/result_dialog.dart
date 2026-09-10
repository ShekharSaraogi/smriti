import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// The "round complete" dialog shared by all four games, replacing each
// screen's separate ad-hoc AlertDialog. A round icon badge stands in for a
// full illustration here — a completion moment is brief by nature, so a
// simple badge reads better in the half-second before it's dismissed than
// a busy photo would. Title/message text is passed straight through
// unchanged so existing widget tests (which assert on that exact text)
// keep working.
Future<void> showResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
  Color accent = AppColors.highlight,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.celebration_rounded, color: accent, size: 32),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: AppTextStyles.headline.copyWith(fontSize: 22),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.body,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(dialogContext);
            onAction();
          },
          icon: const Icon(Icons.replay_rounded),
          label: Text(actionLabel),
        ),
      ],
    ),
  );
}
