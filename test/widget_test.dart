// This is a basic widget test for the Every-Pay app.
//
// Tests will be expanded in the test/ directory following the architecture.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/app.dart';

void main() {
  testWidgets('App renders and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EveryPayApp()));
    // Use pump() instead of pumpAndSettle() since streams keep emitting
    await tester.pump();
    await tester.pump();

    // Verify the app bar title
    expect(find.text('Every-Pay'), findsOneWidget);
    // Verify bottom nav is present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
