import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/demo_profiles.dart';
import '../../data/models/daily_context.dart';
import '../../data/models/demo_profile.dart';

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
  @override
  ActiveProfile build() {
    final first = DemoProfiles.all.first;
    return ActiveProfile(label: first.label, context: first.context);
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
    double? screenTimeHours,
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
        screenTimeHours: screenTimeHours,
      ),
    );
  }
}
