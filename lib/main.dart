import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/app_strings.dart';
import 'l10n/locale_controller.dart';
import 'notifications/notification_service.dart';
import 'screens/home_screen.dart';
import 'sync/supabase_config.dart';
import 'sync/sync_service.dart';
import 'theme/app_theme.dart';

void main() async {
  // Needed before calling plugin code (notifications setup) prior to
  // runApp — without this, Flutter isn't ready to talk to platform plugins.
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.instance.load();
  await NotificationService.instance.initialize();

  // Sync is entirely optional and never something the app waits on: if no
  // Supabase project has been configured yet, this is skipped and nothing
  // else changes. Once configured, syncing runs in the background and
  // isn't awaited here either — startup never blocks on the network.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    unawaited(SyncService.instance.syncAll());
  }

  runApp(const SmritiApp());
}

class SmritiApp extends StatefulWidget {
  const SmritiApp({super.key});

  @override
  State<SmritiApp> createState() => _SmritiAppState();
}

class _SmritiAppState extends State<SmritiApp> {
  @override
  void initState() {
    super.initState();
    // Rebuilding the whole app from the root is all a 2-language switch
    // needs — every screen re-reads AppStrings.t(...) on its next build.
    LocaleController.instance.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() => setState(() {});

  @override
  void dispose() {
    LocaleController.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.t('app_name'),
      theme: AppTheme.light,
      // NOT `const HomeScreen()`: a const widget is the same canonical
      // instance on every rebuild, and Flutter's element diffing skips
      // rebuilding a child entirely when the new widget is identical to
      // the old one — so Home would never re-read AppStrings.t() after
      // its first build, freezing it in whatever language was active at
      // launch even as every freshly-pushed screen (Games, Reminders,
      // Settings — each built fresh by its own MaterialPageRoute) picked
      // up language changes correctly. A plain (non-const) HomeScreen()
      // is a new instance each rebuild, so it always gets rebuilt too.
      home: HomeScreen(),
    );
  }
}