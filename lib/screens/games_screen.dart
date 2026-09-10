import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/large_action_card.dart';
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          LargeActionCard(
            icon: Icons.grid_view_rounded,
            accent: AppColors.sageDark,
            title: AppStrings.t('games_memory_match_button'),
            description: AppStrings.t('games_memory_match_description'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MemoryMatchScreen()),
            ),
          ),
          const SizedBox(height: 16),
          LargeActionCard(
            icon: Icons.mic_rounded,
            accent: AppColors.highlight,
            title: AppStrings.t('games_pattern_voice_button'),
            description: AppStrings.t('games_pattern_voice_description'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PatternVoiceScreen()),
            ),
          ),
          const SizedBox(height: 16),
          LargeActionCard(
            icon: Icons.center_focus_strong_rounded,
            accent: AppColors.sageDark,
            title: AppStrings.t('games_attention_sweep_button'),
            description: AppStrings.t('games_attention_sweep_description'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AttentionSweepScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          LargeActionCard(
            icon: Icons.checklist_rounded,
            accent: AppColors.highlight,
            title: AppStrings.t('games_routine_recall_button'),
            description: AppStrings.t('games_routine_recall_description'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RoutineRecallScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
