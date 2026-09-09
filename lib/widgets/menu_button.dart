import 'package:flutter/material.dart';

// A big, icon-led navigation button shared by the home screen and games
// menu, so every top-level destination in the patient app looks and
// behaves the same way — an icon gives a returning patient a visual
// anchor to recognize a destination by, on top of the text label.
class MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const MenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 72,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
