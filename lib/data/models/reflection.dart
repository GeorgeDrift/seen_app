/// The AI-generated (or user-edited) whole-day narrative reflection.
class Reflection {
  const Reflection({
    required this.text,
    required this.generatedAt,
    this.isEdited = false,
    this.cluesUsed = const [],
    this.passiveContextUsed = const [],
    this.confidence = 'medium',
    this.needsUserReview = false,
    this.safetyState = 'standard',
  });

  final String text;
  final DateTime generatedAt;
  final bool isEdited;

  /// Clue names meaningfully incorporated into the reflection.
  final List<String> cluesUsed;

  /// Passive-context fields (e.g. "calendarLoad", "weather") meaningfully
  /// incorporated into the reflection.
  final List<String> passiveContextUsed;

  /// 'high' | 'medium' | 'low'.
  final String confidence;

  /// True when the input was limited, contradictory, or required
  /// substantial interpretation — a hint the user may want to double-check
  /// the result before saving.
  final bool needsUserReview;

  /// 'standard' | 'needs_immediate_support'. When not 'standard', [text]
  /// is a fixed crisis-resources message, not a normal reflection — the UI
  /// layer is responsible for treating it differently once that's wired up.
  final String safetyState;

  factory Reflection.fromJson(Map<String, dynamic> json) => Reflection(
    text: json['reflection'] as String,
    generatedAt: DateTime.now(),
    cluesUsed: _stringList(json['cluesUsed']),
    passiveContextUsed: _stringList(json['passiveContextUsed']),
    confidence: json['confidence'] as String? ?? 'medium',
    needsUserReview: json['needsUserReview'] as bool? ?? false,
    safetyState: json['safetyState'] as String? ?? 'standard',
  );
}

List<String> _stringList(dynamic value) =>
    (value as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
