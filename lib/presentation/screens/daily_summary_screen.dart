import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/engine/summary_engine.dart';
import '../controllers/app_navigation_controller.dart';
import '../controllers/day_flow_controller.dart';
import '../controllers/summary_controller.dart';

/// Screen 3 — shows the confirmed daily entry (the AI or local summary,
/// whichever came through) plus a breakdown of every selection.
class DailySummaryScreen extends ConsumerWidget {
  const DailySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(dayFlowControllerProvider);
    final selections = flow.selections;
    final asyncEntry = ref.watch(dailySummaryControllerProvider);

    // If the user landed here without committing (e.g. jumped via
    // breadcrumb), fall back to the local-generated summary.
    final localSummary = const SummaryEngine().buildLocal(selections);
    final summary = asyncEntry.maybeWhen(
      data: (entry) => entry?.generatedSummary ?? localSummary,
      orElse: () => localSummary,
    );
    final isLoading = asyncEntry.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sage.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.sage.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assignment_turned_in_outlined,
                    size: 14, color: AppColors.sage),
                SizedBox(width: 6),
                Text(
                  'CONFIRMED DAILY SUMMARY ENTRY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.sage,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Today's Structured Record",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'This entry contains only facts confirmed by you. Unselected passive-data signals remain unassumed.',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_quote,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Confirmed Narrative',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    if (isLoading) ...const [
                      SizedBox(width: 10),
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const Divider(
                    height: 24, color: AppColors.borderTranslucent),
                Row(
                  children: [
                    const Icon(Icons.privacy_tip_outlined,
                        size: 14, color: AppColors.sage),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Strict Privacy Rule Applied: No unconfirmed causal claims ('X caused Y') generated.",
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Annotated Clues (${selections.length}):',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (selections.isEmpty)
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 12,
              child: const Center(
                child: Text('No clues selected today.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selections.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = selections[index];
                return GlassContainer(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  borderRadius: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 16),
                          const SizedBox(width: 10),
                          Text(
                            item.clueTitle,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.userMeaning ?? 'Skipped',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => ref
                  .read(patientStepProvider.notifier)
                  .go(PatientStep.patterns),
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text(
                'View 14-Day Pattern Summary →',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
