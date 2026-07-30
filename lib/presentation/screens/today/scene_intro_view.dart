import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/today_flow_controller.dart';

/// "How this works" explainer shown before the illustrated scene, over the
/// real Figma-exported arch/path illustration.
class SceneIntroView extends ConsumerWidget {
  const SceneIntroView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/figma_intro_background.png',
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'A closer look.',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 12),
          Text(
            "You'll find a few objects scattered through today's scene. Tap up to three that feel familiar, and tell us what they bring to mind.",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            onPressed: () =>
                ref.read(todayFlowControllerProvider.notifier).enterScene(),
            label: 'Enter the scene',
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }
}
