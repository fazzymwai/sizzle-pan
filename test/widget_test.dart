import 'package:flutter_test/flutter_test.dart';

import 'package:sizzle_pan/main.dart';

void main() {
  testWidgets('Sizzle Pan app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SizzlePanApp());

    // Verify that the app loads with the home screen
    expect(find.text('Sizzle Pan'), findsOneWidget);
    expect(find.text('Your AI cooking companion'), findsOneWidget);
    
    // Verify that all main feature cards are present
    expect(find.text('What I Have'), findsOneWidget);
    expect(find.text('How I Feel'), findsOneWidget);
    expect(find.text('Search Recipes'), findsOneWidget);
    expect(find.text('My Recipes'), findsOneWidget);
  });
}
