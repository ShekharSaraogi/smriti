import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/difficulty/difficulty_engine.dart';

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
    final tier = DifficultyEngine.nextTier(
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
    final tier = DifficultyEngine.nextTier(
      currentTier: 2,
      recentSessions: sessions,
    );
    expect(tier, 3);
  });

  test(
      'raises the tier for a realistic near-perfect tier-1 round '
      '(one mistake in 3 pairs)', () {
    // Regression test: 3 correct out of 4 attempts (one wrong guess) is
    // 75% — a genuinely strong round at the lowest tier, where a perfect
    // round is mostly luck since the first flips are always a guess. This
    // must still be enough to progress, or nobody ever leaves tier 1.
    final sessions = List.generate(
      5,
      (_) => _session(correct: 3, total: 4, responseTime: 4.0),
    );
    final tier = DifficultyEngine.nextTier(
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
    final tier = DifficultyEngine.nextTier(
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
    final tier = DifficultyEngine.nextTier(
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
    final tier = DifficultyEngine.nextTier(
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
    final tier = DifficultyEngine.nextTier(
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
    final tier = DifficultyEngine.nextTier(
      currentTier: DifficultyEngine.minTier,
      recentSessions: sessions,
    );
    expect(tier, DifficultyEngine.minTier);
  });
}
