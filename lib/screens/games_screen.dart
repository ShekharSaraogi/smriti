import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(240, 64),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MemoryMatchScreen(),
                  ),
                );
              },
              child: Text(AppStrings.t('games_memory_match_button')),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(240, 64),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatternVoiceScreen(),
                  ),
                );
              },
              child: Text(AppStrings.t('games_pattern_voice_button')),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(240, 64),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttentionSweepScreen(),
                  ),
                );
              },
              child: Text(AppStrings.t('games_attention_sweep_button')),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(240, 64),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoutineRecallScreen(),
                  ),
                );
              },
              child: Text(AppStrings.t('games_routine_recall_button')),
            ),
          ],
        ),
      ),
    );
  }
}
