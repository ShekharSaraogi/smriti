import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smriti/db/database_helper.dart';
import 'package:smriti/screens/reminders_screen.dart';

// sqflite_common_ffi talks to a real background isolate, which the fake
// test clock a testWidgets body normally runs under can't service — so
// any direct database call in a test has to go through runAsync, not
// just the widget's own internal calls once it's pumped.
Future<void> _seedReminder(WidgetTester tester, DateTime scheduledTime) async {
  await tester.runAsync(() async {
    final patientId = await DatabaseHelper.instance.getOrCreateDefaultPatient();
    await DatabaseHelper.instance.insertReminder({
      'patient_id': patientId,
      'type': 'medicine',
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
  testWidgets(
      'a pending reminder shows a Mark as taken button, not a checkmark',
      (WidgetTester tester) async {
    await _seedReminder(tester, DateTime.now().add(const Duration(hours: 1)));

    await _pumpScreen(tester);

    expect(find.text('Mark as taken'), findsWidgets);
  });

  testWidgets('tapping Mark as taken updates the status to Taken',
      (WidgetTester tester) async {
    await _seedReminder(
      tester,
      DateTime.now().subtract(const Duration(minutes: 5)),
    );

    await _pumpScreen(tester);

    // Counts rather than findsOneWidget/findsNothing — the test database
    // can carry reminders over from a previous run, so there could
    // legitimately be other "Missed" rows already on screen. What this
    // test actually cares about is the *change*: exactly one more "Taken"
    // and one fewer "Missed" after tapping, regardless of how many of
    // either already existed.
    final missedBefore = find.text('Missed').evaluate().length;
    final takenBefore = find.text('Taken').evaluate().length;
    // This reminder's time has already passed, so it starts out "Missed".
    expect(missedBefore, greaterThanOrEqualTo(1));

    await tester.tap(find.text('Mark as taken').first);
    // Marking as taken writes to the database, then reloads the list —
    // which itself makes two more sequential real database calls. Poll
    // rather than guess a fixed delay, same reason _pumpScreen does.
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.text('Missed').evaluate().length == missedBefore - 1) break;
    }

    expect(find.text('Missed').evaluate().length, missedBefore - 1);
    expect(find.text('Taken').evaluate().length, takenBefore + 1);
  });
}
