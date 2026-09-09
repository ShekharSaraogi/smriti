import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notifications/notification_service.dart';
import 'screens/home_screen.dart';
import 'sync/supabase_config.dart';
import 'sync/sync_service.dart';

void main() async {
  // Needed before calling plugin code (notifications setup) prior to
  // runApp — without this, Flutter isn't ready to talk to platform plugins.
  WidgetsFlutterBinding.ensureInitialized();
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

class SmritiApp extends StatelessWidget {
  const SmritiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smriti',
      home: const HomeScreen(),
    );
  }
}