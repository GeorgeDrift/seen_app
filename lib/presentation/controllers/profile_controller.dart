import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/demo_profiles.dart';
import '../../data/models/daily_context.dart';
import '../../data/models/demo_profile.dart';
import '../../data/services/passive_data_service.dart';
import '../providers/api_providers.dart';

/// Whether the app is currently driven by the phone's real passive data or
/// by a hand-picked demo profile (used to test scene/pattern behavior
/// without waiting for real conditions to change).
enum DataSourceMode { real, demo }

/// Holds the current [DailyContext] plus a label identifying which demo
/// profile it started from. Ad-hoc simulator tweaks (steps slider etc.)
/// update the context but keep the label so the UI can still say
/// "Profile A (Overloaded)" as a starting point.
class ActiveProfile {
  const ActiveProfile({
    required this.label,
    required this.context,
    this.mode = DataSourceMode.real,
    this.demoKey,
  });

  final String label;
  final DailyContext context;
  final DataSourceMode mode;

  /// Which of the 3 canned profiles is active, when [mode] is
  /// [DataSourceMode.demo]. Null in real-data mode.
  final DemoProfileKey? demoKey;

  /// Only ever changes [context] — mode/demoKey are carried over unchanged,
  /// since this is used for real-data updates (passive data resolving,
  /// simulator tweaks), never for a mode switch (those construct a fresh
  /// [ActiveProfile] directly so `demoKey` can be cleared to null).
  ActiveProfile copyWith({String? label, DailyContext? context}) =>
      ActiveProfile(
        label: label ?? this.label,
        context: context ?? this.context,
        mode: mode,
        demoKey: demoKey,
      );
}

final activeProfileProvider =
    NotifierProvider<ActiveProfileController, ActiveProfile>(
      ActiveProfileController.new,
    );

class ActiveProfileController extends Notifier<ActiveProfile> {
  bool _disposed = false;

  /// The last known real-device-data snapshot, cached so switching back
  /// from a demo profile to "Real data" doesn't need to re-collect —
  /// and so a slow `_loadFromDevice` that resolves *after* the user has
  /// already switched to a demo profile doesn't clobber their test view.
  ActiveProfile? _realSnapshot;

  @override
  ActiveProfile build() {
    final first = DemoProfiles.all.first;
    final initial = ActiveProfile(label: 'Real data', context: first.context);

    _disposed = false;
    ref.onDispose(() => _disposed = true);

    final prefetched = ref.read(prefetchedPassiveDataProvider);
    if (prefetched != null) {
      // Already collected before the first frame — start directly from real
      // data so the UI never shows demo values that then jump to real ones.
      developer.log(
        'Using passive data prefetched before first frame.',
        name: 'PassiveData',
      );
      final real = initial.copyWith(
        context: _applyPassiveData(initial.context, prefetched),
      );
      _realSnapshot = real;
      return real;
    }

    // Prefetch wasn't available (timed out, or not attempted — e.g. tests):
    // fall back to the old fire-and-forget behavior so the app still ends
    // up with real data eventually, just not from the very first frame.
    _realSnapshot = initial;
    _loadFromDevice(initial.context);

    return initial;
  }

  Future<void> _loadFromDevice(DailyContext fallback) async {
    final service = ref.read(passiveDataServiceProvider);
    final result = await service.collect(fallback: fallback);
    if (_disposed) return;

    final updatedContext = _applyPassiveData(fallback, result);
    _realSnapshot = ActiveProfile(label: 'Real data', context: updatedContext);

    developer.log(
      'Applying passive data to active profile — '
      'sleepHours: ${result.sleepHours.source}, '
      'steps: ${result.steps.source}, '
      'calendar: ${result.calendarEventCount.source}, '
      'weather: ${result.weather.source}',
      name: 'PassiveData',
    );

    // Only apply to the live state if the user is still on real-data mode —
    // otherwise this just updates the cache for whenever they switch back.
    if (state.mode == DataSourceMode.real) {
      state = _realSnapshot!;
    }
  }

  DailyContext _applyPassiveData(DailyContext base, PassiveDataResult result) {
    return base.copyWith(
      sleepHours: result.sleepHours.value,
      sleepComparison: result.sleepHours.source == 'device' ? 'unknown' : null,
      steps: result.steps.value,
      activityComparison: result.steps.source == 'device' ? 'unknown' : null,
      calendarEventCount: result.calendarEventCount.value,
      calendarLoad: result.calendarLoad.value,
      weather: result.weather.value,
    );
  }

  /// Switches back to real device data (the last collected snapshot, or the
  /// initial demo fallback if collection hasn't resolved yet).
  void useRealData() {
    state = _realSnapshot ?? ActiveProfile(label: 'Real data', context: state.context);
  }

  /// Switch to one of the three canned demo profiles by label.
  void selectByLabel(String label) {
    selectByKey(DemoProfiles.byLabel(label).key);
  }

  /// Switch to one of the three canned demo profiles by key.
  void selectByKey(DemoProfileKey key) {
    final p = DemoProfiles.byKey(key);
    state = ActiveProfile(
      label: p.label,
      context: p.context,
      mode: DataSourceMode.demo,
      demoKey: key,
    );
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
