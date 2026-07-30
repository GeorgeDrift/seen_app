import '../models/daily_context.dart';
import '../models/demo_profile.dart';

/// The three demo profiles the app is designed around. Preserved from the
/// original in-app engine so switching profiles produces visibly different
/// signal sets and clue compositions.
class DemoProfiles {
  static const _date = '2026-07-29';

  static const _profileA = DemoProfile(
    key: DemoProfileKey.a,
    label: 'Profile A (Overloaded)',
    description: 'Short sleep, low movement, a packed calendar, and rain.',
    context: DailyContext(
      date: _date,
      sleepHours: 5.4,
      sleepComparison: 'lower',
      steps: 2100,
      activityComparison: 'lower',
      calendarEventCount: 7,
      calendarLoad: 'high',
      weather: 'rain',
      locationPattern: 'mostly_home',
      screenTimeHours: 5.2,
    ),
  );

  static const _profileB = DemoProfile(
    key: DemoProfileKey.b,
    label: 'Profile B (Active)',
    description: 'Good sleep, high movement, a light calendar, and sun.',
    context: DailyContext(
      date: _date,
      sleepHours: 7.8,
      sleepComparison: 'typical',
      steps: 10300,
      activityComparison: 'higher',
      calendarEventCount: 2,
      calendarLoad: 'low',
      weather: 'sunny',
      locationPattern: 'mostly_out',
      screenTimeHours: 2.6,
    ),
  );

  static const _profileC = DemoProfile(
    key: DemoProfileKey.c,
    label: 'Profile C (Quiet Recovery)',
    description: 'Full sleep, low movement, an empty calendar, and clouds.',
    context: DailyContext(
      date: _date,
      sleepHours: 8.1,
      sleepComparison: 'typical',
      steps: 3200,
      activityComparison: 'lower',
      calendarEventCount: 0,
      calendarLoad: 'low',
      weather: 'cloudy',
      locationPattern: 'mostly_home',
      screenTimeHours: 3.8,
    ),
  );

  static const List<DemoProfile> all = [_profileA, _profileB, _profileC];

  static DemoProfile byKey(DemoProfileKey key) =>
      all.firstWhere((p) => p.key == key);

  static DemoProfile byLabel(String label) =>
      all.firstWhere((p) => p.label == label, orElse: () => _profileA);
}
