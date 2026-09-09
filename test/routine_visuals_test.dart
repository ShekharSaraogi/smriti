import 'package:flutter_test/flutter_test.dart';

import 'package:smriti/utils/routine_visuals.dart';

void main() {
  test('matches common routine steps to a relevant picture', () {
    expect(routineStepEmoji('Wake up'), '🛏️');
    expect(routineStepEmoji('Brush teeth'), '🪥');
    expect(routineStepEmoji('Take morning medicine'), '💊');
    expect(routineStepEmoji('Breakfast'), '🍽️');
    expect(routineStepEmoji('Morning walk'), '🚶');
    expect(routineStepEmoji('Evening prayer'), '🙏');
  });

  test('matching is case-insensitive', () {
    expect(routineStepEmoji('TAKE MEDICINE'), routineStepEmoji('take medicine'));
  });

  test('falls back to a neutral marker for an unrecognized step', () {
    expect(routineStepEmoji('Feed the fish'), '📝');
  });
}
