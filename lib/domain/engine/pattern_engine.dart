import 'package:flutter/material.dart';
import '../../data/models/daily_entry.dart';
import '../../data/models/pattern_observation.dart';
import '../../core/theme/app_theme.dart';

/// A human-friendly, presentation-ready pattern derived from raw
/// `PatternObservation` counts. This is where associative (not causal!)
/// language and colors live so the UI stays dumb.
class PatternInsight {
  const PatternInsight({
    required this.title,
    required this.description,
    required this.tag,
    required this.color,
    required this.count,
    required this.total,
  });

  final String title;
  final String description;
  final String tag;
  final Color color;
  final int count;
  final int total;

  double get ratio => total == 0 ? 0 : count / total;
}

/// Rule-based frequency and co-occurrence over saved daily entries.
///
/// Every phrase this engine emits describes an *association*
/// ("X and Y appeared together on N of M days"). It never claims causation.
class PatternEngine {
  const PatternEngine();

  /// Raw co-occurrence count for two clue ids across `entries`.
  PatternObservation coOccurrence(
    List<DailyEntry> entries,
    String clueA,
    String clueB,
  ) {
    var aCount = 0;
    var bCount = 0;
    var coCount = 0;
    for (final entry in entries) {
      final ids = entry.selectedClues.map((s) => s.clueId).toSet();
      final hasA = ids.contains(clueA);
      final hasB = ids.contains(clueB);
      if (hasA) aCount++;
      if (hasB) bCount++;
      if (hasA && hasB) coCount++;
    }
    return PatternObservation(
      clueA: clueA,
      clueB: clueB,
      coOccurrenceCount: coCount,
      clueACount: aCount,
      clueBCount: bCount,
      windowDays: entries.length,
    );
  }

  /// The three curated pattern insights the demo highlights on the patterns
  /// screen and in the therapist portal.
  List<PatternInsight> insights(List<DailyEntry> historical) {
    final out = <PatternInsight>[];

    // 1. Short sleep + quiet corner marked restorative
    var shortSleepDays = 0;
    var quietCornerRestorative = 0;
    for (final entry in historical) {
      final isShortSleep =
          entry.context.sleepHours != null && entry.context.sleepHours! < 6.5;
      if (isShortSleep) shortSleepDays++;
      final has = entry.selectedClues.any(
        (s) =>
            s.clueId == 'quiet_corner_01' &&
            (s.userMeaning?.toLowerCase().contains('restorative') == true ||
                s.userMeaning?.toLowerCase().contains('recovery') == true),
      );
      if (isShortSleep && has) quietCornerRestorative++;
    }
    if (shortSleepDays > 0) {
      out.add(
        PatternInsight(
          title: 'Quiet Solitude on Short Sleep Days',
          description:
              'On $quietCornerRestorative of the $shortSleepDays days with short sleep (<6.5h), you selected Quiet Corner as restorative.',
          tag: 'Restorative Solitude',
          color: AppColors.primary,
          count: quietCornerRestorative,
          total: shortSleepDays,
        ),
      );
    }

    // 2. Heavy workload + meeting overload marked draining
    var heavyDays = 0;
    var meetingDraining = 0;
    for (final entry in historical) {
      final isHeavy =
          entry.context.calendarLoad == 'high' ||
          entry.context.calendarEventCount >= 6;
      if (isHeavy) heavyDays++;
      final has = entry.selectedClues.any(
        (s) => s.clueId == 'meeting_overload_01' && s.userMeaning == 'Draining',
      );
      if (isHeavy && has) meetingDraining++;
    }
    if (heavyDays > 0) {
      out.add(
        PatternInsight(
          title: 'Schedule Density & Energy Drain',
          description:
              'Meeting Overload was marked as "Draining" on $meetingDraining of $heavyDays high-density calendar days.',
          tag: 'Workload Drain',
          color: AppColors.calendar,
          count: meetingDraining,
          total: heavyDays,
        ),
      );
    }

    // 3. High steps + walking shoes marked head-clearing
    var highMoveDays = 0;
    var workoutHeadClear = 0;
    for (final entry in historical) {
      final isHighMove =
          entry.context.steps != null && entry.context.steps! > 8000;
      if (isHighMove) highMoveDays++;
      final has = entry.selectedClues.any(
        (s) =>
            s.clueId == 'walking_shoes_01' &&
            s.userMeaning?.toLowerCase().contains('workout') == true,
      );
      if (isHighMove && has) workoutHeadClear++;
    }
    if (highMoveDays > 0) {
      out.add(
        PatternInsight(
          title: 'Active Movement for Mindset',
          description:
              'On $workoutHeadClear of $highMoveDays high-step days (>8k steps), walking/running was marked as "Workout to clear head".',
          tag: 'Active Recovery',
          color: AppColors.steps,
          count: workoutHeadClear,
          total: highMoveDays,
        ),
      );
    }

    return out;
  }
}
