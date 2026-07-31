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

    // Default demo profile (Profile A "Overloaded": low sleep, low steps,
    // high calendar load) has Load=High, which the scene-classification
    // rules map straight to "Full and Active" regardless of Recovery —
    // see ScoringEngine._selectScene.
    final sceneImage = find.image(
      const AssetImage('assets/cozy_plant_filled_bedroom_workspace.png'),
    );
    expect(sceneImage, findsOneWidget);
    final sceneSize = tester.getSize(sceneImage);
    expect(sceneSize.width, 390);
    expect(sceneSize.height, greaterThan(sceneSize.width));

    final laptopTarget = find.bySemanticsLabel('Open laptop');
    expect(laptopTarget, findsOneWidget);
    await tester.tap(laptopTarget);
    await tester.pumpAndSettle();
    expect(find.text('OPEN LAPTOP'), findsOneWidget);
    // The follow-up question is now fetched per-clue (dynamic, not one
    // static prompt for every clue) — offline in this test, it falls back
    // to FallbackQuestions.forCategory('workload') since "open_laptop"'s
    // inferred category is 'workload'.
    expect(
      find.text('How did this schedule or workload feel today?'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seen flow adapts to a short narrow screen without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: SeenApp()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final explore = find.textContaining('Explore my day');
    await tester.ensureVisible(explore);
    await tester.tap(explore);
    await tester.pumpAndSettle();
    expect(find.text('YOUR SCENE IS READY'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final enter = find.textContaining('Enter the scene');
    await tester.ensureVisible(enter);
    await tester.tap(enter);
    await tester.pumpAndSettle();

    expect(
      find.image(
        const AssetImage('assets/cozy_plant_filled_bedroom_workspace.png'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
