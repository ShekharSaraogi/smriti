"""Trains Smriti's Tier 1 difficulty model.

Predicts whether the next round should be easier, the same, or harder,
given a patient's recent accuracy, average response time, and current
tier. Run with:

    py -3.12 ml/train_difficulty_model.py

There is no real player data yet (phone-to-cloud sync doesn't exist yet),
so this trains on simulated sessions instead. The "correct answer" for
each simulated session comes from Smriti's existing Tier 0 rule
(lib/difficulty/difficulty_engine.dart's nextTier: raise if accuracy is
at least 70% AND the average response time is at most 5 seconds, lower
if accuracy is 40% or below, otherwise hold), with some labels randomly
flipped to imitate how messy real behaviour is (a lucky guess, an off
day). The model then learns a smooth, continuous version of that same
human-designed rule instead of inventing its own notion of "good
performance" from nothing.

Once real sessions exist, point simulate_sessions() at exported real
data instead and retrain — the rest of the script (and the Dart side
that consumes its output) doesn't need to change.

Prints the learned weights as a ready-to-paste Dart snippet and saves
them to ml/difficulty_model_weights.json for reference.
"""

import json

import numpy as np
from sklearn.linear_model import LogisticRegression

RNG = np.random.default_rng(seed=42)
N_SAMPLES = 6000

# Order matters and must match the feature order used in Dart's
# DifficultyEngine.nextTierML.
FEATURE_NAMES = [
    "accuracy",
    "response_time / 10",
    "(tier - 1) / 4",
    "meets_both_thresholds",
]
CLASS_NAMES = ["lower", "hold", "raise"]


def _features(accuracy, response_time, current_tier):
    """Builds the feature vector for one session.

    The first three features are the raw, continuous inputs — these are
    where the model actually smooths things out: two rounds that both
    "hold" under the old rule (say 45% accuracy vs 65% accuracy) no longer
    look identical to it, and it can weigh tier level in too.

    The 4th feature is different on purpose: a plain logistic regression
    can only draw a straight-line boundary, and tried-and-tested smooth
    combinations of accuracy/speed still landed on the wrong side for
    rounds sitting just barely past BOTH thresholds at once (like exactly
    3-of-4 correct, answered reasonably fast — the case the tier-1 bug fix
    was about). So this one feature hands the model the exact rule
    directly: 1.0 when a round clears both thresholds together, 0.0
    otherwise. That guarantees that specific corner is never lost, while
    the other three features still do the real smoothing everywhere else.
    """
    meets_both = 1.0 if (accuracy >= 0.7 and response_time <= 5.0) else 0.0
    return [
        accuracy,
        response_time / 10.0,
        (current_tier - 1) / 4.0,
        meets_both,
    ]


def simulate_sessions(n):
    current_tier = RNG.integers(1, 6, size=n)  # 1..5 inclusive
    # Accuracy and response time are drawn independently (not both from one
    # "skill" score) so every combination — including "accurate but slow" —
    # shows up often enough in training for the model to actually learn
    # that raising requires BOTH, not accuracy alone.
    accuracy = RNG.uniform(0, 1, size=n)
    response_time = RNG.uniform(1, 12, size=n)

    raises = (accuracy >= 0.7) & (response_time <= 5.0)
    lowers = accuracy <= 0.4
    label = np.where(raises, 2, np.where(lowers, 0, 1))  # 0=lower,1=hold,2=raise

    # Flip 3% of labels to mimic real-world noise a hand-written rule
    # can't see (a good guess, a distraction, an off day). Kept fairly low:
    # this data is synthetic and IS the rule by construction, so the goal
    # is a model that recovers it faithfully and only smooths the sharp
    # corners a little — not one blurred by noise we invented ourselves.
    flip = RNG.random(n) < 0.03
    label = np.where(flip, RNG.integers(0, 3, size=n), label)

    meets_both = ((accuracy >= 0.7) & (response_time <= 5.0)).astype(float)
    features = np.column_stack(
        [accuracy, response_time / 10.0, (current_tier - 1) / 4.0, meets_both]
    )
    return features, label


# A few illustrative cases, matching the scenarios already covered by
# test/difficulty_engine_test.dart's Tier 0 tests, so the printed
# predictions can be copied straight into the Tier 1 Dart test file.
EXAMPLE_CASES = [
    ("high accuracy, fast (tier 2)", 0.90, 3.0, 2),
    ("one mistake in 3 pairs (tier 1)", 0.75, 4.0, 1),
    ("high accuracy but slow (tier 2)", 0.90, 9.0, 2),
    ("poor accuracy (tier 3)", 0.20, 4.0, 3),
    ("middling accuracy (tier 3)", 0.60, 4.0, 3),
    ("perfect at max tier (tier 5)", 1.00, 1.0, 5),
    ("zero accuracy at min tier (tier 1)", 0.00, 4.0, 1),
]


def main():
    x, y = simulate_sessions(N_SAMPLES)
    # Higher C = less regularization. The default (C=1) turned out to
    # over-smooth the sharp accuracy/speed corner enough to misjudge a case
    # we specifically care about getting right (see the "one mistake in 3
    # pairs" example below) — and since this data is the rule by
    # construction, fitting it tightly is what we want here.
    model = LogisticRegression(max_iter=2000, C=20)
    model.fit(x, y)

    agreement = model.score(x, y)
    print(f"Training agreement with the (noisy) rule-based labels: {agreement:.1%}\n")

    weights = model.coef_.tolist()  # shape (3 classes, 3 features)
    intercepts = model.intercept_.tolist()  # shape (3,)

    print("Weights (rows = classes, columns = features):")
    print("            " + "  ".join(f"{n:>18}" for n in FEATURE_NAMES))
    for class_name, row in zip(CLASS_NAMES, weights):
        print(f"  {class_name:>6}    " + "  ".join(f"{w:18.4f}" for w in row))
    print("Intercepts:")
    print("  " + "  ".join(f"{c}={b:.4f}" for c, b in zip(CLASS_NAMES, intercepts)))

    with open("ml/difficulty_model_weights.json", "w") as f:
        json.dump({"weights": weights, "intercepts": intercepts}, f, indent=2)

    print("\nDart snippet:\n")

    def row(vals):
        return "[" + ", ".join(f"{v:.6f}" for v in vals) + "]"

    print("  static const List<List<double>> _mlWeights = [")
    for r in weights:
        print(f"    {row(r)},")
    print("  ];")
    print(f"  static const List<double> _mlIntercepts = {row(intercepts)};")

    print("\nExample predictions (for the Tier 1 Dart test file):")
    for label, accuracy, response_time, current_tier in EXAMPLE_CASES:
        features = np.array([_features(accuracy, response_time, current_tier)])
        predicted_class = int(model.predict(features)[0])
        delta = predicted_class - 1
        next_tier = min(5, max(1, current_tier + delta))
        print(
            f"  {label}: accuracy={accuracy}, response_time={response_time}, "
            f"current_tier={current_tier} -> {CLASS_NAMES[predicted_class]} "
            f"-> next_tier={next_tier}"
        )


if __name__ == "__main__":
    main()
