import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/large_action_card.dart';
import 'games_screen.dart';
import 'reminders_screen.dart';
import 'routine_entry_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // A very low-opacity photographic wash behind the cream base,
          // faded to nothing by the bottom of the screen — decorative
          // texture only, never strong enough to threaten the text
          // contrast above it.
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/home_wash.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                cacheWidth: 900,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.55),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SMRITI', style: AppTextStyles.wordmark),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.sageDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                LargeActionCard(
                  icon: Icons.videogame_asset_rounded,
                  accent: AppColors.sageDark,
                  title: AppStrings.t('home_games_button'),
                  description: AppStrings.t('home_games_description'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GamesScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                LargeActionCard(
                  icon: Icons.alarm_rounded,
                  accent: AppColors.highlight,
                  title: AppStrings.t('home_reminders_button'),
                  description: AppStrings.t('home_reminders_description'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RemindersScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                LargeActionCard(
                  icon: Icons.checklist_rounded,
                  accent: AppColors.sageDark,
                  title: AppStrings.t('home_routine_button'),
                  description: AppStrings.t('home_routine_description'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoutineEntryScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LargeActionCard(
                  icon: Icons.settings_rounded,
                  accent: AppColors.inkMuted,
                  title: AppStrings.t('home_settings_button'),
                  description: AppStrings.t('home_settings_description'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
