import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smriti/screens/memory_match_screen.dart';

const List<String> _symbols = ['☕', '🍽️', '💊'];

Finder _card(int index) => find.byKey(ValueKey('card_$index'));

/// How many card faces are currently showing a picture (as opposed to the
/// face-down "?" mark).
int _visibleFaces(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .where((text) => _symbols.contains(text.data))
      .length;
}

/// The picture on a face-up card.
String _symbolAt(WidgetTester tester, int index) {
  final text = tester.widget<Text>(
    find.descendant(of: _card(index), matching: find.byType(Text)),
  );
  return text.data!;
}

Future<void> _pumpGame(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: MemoryMatchScreen()),
  );
  // The board deals synchronously in initState, so it's already on screen
  // after just pumpWidget — none of these tests need to wait on anything
  // for that. initState *also* kicks off a background database lookup
  // (checking whether the patient's tier has changed), which the screen
  // deliberately doesn't block on. runAsync gives that background work a
  // real-time window to finish quietly, purely so it doesn't leave a
  // dangling database timer at test teardown — not because any assertion
  // here depends on it completing.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump();
}

void main() {
  testWidgets('starts with 6 face-down cards and no pairs found',
      (WidgetTester tester) async {
    await _pumpGame(tester);

    expect(find.byType(GestureDetector), findsNWidgets(6));
    expect(_visibleFaces(tester), 0);
    expect(find.text('Pairs found: 0 of 3  •  Level 1'), findsOneWidget);
  });

  testWidgets('tapping one card reveals exactly one picture',
      (WidgetTester tester) async {
    await _pumpGame(tester);

    await tester.tap(_card(0));
    await tester.pump();

    expect(_visibleFaces(tester), 1);
  });

  testWidgets('two cards resolve correctly as a match or a mismatch',
      (WidgetTester tester) async {
    await _pumpGame(tester);

    await tester.tap(_card(0));
    await tester.pump();
    final first = _symbolAt(tester, 0);

    await tester.tap(_card(1));
    await tester.pump();
    final second = _symbolAt(tester, 1);

    // Both are visible while the player compares them.
    expect(_visibleFaces(tester), 2);

    // Let the mismatch pause elapse.
    await tester.pump(const Duration(milliseconds: 1500));

    if (first == second) {
      expect(_visibleFaces(tester), 2);
      expect(find.text('Pairs found: 1 of 3  •  Level 1'), findsOneWidget);
    } else {
      expect(_visibleFaces(tester), 0);
      expect(find.text('Pairs found: 0 of 3  •  Level 1'), findsOneWidget);
    }
  });

  testWidgets('finding every pair completes the round',
      (WidgetTester tester) async {
    await _pumpGame(tester);

    bool roundComplete() => find.text('Well done!').evaluate().isNotEmpty;

    // The board is shuffled, so the test has to learn the layout the same way
    // a player would: flip cards two at a time and remember what was there.
    // A "learning" pair can itself turn out to be a real match by luck — if
    // that finishes the round early, stop right there rather than tapping
    // cards that are now hidden behind the completion dialog.
    final symbolByIndex = <int, String>{};
    for (var i = 0; i < 6 && !roundComplete(); i += 2) {
      await tester.tap(_card(i));
      await tester.pump();
      symbolByIndex[i] = _symbolAt(tester, i);

      await tester.tap(_card(i + 1));
      await tester.pump();
      symbolByIndex[i + 1] = _symbolAt(tester, i + 1);

      await tester.pump(const Duration(milliseconds: 1500));
    }

    final indicesBySymbol = <String, List<int>>{};
    symbolByIndex.forEach((index, symbol) {
      indicesBySymbol.putIfAbsent(symbol, () => []).add(index);
    });

    // Play any pair not already solved by luck during the learning phase.
    for (final pair in indicesBySymbol.values) {
      if (roundComplete()) break;

      await tester.tap(_card(pair[0]));
      await tester.pump();
      await tester.tap(_card(pair[1]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
    }

    expect(find.text('Pairs found: 3 of 3  •  Level 1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Well done!'), findsOneWidget);
  });
}
