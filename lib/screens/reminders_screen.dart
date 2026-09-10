import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../db/database_helper.dart';
import '../l10n/app_strings.dart';
import '../notifications/notification_service.dart';
import '../sync/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/reminder_card.dart';

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
  final Color color;
  final String notificationBodyKey;
  final String snackbarKey;

  const _ReminderType({
    required this.key,
    required this.labelKey,
    required this.icon,
    required this.color,
    required this.notificationBodyKey,
    required this.snackbarKey,
  });
}

const _reminderTypes = [
  _ReminderType(
    key: 'medicine',
    labelKey: 'reminder_type_medicine',
    icon: Icons.medication,
    color: AppColors.highlight,
    notificationBodyKey: 'reminder_notification_body_medicine',
    snackbarKey: 'reminder_set_snackbar_medicine',
  ),
  _ReminderType(
    key: 'hydration',
    labelKey: 'reminder_type_hydration',
    icon: Icons.local_drink,
    color: AppColors.sage,
    notificationBodyKey: 'reminder_notification_body_hydration',
    snackbarKey: 'reminder_set_snackbar_hydration',
  ),
  _ReminderType(
    key: 'activity',
    labelKey: 'reminder_type_activity',
    icon: Icons.directions_walk,
    color: AppColors.sageDark,
    notificationBodyKey: 'reminder_notification_body_activity',
    snackbarKey: 'reminder_set_snackbar_activity',
  ),
  _ReminderType(
    key: 'appointment',
    labelKey: 'reminder_type_appointment',
    icon: Icons.event,
    color: AppColors.highlight,
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

  // Shared by both creating and editing a reminder — asks for a date, then
  // a time, and returns the combined instant, or null if either was
  // cancelled or the result isn't actually in the future. [initialDate]/
  // [initialTime] let editing start from the reminder's current schedule
  // instead of "today, now".
  Future<tz.TZDateTime?> _pickDateAndTime({
    required DateTime initialDate,
    required TimeOfDay initialTime,
  }) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime == null || !mounted) return null;

    final scheduledDate = NotificationService.instance.combine(
      pickedDate,
      pickedTime,
    );
    if (scheduledDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('reminder_time_in_past_error'))),
      );
      return null;
    }
    return scheduledDate;
  }

  Future<void> _setReminder(_ReminderType type) async {
    final scheduledDate = await _pickDateAndTime(
      initialDate: DateTime.now(),
      initialTime: TimeOfDay.now(),
    );
    if (scheduledDate == null || !mounted) return;

    try {
      await NotificationService.instance.requestPermission();

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
              'time': TimeOfDay.fromDateTime(scheduledDate).format(context),
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

  Future<void> _editReminder(Map<String, dynamic> reminder) async {
    final currentScheduled = DateTime.parse(
      reminder['scheduled_time'] as String,
    ).toLocal();

    final scheduledDate = await _pickDateAndTime(
      initialDate: currentScheduled,
      initialTime: TimeOfDay.fromDateTime(currentScheduled),
    );
    if (scheduledDate == null || !mounted) return;

    final reminderId = reminder['id'] as int;
    final type = _typeFor(reminder['type'] as String);

    // Cancel the old alarm before scheduling the new one — otherwise both
    // would fire, since they'd share the same id but the plugin has no
    // reason to assume a re-schedule was intended rather than a duplicate.
    await NotificationService.instance.cancelReminder(reminderId);
    await DatabaseHelper.instance.updateReminderSchedule(
      reminderId,
      scheduledDate.toIso8601String(),
    );
    await NotificationService.instance.scheduleReminder(
      id: reminderId,
      title: AppStrings.t('app_name'),
      body: AppStrings.t(type.notificationBodyKey),
      scheduledDate: scheduledDate,
    );
    unawaited(SyncService.instance.syncAll());
    _loadReminders();
  }

  Future<void> _deleteReminder(Map<String, dynamic> reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.t('delete_reminder_title')),
        content: Text(AppStrings.t('delete_reminder_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppStrings.t('cancel_button')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              AppStrings.t('delete_button'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final reminderId = reminder['id'] as int;
    await NotificationService.instance.cancelReminder(reminderId);
    await DatabaseHelper.instance.deleteReminder(reminderId);
    unawaited(SyncService.instance.syncAll());
    _loadReminders();
  }

  Future<void> _showReminderOptions(Map<String, dynamic> reminder) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(AppStrings.t('edit_reminder_button')),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: Text(
                AppStrings.t('delete_button'),
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _editReminder(reminder);
    } else if (action == 'delete') {
      await _deleteReminder(reminder);
    }
  }

  Widget _buildTypeGrid() {
    return Padding(
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
            ElevatedButton(
              onPressed: () => _setReminder(type),
              style: ElevatedButton.styleFrom(backgroundColor: type.color),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(type.icon),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppStrings.t(type.labelKey),
                      textAlign: TextAlign.center,
                      // 2 lines rather than an ellipsis cutoff — "Daily
                      // Activity" and "Medical Appointment" both need it at
                      // this text size, and shrinking the font instead
                      // would work against the elderly-readability
                      // requirement.
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // One scrollable unit (type-picker + list together) rather than a
    // fixed-height type-picker above an Expanded list — that split
    // previously meant a tall enough type-picker or reminder card could
    // push list content below the visible area with no way to reach it.
    // A CustomScrollView lets everything scroll as needed instead.
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('reminders_title'))),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildTypeGrid()),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _loadError!,
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else if (_reminders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  AppStrings.t('no_reminders_yet'),
                  style: AppTextStyles.bodyLarge,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverList.separated(
                itemCount: _reminders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];
                  final type = _typeFor(reminder['type'] as String);
                  // The stored string carries an explicit UTC offset
                  // (e.g. "...+0530"). DateTime.parse alone returns that
                  // normalized to UTC — its .hour and .minute would be UTC
                  // clock fields, not the local wall-clock time a person
                  // actually picked. .toLocal() converts it back to this
                  // device's own local time before reading those fields.
                  final scheduledDate = DateTime.parse(
                    reminder['scheduled_time'] as String,
                  ).toLocal();
                  final timeLabel = TimeOfDay.fromDateTime(
                    scheduledDate,
                  ).format(context);
                  final dateLabel =
                      '${scheduledDate.day}/${scheduledDate.month}';
                  final rawStatus = reminder['status'] as String;
                  final status = _displayStatus(rawStatus, scheduledDate);
                  final statusColor =
                      status == AppStrings.t('reminder_missed_status')
                          ? AppColors.error
                          : status == AppStrings.t('reminder_done_status')
                              ? AppColors.sageDark
                              : AppColors.inkMuted;
                  return ReminderCard(
                    icon: type.icon,
                    accent: type.color,
                    title: AppStrings.t(type.labelKey),
                    timeLabel: timeLabel,
                    dateLabel: dateLabel,
                    statusLabel: status,
                    statusColor: statusColor,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (rawStatus == 'pending')
                          TextButton(
                            onPressed: () =>
                                _markAsDone(reminder['id'] as int),
                            child: Text(AppStrings.t('mark_done_button')),
                          )
                        else
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.sageDark,
                          ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showReminderOptions(reminder),
                        ),
                      ],
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
