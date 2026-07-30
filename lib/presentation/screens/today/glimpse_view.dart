import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/day_flow_controller.dart';
import '../../controllers/today_flow_controller.dart';

/// The Today tab's landing stage: banner, time-of-day greeting, a glimpse of
/// the day's passive-data stats, and the entry point into the scene.
class GlimpseView extends ConsumerWidget {
  const GlimpseView({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(dayFlowControllerProvider);
    final ctx = flow.context;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/cozy_reflection_header.png',
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${_greeting()}.',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            "Here's a glimpse of your day before you look closer.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.bedtime,
                  label: 'Sleep',
                  value: ctx.sleepHours != null
                      ? '${ctx.sleepHours!.toStringAsFixed(1)}h'
                      : '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.directions_walk,
                  label: 'Movement',
                  value: ctx.steps != null ? '${ctx.steps}' : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.wb_cloudy,
                  label: 'Weather',
                  value: ctx.weather,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.event_note,
                  label: 'Calendar',
                  value: '${ctx.calendarEventCount} events',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            onPressed: () => ref
                .read(todayFlowControllerProvider.notifier)
                .enterSceneIntro(),
            label: 'Explore my day',
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
