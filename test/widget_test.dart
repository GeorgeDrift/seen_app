import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seen_app/main.dart';
import 'package:seen_app/presentation/controllers/app_navigation_controller.dart';

void main() {
  testWidgets('Seen app renders main layout after walkthrough',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Skip the intro so the main layout mounts immediately.
          walkthroughDoneProvider.overrideWith(
              () => _AlreadyDoneWalkthroughController()),
        ],
        child: const SeenApp(),
      ),
    );

    // Let AnimatedSwitcher and initial pulses settle.
    await tester.pumpAndSettle(const Duration(milliseconds: 800));

    expect(find.text('SEEN'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Patterns'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}

class _AlreadyDoneWalkthroughController extends WalkthroughDoneController {
  @override
  bool build() => true;
}
