// Detects whether a patient's cognitive performance is trending up, down,
// or holding steady over time.
//
// This is a genuinely different problem from the patient app's difficulty
// engine (lib/difficulty/difficulty_engine.dart). The difficulty engine is
// tactical and short-term: it looks at the single most recent round and
// decides what tier the *next* round should be. This is strategic and
// long-term: it looks across weeks of history and decides whether the
// patient's underlying ability is drifting — which is the actual early-
// warning signal a caregiver or doctor cares about, not "what level are
// they on right now."
//
// Pure math, no I/O, no Supabase — same philosophy as
// DashboardDataService.build() in dashboard_data.dart: this takes plain
// data in and returns a plain verdict out, so it can be unit tested with
// made-up histories and never needs a live connection.
class PerformancePoint {
  final DateTime timestamp;
  final int difficultyTier;
  final double accuracy; // 0-1
  const PerformancePoint({
    required this.timestamp,
    required this.difficultyTier,
    required this.accuracy,
  });
}

enum TrendDirection { declining, stable, improving, insufficientData }

class CognitiveTrend {
  final TrendDirection direction;
  // Change in "performance score" (see _scoreOf below) per week. Only
  // meaningful when direction isn't insufficientData.
  final double slopePerWeek;
  final int sessionsAnalyzed;
  final int daysSpanned;

  const CognitiveTrend({
    required this.direction,
    required this.slopePerWeek,
    required this.sessionsAnalyzed,
    required this.daysSpanned,
  });

  static const insufficientData = CognitiveTrend(
    direction: TrendDirection.insufficientData,
    slopePerWeek: 0,
    sessionsAnalyzed: 0,
    daysSpanned: 0,
  );

  // A caregiver-facing sentence. Plain language on purpose — a caregiver
  // opening this dashboard wants an answer, not a slope coefficient.
  String get message {
    switch (direction) {
      case TrendDirection.insufficientData:
        return 'Not enough history yet to spot a trend — check back after '
            'a few more days of play.';
      case TrendDirection.declining:
        return 'Performance has been trending down over the last few '
            'weeks. Worth mentioning at the next check-up.';
      case TrendDirection.improving:
        return 'Performance has been trending up over the last few weeks.';
      case TrendDirection.stable:
        return 'Performance has stayed steady over the last few weeks.';
    }
  }
}

class DeclineDetector {
  DeclineDetector._();

  // Below this many sessions, a trend line is just connecting noise —
  // not a real minimum from a clinical study, but a sane guard against a
  // brand-new patient with 2 sessions getting a confident-sounding
  // "declining" verdict off nothing.
  static const _minSessions = 6;

  // The sessions also need to actually be spread out in time, not just
  // "6 rounds played back-to-back this afternoon" — a trend needs days to
  // trend across.
  static const _minDaySpan = 5;

  // A change smaller than this many score-points per week is treated as
  // day-to-day wobble, not a real trend. Worked backwards from a concrete
  // example: an accuracy drop from 95% to 55% over 3 weeks — a genuinely
  // worrying decline, not noise — works out to about -0.13 score-points
  // per week. 0.1 sits comfortably below that while still being well
  // above the ~0.01/week that pure day-to-day noise produces in practice.
  // A starting threshold, not a clinical constant — worth revisiting once
  // real pilot data shows what normal week-to-week wobble actually looks
  // like for an actual patient.
  static const _significantSlopePerWeek = 0.1;

  static CognitiveTrend analyze(
    List<PerformancePoint> sessions, {
    DateTime? now,
  }) {
    if (sessions.length < _minSessions) return CognitiveTrend.insufficientData;

    final sorted = [...sessions]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final firstDay = _dateOnly(sorted.first.timestamp);
    final lastDay = _dateOnly(sorted.last.timestamp);
    final daySpan = lastDay.difference(firstDay).inDays;
    if (daySpan < _minDaySpan) return CognitiveTrend.insufficientData;

    // x = days since the first session in the window; y = a single
    // "how well did they do" number per session (see _scoreOf). Feeding
    // this pair into a standard "best-fit straight line" calculation
    // (ordinary least squares) gives a slope: is that line going up,
    // down, or flat.
    final xs = <double>[];
    final ys = <double>[];
    for (final s in sorted) {
      xs.add(_dateOnly(s.timestamp).difference(firstDay).inDays.toDouble());
      ys.add(_scoreOf(s));
    }

    final slopePerDay = _olsSlope(xs, ys);
    if (slopePerDay == null) return CognitiveTrend.insufficientData;
    final slopePerWeek = slopePerDay * 7;

    final direction = slopePerWeek <= -_significantSlopePerWeek
        ? TrendDirection.declining
        : slopePerWeek >= _significantSlopePerWeek
            ? TrendDirection.improving
            : TrendDirection.stable;

    return CognitiveTrend(
      direction: direction,
      slopePerWeek: slopePerWeek,
      sessionsAnalyzed: sorted.length,
      daysSpanned: daySpan,
    );
  }

  // Raw accuracy alone is a misleading measure of ability here, because
  // the difficulty engine is constantly moving the goalposts: a patient
  // who's improving gets bumped to a harder tier, where their accuracy
  // naturally dips a little even though they're doing *better* overall.
  // Adding the tier itself to the accuracy folds the difficulty back in,
  // so "tier 4 at 70%" correctly scores higher than "tier 1 at 95%" —
  // both signals move the same score in the same direction instead of
  // fighting each other.
  static double _scoreOf(PerformancePoint s) => s.difficultyTier + s.accuracy;

  // Ordinary least squares: the standard formula for "the straight line
  // that best fits these points." slope = how much y changes per unit of
  // x, on average, along that best-fit line.
  //
  //   slope = Σ((x - mean_x)(y - mean_y)) / Σ((x - mean_x)²)
  //
  // Returns null if every x is identical (all sessions on the same day),
  // which would divide by zero — guarded in practice by the day-span
  // check above, but safe regardless.
  static double? _olsSlope(List<double> xs, List<double> ys) {
    final n = xs.length;
    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = ys.reduce((a, b) => a + b) / n;
    var numerator = 0.0;
    var denominator = 0.0;
    for (var i = 0; i < n; i++) {
      numerator += (xs[i] - meanX) * (ys[i] - meanY);
      denominator += (xs[i] - meanX) * (xs[i] - meanX);
    }
    if (denominator == 0) return null;
    return numerator / denominator;
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
