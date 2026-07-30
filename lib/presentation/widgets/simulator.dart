import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../controllers/day_flow_controller.dart';
import '../controllers/profile_controller.dart';

/// Optional utility panel exposed via demo controls / dev overlay. Not wired
/// into the default patient flow, but ready to drop into any screen — it
/// reads the current context from the profile controller and pushes tweaks
/// back through `tune()`.
class TelemetrySimulator extends ConsumerWidget {
  const TelemetrySimulator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(dayFlowControllerProvider).context;
    final profileNotifier = ref.read(activeProfileProvider.notifier);

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Telemetry Signal Simulator',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust simulated phone sensors in real-time to watch clue scoring & scene composition update.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
          ),
          const Divider(height: 24, color: AppColors.borderTranslucent),
          _buildMetricSlider(
            context: context,
            label: 'Sleep Duration',
            value: ctx.sleepHours ?? 7.0,
            min: 0,
            max: 12,
            divisions: 24,
            displayValue:
                '${(ctx.sleepHours ?? 7.0).toStringAsFixed(1)} hrs (${ctx.sleepComparison})',
            icon: Icons.dark_mode_outlined,
            color: AppColors.sleep,
            onChanged: (val) {
              final comp =
                  val < 6.5 ? 'lower' : (val > 8.5 ? 'higher' : 'typical');
              profileNotifier.tune(sleepHours: val, sleepComparison: comp);
            },
          ),
          _buildMetricSlider(
            context: context,
            label: 'Daily Footsteps',
            value: (ctx.steps ?? 4000).toDouble(),
            min: 0,
            max: 15000,
            divisions: 60,
            displayValue:
                '${ctx.steps ?? 4000} steps (${ctx.activityComparison})',
            icon: Icons.directions_walk,
            color: AppColors.steps,
            onChanged: (val) {
              final stepsVal = val.round();
              final comp = stepsVal < 3000
                  ? 'lower'
                  : (stepsVal > 8000 ? 'higher' : 'typical');
              profileNotifier.tune(
                  steps: stepsVal, activityComparison: comp);
            },
          ),
          _buildMetricSlider(
            context: context,
            label: 'Calendar Events',
            value: ctx.calendarEventCount.toDouble(),
            min: 0,
            max: 12,
            divisions: 12,
            displayValue:
                '${ctx.calendarEventCount} events (${ctx.calendarLoad})',
            icon: Icons.calendar_month,
            color: AppColors.calendar,
            onChanged: (val) {
              final evVal = val.round();
              final load = evVal >= 6
                  ? 'high'
                  : (evVal <= 1 ? 'low' : 'moderate');
              profileNotifier.tune(
                  calendarEventCount: evVal, calendarLoad: load);
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Weather Condition:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['sunny', 'cloudy', 'rain', 'snow'].map((w) {
              final isSelected = ctx.weather == w;
              final wColor = _getWeatherColor(w);
              return ChoiceChip(
                label: Text(
                  w.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
                selected: isSelected,
                selectedColor: wColor,
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                onSelected: (selected) {
                  if (selected) profileNotifier.tune(weather: w);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: isSelected
                          ? wColor
                          : Colors.white.withValues(alpha: 0.1)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getWeatherColor(String w) {
    switch (w) {
      case 'sunny':
        return AppColors.amber;
      case 'rain':
        return AppColors.weatherRain;
      case 'snow':
        return AppColors.weatherStorm;
      default:
        return AppColors.sage;
    }
  }

  Widget _buildMetricSlider({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 15),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            Text(
              displayValue,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.12),
            valueIndicatorColor: color,
            trackHeight: 3,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }
}
