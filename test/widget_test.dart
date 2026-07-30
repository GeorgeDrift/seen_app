import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seen_app/main.dart';

void main() {
  testWidgets('Seen app renders the reflection welcome screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: SeenApp()));

    await tester.pumpAndSettle();

    expect(find.text('Good evening,'), findsOneWidget);
    expect(find.textContaining('Explore my day'), findsOneWidget);

    final exploreButton = find.widgetWithText(
      ElevatedButton,
      '✦   Explore my day',
    );
    await tester.ensureVisible(exploreButton);
    await tester.tap(exploreButton);
    await tester.pumpAndSettle();

    expect(find.text('YOUR SCENE IS READY'), findsOneWidget);
    expect(find.textContaining('Enter the scene'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('Enter the scene'));
    await tester.tap(find.textContaining('Enter the scene'));
    await tester.pumpAndSettle();

    expect(
      find.text('What brings a part of your day back to mind?'),
      findsOneWidget,
    );
    expect(find.text('0 moments found'), findsOneWidget);
  });
}
