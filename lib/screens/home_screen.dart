import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/menu_button.dart';
import 'games_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('home_title'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MenuButton(
              icon: Icons.videogame_asset_rounded,
              label: AppStrings.t('home_games_button'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GamesScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            MenuButton(
              icon: Icons.alarm_rounded,
              label: AppStrings.t('home_reminders_button'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RemindersScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            MenuButton(
              icon: Icons.settings_rounded,
              label: AppStrings.t('home_settings_button'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
