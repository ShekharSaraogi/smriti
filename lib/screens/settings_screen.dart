import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import 'routine_entry_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('settings_title'))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    builder: (context) => const RoutineEntryScreen(),
                  ),
                );
              },
              child: Text(AppStrings.t('edit_daily_routine_button')),
            ),
            const SizedBox(height: 32),
            Text(AppStrings.t('language_label'), style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            // A rebuild-driven dropdown: picking a language calls
            // LocaleController.setLanguage, which notifies main.dart's
            // root listener, which rebuilds the whole app (this screen
            // included) — so the selection here just reflects whatever
            // LocaleController currently holds rather than tracking its
            // own local state.
            DropdownButton<String>(
              value: LocaleController.instance.languageCode,
              items: LocaleController.supportedLanguages.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (code) {
                if (code != null) LocaleController.instance.setLanguage(code);
              },
            ),
          ],
        ),
      ),
    );
  }
}
