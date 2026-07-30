/// Rule-based co-occurrence between two clue ids across a window of days.
/// Language rule: consumers must phrase this as an *association*, never
/// as a cause-and-effect claim.
class PatternObservation {
  const PatternObservation({
    required this.clueA,
    required this.clueB,
    required this.coOccurrenceCount,
    required this.clueACount,
    required this.clueBCount,
    required this.windowDays,
  });

  final String clueA;
  final String clueB;
  final int coOccurrenceCount;
  final int clueACount;
  final int clueBCount;
  final int windowDays;

  factory PatternObservation.fromJson(Map<String, dynamic> json) =>
      PatternObservation(
        clueA: json['clueA'] as String,
        clueB: json['clueB'] as String,
        coOccurrenceCount: json['coOccurrenceCount'] as int? ?? 0,
        clueACount: json['clueACount'] as int? ?? 0,
        clueBCount: json['clueBCount'] as int? ?? 0,
        windowDays: json['windowDays'] as int? ?? 0,
      );
}
