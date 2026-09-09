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

      expect(result.year, future.year);
      expect(result.month, future.month);
      expect(result.day, future.day);
    });

    test('rolls over to tomorrow when the time has already passed', () {
      final now = DateTime.now();
      final past = now.subtract(const Duration(minutes: 10));
      final expectedDay = now.add(const Duration(days: 1));
      final result = NotificationService.instance.nextInstanceOf(
        TimeOfDay(hour: past.hour, minute: past.minute),
      );

      expect(result.isAfter(now), isTrue);
      expect(result.day, expectedDay.day);
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
