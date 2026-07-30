import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/demo_profiles.dart';
import '../../data/models/demo_profile.dart';
import '../controllers/app_navigation_controller.dart';
import '../controllers/day_flow_controller.dart';
import '../controllers/profile_controller.dart';

/// Screen 1 — shows the passive data and interpreted signals for today,
/// plus the profile picker. Reads everything from providers; the only
/// action it takes is switching profile and advancing the step.
class ContextPreviewScreen extends ConsumerWidget {
  const ContextPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final flow = ref.watch(dayFlowControllerProvider);
    final ctx = flow.context;
    final signals = flow.signals;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.query_stats,
                    size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'SCREEN 1: DAILY CONTEXT PREVIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Today's Passive Data Context",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            "Simulated passive context for prototype demonstration. Seen uses these facts to compose today's visual hidden-object scene without guessing what they mean.",
            style: TextStyle(
                fontSize: 13, color: Colors.grey[400], height: 1.4),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Simulated Demo Profile:',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in DemoProfiles.all) ...[
                  _buildProfileChip(
                    context: context,
                    ref: ref,
                    label: p.label,
                    icon: _iconForProfile(p.key),
                    color: _colorForProfile(p.key),
                    isSelected: profile.label == p.label,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricCard(
                    title: 'Sleep Duration',
                    value:
                        '${ctx.sleepHours?.toStringAsFixed(1) ?? "--"} hrs',
                    subtitle:
                        'Baseline: ${ctx.sleepComparison.toUpperCase()}',
                    icon: Icons.dark_mode_outlined,
                    color: AppColors.sleep,
                  ),
                  _buildMetricCard(
                    title: 'Steps / Movement',
                    value: '${ctx.steps ?? 0}',
                    subtitle:
                        'Activity: ${ctx.activityComparison.toUpperCase()}',
                    icon: Icons.directions_walk,
                    color: AppColors.steps,
                  ),
                  _buildMetricCard(
                    title: 'Calendar Load',
                    value: '${ctx.calendarEventCount} events',
                    subtitle:
                        'Density: ${ctx.calendarLoad.toUpperCase()}',
                    icon: Icons.calendar_month,
                    color: AppColors.calendar,
                  ),
                  _buildMetricCard(
                    title: 'Weather & Env',
                    value: ctx.weather.toUpperCase(),
                    subtitle: 'Location: ${ctx.locationPattern}',
                    icon: Icons.cloud_outlined,
                    color: AppColors.weatherRain,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.memory,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Signal Interpreter Output',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Non-Clinical Tags',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.sage,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Raw data is transformed into non-judgmental semantic tags for clue scoring.',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                const Divider(
                    height: 24, color: AppColors.borderTranslucent),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: signals.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sig = signals[index];
                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    sig.tag,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${sig.source})',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color:
                                            AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sig.explanation,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[300]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Strength: ${(sig.strength * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
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
                elevation: 4,
              ),
              onPressed: () => ref
                  .read(patientStepProvider.notifier)
                  .go(PatientStep.hiddenScene),
              icon: const Icon(Icons.palette_outlined, size: 18),
              label: const Text(
                'Proceed to Scene Composition →',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForProfile(DemoProfileKey k) {
    switch (k) {
      case DemoProfileKey.a:
        return Icons.thunderstorm_outlined;
      case DemoProfileKey.b:
        return Icons.wb_sunny_outlined;
      case DemoProfileKey.c:
        return Icons.bedtime_outlined;
    }
  }

  Color _colorForProfile(DemoProfileKey k) {
    switch (k) {
      case DemoProfileKey.a:
        return AppColors.coral;
      case DemoProfileKey.b:
        return AppColors.amber;
      case DemoProfileKey.c:
        return AppColors.sage;
    }
  }

  Widget _buildProfileChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return ChoiceChip(
      avatar:
          Icon(icon, size: 14, color: isSelected ? Colors.black : color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.black : Colors.white,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.white.withValues(alpha: 0.04),
      onSelected: (selected) {
        if (selected) {
          ref.read(activeProfileProvider.notifier).selectByLabel(label);
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color:
                isSelected ? color : Colors.white.withValues(alpha: 0.1)),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
                fontSize: 9.5,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
