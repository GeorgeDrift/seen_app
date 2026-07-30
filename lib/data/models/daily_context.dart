/// The passive-data snapshot for a single day.
///
/// Mirrors the backend `DailyContext` type exactly. Kept immutable — every
/// change produces a fresh copy via [copyWith] so state changes fan out
/// predictably through Riverpod.
class DailyContext {
  const DailyContext({
    required this.date,
    required this.sleepHours,
    required this.sleepComparison,
    required this.steps,
    required this.activityComparison,
    required this.calendarEventCount,
    required this.calendarLoad,
    required this.weather,
    this.locationPattern = 'mostly_home',
  });

  final String date;
  final double? sleepHours;
  final String sleepComparison; // 'lower' | 'typical' | 'higher' | 'unknown'
  final int? steps;
  final String activityComparison; // 'lower' | 'typical' | 'higher' | 'unknown'
  final int calendarEventCount;
  final String calendarLoad; // 'low' | 'moderate' | 'high'
  final String weather; // 'sunny' | 'cloudy' | 'rain' | 'snow' | 'hot' | 'cold'
  final String
  locationPattern; // 'mostly_home' | 'mostly_out' | 'mixed' | 'unknown'

  DailyContext copyWith({
    String? date,
    double? sleepHours,
    String? sleepComparison,
    int? steps,
    String? activityComparison,
    int? calendarEventCount,
    String? calendarLoad,
    String? weather,
    String? locationPattern,
  }) {
    return DailyContext(
      date: date ?? this.date,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepComparison: sleepComparison ?? this.sleepComparison,
      steps: steps ?? this.steps,
      activityComparison: activityComparison ?? this.activityComparison,
      calendarEventCount: calendarEventCount ?? this.calendarEventCount,
      calendarLoad: calendarLoad ?? this.calendarLoad,
      weather: weather ?? this.weather,
      locationPattern: locationPattern ?? this.locationPattern,
    );
  }

  factory DailyContext.fromJson(Map<String, dynamic> json) => DailyContext(
    date: json['date'] as String,
    sleepHours: (json['sleepHours'] as num?)?.toDouble(),
    sleepComparison: json['sleepComparison'] as String? ?? 'unknown',
    steps: json['steps'] as int?,
    activityComparison: json['activityComparison'] as String? ?? 'unknown',
    calendarEventCount: json['calendarEventCount'] as int? ?? 0,
    calendarLoad: json['calendarLoad'] as String? ?? 'low',
    weather: json['weather'] as String? ?? 'cloudy',
    locationPattern: json['locationPattern'] as String? ?? 'unknown',
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'sleepHours': sleepHours,
    'sleepComparison': sleepComparison,
    'steps': steps,
    'activityComparison': activityComparison,
    'calendarEventCount': calendarEventCount,
    'calendarLoad': calendarLoad,
    'weather': weather,
    'locationPattern': locationPattern,
  };
}
