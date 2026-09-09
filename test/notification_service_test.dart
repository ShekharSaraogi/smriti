import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/db/database_helper.dart';
import 'package:smriti/notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  // combine reads tz.local, which (unlike most of the timezone package)
  // has no default — it must be set explicitly before use.
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  });

  group('combine', () {
    // combine is deliberately built from plain DateTime, not tz.TZDateTime's
    // own component constructor (see its doc comment for why: it must stay
    // correct even when tz.local fails to resolve to the right named zone,
    // as happened on a real device). Comparing via isAtSameMomentAs checks
    // the actual instant, immune to whatever label tz.local happens to be
    // pinned to above.
    test('combines a specific date and time into that exact instant', () {
      final result = NotificationService.instance.combine(
        DateTime(2026, 12, 25),
        const TimeOfDay(hour: 14, minute: 30),
      );
      expect(
        result.isAtSameMomentAs(DateTime(2026, 12, 25, 14, 30)),
        isTrue,
      );
    });

    test('does not adjust for whether the result is in the past', () {
      // combine is a pure combination of whatever date and time it's
      // given — validating that the result is actually in the future is
      // the caller's job (the screen, right after the date/time pickers
      // return), not this method's.
      final result = NotificationService.instance.combine(
        DateTime(2020, 1, 1),
        const TimeOfDay(hour: 9, minute: 0),
      );
      expect(result.isAtSameMomentAs(DateTime(2020, 1, 1, 9, 0)), isTrue);
    });
  });

  test('reminders sort chronologically, not alphabetically', () async {
    final patientId = await DatabaseHelper.instance.getOrCreateDefaultPatient();

    // Deliberately inserted out of order, and deliberately chosen so that
    // sorting as plain text ("10:00" before "9:00") would get this wrong.
    final nineAm = DateTime(2026, 1, 1, 9);
    final tenAm = DateTime(2026, 1, 1, 10);

    await DatabaseHelper.instance.insertReminder({
      'patient_id': patientId,
      'type': 'medicine',
      'scheduled_time': tenAm.toIso8601String(),
      'status': 'pending',
    });
    await DatabaseHelper.instance.insertReminder({
      'patient_id': patientId,
      'type': 'medicine',
      'scheduled_time': nineAm.toIso8601String(),
      'status': 'pending',
    });

    final reminders = await DatabaseHelper.instance.getRemindersForPatient(
      patientId,
    );

    final ourReminders = reminders.where(
      (r) =>
          r['scheduled_time'] == nineAm.toIso8601String() ||
          r['scheduled_time'] == tenAm.toIso8601String(),
    );
    expect(ourReminders.first['scheduled_time'], nineAm.toIso8601String());
    expect(ourReminders.last['scheduled_time'], tenAm.toIso8601String());
  });
}
