import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BudgetApp());

    // Verify that our app name or key elements exist in the UI.
    expect(find.text('Total savings'), findsOneWidget);
  });
}
