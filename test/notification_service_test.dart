import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/db/database_helper.dart';
import 'package:smriti/notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  // nextInstanceOf reads tz.local, which (unlike most of the timezone
  // package) has no default — it must be set explicitly before use.
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  });

  group('nextInstanceOf', () {
    // nextInstanceOf is deliberately built from plain DateTime.now() now
    // (see its doc comment for why: it must stay correct even when tz.local
    // fails to resolve to the right named zone, as happened on a real
    // device). So these tests compare against DateTime.now() too, not
    // tz.TZDateTime.now(tz.local) — the two are no longer the same clock,
    // since tz.local is pinned to UTC above purely so the tz.TZDateTime.from
    // call inside nextInstanceOf has a valid location to attach, not because
    // the result should be measured against it.
    test('stays on today when the time has not passed yet', () {
      final now = DateTime.now();
      final future = now.add(const Duration(minutes: 10));
      final result = NotificationService.instance.nextInstanceOf(
        TimeOfDay(hour: future.hour, minute: future.minute),
      );

      // Compares the absolute instant rather than individual date fields.
      // result's fields are labeled in tz.local (pinned to UTC above),
      // which can legitimately disagree with the real system-local
      // calendar day used to build `future` whenever the test happens to
      // run close to midnight IST — this flaked for exactly that reason
      // once already. The instant is what actually matters: does the
      // reminder fire at the right moment, not what day number some
      // arbitrary timezone label attaches to it.
      final expectedInstant = DateTime(
        future.year,
        future.month,
        future.day,
        future.hour,
        future.minute,
      );
      expect(result.isAtSameMomentAs(expectedInstant), isTrue);
    });

    test('rolls over to tomorrow when the time has already passed', () {
      final now = DateTime.now();
      final past = now.subtract(const Duration(minutes: 10));
      final result = NotificationService.instance.nextInstanceOf(
        TimeOfDay(hour: past.hour, minute: past.minute),
      );

      final expectedInstant = DateTime(
        past.year,
        past.month,
        past.day,
        past.hour,
        past.minute,
      ).add(const Duration(days: 1));

      expect(result.isAfter(now), isTrue);
      expect(result.isAtSameMomentAs(expectedInstant), isTrue);
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
