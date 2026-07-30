import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/demo_profiles.dart';
import '../../data/models/daily_context.dart';
import '../../data/models/demo_profile.dart';
import '../providers/api_providers.dart';

/// Holds the current [DailyContext] plus a label identifying which demo
/// profile it started from. Ad-hoc simulator tweaks (steps slider etc.)
/// update the context but keep the label so the UI can still say
/// "Profile A (Overloaded)" as a starting point.
class ActiveProfile {
  const ActiveProfile({required this.label, required this.context});
  final String label;
  final DailyContext context;

  ActiveProfile copyWith({String? label, DailyContext? context}) =>
      ActiveProfile(
        label: label ?? this.label,
        context: context ?? this.context,
      );
}

final activeProfileProvider =
    NotifierProvider<ActiveProfileController, ActiveProfile>(
      ActiveProfileController.new,
    );

class ActiveProfileController extends Notifier<ActiveProfile> {
  bool _disposed = false;

  @override
  ActiveProfile build() {
    final first = DemoProfiles.all.first;
    final initial = ActiveProfile(label: first.label, context: first.context);

    _disposed = false;
    ref.onDispose(() => _disposed = true);

    // Fire-and-forget: fills in real device data (sleep/steps/calendar/
    // weather) once collection resolves, field-by-field, falling back to
    // this demo profile's values for anything unavailable or denied.
    _loadFromDevice(initial.context);

    return initial;
  }

  Future<void> _loadFromDevice(DailyContext fallback) async {
    final service = ref.read(passiveDataServiceProvider);
    final result = await service.collect(fallback: fallback);
    if (_disposed) return;

    developer.log(
      'Applying passive data to active profile — '
      'sleepHours: ${result.sleepHours.source}, '
      'steps: ${result.steps.source}, '
      'calendar: ${result.calendarEventCount.source}, '
      'weather: ${result.weather.source}',
      name: 'PassiveData',
    );

    state = state.copyWith(
      context: state.context.copyWith(
        sleepHours: result.sleepHours.value,
        sleepComparison: result.sleepHours.source == 'device'
            ? 'unknown'
            : null,
        steps: result.steps.value,
        activityComparison: result.steps.source == 'device'
            ? 'unknown'
            : null,
        calendarEventCount: result.calendarEventCount.value,
        calendarLoad: result.calendarLoad.value,
        weather: result.weather.value,
      ),
    );
  }

  /// Switch to one of the three canned demo profiles by label.
  void selectByLabel(String label) {
    final p = DemoProfiles.byLabel(label);
    state = ActiveProfile(label: p.label, context: p.context);
  }

  /// Switch to one of the three canned demo profiles by key.
  void selectByKey(DemoProfileKey key) {
    final p = DemoProfiles.byKey(key);
    state = ActiveProfile(label: p.label, context: p.context);
  }

  /// Ad-hoc tweak of the current context. Used by the telemetry simulator.
  void tune({
    double? sleepHours,
    int? steps,
    int? calendarEventCount,
    String? calendarLoad,
    String? weather,
    String? sleepComparison,
    String? activityComparison,
  }) {
    state = state.copyWith(
      context: state.context.copyWith(
        sleepHours: sleepHours,
        steps: steps,
        calendarEventCount: calendarEventCount,
        calendarLoad: calendarLoad,
        weather: weather,
        sleepComparison: sleepComparison,
        activityComparison: activityComparison,
      ),
    );
  }
}
