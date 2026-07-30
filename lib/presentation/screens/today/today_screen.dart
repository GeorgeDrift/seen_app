import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/today_flow_controller.dart';
import 'done_view.dart';
import 'glimpse_view.dart';
import 'reflection_loading_view.dart';
import 'reflection_view.dart';
import 'scene_intro_view.dart';
import 'scene_view.dart';

/// Orchestrates the Today tab's 6 stages, swapping between them with an
/// [AnimatedSwitcher] — same fade/slide pattern used elsewhere in the app.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(todayFlowControllerProvider).stage;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: switch (stage) {
        TodayStage.glimpse => const GlimpseView(key: ValueKey('glimpse')),
        TodayStage.sceneIntro => const SceneIntroView(
          key: ValueKey('sceneIntro'),
        ),
        TodayStage.scene => const SceneView(key: ValueKey('scene')),
        TodayStage.reflectionLoading => const ReflectionLoadingView(
          key: ValueKey('reflectionLoading'),
        ),
        TodayStage.reflection => const ReflectionView(
          key: ValueKey('reflection'),
        ),
        TodayStage.done => const DoneView(key: ValueKey('done')),
      },
    );
  }
}
