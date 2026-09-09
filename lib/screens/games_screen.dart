import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/menu_button.dart';
import 'attention_sweep_screen.dart';
import 'memory_match_screen.dart';
import 'pattern_voice_screen.dart';
import 'routine_recall_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('games_title'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Same icon per game as the caregiver dashboard's game cards
            // (lib/dashboard/dashboard_theme.dart gameIcons) — one visual
            // identity per game across both apps.
            MenuButton(
              icon: Icons.grid_view_rounded,
              label: AppStrings.t('games_memory_match_button'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MemoryMatchScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            MenuButton(
              icon: Icons.mic_rounded,
              label: AppStrings.t('games_pattern_voice_button'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatternVoiceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            MenuButton(
              icon: Icons.center_focus_strong_rounded,
              label: AppStrings.t('games_attention_sweep_button'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttentionSweepScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            MenuButton(
              icon: Icons.checklist_rounded,
              label: AppStrings.t('games_routine_recall_button'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoutineRecallScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
