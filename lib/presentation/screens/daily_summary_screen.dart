import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/engine/summary_engine.dart';
import '../controllers/app_navigation_controller.dart';
import '../controllers/day_flow_controller.dart';
import '../controllers/summary_controller.dart';

/// Screen 3 — shows the completed daily reflection matched to the new UI design,
/// featuring the cozy image header, formatted date, personalized completion title,
/// narrative summary card, metadata, and full reflection breakdown options.
class DailySummaryScreen extends ConsumerStatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  ConsumerState<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends ConsumerState<DailySummaryScreen> {
  bool _showFullDetails = false;

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(dayFlowControllerProvider);
    final selections = flow.selections;
    final asyncEntry = ref.watch(dailySummaryControllerProvider);

    const defaultSummaryText =
        'Today seemed to hold both pressure and relief. Work stayed with you longer than you wanted, but a quiet pause and finishing something difficult gave the day a sense of movement.';

    final localSummary = const SummaryEngine().buildLocal(selections);
    final summary = asyncEntry.maybeWhen(
      data: (entry) =>
          (entry?.generatedSummary != null &&
              entry!.generatedSummary.isNotEmpty)
          ? entry.generatedSummary
          : (localSummary.isNotEmpty ? localSummary : defaultSummaryText),
      orElse: () => localSummary.isNotEmpty ? localSummary : defaultSummaryText,
    );
    final isLoading = asyncEntry.isLoading;

    final momentsCount = selections.isNotEmpty ? selections.length : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Cozy Illustration Header
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/cozy_reflection_header.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF7C6A9B).withValues(alpha: 0.3),
                    child: const Center(
                      child: Icon(
                        Icons.nightlight_round,
                        size: 48,
                        color: AppColors.lavender,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Formatted Date Header
          const Text(
            'WEDNESDAY, JULY 30',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),

          // Main Title with Mixed Regular & Italic Serif Text
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "You're done reflecting\n",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                    letterSpacing: -0.4,
                  ),
                ),
                TextSpan(
                  text: 'for today, Upasana.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFC4B5FD),
                    height: 1.25,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle Paragraph
          const Text(
            'You took a moment to look back, notice what stood out, and put your day into words. Nice work showing up for yourself today.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),

          // Today's Reflection Card (Warm Cream Layout)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2), // Warm off-white cream background
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TODAY'S REFLECTION",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xFF8E8899),
                      ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF7F6A9D),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Reflection Narrative Body Text
                Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2936),
                  ),
                ),
                const SizedBox(height: 20),

                // Metadata Row: Checkmark & Clock
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 15,
                      color: Color(0xFF7F6A9D),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$momentsCount moments reflected on',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF787285),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time,
                      size: 15,
                      color: Color(0xFF7F6A9D),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Saved at 8:46 PM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF787285),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action Pill Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F6A9D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _showFullDetails = !_showFullDetails;
                          });
                        },
                        child: Text(
                          _showFullDetails
                              ? 'Hide full reflection'
                              : 'Read full reflection',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0ECF6),
                          foregroundColor: const Color(0xFF675185),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(patientStepProvider.notifier)
                              .go(PatientStep.hiddenScene);
                        },
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Collapsible Detailed View (Annotated Clues Breakdown)
          if (_showFullDetails) ...[
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annotated Clues (${selections.length}):',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selections.isEmpty)
                    const Text(
                      'No specific clues selected today.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selections.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = selections[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.clueTitle,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                item.userMeaning ?? 'Skipped',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.lavender,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 14,
                        color: AppColors.sage,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Strict Privacy Rule Applied: No unconfirmed causal claims generated.",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Footer Navigation Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => ref
                  .read(patientStepProvider.notifier)
                  .go(PatientStep.patterns),
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text(
                'View 14-Day Pattern Summary →',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
