import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smriti/screens/attention_sweep_screen.dart';

Finder _cell(int index) => find.byKey(ValueKey('cell_$index'));

Future<void> _pumpGame(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: AttentionSweepScreen()),
  );
  // The board deals synchronously in initState, so it's already on screen
  // right after pumpWidget. initState also kicks off a background tier
  // lookup that this screen deliberately doesn't block on; runAsync gives
  // it a real-time window to finish quietly so it doesn't leave a dangling
  // database timer at teardown.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump();
}

/// Finds which cell is currently the odd one out by inspecting the icons.
int _findOddCell(WidgetTester tester, int cellCount) {
  for (var i = 0; i < cellCount; i++) {
    final icon = tester.widget<Icon>(
      find.descendant(of: _cell(i), matching: find.byType(Icon)),
    );
    if (icon.icon == Icons.star) return i;
  }
  throw StateError('No odd cell found among $cellCount cells');
}

void main() {
  testWidgets('starts at tier 1 with 4 cells and a 8s timer',
      (WidgetTester tester) async {
    await _pumpGame(tester);

    expect(find.text('Round 1 of 5  •  Level 1'), findsOneWidget);
    expect(find.text('Time left: 8 s'), findsOneWidget);
    expect(find.byType(GestureDetector), findsNWidgets(4));
  });

  testWidgets('tapping the odd cell counts as correct and advances',
      (WidgetTester tester) async {
    await _pumpGame(tester);

    final oddIndex = _findOddCell(tester, 4);
    await tester.tap(_cell(oddIndex));
    await tester.pump();

    expect(find.text('Correct!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    expect(find.text('Round 2 of 5  •  Level 1'), findsOneWidget);
  });

  testWidgets('tapping a non-odd cell counts as wrong and advances',
      (WidgetTester tester) async {
    await _pumpGame(tester);

    final oddIndex = _findOddCell(tester, 4);
    final wrongIndex = (oddIndex + 1) % 4;
    await tester.tap(_cell(wrongIndex));
    await tester.pump();

    expect(find.text('Not quite — next one'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    expect(find.text('Round 2 of 5  •  Level 1'), findsOneWidget);
  });

  testWidgets('running out of time counts as a timeout and advances',
      (WidgetTester tester) async {
    await _pumpGame(tester);

    await tester.pump(const Duration(seconds: 8));
    expect(find.text("Time's up — next one"), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    expect(find.text('Round 2 of 5  •  Level 1'), findsOneWidget);
  });

  testWidgets('completing all 5 rounds shows the completion dialog',
      (WidgetTester tester) async {
    await _pumpGame(tester);

    for (var round = 0; round < 5; round++) {
      final oddIndex = _findOddCell(tester, 4);
      await tester.tap(_cell(oddIndex));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 950));
    }

    expect(find.text('Well done!'), findsOneWidget);
    expect(find.text('You got 5 of 5 correct.'), findsOneWidget);
  });
}
