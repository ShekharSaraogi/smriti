import '../db/database_helper.dart';

class DifficultyEngine {
  static const minTier = 1;
  static const maxTier = 5;

  // Raise the tier if the patient is doing well AND answering quickly;
  // lower it if they're struggling; otherwise leave it alone. Pure logic,
  // no database access — this is what makes it easy to test thoroughly.
  static int nextTier({
    required int currentTier,
    required List<Map<String, dynamic>> recentSessions,
  }) {
    if (recentSessions.isEmpty) return currentTier.clamp(minTier, maxTier);

    var totalCorrect = 0;
    var totalAnswers = 0;
    var totalResponseTime = 0.0;
    for (final session in recentSessions) {
      totalCorrect += session['correct_answers'] as int;
      totalAnswers += session['total_answers'] as int;
      totalResponseTime += session['response_time_seconds'] as double;
    }

    final accuracy = totalCorrect / totalAnswers;
    final avgResponseTime = totalResponseTime / recentSessions.length;

    int newTier;
    // The PRD's own pseudocode suggests 80%, but that's unreachable at the
    // lowest tier: with only 3 pairs, a single wrong guess already caps
    // accuracy at 3/4 = 75% for the whole round — and the very first two
    // cards flipped on an unseen board are inherently a guess, so a
    // genuinely perfect round is mostly luck, not skill. 70% still rewards
    // strong play (one mistake is fine; two usually isn't) without
    // requiring a flawless round just to progress past tier 1.
    if (accuracy >= 0.7 && avgResponseTime <= 5.0) {
      newTier = currentTier + 1;
    } else if (accuracy <= 0.4) {
      newTier = currentTier - 1;
    } else {
      newTier = currentTier;
    }

    return newTier.clamp(minTier, maxTier);
  }

  // Looks up a patient's real history for [gameType] and returns the tier
  // their next round should be played at.
  static Future<int> tierForPatient({
    required int patientId,
    required String gameType,
  }) async {
    final recentSessions = await DatabaseHelper.instance.getRecentSessions(
      patientId,
      gameType,
      limit: 5,
    );

    final currentTier = recentSessions.isEmpty
        ? minTier
        : recentSessions.first['difficulty_tier'] as int;

    return nextTierML(currentTier: currentTier, recentSessions: recentSessions);
  }

  // Tier 1: a multinomial logistic regression trained on simulated session
  // data (see ml/train_difficulty_model.py) that picks one of three
  // classes — lower, hold, raise — in place of nextTier's hand-picked
  // thresholds. There's no real player history yet (nothing syncs to the
  // cloud yet), so the training data is synthetic: it's generated FROM
  // nextTier's own rule with a little noise mixed in, so what this has
  // actually learned is a smoothed version of that same rule, not
  // something invented from nothing. Once real session data exists (after
  // phone-to-cloud sync is built), re-run the training script against that
  // instead and paste in the new weights below.
  //
  // Rows are [lower, hold, raise]; columns match the feature order built
  // in nextTierML below (accuracy, response_time / 10, (tier - 1) / 4,
  // meets_both_thresholds).
  static const List<List<double>> _mlWeights = [
    [-11.150731, 0.051372, -0.000146, 2.390075],
    [10.360111, -0.039330, -0.146440, -7.469446],
    [0.790619, -0.012042, 0.146586, 5.079371],
  ];
  static const List<double> _mlIntercepts = [5.341514, -3.152762, -2.188752];

  static int nextTierML({
    required int currentTier,
    required List<Map<String, dynamic>> recentSessions,
  }) {
    if (recentSessions.isEmpty) return currentTier.clamp(minTier, maxTier);

    var totalCorrect = 0;
    var totalAnswers = 0;
    var totalResponseTime = 0.0;
    for (final session in recentSessions) {
      totalCorrect += session['correct_answers'] as int;
      totalAnswers += session['total_answers'] as int;
      totalResponseTime += session['response_time_seconds'] as double;
    }

    final accuracy = totalCorrect / totalAnswers;
    final avgResponseTime = totalResponseTime / recentSessions.length;
    // The model gets one feature that isn't a raw continuous value: whether
    // this round already clears both of nextTier's old thresholds at once.
    // A straight-line model can't otherwise carve out that exact corner —
    // see the training script for the full explanation — so this feature
    // guarantees cases like "3 correct out of 4" at a fast pace still
    // count as a clear raise, while the other three features still let the
    // model smooth everything else (e.g. 45% vs 65% accuracy no longer
    // look identical the way they do to nextTier).
    final meetsBothThresholds =
        (accuracy >= 0.7 && avgResponseTime <= 5.0) ? 1.0 : 0.0;

    final features = [
      accuracy,
      avgResponseTime / 10.0,
      (currentTier - 1) / 4.0,
      meetsBothThresholds,
    ];

    // One score per class (0=lower, 1=hold, 2=raise): each is a weighted
    // sum of the features plus that class's intercept. Whichever class
    // scores highest wins — that's the same answer softmax would give
    // after turning these into probabilities, so there's no need to
    // actually exponentiate anything just to find the winner.
    var bestClass = 0;
    var bestScore = double.negativeInfinity;
    for (var classIndex = 0; classIndex < _mlWeights.length; classIndex++) {
      var score = _mlIntercepts[classIndex];
      for (var i = 0; i < features.length; i++) {
        score += _mlWeights[classIndex][i] * features[i];
      }
      if (score > bestScore) {
        bestScore = score;
        bestClass = classIndex;
      }
    }

    final tierChange = bestClass - 1; // class 1 (hold) means no change
    return (currentTier + tierChange).clamp(minTier, maxTier);
  }
}
