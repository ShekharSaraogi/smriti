import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/large_action_card.dart';
import 'routine_entry_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LargeActionCard(
            icon: Icons.checklist_rounded,
            accent: AppColors.sageDark,
            title: AppStrings.t('edit_daily_routine_button'),
            description: AppStrings.t('home_routine_description'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoutineEntryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.highlight.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    color: AppColors.highlight,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    AppStrings.t('language_label'),
                    style: AppTextStyles.title,
                  ),
                ),
                // A rebuild-driven dropdown: picking a language calls
                // LocaleController.setLanguage, which notifies main.dart's
                // root listener, which rebuilds the whole app (this screen
                // included) — so the selection here just reflects whatever
                // LocaleController currently holds rather than tracking its
                // own local state.
                DropdownButton<String>(
                  value: LocaleController.instance.languageCode,
                  underline: const SizedBox.shrink(),
                  items: LocaleController.supportedLanguages.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value, style: AppTextStyles.body),
                        ),
                      )
                      .toList(),
                  onChanged: (code) {
                    if (code != null) {
                      LocaleController.instance.setLanguage(code);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
