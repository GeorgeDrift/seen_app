/// A single day's passive context + reflection for the "Health over time"
/// weekly dashboard. Deliberately a separate shape from [DailyContext]/
/// [ClueSelection] — this feature's wire contract (nested objects, plain
/// `name`/`meaning` clue pairs, capitalized load labels like "Busy"/"Light")
/// doesn't match those models, and forcing a translation layer would add
/// risk for no benefit. `toJson()` is exactly what gets POSTed to the
/// backend's `/week/insights` endpoint.
class HealthWeekDay {
  const HealthWeekDay({
    required this.date,
    required this.sleep,
    required this.movement,
    required this.weather,
    required this.calendar,
    required this.reflection,
  });

  final String date;
  final HealthWeekSleep sleep;
  final HealthWeekMovement movement;
  final HealthWeekWeather weather;
  final HealthWeekCalendar calendar;
  final HealthWeekReflection reflection;

  Map<String, dynamic> toJson() => {
    'date': date,
    'sleep': sleep.toJson(),
    'movement': movement.toJson(),
    'weather': weather.toJson(),
    'calendar': calendar.toJson(),
    'reflection': reflection.toJson(),
  };
}

class HealthWeekSleep {
  const HealthWeekSleep({required this.durationHours});

  final double durationHours;

  Map<String, dynamic> toJson() => {'durationHours': durationHours};
}

class HealthWeekMovement {
  const HealthWeekMovement({required this.steps, required this.relativeLevel});

  final int steps;

  /// One of "Lower than usual" | "Usual" | "Higher than usual".
  final String relativeLevel;

  Map<String, dynamic> toJson() => {
    'steps': steps,
    'relativeLevel': relativeLevel,
  };
}

class HealthWeekWeather {
  const HealthWeekWeather({required this.condition, required this.temperatureF});

  final String condition;
  final int temperatureF;

  Map<String, dynamic> toJson() => {
    'condition': condition,
    'temperatureF': temperatureF,
  };
}

class HealthWeekCalendar {
  const HealthWeekCalendar({required this.eventCount, required this.load});

  final int eventCount;

  /// One of "Light" | "Moderate" | "Busy".
  final String load;

  Map<String, dynamic> toJson() => {'eventCount': eventCount, 'load': load};
}

class HealthWeekClueMeaning {
  const HealthWeekClueMeaning({required this.name, required this.meaning});

  final String name;
  final String meaning;

  Map<String, dynamic> toJson() => {'name': name, 'meaning': meaning};
}

class HealthWeekReflection {
  const HealthWeekReflection({
    required this.completed,
    this.submittedAt,
    this.selectedClues = const [],
    this.finalText,
  });

  final bool completed;

  /// ISO-8601 with offset, e.g. `2026-05-12T22:14:00-04:00`. Only used for
  /// reflection-habit calculations (typical submission window) — never sent
  /// to the AI as evidence of mood/health.
  final DateTime? submittedAt;
  final List<HealthWeekClueMeaning> selectedClues;
  final String? finalText;

  Map<String, dynamic> toJson() => {
    'completed': completed,
    'submittedAt': submittedAt?.toIso8601String(),
    'selectedClues': selectedClues.map((c) => c.toJson()).toList(),
    'finalText': finalText,
  };
}
