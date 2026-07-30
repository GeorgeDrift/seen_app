import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/controllers/app_navigation_controller.dart';
import 'presentation/screens/main_layout.dart';
import 'presentation/screens/walkthrough_screen.dart';

void main() {
  runApp(const ProviderScope(child: SeenApp()));
}

class SeenApp extends StatelessWidget {
  const SeenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seen — Behavioral Annotation & Therapist System',
      debugShowCheckedModeBanner: false,
      theme: getDarkSeenTheme(),
      home: const AppEntry(),
    );
  }
}

/// Fades between the walkthrough and the main layout based on whether the
/// user has finished the intro. Kept intentionally thin — everything else
/// (navigation, mode, day flow) lives in Riverpod controllers.
class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walkthroughDone = ref.watch(walkthroughDoneProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      ),
      child: walkthroughDone
          ? const MainLayout(key: ValueKey('main'))
          : const WalkthroughScreen(key: ValueKey('walkthrough')),
    );
  }
}
