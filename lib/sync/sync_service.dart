import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/database_helper.dart';
import 'device_identity.dart';
import 'supabase_config.dart';

// Pushes local, not-yet-uploaded game sessions and reminders up to
// Supabase, so the caregiver dashboard (which has no way to reach a
// patient's own phone) has something to read. One-directional and
// best-effort: the phone never reads anything back from the cloud, and
// any failure here (no internet, project unreachable) just leaves rows
// marked unsynced for the next attempt — it can never block or break
// anything the patient is doing, in keeping with this app being
// offline-first.
//
// Known limitation: if the app is killed between a row being inserted
// into Supabase and its local `synced` flag being set, that row gets
// re-sent next time, appearing twice in the cloud. Fine for now (a
// duplicate session in the dashboard's stats is cosmetic, not
// dangerous) — worth fixing later by giving each local row its own uuid
// and upserting on that instead of plain inserting, if it turns out to
// matter in practice.
class SyncService {
  SyncService._privateConstructor();
  static final SyncService instance = SyncService._privateConstructor();

  Future<void> syncAll() async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      final client = Supabase.instance.client;
      final cloudPatientId = await _ensureCloudPatient(client);
      await _syncSessions(client, cloudPatientId);
      await _syncReminders(client, cloudPatientId);
    } catch (_) {
      // No internet, project unreachable, etc. Silently retried on the
      // next call (e.g. next app start) — never surfaced to the patient.
    }
  }

  // Upserts this device's own patient row by device_uuid, so repeated
  // calls always resolve to the same cloud patient rather than creating a
  // new one every time.
  Future<String> _ensureCloudPatient(SupabaseClient client) async {
    final deviceUuid = await DeviceIdentity.instance.getOrCreate();
    final localPatientId =
        await DatabaseHelper.instance.getOrCreateDefaultPatient();
    final patients = await DatabaseHelper.instance.getPatients();
    final localPatient = patients.firstWhere(
      (p) => p['id'] == localPatientId,
    );

    final response = await client
        .from('patients')
        .upsert({
          'device_uuid': deviceUuid,
          'name': localPatient['name'],
          'preferred_language': localPatient['preferred_language'],
          'daily_routine': localPatient['daily_routine'],
          'created_at': localPatient['created_at'],
        }, onConflict: 'device_uuid')
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<void> _syncSessions(
    SupabaseClient client,
    String cloudPatientId,
  ) async {
    final sessions = await DatabaseHelper.instance.getUnsyncedSessions();
    for (final session in sessions) {
      await client.from('game_sessions').insert({
        'patient_id': cloudPatientId,
        'game_type': session['game_type'],
        'difficulty_tier': session['difficulty_tier'],
        'accuracy': session['accuracy'],
        'response_time_seconds': session['response_time_seconds'],
        'correct_answers': session['correct_answers'],
        'total_answers': session['total_answers'],
        'timestamp': session['timestamp'],
      });
      await DatabaseHelper.instance.markSessionSynced(session['id'] as int);
    }
  }

  Future<void> _syncReminders(
    SupabaseClient client,
    String cloudPatientId,
  ) async {
    final reminders = await DatabaseHelper.instance.getUnsyncedReminders();
    for (final reminder in reminders) {
      // Upsert, not insert: a reminder can be re-synced more than once
      // (e.g. once as "pending", again later once marked done), and
      // local_id + patient_id together identify the same reminder each
      // time — without this, a second sync of the same row would just
      // create a duplicate in the cloud instead of updating it.
      await client.from('reminders').upsert({
        'patient_id': cloudPatientId,
        'local_id': reminder['id'],
        'type': reminder['type'],
        'scheduled_time': reminder['scheduled_time'],
        'status': reminder['status'],
        'completed_at': reminder['completed_at'],
      }, onConflict: 'patient_id,local_id');
      await DatabaseHelper.instance.markReminderSynced(reminder['id'] as int);
    }
  }
}
