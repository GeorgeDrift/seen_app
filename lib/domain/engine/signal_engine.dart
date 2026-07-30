import '../../data/models/daily_context.dart';
import '../../data/models/interpreted_signal.dart';

/// Turns raw passive-data values into semantic tags. Deliberately keeps the
/// vocabulary observational (`short_sleep`, `low_activity`) — never
/// psychological. Any interpretation of what a signal *means* has to come
/// from the user, not this function.
///
/// This mirrors the backend's `interpretSignals` in behavior so the local
/// preview and the server-computed preview never disagree.
class SignalEngine {
  const SignalEngine();

  List<InterpretedSignal> interpret(DailyContext context) {
    final signals = <InterpretedSignal>[];

    // Sleep
    if (context.sleepHours != null && context.sleepHours! < 6.5) {
      final diff = 6.5 - context.sleepHours!;
      signals.add(
        InterpretedSignal(
          tag: 'short_sleep',
          strength: (diff / 2.0).clamp(0.1, 1.0),
          source: 'sleep_hours',
          explanation:
              'Sleep duration (${context.sleepHours!.toStringAsFixed(1)}h) was below the 6.5h threshold.',
        ),
      );
    } else if (context.sleepHours != null && context.sleepHours! > 8.5) {
      signals.add(
        InterpretedSignal(
          tag: 'long_sleep',
          strength: 0.8,
          source: 'sleep_hours',
          explanation:
              'Sleep duration (${context.sleepHours!.toStringAsFixed(1)}h) was longer than typical baseline.',
        ),
      );
    }

    // Calendar load
    if (context.calendarLoad == 'high' || context.calendarEventCount >= 6) {
      signals.add(
        InterpretedSignal(
          tag: 'high_calendar_load',
          strength: 0.9,
          source: 'calendar',
          explanation:
              'The day included ${context.calendarEventCount} scheduled events.',
        ),
      );
    } else if (context.calendarLoad == 'low' ||
        context.calendarEventCount <= 1) {
      signals.add(
        InterpretedSignal(
          tag: 'low_calendar_load',
          strength: 0.7,
          source: 'calendar',
          explanation:
              'Schedule had high spaciousness with only ${context.calendarEventCount} events.',
        ),
      );
    }

    // Movement
    if (context.activityComparison == 'lower' ||
        (context.steps != null && context.steps! < 3000)) {
      signals.add(
        InterpretedSignal(
          tag: 'low_activity',
          strength: 0.75,
          source: 'steps',
          explanation:
              'Movement (${context.steps ?? 0} steps) was lower than usual baseline.',
        ),
      );
    } else if (context.activityComparison == 'higher' ||
        (context.steps != null && context.steps! > 8000)) {
      signals.add(
        InterpretedSignal(
          tag: 'high_activity',
          strength: 0.85,
          source: 'steps',
          explanation:
              'Movement (${context.steps ?? 0} steps) was higher than usual baseline.',
        ),
      );
    }

    // Weather
    if (context.weather == 'rain' || context.weather == 'snow') {
      signals.add(
        InterpretedSignal(
          tag: 'rainy_environment',
          strength: 0.65,
          source: 'weather',
          explanation:
              'Precipitation recorded for this day (${context.weather}).',
        ),
      );
    } else if (context.weather == 'sunny') {
      signals.add(
        InterpretedSignal(
          tag: 'sunny_environment',
          strength: 0.70,
          source: 'weather',
          explanation: 'Clear sunny weather conditions.',
        ),
      );
    }

    return signals;
  }
}
