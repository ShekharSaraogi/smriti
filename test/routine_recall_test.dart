import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smriti/db/database_helper.dart';
import 'package:smriti/screens/routine_recall_screen.dart';

const _routine = [
  'Wake up',
  'Breakfast',
  'Take morning medicine',
  'Morning walk',
  'Lunch',
];

// sqflite_common_ffi talks to a real background isolate, which the fake
// test clock a testWidgets body normally runs under can't service —
// hence runAsync here, same reason _pumpGame below needs it. This has to
// happen BEFORE pumping the widget, since the widget reads back whatever
// routine is seeded here.
Future<void> _seedRoutine(WidgetTester tester, List<String> steps) async {
  await tester.runAsync(() async {
    final patientId =
        await DatabaseHelper.instance.getOrCreateDefaultPatient();
    await DatabaseHelper.instance.updatePatientRoutine(
      patientId,
      jsonEncode(steps),
    );
  });
}

/// The visible label of the Nth ElevatedButton on screen. Each button's
/// child is a Row of [emoji, label] (see RoutineRecallScreen), so the
/// label is the last Text descendant rather than the button's own child.
String _buttonLabel(WidgetTester tester, int index) {
  final texts = tester.widgetList<Text>(
    find.descendant(
      of: find.byType(ElevatedButton).at(index),
      matching: find.byType(Text),
    ),
  );
  return texts.last.data!;
}

Future<void> _pumpGame(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: RoutineRecallScreen()),
  );
  // Unlike the other 3 games, there's no hardcoded content to deal
  // instantly — the routine has to load from the database first, via two
  // sequential real queries. How long that actually takes through the FFI
  // test database varies a lot by machine, so poll for the spinner to
  // disappear instead of guessing a fixed delay.
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
  fail('Routine Recall never finished loading after 4 seconds');
}

void main() {
  testWidgets('with no routine set up, prompts to set one up first',
      (WidgetTester tester) async {
    // Explicitly cleared rather than assumed empty — the test database
    // can carry state over from a previous run.
    await _seedRoutine(tester, []);

    await _pumpGame(tester);

    expect(find.text('Set up routine'), findsOneWidget);
  });

  testWidgets('with a routine set up, starts at round 1 with 3 choices',
      (WidgetTester tester) async {
    await _seedRoutine(tester, _routine);

    await _pumpGame(tester);

    expect(find.textContaining('Round 1 of'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(3));
  });

  testWidgets(
      'never offers the step being asked about as one of its own answers',
      (WidgetTester tester) async {
    await _seedRoutine(tester, _routine);

    await _pumpGame(tester);

    for (var round = 0; round < 3; round++) {
      final promptFinder = find.textContaining('what comes next?');
      final promptText = tester.widget<Text>(promptFinder).data!;
      final promptStep = _routine.firstWhere((s) => promptText.contains(s));

      // Each button's child is now a Row of [emoji, label] rather than a
      // bare Text, so the label is read back as the last Text descendant
      // of each button instead of casting the button's child directly.
      final buttonCount = find.byType(ElevatedButton).evaluate().length;
      final choiceButtons = [
        for (var i = 0; i < buttonCount; i++) _buttonLabel(tester, i),
      ];
      expect(
        choiceButtons,
        isNot(contains(promptStep)),
        reason: 'Prompt "$promptStep" should not appear as one of its '
            'own answer choices',
      );

      final correctAnswer = _routine[_routine.indexOf(promptStep) + 1];
      await tester.tap(find.widgetWithText(ElevatedButton, correctAnswer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1050));
    }

    // The last round in this loop completes the game, which triggers a
    // real database write — needs runAsync to actually resolve before the
    // test ends, same as "completing every round..." below.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
  });

  testWidgets('tapping the correct next step counts as correct and advances',
      (WidgetTester tester) async {
    await _seedRoutine(tester, _routine);

    await _pumpGame(tester);

    // Whichever step is being asked about, its correct answer is the next
    // item in _routine — find it by reading the prompt text.
    final promptFinder = find.textContaining('what comes next?');
    final promptText = tester.widget<Text>(promptFinder).data!;
    final promptStep = _routine.firstWhere((s) => promptText.contains(s));
    final correctAnswer = _routine[_routine.indexOf(promptStep) + 1];

    await tester.tap(find.widgetWithText(ElevatedButton, correctAnswer));
    await tester.pump();

    expect(find.text('Correct!'), findsOneWidget);

    // Drain the pending "show feedback, then advance" timer before the
    // test ends — otherwise the test framework fails the test for leaving
    // a timer pending at teardown, even though the assertion above passed.
    await tester.pump(const Duration(milliseconds: 1050));
  });

  testWidgets('completing every round shows the completion dialog',
      (WidgetTester tester) async {
    await _seedRoutine(tester, _routine);

    await _pumpGame(tester);

    for (var round = 0; round < 3; round++) {
      final promptFinder = find.textContaining('what comes next?');
      final promptText = tester.widget<Text>(promptFinder).data!;
      final promptStep = _routine.firstWhere((s) => promptText.contains(s));
      final correctAnswer = _routine[_routine.indexOf(promptStep) + 1];

      await tester.tap(find.widgetWithText(ElevatedButton, correctAnswer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1050));
    }

    // The final round triggers a real database write (saving the
    // session) before the completion dialog shows — same as the routine
    // load itself, that needs real time via runAsync, not just the fake
    // clock advanced above.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();

    expect(find.text('Well done!'), findsOneWidget);
  });
}
