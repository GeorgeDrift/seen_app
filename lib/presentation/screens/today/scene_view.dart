import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/today_flow_controller.dart';
import '../../widgets/illustrated_scene_canvas.dart';
import '../../widgets/moment_capture_sheet.dart';

/// The illustrated hidden-object scene. Renders the active profile's fixed
/// room image with tappable hotspots; tapping one opens the free-text
/// [MomentCaptureSheet].
class SceneView extends ConsumerWidget {
  const SceneView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(todayFlowControllerProvider.notifier);
    final flowState = ref.watch(todayFlowControllerProvider);
    final scene = controller.sceneForActiveProfile;
    final tappedIds = flowState.moments.map((m) => m.clueId).toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Find what feels familiar.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardCool,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${tappedIds.length} moment${tappedIds.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          IllustratedSceneCanvas(
            scene: scene,
            tappedIds: tappedIds,
            onHotspotTapped: (hotspot) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => MomentCaptureSheet(hotspot: hotspot),
              );
            },
          ),
          const SizedBox(height: 28),
          if (tappedIds.isNotEmpty)
            PrimaryButton(
              onPressed: () => controller.reviewMoments(),
              label: 'Review my moments',
              icon: Icons.arrow_forward,
            ),
        ],
      ),
    );
  }
}
