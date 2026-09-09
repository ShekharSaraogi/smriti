import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smriti/db/database_helper.dart';
import 'package:smriti/screens/reminders_screen.dart';

// sqflite_common_ffi talks to a real background isolate, which the fake
// test clock a testWidgets body normally runs under can't service — so
// any direct database call in a test has to go through runAsync, not
// just the widget's own internal calls once it's pumped.
//
// Also wipes the reminders table first. This file gets run many times
// while developing this exact feature, and the FFI test database persists
// across runs — without this, leftover rows from earlier runs eventually
// grow the list long enough that a freshly-seeded reminder scrolls off
// the default test viewport and ListView.builder never renders it at all,
// which looks like a completely unrelated failure if you don't know that's
// what's happening.
Future<void> _seedReminder(
  WidgetTester tester,
  DateTime scheduledTime, {
  String type = 'medicine',
}) async {
  await tester.runAsync(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('reminders');
    final patientId = await DatabaseHelper.instance.getOrCreateDefaultPatient();
    await DatabaseHelper.instance.insertReminder({
      'patient_id': patientId,
      'type': type,
      'scheduled_time': scheduledTime.toIso8601String(),
      'status': 'pending',
    });
  });
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: RemindersScreen()),
  );
  // Loading the reminder list is two sequential real database round trips
  // through the FFI test double (getOrCreateDefaultPatient, then
  // getRemindersForPatient) — how long that actually takes varies a lot by
  // machine, so poll for the spinner to disappear instead of guessing a
  // fixed delay (a fixed 300ms wasn't always enough, same as Routine
  // Recall's screen ran into earlier).
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
  fail('Reminders screen never finished loading after 4 seconds');
}

void main() {
  testWidgets('shows one button per reminder type', (WidgetTester tester) async {
    await tester.runAsync(
      () => DatabaseHelper.instance.database.then((db) => db.delete('reminders')),
    );
    await _pumpScreen(tester);

    // widgetWithText scoped to ElevatedButton specifically — a reminder
    // row's own title can say the same word (e.g. "Medicine"), so a plain
    // find.text would also match that, not just the type button.
    expect(find.widgetWithText(ElevatedButton, 'Medicine'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Hydration'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Daily Activity'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Medical Appointment'),
      findsOneWidget,
    );
  });

  testWidgets(
      'a pending reminder shows a Mark as done button, not a checkmark',
      (WidgetTester tester) async {
    await _seedReminder(tester, DateTime.now().add(const Duration(hours: 1)));

    await _pumpScreen(tester);

    expect(find.text('Mark as done'), findsWidgets);
  });

  testWidgets('a hydration reminder shows the Hydration label in its row',
      (WidgetTester tester) async {
    await _seedReminder(
      tester,
      DateTime.now().add(const Duration(hours: 1)),
      type: 'hydration',
    );

    await _pumpScreen(tester);

    // Once for the type button, once for this reminder's own row title.
    expect(find.text('Hydration'), findsNWidgets(2));
  });

  testWidgets('tapping Mark as done updates the status to Done',
      (WidgetTester tester) async {
    await _seedReminder(
      tester,
      DateTime.now().subtract(const Duration(minutes: 5)),
    );

    await _pumpScreen(tester);

    // This reminder's time has already passed, so it starts out "Missed",
    // and it's the only reminder in the (freshly cleared) table.
    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('Done'), findsNothing);

    await tester.tap(find.text('Mark as done').first);
    // Marking as done writes to the database, then reloads the list —
    // which itself makes two more sequential real database calls. Poll
    // rather than guess a fixed delay, same reason _pumpScreen does.
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.text('Done').evaluate().isNotEmpty) break;
    }

    expect(find.text('Missed'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
  });
}
