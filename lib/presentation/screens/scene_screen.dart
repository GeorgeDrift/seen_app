import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/clue.dart';
import '../controllers/app_navigation_controller.dart';
import '../controllers/summary_controller.dart';
import '../widgets/question_sheet.dart';
import '../widgets/scene_canvas.dart';

/// Screen 2 — hidden-object canvas. Tapping a clue opens the question sheet.
/// "Complete Daily Entry" advances to the summary screen after asking the
/// summary controller to commit today's answers.
class SceneScreen extends ConsumerWidget {
  const SceneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Expanded(
            child: SceneCanvas(
              onClueTapped: (clue) => _openQuestionSheet(context, clue),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await ref
                    .read(dailySummaryControllerProvider.notifier)
                    .commit();
                ref
                    .read(patientStepProvider.notifier)
                    .go(PatientStep.dailySummary);
              },
              icon: const Icon(Icons.check_circle_outline,
                  color: AppColors.sage, size: 16),
              label: const Text(
                'Complete Daily Entry & View Summary →',
                style: TextStyle(
                    color: AppColors.sage, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openQuestionSheet(BuildContext context, Clue clue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ClueQuestionSheet(clue: clue),
    );
  }
}
