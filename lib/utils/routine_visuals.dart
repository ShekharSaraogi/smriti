// Maps a caregiver's free-typed routine step (e.g. "Take morning medicine")
// to a real-life picture. A picture-based daily schedule is a well-known
// memory aid for dementia patients — matching each step to a recognizable
// object or action makes Routine Recall (and the routine entry form) read
// as a picture schedule instead of a plain text quiz.
//
// Keyword matching, not a fixed lookup table, because the routine text is
// whatever the caregiver typed — there's no way to know the exact steps in
// advance. Order matters: more specific checks (e.g. "medicine") come
// before broader ones so a step like "Take a walk" doesn't get swallowed by
// a generic "take" rule that doesn't exist, but similar overlaps elsewhere
// are avoided by checking the most distinctive keyword for each concept.
String routineStepEmoji(String step) {
  final s = step.toLowerCase();

  if (s.contains('wake') || s.contains('sleep') || s.contains('bed')) {
    return '🛏️';
  }
  if (s.contains('brush') || s.contains('teeth')) return '🪥';
  if (s.contains('bath') || s.contains('shower') || s.contains('wash')) {
    return '🚿';
  }
  if (s.contains('medicine') || s.contains('pill') || s.contains('tablet')) {
    return '💊';
  }
  if (s.contains('breakfast') ||
      s.contains('lunch') ||
      s.contains('dinner') ||
      s.contains('meal') ||
      s.contains('eat') ||
      s.contains('food')) {
    return '🍽️';
  }
  if (s.contains('tea') || s.contains('coffee')) return '☕';
  if (s.contains('water') || s.contains('drink')) return '💧';
  if (s.contains('walk') || s.contains('exercise') || s.contains('yoga')) {
    return '🚶';
  }
  if (s.contains('dress') || s.contains('cloth')) return '👕';
  if (s.contains('pray') || s.contains('temple')) return '🙏';
  if (s.contains('tv') || s.contains('news') || s.contains('read')) {
    return '📖';
  }
  if (s.contains('nap') || s.contains('rest')) return '😴';
  if (s.contains('phone') || s.contains('call')) return '📞';
  if (s.contains('garden') || s.contains('plant')) return '🌱';

  // No keyword matched — still a real step in the routine, just shown with
  // a plain, neutral marker rather than guessing wrong.
  return '📝';
}
