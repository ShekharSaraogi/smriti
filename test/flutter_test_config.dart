import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Flutter runs this automatically before every test in this folder.
// Without it, any code that touches sqflite (like DatabaseHelper) throws
// MissingPluginException in tests, since there's no real phone to talk to.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await testMain();
}
