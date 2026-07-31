import '../models/daily_context.dart';
import '../models/demo_profile.dart';

/// The three demo profiles the app is designed around. Values are tuned so
/// each one lands on a *different* SceneKind under
/// `ScoringEngine._selectScene`'s Recovery/Activation/Load rules — verified
/// via a scoring_engine_test.dart-style check. They were originally tuned
/// for the old weather-based scene rule (rain → rest, sunny → active,
/// cloudy → default); after the engine changed, A and B both landed on
/// "Full and Active" and nothing ever produced "Rest and Reset". Screen time
/// (B) and sleep (C) were adjusted here specifically to fix that collision —
/// see the per-profile comments for the exact rule each one exercises.
class DemoProfiles {
  static const _date = '2026-07-29';

  // Recovery=Low (sleep<6.5), Activation=Low (steps<3000), Load=High
  // (calendarLoad 'high') → Load wins immediately → "Full and Active".
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

  // Recovery=Medium (7.8h), Activation=High (steps>8000), Load=Low
  // (calendarLoad 'low' + screenTimeHours<2h) → high Activation with low
  // Load stays "Open and Steady" — an active day isn't automatically a
  // busy/overloaded one. (screenTimeHours lowered from 2.6 to 1.5 — at 2.6
  // it pushed Load to Medium, which combined with high Activation instead
  // produces "Full and Active", colliding with Profile A.)
  static const _profileB = DemoProfile(
    key: DemoProfileKey.b,
    label: 'Profile B (Active)',
    description:
        'Good sleep, high movement, a light calendar, low screen time, and sun.',
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
      screenTimeHours: 1.5,
    ),
  );

  // Recovery=Low (sleep<6.5 — restless, not the "full sleep" this profile
  // used to describe under the old engine), Activation=Medium (steps
  // 3000-8000) → Recovery Low + Activation not High → "Rest and Reset",
  // regardless of Load. This is the only rule shape that produces "Rest and
  // Reset", so this profile's sleep value was deliberately lowered (8.1 →
  // 5.8) to actually exercise that scene — a "quiet recovery" day here reads
  // as "recovering from a rough night", not "already well-rested".
  static const _profileC = DemoProfile(
    key: DemoProfileKey.c,
    label: 'Profile C (Quiet Recovery)',
    description: 'Restless sleep, low movement, an empty calendar, and clouds.',
    context: DailyContext(
      date: _date,
      sleepHours: 5.8,
      sleepComparison: 'lower',
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
