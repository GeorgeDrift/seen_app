import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../controllers/historical_entries_controller.dart';

/// Therapist-facing view. Reads the same historical entries + pattern
/// insights the patient patterns screen uses, then adds a privacy audit
/// panel and a clipboard-copyable "EHR session preparation note".
class TherapistPortalScreen extends ConsumerWidget {
  const TherapistPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patterns = ref.watch(patternInsightsProvider);
    final entries = ref.watch(historicalEntriesProvider);
    final ehrSummary = _buildEhrSummary(patterns, entries.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 12, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'CLINICIAN PORTAL VIEW',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Patient Clinical Insights & Behavioral Trends',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child:
                          Icon(Icons.person, size: 16, color: Colors.black),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alex Morgan',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text(
                          'ID: #P-4089 • Active Case',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.insights,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Self-Reported Meaning vs. Telemetry Baseline',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      '14-Day Dataset',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.sage,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Crucial distinction: Passive data records "low activity", but patient annotations clarify this is restorative solitude rather than depressive withdrawal.',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey[300],
                      height: 1.4),
                ),
                const Divider(
                    height: 24, color: AppColors.borderTranslucent),
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
                        const Icon(Icons.check_circle,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.description,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400]),
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
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined,
                        color: AppColors.sage, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Data Minimization & Privacy Audit Log',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPrivacyCheckItem(
                    'Raw Calendar Event Titles & Attendees',
                    'NOT STORED (Converted to load index only)'),
                _buildPrivacyCheckItem(
                    'Exact GPS Coordinates & Location Logs',
                    'NOT STORED (Converted to pattern tags only)'),
                _buildPrivacyCheckItem(
                    'Raw Microphone / Audio Recordings', 'NOT COLLECTED'),
                _buildPrivacyCheckItem(
                    'Clinical Diagnosis Claims',
                    'BLOCKED (Engine restricts output to associations only)'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description_outlined,
                            color: AppColors.lavender, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'EHR Session Preparation Note',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.lavender.withValues(alpha: 0.2),
                        foregroundColor: AppColors.lavender,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: ehrSummary));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'EHR Summary copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 12),
                      label: const Text('Copy for EHR',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Text(
                    ehrSummary,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      color: AppColors.sage,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCheckItem(String label, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.sage.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sage),
            ),
          ),
        ],
      ),
    );
  }

  String _buildEhrSummary(List patterns, int totalDays) {
    final buffer = StringBuffer();
    buffer.writeln('=== SEEN PATIENT BEHAVIORAL ANNOTATION SUMMARY ===');
    buffer.writeln('Patient ID: Alex Morgan (#P-4089)');
    buffer.writeln(
        'Observation Period: 14 Days ($totalDays completed daily entries)');
    buffer.writeln(
        'Data Provenance: Self-annotated visual context logs (Zero PII raw telemetry stored)');
    buffer.writeln('');
    buffer.writeln('--- KEY OBSERVED ASSOCIATIONS (NON-CAUSAL) ---');
    for (final p in patterns) {
      buffer.writeln('• ${p.title}: ${p.description}');
    }
    buffer.writeln('');
    buffer.writeln('--- THERAPIST CLINICAL NOTES ---');
    buffer.writeln(
        'Patient consistently leverages solitary quiet moments on high-demand days as restorative recovery rather than isolation.');
    return buffer.toString();
  }
}
