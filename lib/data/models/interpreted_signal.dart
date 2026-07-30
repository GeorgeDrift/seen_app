/// A single semantic tag derived from raw passive data.
///
/// Interpretation NEVER produces a psychological label — signals are purely
/// descriptive (e.g. "short_sleep", "high_calendar_load"). Any interpretation
/// of what a signal *means* happens later, and only the user can commit to
/// one — the system just surfaces possibilities.
class InterpretedSignal {
  const InterpretedSignal({
    required this.tag,
    required this.strength,
    required this.source,
    required this.explanation,
  });

  final String tag;
  final double strength; // 0.0 – 1.0
  final String source;
  final String explanation;

  factory InterpretedSignal.fromJson(Map<String, dynamic> json) =>
      InterpretedSignal(
        tag: json['tag'] as String,
        strength: (json['strength'] as num).toDouble(),
        source: json['source'] as String,
        explanation: json['explanation'] as String,
      );

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'strength': strength,
    'source': source,
    'explanation': explanation,
  };
}
