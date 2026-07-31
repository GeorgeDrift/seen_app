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
    this.timeRangeLabel = '',
    this.hourlyCounts = const [],
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

  /// e.g. "8:55 PM – 10:40 PM", spanning the earliest and latest completed
  /// `submittedAt` clock times — "" if none have a timestamp.
  final String timeRangeLabel;

  /// 24 entries: index 0 is the 6 AM–7 AM bucket, index 23 is 5 AM–6 AM the
  /// next day (wrapping midnight) — a count of completed reflections whose
  /// `submittedAt` falls in that hour. Empty list if there are none. Bar
  /// height/tone (quiet/warm/peak) is a presentation concern for whatever
  /// renders this, not engine logic — this only counts.
  final List<int> hourlyCounts;
}

/// 0..23 -> a 6 AM-anchored bucket index (0 = 6 AM–7 AM, 23 = 5 AM–6 AM next
/// day), so the resulting 24-entry list reads left-to-right as a full day
/// starting in the early morning, matching how a "your day" chart is read.
int _hourBucket(int hour) => (hour - 6 + 24) % 24;

String _formatClockTime(DateTime t) {
  final hour24 = t.hour;
  final period = hour24 < 12 ? 'AM' : 'PM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
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

    final timestamps = completed
        .map((d) => d.reflection.submittedAt)
        .whereType<DateTime>()
        .toList();

    if (timestamps.isEmpty) {
      return ReflectionHabits(
        completedCount: completedCount,
        totalDays: totalDays,
        completionRatePercent: completionRatePercent,
        typicalWindowLabel: '',
        consistentWindow: false,
      );
    }

    final windows = timestamps.map((t) => t.window).toList();
    final counts = <ReflectionTimeWindow, int>{};
    for (final w in windows) {
      counts[w] = (counts[w] ?? 0) + 1;
    }
    final mostCommon = counts.entries.reduce(
      (a, b) => b.value > a.value ? b : a,
    );

    final sorted = [...timestamps]
      ..sort((a, b) => a.hour * 60 + a.minute - (b.hour * 60 + b.minute));
    final timeRangeLabel = sorted.length == 1
        ? _formatClockTime(sorted.first)
        : '${_formatClockTime(sorted.first)} – ${_formatClockTime(sorted.last)}';

    final hourlyCounts = List<int>.filled(24, 0);
    for (final t in timestamps) {
      hourlyCounts[_hourBucket(t.hour)]++;
    }

    return ReflectionHabits(
      completedCount: completedCount,
      totalDays: totalDays,
      completionRatePercent: completionRatePercent,
      typicalWindowLabel: _windowLabel(mostCommon.key),
      consistentWindow: counts.length == 1,
      timeRangeLabel: timeRangeLabel,
      hourlyCounts: hourlyCounts,
    );
  }
}
