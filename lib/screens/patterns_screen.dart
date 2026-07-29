import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';

class PatternsScreen extends StatelessWidget {
  final AppState appState;

  const PatternsScreen({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final patterns = appState.calculatePatterns();
    final history = appState.historicalEntries;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lavender.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.lavender.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_graph, size: 14, color: AppColors.lavender),
                SizedBox(width: 6),
                Text(
                  'SCREEN 4: LONGITUDINAL PATTERN SUMMARY (14-DAY WINDOW)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.lavender,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Transparent Behavioral Patterns',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Calculated from your 14-day self-annotated history. The system highlights co-occurrences without assuming cause and effect.',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          // Non-Causal Rules Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.sage, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Transparent Language Rule: Describes associations only (e.g. 'X and Y appeared together'), never claims clinical causation.",
                    style: TextStyle(fontSize: 11, color: AppColors.sage, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Co-occurrence Pattern Cards
          Text(
            'Observed Co-occurrence Patterns:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: patterns.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = patterns[index];
              final Color color = p['color'] as Color;
              final double ratio = (p['count'] as int) / (p['total'] as int);

              return GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                border: Border.all(color: color.withOpacity(0.2)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.hub_outlined, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                p['title'] as String,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${(ratio * 100).toStringAsFixed(0)}% co-occurrence',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p['desc'] as String,
                            style: TextStyle(fontSize: 12.5, color: Colors.grey[300], height: 1.35),
                          ),
                          const SizedBox(height: 10),
                          // Progress ratio bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: Colors.white.withOpacity(0.06),
                              color: color,
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // 14-Day History Log Table
          Text(
            '14-Day Synthetic Entry Records (${history.length} days):',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length > 5 ? 5 : history.length, // Show recent 5 days
            itemBuilder: (context, index) {
              final entry = history[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_note, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          entry.date,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      '${entry.context.sleepHours ?? "--"}h sleep • ${entry.context.steps} steps • ${entry.context.weather}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
