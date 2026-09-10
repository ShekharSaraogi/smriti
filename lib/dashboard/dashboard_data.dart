import 'package:supabase_flutter/supabase_flutter.dart';

class Patient {
  final String id;
  final String name;
  const Patient({required this.id, required this.name});
}

class DailyPoint {
  final DateTime day;
  final double accuracy; // 0-1, average across all games that day
  final int sessionCount;
  const DailyPoint({
    required this.day,
    required this.accuracy,
    required this.sessionCount,
  });
}

class GameSummary {
  final String gameType;
  final int currentTier;
  final double last7DayAccuracy; // 0-1
  final int sessionsLast7Days;
  const GameSummary({
    required this.gameType,
    required this.currentTier,
    required this.last7DayAccuracy,
    required this.sessionsLast7Days,
  });
}

// One row straight out of game_sessions, close to unmodified — the point
// of surfacing this alongside the aggregated stats is to show a caregiver
// (and anyone watching over their shoulder) the actual individual events
// arriving from the phone, not just numbers that have already been
// averaged away.
class SessionEntry {
  final String gameType;
  final int difficultyTier;
  final double accuracy; // 0-1
  final double responseTimeSeconds;
  final int correctAnswers;
  final int totalAnswers;
  final DateTime timestamp;
  const SessionEntry({
    required this.gameType,
    required this.difficultyTier,
    required this.accuracy,
    required this.responseTimeSeconds,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.timestamp,
  });
}

class ReminderInfo {
  final String type;
  final DateTime scheduledTime;
  final bool isMissed;
  const ReminderInfo({
    required this.type,
    required this.scheduledTime,
    required this.isMissed,
  });
}

class DashboardSnapshot {
  final Patient patient;
  final int dayStreak;
  final double last7DayAccuracy; // 0-1, across all games
  final int sessionsLast7Days;
  final List<DailyPoint> last7DayTrend; // oldest to newest, always 7 entries
  final List<GameSummary> gameSummaries;
  final List<ReminderInfo> upcomingReminders;
  final List<ReminderInfo> missedReminders;
  // Newest first, capped at 15 — the individual events behind the
  // aggregated numbers above, so the dashboard can show a live activity
  // feed rather than only pre-averaged stats.
  final List<SessionEntry> recentActivity;
  final DateTime fetchedAt;
  const DashboardSnapshot({
    required this.patient,
    required this.dayStreak,
    required this.last7DayAccuracy,
    required this.sessionsLast7Days,
    required this.last7DayTrend,
    required this.gameSummaries,
    required this.upcomingReminders,
    required this.missedReminders,
    required this.recentActivity,
    required this.fetchedAt,
  });
}

// All the actual network I/O lives here; the math lives in build(), which
// takes plain data and has no dependency on Supabase at all — so the math
// can be unit tested with made-up data, without a live connection.
class DashboardDataService {
  static Future<List<Patient>> fetchPatients() async {
    final rows = await Supabase.instance.client
        .from('patients')
        .select('id, name, created_at')
        .order('created_at');
    return rows
        .map((row) => Patient(id: row['id'] as String, name: row['name'] as String))
        .toList();
  }

  static Future<DashboardSnapshot> fetchSnapshot(Patient patient) async {
    final client = Supabase.instance.client;
    final sessions = await client
        .from('game_sessions')
        .select()
        .eq('patient_id', patient.id)
        .order('timestamp');
    final reminders = await client
        .from('reminders')
        .select()
        .eq('patient_id', patient.id)
        .order('scheduled_time');

    return build(
      patient: patient,
      unsortedSessions: List<Map<String, dynamic>>.from(sessions),
      reminders: List<Map<String, dynamic>>.from(reminders),
    );
  }

