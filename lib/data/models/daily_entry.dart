import 'clue_selection.dart';
import 'daily_context.dart';
import 'interpreted_signal.dart';

/// The persisted record of a single day: what the context was, what signals
/// the interpreter drew from it, which clues were shown, which the user
/// picked, and the confirmed-info-only summary.
class DailyEntry {
  const DailyEntry({
    required this.id,
    required this.date,
    required this.context,
    required this.interpretedSignals,
    required this.displayedClueIds,
    required this.selectedClues,
    required this.generatedSummary,
  });

  final String id;
  final String date;
  final DailyContext context;
  final List<InterpretedSignal> interpretedSignals;
  final List<String> displayedClueIds;
  final List<ClueSelection> selectedClues;
  final String generatedSummary;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'context': context.toJson(),
        'interpretedSignals':
            interpretedSignals.map((s) => s.toJson()).toList(),
        'displayedClueIds': displayedClueIds,
        'selectedClues': selectedClues.map((s) => s.toJson()).toList(),
        'generatedSummary': generatedSummary,
      };
}
