import 'dart:async';

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../l10n/app_strings.dart';
import '../notifications/notification_service.dart';
import '../sync/sync_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

// One entry per kind of reminder this screen can set — everything that
// differs between "medicine" and "hydration" (icon, name, notification
// wording, confirmation wording) lives here, so adding a 5th type later is
// one more entry, not a change scattered across the build method.
class _ReminderType {
  final String key; // stored in the database's 'type' column
  final String labelKey;
  final IconData icon;
  final String notificationBodyKey;
  final String snackbarKey;

  const _ReminderType({
    required this.key,
    required this.labelKey,
    required this.icon,
    required this.notificationBodyKey,
    required this.snackbarKey,
  });
}

const _reminderTypes = [
  _ReminderType(
    key: 'medicine',
    labelKey: 'reminder_type_medicine',
    icon: Icons.medication,
    notificationBodyKey: 'reminder_notification_body_medicine',
    snackbarKey: 'reminder_set_snackbar_medicine',
  ),
  _ReminderType(
    key: 'hydration',
    labelKey: 'reminder_type_hydration',
    icon: Icons.local_drink,
    notificationBodyKey: 'reminder_notification_body_hydration',
    snackbarKey: 'reminder_set_snackbar_hydration',
  ),
  _ReminderType(
    key: 'activity',
    labelKey: 'reminder_type_activity',
    icon: Icons.directions_walk,
    notificationBodyKey: 'reminder_notification_body_activity',
    snackbarKey: 'reminder_set_snackbar_activity',
  ),
  _ReminderType(
    key: 'appointment',
    labelKey: 'reminder_type_appointment',
    icon: Icons.event,
    notificationBodyKey: 'reminder_notification_body_appointment',
    snackbarKey: 'reminder_set_snackbar_appointment',
  ),
];

// Falls back to the medicine type's look for any unrecognized/legacy value
// rather than crashing — old data should always render as *something*.
_ReminderType _typeFor(String key) {
  return _reminderTypes.firstWhere(
    (t) => t.key == key,
    orElse: () => _reminderTypes.first,
  );
}

// The database stores internal status codes (e.g. 'pending'); this maps
// them to what a patient or caregiver should actually read on screen.
// 'pending' alone doesn't say whether the time has already passed — the
// database never updates the status on its own once a reminder's moment
// arrives, so that has to be computed here from the current time, the
// same way the caregiver dashboard already does.
String _displayStatus(String status, DateTime scheduledDate) {
  switch (status) {
    case 'pending':
      return scheduledDate.isBefore(DateTime.now())
          ? AppStrings.t('reminder_missed_status')
          : AppStrings.t('reminder_upcoming_status');
    case 'completed':
      return AppStrings.t('reminder_done_status');
    default:
      return status;
  }
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final patientId =
          await DatabaseHelper.instance.getOrCreateDefaultPatient();
      final reminders = await DatabaseHelper.instance.getRemindersForPatient(
        patientId,
      );
      if (!mounted) return;
      setState(() {
        _reminders = reminders;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load reminders: $e';
      });
    }
  }

  Future<void> _setReminder(_ReminderType type) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;
    if (!mounted) return;

    try {
      await NotificationService.instance.requestPermission();

      // Computed once, then reused for both the notification and the
      // database row below, so they always agree on exactly when this fires.
      final scheduledDate = NotificationService.instance.nextInstanceOf(
        pickedTime,
      );

      final patientId =
          await DatabaseHelper.instance.getOrCreateDefaultPatient();
      final reminderId = await DatabaseHelper.instance.insertReminder({
        'patient_id': patientId,
        'type': type.key,
        'scheduled_time': scheduledDate.toIso8601String(),
        'status': 'pending',
      });

      await NotificationService.instance.scheduleReminder(
        id: reminderId,
        title: AppStrings.t('app_name'),
        body: AppStrings.t(type.notificationBodyKey),
        scheduledDate: scheduledDate,
      );
      // Fire-and-forget: don't make the patient wait on a network round
      // trip just to see the confirmation snackbar. If it fails (no
      // internet), the row stays marked unsynced and goes out later.
      unawaited(SyncService.instance.syncAll());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t(type.snackbarKey, {
              'time': pickedTime.format(context),
            }),
          ),
        ),
      );
      _loadReminders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not set reminder: $e')),
      );
    }
  }

  Future<void> _markAsDone(int reminderId) async {
    await DatabaseHelper.instance.markReminderStatus(
      reminderId,
      'completed',
      completedAt: DateTime.now().toIso8601String(),
    );
    // Fire-and-forget, same reasoning as everywhere else this is used —
    // don't make the patient wait on a network round trip for a UI update.
    unawaited(SyncService.instance.syncAll());
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('reminders_title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: [
                for (final type in _reminderTypes)
                  ElevatedButton.icon(
                    onPressed: () => _setReminder(type),
                    icon: Icon(type.icon),
                    label: Text(
                      AppStrings.t(type.labelKey),
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _loadError!,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                : _reminders.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.t('no_reminders_yet'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _reminders.length,
                        itemBuilder: (context, index) {
                          final reminder = _reminders[index];
                          final type = _typeFor(reminder['type'] as String);
                          // The stored string carries an explicit UTC
                          // offset (e.g. "...+0530"). DateTime.parse alone
                          // returns that normalized to UTC — its .hour and
                          // .minute would be UTC clock fields, not the
                          // local wall-clock time a person actually picked.
                          // .toLocal() converts it back to this device's
                          // own local time before reading those fields.
                          final scheduledDate = DateTime.parse(
                            reminder['scheduled_time'] as String,
                          ).toLocal();
                          final timeLabel = TimeOfDay.fromDateTime(
                            scheduledDate,
                          ).format(context);
                          final dateLabel =
                              '${scheduledDate.day}/${scheduledDate.month}';
                          final rawStatus = reminder['status'] as String;
                          final status = _displayStatus(
                            rawStatus,
                            scheduledDate,
                          );
                          return ListTile(
                            leading: Icon(type.icon, size: 32),
                            title: Text(
                              AppStrings.t(type.labelKey),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$timeLabel  •  $dateLabel'),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: status ==
                                            AppStrings.t(
                                              'reminder_missed_status',
                                            )
                                        ? Colors.red
                                        : status ==
                                                AppStrings.t(
                                                  'reminder_done_status',
                                                )
                                            ? Colors.green
                                            : null,
                                  ),
                                ),
                              ],
                            ),
                            trailing: rawStatus == 'pending'
                                ? TextButton(
                                    onPressed: () => _markAsDone(
                                      reminder['id'] as int,
                                    ),
                                    child: Text(
                                      AppStrings.t('mark_done_button'),
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
