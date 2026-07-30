import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../controllers/historical_entries_controller.dart';

/// Therapist-facing view. Reads the same historical entries + pattern
/// insights the patient patterns screen uses, then adds a privacy audit
/// panel and a clipboard-copyable "EHR session preparation note".
///
/// Reachable only via the debug demo-controls sheet (long-press the "SEEN"
/// wordmark) — a real end user has no visible entry point to this screen.
class TherapistPortalScreen extends ConsumerWidget {
  const TherapistPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patterns = ref.watch(patternInsightsProvider);
    final entries = ref.watch(historicalEntriesProvider);
    final ehrSummary = _buildEhrSummary(patterns, entries.length);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Clinician Portal',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient insights & behavioral trends',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Self-reported meaning vs. telemetry baseline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crucial distinction: passive data records "low activity", but patient annotations may clarify this is restorative solitude rather than withdrawal.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Divider(height: 28),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: patterns.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = patterns[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data minimization & privacy audit log',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _privacyItem(
                    context,
                    'Raw calendar event titles & attendees',
                    'Not stored (load index only)',
                  ),
                  _privacyItem(
                    context,
                    'Exact GPS coordinates & location logs',
                    'Not stored (pattern tags only)',
                  ),
                  _privacyItem(
                    context,
                    'Raw microphone / audio recordings',
                    'Not collected',
                  ),
                  _privacyItem(
                    context,
                    'Clinical diagnosis claims',
                    'Blocked (restricted to associations only)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'EHR session preparation note',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: ehrSummary));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('Copy'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardCool,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ehrSummary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacyItem(BuildContext context, String label, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.steps.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.steps,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildEhrSummary(List patterns, int totalDays) {
    final buffer = StringBuffer();
    buffer.writeln('=== SEEN PATIENT BEHAVIORAL ANNOTATION SUMMARY ===');
    buffer.writeln(
      'Observation Period: 14 Days ($totalDays completed daily entries)',
    );
    buffer.writeln(
      'Data Provenance: Self-annotated visual context logs (zero raw telemetry stored)',
    );
    buffer.writeln('');
    buffer.writeln('--- KEY OBSERVED ASSOCIATIONS (NON-CAUSAL) ---');
    for (final p in patterns) {
      buffer.writeln('• ${p.title}: ${p.description}');
    }
    return buffer.toString();
  }
}
