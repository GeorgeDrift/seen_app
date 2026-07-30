import '../../data/models/health_week_day.dart';

/// The bucketed time-of-day a reflection was submitted in, per the spec's
/// simple grouping. Used only to describe reflection *habits* — never as
/// evidence for mood, sleep quality, or day quality.
enum ReflectionTimeWindow { morning, afternoon, evening, lateNight }

extension on DateTime {
  ReflectionTimeWindow get window {
    final h = hour;
    if (h >= 5 && h < 12) return ReflectionTimeWindow.morning;
    if (h >= 12 && h < 17) return ReflectionTimeWindow.afternoon;
    if (h >= 17 && h < 22) return ReflectionTimeWindow.evening;
    return ReflectionTimeWindow.lateNight;
  }
}

String _windowLabel(ReflectionTimeWindow w) => switch (w) {
  ReflectionTimeWindow.morning => 'morning',
  ReflectionTimeWindow.afternoon => 'afternoon',
  ReflectionTimeWindow.evening => 'evening',
  ReflectionTimeWindow.lateNight => 'late night',
};

/// Reflection-habit stats for a 7-day window — calculated directly from the
/// dataset, never AI-generated (per spec section G: "Your reflection
/// rhythm").
class ReflectionHabits {
  const ReflectionHabits({
    required this.completedCount,
    required this.totalDays,
    required this.completionRatePercent,
    required this.typicalWindowLabel,
    required this.consistentWindow,
  });

  final int completedCount;
  final int totalDays;
  final int completionRatePercent;

  /// e.g. "evening", or "" if there weren't enough completed reflections to
  /// call any window typical.
  final String typicalWindowLabel;

  /// True when every completed reflection this week fell in the same
  /// bucketed window — lets the UI show the optional "stayed fairly
  /// consistent" line.
  final bool consistentWindow;
}

/// Pure Dart, zero-dependency — mirrors the engine-layer convention already
/// used by `signal_engine.dart`/`pattern_engine.dart` (plain functions, no
/// Riverpod, unit-testable in isolation).
class ReflectionHabitsEngine {
  const ReflectionHabitsEngine();

  ReflectionHabits summarize(List<HealthWeekDay> days) {
    final completed = days.where((d) => d.reflection.completed).toList();
    final totalDays = days.length;
    final completedCount = completed.length;
    final completionRatePercent = totalDays == 0
        ? 0
        : ((completedCount / totalDays) * 100).round();

    final windows = completed
        .map((d) => d.reflection.submittedAt)
        .whereType<DateTime>()
        .map((t) => t.window)
        .toList();

    if (windows.isEmpty) {
      return ReflectionHabits(
        completedCount: completedCount,
        totalDays: totalDays,
        completionRatePercent: completionRatePercent,
        typicalWindowLabel: '',
        consistentWindow: false,
      );
    }

    final counts = <ReflectionTimeWindow, int>{};
    for (final w in windows) {
      counts[w] = (counts[w] ?? 0) + 1;
    }
    final mostCommon = counts.entries.reduce(
      (a, b) => b.value > a.value ? b : a,
    );

    return ReflectionHabits(
      completedCount: completedCount,
      totalDays: totalDays,
      completionRatePercent: completionRatePercent,
      typicalWindowLabel: _windowLabel(mostCommon.key),
      consistentWindow: counts.length == 1,
    );
  }
}