  static DashboardSnapshot build({
    required Patient patient,
    required List<Map<String, dynamic>> unsortedSessions,
    required List<Map<String, dynamic>> reminders,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    // "Current tier" below picks the most recent session via .last, which
    // only means anything if this list is ordered oldest-to-newest.
    // fetchSnapshot's own query already asks Supabase for that order, but
    // sorting here too means build() gives a correct answer regardless of
    // what order a caller (including a test) happens to pass in.
    final sessions = [...unsortedSessions]
      ..sort(
        (a, b) => DateTime.parse(a['timestamp'] as String)
            .compareTo(DateTime.parse(b['timestamp'] as String)),
      );

    final sessionDays = sessions
        .map((s) => _dateOnly(DateTime.parse(s['timestamp'] as String)))
        .toSet();

    final last7DayTrend = <DailyPoint>[];
    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final daySessions = sessions.where(
        (s) => _dateOnly(DateTime.parse(s['timestamp'] as String)) == day,
      );
      final accuracies = daySessions.map((s) => (s['accuracy'] as num).toDouble());
      last7DayTrend.add(
        DailyPoint(
          day: day,
          accuracy: accuracies.isEmpty
              ? 0
              : accuracies.reduce((a, b) => a + b) / accuracies.length,
          sessionCount: daySessions.length,
        ),
      );
    }

    final last7DaysCutoff = today.subtract(const Duration(days: 6));
    final recentSessions = sessions.where(
      (s) => !_dateOnly(DateTime.parse(s['timestamp'] as String))
          .isBefore(last7DaysCutoff),
    );
    final recentAccuracies =
        recentSessions.map((s) => (s['accuracy'] as num).toDouble()).toList();

    final gameSummaries = <GameSummary>[];
    for (final gameType in {
      'memory_match',
      'pattern_voice',
      'attention_sweep',
      'routine_recall',
    }) {
      final gameSessions =
          sessions.where((s) => s['game_type'] == gameType).toList();
      final gameRecent = gameSessions.where(
        (s) => !_dateOnly(DateTime.parse(s['timestamp'] as String))
            .isBefore(last7DaysCutoff),
      );
      final gameRecentAccuracies =
          gameRecent.map((s) => (s['accuracy'] as num).toDouble()).toList();
      gameSummaries.add(
        GameSummary(
          gameType: gameType,
          currentTier: gameSessions.isEmpty
              ? 1
              : gameSessions.last['difficulty_tier'] as int,
          last7DayAccuracy: gameRecentAccuracies.isEmpty
              ? 0
              : gameRecentAccuracies.reduce((a, b) => a + b) /
                  gameRecentAccuracies.length,
          sessionsLast7Days: gameRecent.length,
        ),
      );
    }

    final upcomingReminders = <ReminderInfo>[];
    final missedReminders = <ReminderInfo>[];
    for (final reminder in reminders) {
      if (reminder['status'] != 'pending') continue;
      final scheduledTime = DateTime.parse(reminder['scheduled_time'] as String);
      final info = ReminderInfo(
        type: reminder['type'] as String,
        scheduledTime: scheduledTime,
        isMissed: scheduledTime.isBefore(now ?? DateTime.now()),
      );
      (info.isMissed ? missedReminders : upcomingReminders).add(info);
    }

    // Tolerant of missing fields (e.g. handwritten test fixtures, or any
    // legacy row from before a column existed) — this feed is a nice-to-
    // have activity view, not something that should crash the whole
    // dashboard over one incomplete row.
    final recentActivity = sessions.reversed
        .take(15)
        .map(
          (s) => SessionEntry(
            gameType: s['game_type'] as String,
            difficultyTier: (s['difficulty_tier'] as num?)?.toInt() ?? 1,
            accuracy: (s['accuracy'] as num?)?.toDouble() ?? 0,
            responseTimeSeconds:
                (s['response_time_seconds'] as num?)?.toDouble() ?? 0,
            correctAnswers: (s['correct_answers'] as num?)?.toInt() ?? 0,
            totalAnswers: (s['total_answers'] as num?)?.toInt() ?? 0,
            timestamp: DateTime.parse(s['timestamp'] as String),
          ),
        )
        .toList();

    return DashboardSnapshot(
      patient: patient,
      dayStreak: _computeStreak(sessionDays, today),
      last7DayAccuracy: recentAccuracies.isEmpty
          ? 0
          : recentAccuracies.reduce((a, b) => a + b) / recentAccuracies.length,
      sessionsLast7Days: recentSessions.length,
      last7DayTrend: last7DayTrend,
      gameSummaries: gameSummaries,
      upcomingReminders: upcomingReminders,
      missedReminders: missedReminders,
      recentActivity: recentActivity,
      fetchedAt: now ?? DateTime.now(),
    );
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // Consecutive days with at least one session, counting back from the most
  // recent day played. A streak is only "alive" if that most recent day was
  // today or yesterday — anything older means it's already lapsed.
  static int _computeStreak(Set<DateTime> sessionDays, DateTime today) {
    if (sessionDays.isEmpty) return 0;
    final mostRecent = sessionDays.reduce((a, b) => a.isAfter(b) ? a : b);
    if (today.difference(mostRecent).inDays > 1) return 0;

    var streak = 0;
    var cursor = mostRecent;
    while (sessionDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
