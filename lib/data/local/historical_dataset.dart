import 'package:uuid/uuid.dart';

import '../../domain/engine/signal_engine.dart';
import '../../domain/engine/summary_engine.dart';
import '../models/clue_selection.dart';
import '../models/daily_context.dart';
import '../models/daily_entry.dart';

/// Generates the 14-day synthetic history used by the patterns and
/// therapist screens. Cycles through overloaded/active/quiet-recovery
/// shapes so pattern insights (e.g. "quiet corner on short sleep days")
/// have real numerators to draw from.
class HistoricalDataset {
  HistoricalDataset({
    SignalEngine? signalEngine,
    SummaryEngine? summaryEngine,
    Uuid? uuid,
    DateTime? anchorDate,
  })  : _signalEngine = signalEngine ?? const SignalEngine(),
        _summaryEngine = summaryEngine ?? const SummaryEngine(),
        _uuid = uuid ?? const Uuid(),
        _anchorDate = anchorDate ?? DateTime(2026, 7, 29);

  final SignalEngine _signalEngine;
  final SummaryEngine _summaryEngine;
  final Uuid _uuid;
  final DateTime _anchorDate;

  List<DailyEntry> generate({int days = 14}) {
    final entries = <DailyEntry>[];
    for (var i = 1; i <= days; i++) {
      final dt = _anchorDate.subtract(Duration(days: i));
      final dateStr =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final isOverloaded = i % 3 == 0;
      final isActive = i % 3 == 1;

      final ctx = isOverloaded
          ? DailyContext(
              date: dateStr,
              sleepHours: 5.5,
              sleepComparison: 'lower',
              steps: 2400,
              activityComparison: 'lower',
              calendarEventCount: 7,
              calendarLoad: 'high',
              weather: 'rain',
            )
          : (isActive
              ? DailyContext(
                  date: dateStr,
                  sleepHours: 7.6,
                  sleepComparison: 'typical',
                  steps: 9800,
                  activityComparison: 'higher',
                  calendarEventCount: 2,
                  calendarLoad: 'low',
                  weather: 'sunny',
                )
              : DailyContext(
                  date: dateStr,
                  sleepHours: 8.2,
                  sleepComparison: 'typical',
                  steps: 3400,
                  activityComparison: 'lower',
                  calendarEventCount: 1,
                  calendarLoad: 'low',
                  weather: 'cloudy',
                ));

      final signals = _signalEngine.interpret(ctx);
      final selections = <ClueSelection>[];

      if (isOverloaded) {
        selections.add(ClueSelection(
          clueId: 'quiet_corner_01',
          clueTitle: 'Quiet Corner',
          selectedAt: dt,
          dailyContextDate: dateStr,
          userMeaning: 'Restorative solitude',
        ));
        selections.add(ClueSelection(
          clueId: 'meeting_overload_01',
          clueTitle: 'Meeting Overload',
          selectedAt: dt,
          dailyContextDate: dateStr,
          userMeaning: 'Draining',
        ));
      } else if (isActive) {
        selections.add(ClueSelection(
          clueId: 'walking_shoes_01',
          clueTitle: 'Walking Shoes',
          selectedAt: dt,
          dailyContextDate: dateStr,
          userMeaning: 'Workout to clear head',
        ));
      }

      entries.add(DailyEntry(
        id: _uuid.v4(),
        date: dateStr,
        context: ctx,
        interpretedSignals: signals,
        displayedClueIds: const [
          'quiet_corner_01',
          'meeting_overload_01',
          'walking_shoes_01',
        ],
        selectedClues: selections,
        generatedSummary: _summaryEngine.buildLocal(selections),
      ));
    }
    return entries;
  }
}
