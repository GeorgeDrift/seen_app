import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/demo_profiles.dart';
import '../../data/models/demo_profile.dart';
import '../controllers/app_navigation_controller.dart';
import '../controllers/day_flow_controller.dart';
import '../controllers/profile_controller.dart';

/// Screen 1 — Context Preview on a light/white background.
/// Matches the "Good evening, Upasana." design with cozy header image,
/// metric glimpse card, and "Explore my day" CTA.
class ContextPreviewScreen extends ConsumerWidget {
  const ContextPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final flow = ref.watch(dayFlowControllerProvider);
    final ctx = flow.context;

    final sleepH = ctx.sleepHours ?? 0;
    final sleepFormatted = '${sleepH.floor()}h ${((sleepH % 1) * 60).round()}m';
    final steps = ctx.steps ?? 0;
    final stepsFormatted =
        '${steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} steps';
    final weatherDisplay = ctx.weather.isNotEmpty
        ? ctx.weather[0].toUpperCase() + ctx.weather.substring(1).toLowerCase()
        : 'Clear';

    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final timeFormatted = '$hour:$minute $period';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cozy Header Illustration ─────────────────────────────────────
          Container(
            width: double.infinity,
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B8BB0).withValues(alpha: 0.20),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/cozy_reflection_header.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFD6C9E8), Color(0xFFB8A9D4)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.nightlight_round,
                      size: 48,
                      color: Color(0xFF7F6A9D),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // ── Date Label ──────────────────────────────────────────────────
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

          // ── Greeting ────────────────────────────────────────────────────
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Good evening,\n',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1230),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Upasana.',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF7F6A9D),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Subheading ──────────────────────────────────────────────────
          const Text(
            "Let's talk about today.",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1230),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "You don't have to remember everything. We'll help you find a place to begin.",
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF7A7490),
            ),
          ),
          const SizedBox(height: 24),

          // ── "A glimpse of your day" Card ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F0FA),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B8BB0).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A glimpse of your day',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2936),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Here are a few things we noticed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8899),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8E1F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFF7F6A9D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricPill(
                      icon: Icons.nightlight_round,
                      label: 'SLEEP',
                      value: sleepFormatted,
                    ),
                    _MetricPill(
                      icon: Icons.directions_walk_rounded,
                      label: 'MOVEMENT',
                      value: stepsFormatted,
                    ),
                    _MetricPill(
                      icon: Icons.cloud_rounded,
                      label: 'WEATHER',
                      value: weatherDisplay,
                    ),
                    _MetricPill(
                      icon: Icons.schedule_rounded,
                      label: 'TIME',
                      value: timeFormatted,
                      iconColor: const Color(0xFFF5A623),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Profile switcher (compact) ───────────────────────────────────
          Row(
            children: [
              const Text(
                'Simulated profile: ',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final p in DemoProfiles.all) ...[
                        _buildProfileChip(
                          ref: ref,
                          label: p.label,
                          icon: _iconForProfile(p.key),
                          color: _colorForProfile(p.key),
                          isSelected: profile.label == p.label,
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Explore CTA ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F6A9D),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => ref
                  .read(patientStepProvider.notifier)
                  .go(PatientStep.hiddenScene),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Explore my day',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Therapist portal link ────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: () =>
                  ref.read(appModeProvider.notifier).set(AppMode.therapist),
              child: const Text(
                'Switch to Therapist Portal →',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB0A8C8),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFB0A8C8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
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
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () =>
          ref.read(activeProfileProvider.notifier).selectByLabel(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : const Color(0xFFF0ECF8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? color : const Color(0xFF8E8899),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : const Color(0xFF8E8899),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric Pill ───────────────────────────────────────────────────────────────

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = const Color(0xFF7F6A9D),
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Color(0xFFEBE6F3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF8E8899),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D2936),
          ),
        ),
      ],
    );
  }
}
