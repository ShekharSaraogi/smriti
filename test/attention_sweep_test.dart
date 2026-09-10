import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smriti/db/database_helper.dart';
import 'package:smriti/screens/attention_sweep_screen.dart';

Finder _cell(int index) => find.byKey(ValueKey('cell_$index'));

Future<void> _pumpGame(WidgetTester tester) async {
  // The FFI test database persists across runs, and this file never
  // cleared its own history the way reminders/routine tests do — accuracy
  // logged by earlier runs eventually pushes the default patient's
  // attention_sweep tier above 1, which changes the cell count these tests
  // hardcode. Clearing it first keeps every test starting from tier 1.
  await tester.runAsync(
    () => DatabaseHelper.instance.database.then(
      (db) => db.delete('game_sessions', where: "game_type = 'attention_sweep'"),
    ),
  );
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

/// Image.asset's cacheWidth wraps the AssetImage in a ResizeImage — this
/// unwraps that to get to the actual asset path either way.
String _assetNameOf(ImageProvider provider) {
  if (provider is ResizeImage) return _assetNameOf(provider.imageProvider);
  return (provider as AssetImage).assetName;
}

/// Finds which cell is currently the odd one out. Each round uses a
/// different real-photo pair (see AttentionSweepScreen._objectPairs), so
/// rather than hardcoding one asset path, this finds the cell whose
/// picture differs from the majority — same idea as a player visually
/// scanning the grid for the one that doesn't match the rest.
int _findOddCell(WidgetTester tester, int cellCount) {
  final assetByIndex = <int, String>{
    for (var i = 0; i < cellCount; i++)
      i: _assetNameOf(
        tester
            .widget<Image>(
              find.descendant(of: _cell(i), matching: find.byType(Image)),
            )
            .image,
      ),
  };
  final counts = <String, int>{};
  for (final asset in assetByIndex.values) {
    counts[asset] = (counts[asset] ?? 0) + 1;
  }
  final oddAsset =
      counts.entries.firstWhere((entry) => entry.value == 1).key;
  return assetByIndex.entries.firstWhere((e) => e.value == oddAsset).key;
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
