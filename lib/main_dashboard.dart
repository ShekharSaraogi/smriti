import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard/dashboard_home_screen.dart';
import 'dashboard/dashboard_theme.dart';
import 'sync/supabase_config.dart';

// A separate entry point from the patient-facing app (lib/main.dart) —
// built and run independently via:
//   flutter run -d chrome -t lib/main_dashboard.dart
// It shares the same Supabase project and pubspec dependencies, but none
// of the patient app's screens, sqflite, notifications, or difficulty
// engine — a caregiver viewing this in a browser has no use for any of
// that.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!SupabaseConfig.isConfigured) {
    runApp(const _NotConfiguredApp());
    return;
  }
  Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  ).then((_) => runApp(const DashboardApp()));
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smriti Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: DashboardColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: DashboardColors.primary,
        ),
        fontFamily: 'Roboto',
      ),
      home: const DashboardHomeScreen(),
    );
  }
}

class _NotConfiguredApp extends StatelessWidget {
  const _NotConfiguredApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Supabase isn\'t configured yet — fill in lib/sync/supabase_config.dart first.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
