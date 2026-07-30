/// AI-generated weekly insights returned by `POST /week/insights`. These
/// three sections are the only part of "Health over time" that's AI-
/// generated — the passive-context timeline and reflection-habit stats are
/// calculated directly from [HealthWeekDay] data, never from this response.
class WeeklyInsights {
  const WeeklyInsights({
    required this.patternWorthNoticing,
    required this.whatMayBeHelping,
    required this.themes,
  });

  final WeeklyPatternInsight patternWorthNoticing;
  final WeeklyHelpingInsight whatMayBeHelping;
  final List<WeeklyTheme> themes;

  factory WeeklyInsights.fromJson(Map<String, dynamic> json) => WeeklyInsights(
    patternWorthNoticing: WeeklyPatternInsight.fromJson(
      Map<String, dynamic>.from(json['patternWorthNoticing'] as Map),
    ),
    whatMayBeHelping: WeeklyHelpingInsight.fromJson(
      Map<String, dynamic>.from(json['whatMayBeHelping'] as Map),
    ),
    themes: (json['themes'] as List<dynamic>? ?? const [])
        .map((t) => WeeklyTheme.fromJson(Map<String, dynamic>.from(t as Map)))
        .toList(),
  );
}

class WeeklyPatternInsight {
  const WeeklyPatternInsight({
    required this.title,
    required this.summary,
    required this.supportingDayCount,
    required this.supportingDates,
    required this.signals,
    required this.commonClues,
    required this.confidence,
  });

  final String title;
  final String summary;
  final int supportingDayCount;
  final List<String> supportingDates;
  final List<String> signals;
  final List<String> commonClues;

  /// 'low' | 'medium' | 'high'.
  final String confidence;

  factory WeeklyPatternInsight.fromJson(Map<String, dynamic> json) =>
      WeeklyPatternInsight(
        title: json['title'] as String? ?? 'A pattern worth noticing',
        summary: json['summary'] as String? ?? '',
        supportingDayCount: (json['supportingDayCount'] as num?)?.toInt() ?? 0,
        supportingDates: _stringList(json['supportingDates']),
        signals: _stringList(json['signals']),
        commonClues: _stringList(json['commonClues']),
        confidence: json['confidence'] as String? ?? 'low',
      );
}

class WeeklyHelpingInsight {
  const WeeklyHelpingInsight({
    required this.title,
    required this.summary,
    required this.supportingReflectionCount,
    required this.supportingDates,
    required this.signals,
    required this.confidence,
  });

  final String title;
  final String summary;
  final int supportingReflectionCount;
  final List<String> supportingDates;
  final List<String> signals;

  /// 'low' | 'medium' | 'high'.
  final String confidence;

  factory WeeklyHelpingInsight.fromJson(Map<String, dynamic> json) =>
      WeeklyHelpingInsight(
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        supportingReflectionCount:
            (json['supportingReflectionCount'] as num?)?.toInt() ?? 0,
        supportingDates: _stringList(json['supportingDates']),
        signals: _stringList(json['signals']),
        confidence: json['confidence'] as String? ?? 'low',
      );
}

class WeeklyTheme {
  const WeeklyTheme({
    required this.title,
    required this.description,
    required this.quotes,
    required this.reflectionCount,
    required this.supportingDates,
    required this.relatedClues,
  });

  final String title;
  final String description;

  /// Exact excerpts from a submitted day's `reflection.finalText` — the
  /// backend already verifies these are real substrings before returning
  /// them, so no re-verification is needed client-side.
  final List<String> quotes;
  final int reflectionCount;
  final List<String> supportingDates;
  final List<String> relatedClues;

  factory WeeklyTheme.fromJson(Map<String, dynamic> json) => WeeklyTheme(
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    quotes: _stringList(json['quotes']),
    reflectionCount: (json['reflectionCount'] as num?)?.toInt() ?? 0,
    supportingDates: _stringList(json['supportingDates']),
    relatedClues: _stringList(json['relatedClues']),
  );
}

List<String> _stringList(dynamic value) =>
    (value as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
