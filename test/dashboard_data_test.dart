import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/dashboard/dashboard_data.dart';

const _patient = Patient(id: 'p1', name: 'Test Patient');

Map<String, dynamic> _session({
  required String gameType,
  required String daysAgoFromNow,
  required double accuracy,
  int tier = 1,
}) {
  return {
    'game_type': gameType,
    'difficulty_tier': tier,
    'accuracy': accuracy,
    'timestamp': daysAgoFromNow,
  };
}

void main() {
  final now = DateTime(2026, 9, 10, 12); // fixed reference instant

  String isoDaysAgo(int days) =>
      now.subtract(Duration(days: days)).toIso8601String();

  group('day streak', () {
    test('is 0 with no sessions', () {
      final snapshot = DashboardDataService.build(
        patient: _patient,
        unsortedSessions: [],
        reminders: [],
        now: now,
      );
      expect(snapshot.dayStreak, 0);
    });

    test('counts consecutive days including today', () {
      final sessions = [
        _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(0), accuracy: 0.8),
        _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(1), accuracy: 0.8),
        _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(2), accuracy: 0.8),
      ];
      final snapshot = DashboardDataService.build(
        patient: _patient,
        unsortedSessions: sessions,
        reminders: [],
        now: now,
      );
      expect(snapshot.dayStreak, 3);
    });

    test('stops counting at a gap', () {
      final sessions = [
        _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(0), accuracy: 0.8),
        _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(1), accuracy: 0.8),
        // gap at day 2
        _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(3), accuracy: 0.8),
      ];
      final snapshot = DashboardDataService.build(
        patient: _patient,
        unsortedSessions: sessions,
        reminders: [],
        now: now,
      );
      expect(snapshot.dayStreak, 2);
    });

    test('is 0 once the most recent play day is more than 1 day old', () {
      final sessions = [
        _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(3), accuracy: 0.8),
      ];
      final snapshot = DashboardDataService.build(
        patient: _patient,
        unsortedSessions: sessions,
        reminders: [],
        now: now,
      );
      expect(snapshot.dayStreak, 0);
    });

    test('still counts as alive if the last play was yesterday', () {
      final sessions = [
        _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(1), accuracy: 0.8),
        _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(2), accuracy: 0.8),
      ];
      final snapshot = DashboardDataService.build(
        patient: _patient,
        unsortedSessions: sessions,
        reminders: [],
        now: now,
      );
      expect(snapshot.dayStreak, 2);
    });
  });

  test('7-day trend always has exactly 7 points, oldest to newest', () {
    final snapshot = DashboardDataService.build(
      patient: _patient,
      unsortedSessions: [
        _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(0), accuracy: 1.0),
      ],
      reminders: [],
      now: now,
    );
    final today = DateTime(now.year, now.month, now.day);
    expect(snapshot.last7DayTrend, hasLength(7));
    expect(
      snapshot.last7DayTrend.first.day,
      today.subtract(const Duration(days: 6)),
    );
    expect(snapshot.last7DayTrend.last.day, today);
    expect(snapshot.last7DayTrend.last.accuracy, 1.0);
    expect(snapshot.last7DayTrend.first.sessionCount, 0);
  });

  test('per-game summary averages only that game\'s recent sessions', () {
    final sessions = [
      _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(0), accuracy: 1.0, tier: 3),
      _session(gameType: 'memory_match', daysAgoFromNow: isoDaysAgo(1), accuracy: 0.5, tier: 2),
      _session(gameType: 'attention_sweep', daysAgoFromNow: isoDaysAgo(0), accuracy: 0.2, tier: 1),
    ];
    final snapshot = DashboardDataService.build(
      patient: _patient,
      unsortedSessions: sessions,
      reminders: [],
      now: now,
    );
    final memoryMatch =
        snapshot.gameSummaries.firstWhere((g) => g.gameType == 'memory_match');
    expect(memoryMatch.sessionsLast7Days, 2);
    expect(memoryMatch.last7DayAccuracy, closeTo(0.75, 0.001));
    // Most recent session for that game, not the highest.
    expect(memoryMatch.currentTier, 3);

    final attentionSweep = snapshot.gameSummaries
        .firstWhere((g) => g.gameType == 'attention_sweep');
    expect(attentionSweep.last7DayAccuracy, closeTo(0.2, 0.001));
  });

  test('reminders split into upcoming vs missed', () {
    final reminders = [
      {
        'type': 'medicine',
        'status': 'pending',
        'scheduled_time': now.add(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'type': 'medicine',
        'status': 'pending',
        'scheduled_time': now.subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        // Already completed — should be excluded from both lists.
        'type': 'medicine',
        'status': 'completed',
        'scheduled_time': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];
    final snapshot = DashboardDataService.build(
      patient: _patient,
      unsortedSessions: [],
      reminders: reminders,
      now: now,
    );
    expect(snapshot.upcomingReminders, hasLength(1));
    expect(snapshot.missedReminders, hasLength(1));
  });
}
