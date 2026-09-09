import 'package:flutter_test/flutter_test.dart';

import 'package:smriti/main.dart';

void main() {
  testWidgets('Home screen shows Games, Reminders and Settings buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmritiApp());

    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
