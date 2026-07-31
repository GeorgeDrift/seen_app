import 'package:flutter_test/flutter_test.dart';
import 'package:seen_app/data/local/health_week_dataset.dart';
import 'package:seen_app/domain/engine/reflection_habits_engine.dart';

void main() {
  const engine = ReflectionHabitsEngine();

  group('ReflectionHabitsEngine.summarize — real 7-day demo dataset', () {
    final habits = engine.summarize(HealthWeekDataset.demo);

    test('counts completed/total days correctly (one missed day)', () {
      expect(habits.completedCount, 6);
      expect(habits.totalDays, 7);
      expect(habits.completionRatePercent, 86);
    });

    test('typical window is evening, but not fully consistent', () {
      // Submissions: 22:14, 21:08, 22:40, 20:55, 21:50, 21:15 -> four fall
      // in the 17:00-21:59 "evening" bucket, two (22:14, 22:40) fall in
      // "late night" (>=22:00) per ReflectionTimeWindow's boundaries.
      expect(habits.typicalWindowLabel, 'evening');
      expect(habits.consistentWindow, isFalse);
    });

    test('time range spans the earliest to latest submission', () {
      // Submissions: 22:14, 21:08, 22:40, 20:55, 21:50, 21:15.
      expect(habits.timeRangeLabel, '8:55 PM – 10:40 PM');
    });

    test('hourly histogram peaks at 9 PM (hour 21)', () {
      expect(habits.hourlyCounts, hasLength(24));
      final hour21 = habits.hourlyCounts[_hourBucketIndex(21)];
      final hour22 = habits.hourlyCounts[_hourBucketIndex(22)];
      final hour20 = habits.hourlyCounts[_hourBucketIndex(20)];
      expect(hour21, 3);
      expect(hour22, 2);
      expect(hour20, 1);
      expect(habits.hourlyCounts.reduce((a, b) => a + b), 6);
      // 9 PM should be the single largest bucket.
      expect(hour21, greaterThan(hour22));
      expect(hour21, greaterThan(hour20));
    });
  });

  test('no completed reflections -> empty label, no consistency claim', () {
    final habits = engine.summarize(const []);
    expect(habits.completedCount, 0);
    expect(habits.totalDays, 0);
    expect(habits.typicalWindowLabel, '');
    expect(habits.consistentWindow, isFalse);
    expect(habits.timeRangeLabel, '');
    expect(habits.hourlyCounts, isEmpty);
  });
}

/// Mirrors the engine's private 6-AM-anchored bucket mapping for test
/// assertions (0 = 6 AM–7 AM ... 23 = 5 AM–6 AM next day).
int _hourBucketIndex(int hour) => (hour - 6 + 24) % 24;
