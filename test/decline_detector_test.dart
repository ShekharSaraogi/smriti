import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/dashboard/decline_detector.dart';

// Builds one session per day, starting [daysAgo] days before [now], with
// accuracy following a straight line from [startAccuracy] to
// [endAccuracy] — the simplest possible "clearly trending" fixture.
List<PerformancePoint> _sessionsOverDays({
  required DateTime now,
  required int daysAgo,
  required double startAccuracy,
  required double endAccuracy,
  int tier = 2,
}) {
  final points = <PerformancePoint>[];
  for (var i = 0; i <= daysAgo; i++) {
    final progress = i / daysAgo;
    final accuracy = startAccuracy + (endAccuracy - startAccuracy) * progress;
    points.add(
      PerformancePoint(
        timestamp: now.subtract(Duration(days: daysAgo - i)),
        difficultyTier: tier,
        accuracy: accuracy,
      ),
    );
  }
  return points;
}

void main() {
  final now = DateTime(2026, 3, 1);

  test('too few sessions is insufficient data, even if they look fine', () {
    final points = [
      PerformancePoint(timestamp: now, difficultyTier: 3, accuracy: 0.9),
      PerformancePoint(
        timestamp: now.subtract(const Duration(days: 1)),
        difficultyTier: 3,
        accuracy: 0.9,
      ),
    ];
    expect(
      DeclineDetector.analyze(points, now: now).direction,
      TrendDirection.insufficientData,
    );
  });

  test('enough sessions but all on one day is insufficient data', () {
    final points = List.generate(
      8,
      (i) => PerformancePoint(timestamp: now, difficultyTier: 3, accuracy: 0.8),
    );
    expect(
      DeclineDetector.analyze(points, now: now).direction,
      TrendDirection.insufficientData,
    );
  });

  test('accuracy dropping steadily over weeks is flagged as declining', () {
    final points = _sessionsOverDays(
      now: now,
      daysAgo: 20,
      startAccuracy: 0.95,
      endAccuracy: 0.55,
    );
    final trend = DeclineDetector.analyze(points, now: now);
    expect(trend.direction, TrendDirection.declining);
    expect(trend.slopePerWeek, lessThan(0));
  });

  test('accuracy climbing steadily over weeks is flagged as improving', () {
    final points = _sessionsOverDays(
      now: now,
      daysAgo: 20,
      startAccuracy: 0.5,
      endAccuracy: 0.95,
    );
    final trend = DeclineDetector.analyze(points, now: now);
    expect(trend.direction, TrendDirection.improving);
    expect(trend.slopePerWeek, greaterThan(0));
  });

  test('roughly flat accuracy is stable, not a false alarm', () {
    final points = _sessionsOverDays(
      now: now,
      daysAgo: 20,
      startAccuracy: 0.8,
      endAccuracy: 0.82,
    );
    expect(
      DeclineDetector.analyze(points, now: now).direction,
      TrendDirection.stable,
    );
  });

  test(
      'rising tier offsets a same-size accuracy dip — the difficulty '
      'adjustment doing its job', () {
    // Accuracy alone looks like a decline (95% -> 60%), but the patient
    // also climbed from tier 1 to tier 4 over the same stretch — a sign
    // they're being challenged more, not doing worse. The combined score
    // (tier + accuracy) should net out close to flat rather than reading
    // as a straightforward decline.
    final now2 = DateTime(2026, 3, 1);
    final points = <PerformancePoint>[];
    for (var i = 0; i <= 20; i++) {
      final progress = i / 20;
      points.add(
        PerformancePoint(
          timestamp: now2.subtract(Duration(days: 20 - i)),
          difficultyTier: 1 + (progress * 3).round(),
          accuracy: 0.95 - (0.35 * progress),
        ),
      );
    }
    final trend = DeclineDetector.analyze(points, now: now2);
    expect(trend.direction, isNot(TrendDirection.declining));
  });

  test('reports how much data it actually analyzed', () {
    final points = _sessionsOverDays(
      now: now,
      daysAgo: 10,
      startAccuracy: 0.8,
      endAccuracy: 0.8,
    );
    final trend = DeclineDetector.analyze(points, now: now);
    expect(trend.sessionsAnalyzed, points.length);
    expect(trend.daysSpanned, 10);
  });
}
