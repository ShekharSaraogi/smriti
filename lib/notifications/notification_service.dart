import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance =
      NotificationService._privateConstructor();

  // Bumped to v2: Android permanently locks in a channel's importance/
  // sound/vibration settings from whenever that channel ID was FIRST
  // created on a device, and silently ignores any later change to those
  // settings for the same ID — only the user can change them by hand, in
  // system Settings. The original channel may have been created early on
  // (implicitly, with weaker defaults) before we ever set these
  // explicitly. A new ID forces Android to create it fresh.
  static const _channelId = 'smriti_reminders_v2';
  static const _channelName = 'Smriti Medicine Reminders';
  static const _channelDescription =
      'Medicine, hydration and appointment reminders';

  // A distinct buzz-pause-buzz pattern rather than one short vibration, so
  // a medicine reminder is harder to sleep through than a generic ping.
  static final Int64List _vibrationPattern = Int64List.fromList(
    [0, 1000, 500, 1000, 500, 1000],
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static NotificationDetails get _notificationDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _vibrationPattern,
          // Asks Android to wake the screen and show over the lock screen —
          // the same delivery path alarm-clock and calling apps get, and a
          // much stronger signal to the OS than a normal notification that
          // this shouldn't be silently deferred by background restrictions.
          fullScreenIntent: true,
        ),
      );

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
      // Reported name didn't resolve to anything the timezone package
      // recognizes. This app only ships in India for now, so defaulting to
      // Asia/Kolkata is a reasonable guess — better than silently falling
      // back to UTC, which is what caused reminders to fire 5.5 hours off
      // once already.
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        // Keep the default (UTC) location.
      }
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
      notificationDetails: _notificationDetails,
      // Exact, not inexact: a medicine reminder needs to fire at the actual
      // chosen time, not "sometime around then" — worth the extra permission
      // this requires (requested above), especially since real-device testing
      // showed inexact firing unreliably under MIUI's aggressive power saving.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Combines an explicitly picked date and time into one instant. Callers
  // use this same instant for both the notification and the database row,
  // so the two can never disagree.
  //
  // Deliberately built from plain Dart DateTime, not tz.TZDateTime's own
  // component constructor. Dart's DateTime always knows the device's real
  // local time correctly, straight from the OS — no zone-name database
  // involved, nothing that can fail to resolve. tz.TZDateTime.from() then
  // carries that already-correct absolute instant over, using tz.local only
  // to label/display it. That split is what makes this correct even if
  // tz.local's *name* is wrong (as it happened on a real device once
  // already): only the label would be off, never the actual moment the
  // reminder fires.
  tz.TZDateTime combine(DateTime date, TimeOfDay time) {
    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return tz.TZDateTime.from(combined, tz.local);
  }

  // Cancels a previously scheduled reminder — used when a reminder is
  // edited (cancel the old time, schedule the new one) or deleted.
  // Harmless no-op if nothing with this id is currently scheduled.
  Future<void> cancelReminder(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {
      // Best-effort: whatever change triggered this (editing or deleting
      // a reminder) should still go through even if the notification
      // itself couldn't be cancelled — the database change is what
      // actually matters to the user, not this cleanup step.
    }
  }
}
