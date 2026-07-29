import 'package:flutter_test/flutter_test.dart';
import 'package:seen_app/main.dart';

void main() {
  testWidgets('Seen app startup smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SeenApp());

    // Verify that our app displays "S E E N" branding and navigation.
    expect(find.text('S E E N'), findsOneWidget);
    expect(find.text('Patient View'), findsOneWidget);
    expect(find.text('Therapist Portal'), findsOneWidget);
  });
}
