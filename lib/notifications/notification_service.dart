import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance =
      NotificationService._privateConstructor();

  static const _channelId = 'smriti_reminders';
  static const _channelName = 'Smriti Reminders';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Sets up the notification plugin and the device's real timezone. Must
  // run once before scheduling anything. Safe to call more than once.
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    // Web and Windows don't reliably report a real IANA timezone name yet;
    // falling back to UTC there is fine since those are dev-preview targets,
    // not where this app actually ships.
    //
    // Real-device testing turned up a sharper problem than "unsupported
    // platform" though: this device reports "Asia/Calcutta" (the old IANA
    // alias for Asia/Kolkata), which this package's bundled zone database
    // doesn't recognize at all. The lookup below throws, gets caught, and
    // tz.local silently stays at its UTC default — which shifted every
    // scheduled reminder by exactly India's +5:30 offset. Correctness for
    // the actual scheduled time no longer depends on this resolving right
    // (see nextInstanceOf), but getting the name itself right too, when we
    // can, is worth the one-line alias fix.
    const legacyTimezoneAliases = {'Asia/Calcutta': 'Asia/Kolkata'};
    try {
      final reportedName = (await FlutterTimezone.getLocalTimezone()).identifier;
      final resolvedName = legacyTimezoneAliases[reportedName] ?? reportedName;
      tz.setLocalLocation(tz.getLocation(resolvedName));
    } catch (_) {
      // Keep the default (UTC) location.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    _isInitialized = true;
  }

  // Android 13+ hides notifications entirely until the user grants this,
  // and Android 14+ requires a separate grant for exact-time alarms.
  // Harmless no-op on platforms/versions that don't need either.
  Future<void> requestPermission() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  // TEMPORARY DIAGNOSTIC: fires a notification immediately, with no alarm
  // or scheduling involved. Used to isolate whether the problem is in the
  // scheduling path or in notification display itself. Remove once the
  // reminder issue is resolved.
  Future<void> showNowForDiagnostics() async {
    await _plugin.show(
      id: 99999,
      title: 'Smriti test',
      body: 'If you can see this, notifications themselves work.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Medicine, hydration and appointment reminders',
        ),
      ),
    );
  }

  // Schedules a single reminder to fire at exactly [scheduledDate]. [id]
  // should be the reminder's own database row id, so the two stay in sync.
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Medicine, hydration and appointment reminders',
        ),
      ),
      // Exact, not inexact: a medicine reminder needs to fire at the actual
      // chosen time, not "sometime around then" — worth the extra permission
      // this requires (requested above), especially since real-device testing
      // showed inexact firing unreliably under MIUI's aggressive power saving.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // The next moment [timeOfDay] occurs — today if it hasn't passed yet,
  // otherwise tomorrow. Callers use this same instant for both the
  // notification and the database row, so the two can never disagree.
  //
  // Deliberately built from plain Dart DateTime, not tz.TZDateTime's own
  // component constructor. Dart's DateTime always knows the device's real
  // local time correctly, straight from the OS — no zone-name database
  // involved, nothing that can fail to resolve. tz.TZDateTime.from() then
  // carries that already-correct absolute instant over, using tz.local only
  // to label/display it. That split is what makes this correct even if
  // tz.local's *name* is wrong (as it was here): only the label would be
  // off, never the actual moment the reminder fires.
  tz.TZDateTime nextInstanceOf(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduled, tz.local);
  }
}
