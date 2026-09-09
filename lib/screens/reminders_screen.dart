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

// The database stores internal status codes (e.g. 'pending'); this maps
// them to what a patient or caregiver should actually read on screen.
String _displayStatus(String status) {
  switch (status) {
    case 'pending':
      return AppStrings.t('reminder_upcoming_status');
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

  Future<void> _setMedicineReminder() async {
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
        'type': 'medicine',
        'scheduled_time': scheduledDate.toIso8601String(),
        'status': 'pending',
      });

      await NotificationService.instance.scheduleReminder(
        id: reminderId,
        title: AppStrings.t('app_name'),
        body: AppStrings.t('reminder_notification_body'),
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
            AppStrings.t('reminder_set_snackbar', {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('reminders_title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(240, 64),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: _setMedicineReminder,
              child: Text(AppStrings.t('set_reminder_button')),
            ),
          ),
          // TEMPORARY DIAGNOSTIC BUTTON — remove once reminders work.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () async {
                try {
                  await NotificationService.instance.requestPermission();
                  await NotificationService.instance.showNowForDiagnostics();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test notification sent')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Test notification failed: $e')),
                  );
                }
              },
              child: const Text('Test notification now'),
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
                          return ListTile(
                            leading: const Icon(Icons.medication, size: 32),
                            title: Text(
                              '$timeLabel  •  $dateLabel',
                              style: const TextStyle(fontSize: 18),
                            ),
                            subtitle: Text(
                              _displayStatus(reminder['status'] as String),
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
