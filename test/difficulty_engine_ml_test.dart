import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/difficulty/difficulty_engine.dart';

// Mirrors difficulty_engine_test.dart's scenarios so Tier 1 (the trained
// model) can be checked against the exact same cases Tier 0 (the
// hand-picked rule) was checked against — including the tier-1 regression
// case ("one mistake in 3 pairs") that mattered enough to get its own bug
// fix. Expected outcomes below were verified against the actual trained
// weights via ml/train_difficulty_model.py, not guessed.

Map<String, dynamic> _session({
  required int correct,
  required int total,
  required double responseTime,
}) {
  return {
    'correct_answers': correct,
    'total_answers': total,
    'response_time_seconds': responseTime,
  };
}

void main() {
  test('with no history, holds at the current tier', () {
    final tier = DifficultyEngine.nextTierML(
      currentTier: 3,
      recentSessions: [],
    );
    expect(tier, 3);
  });

  test('raises the tier when accuracy is high and answers are fast', () {
    final sessions = List.generate(
      5,
      (_) => _session(correct: 9, total: 10, responseTime: 3.0),
    );
    final tier = DifficultyEngine.nextTierML(
      currentTier: 2,
      recentSessions: sessions,
    );
    expect(tier, 3);
  });

  test(
      'raises the tier for a realistic near-perfect tier-1 round '
      '(one mistake in 3 pairs)', () {
    final sessions = List.generate(
      5,
      (_) => _session(correct: 3, total: 4, responseTime: 4.0),
    );
    final tier = DifficultyEngine.nextTierML(
      currentTier: 1,
      recentSessions: sessions,
    );
    expect(tier, 2);
  });

  test('does NOT raise the tier when accuracy is high but answers are slow',
      () {
    final sessions = List.generate(
      5,
      (_) => _session(correct: 9, total: 10, responseTime: 9.0),
    );
    final tier = DifficultyEngine.nextTierML(
      currentTier: 2,
      recentSessions: sessions,
    );
    expect(tier, 2);
  });

  test('lowers the tier when accuracy is poor', () {
    final sessions = List.generate(
      5,
      (_) => _session(correct: 2, total: 10, responseTime: 4.0),
    );
    final tier = DifficultyEngine.nextTierML(
      currentTier: 3,
      recentSessions: sessions,
    );
    expect(tier, 2);
  });

  test('holds steady for middling performance', () {
    final sessions = List.generate(
      5,
      (_) => _session(correct: 6, total: 10, responseTime: 4.0),
    );
    final tier = DifficultyEngine.nextTierML(
      currentTier: 3,
      recentSessions: sessions,
    );
    expect(tier, 3);
  });

  test('never rises above the maximum tier', () {
    final sessions = List.generate(
      5,
      (_) => _session(correct: 10, total: 10, responseTime: 1.0),
    );
    final tier = DifficultyEngine.nextTierML(
      currentTier: DifficultyEngine.maxTier,
      recentSessions: sessions,
    );
    expect(tier, DifficultyEngine.maxTier);
  });

  test('never drops below the minimum tier', () {
    final sessions = List.generate(
      5,
      (_) => _session(correct: 0, total: 10, responseTime: 4.0),
    );
    final tier = DifficultyEngine.nextTierML(
      currentTier: DifficultyEngine.minTier,
      recentSessions: sessions,
    );
    expect(tier, DifficultyEngine.minTier);
  });
}
