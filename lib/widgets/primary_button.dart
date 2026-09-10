import 'package:flutter/material.dart';

// The one obvious primary action on a screen — icon + label together
// (never icon-only, per the elderly-first requirement), generously sized.
// Wraps a plain ElevatedButton so it still inherits every theme change
// automatically; this just fixes the icon+label+size convention in one
// place instead of repeating it at every call site.
class PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 60)),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
