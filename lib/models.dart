import 'package:flutter/material.dart';

// 1. Daily Passive-Context Data Model
class DailyContext {
  final String date;
  final double? sleepHours;
  final String sleepComparison; // 'lower', 'typical', 'higher', 'unknown'
  final int? steps;
  final String activityComparison; // 'lower', 'typical', 'higher', 'unknown'
  final int calendarEventCount;
  final String calendarLoad; // 'low', 'moderate', 'high'
  final String weather; // 'sunny', 'cloudy', 'rain', 'snow', 'hot', 'cold'
  final String locationPattern; // 'mostly_home', 'mostly_out', 'mixed', 'unknown'

  DailyContext({
    required this.date,
    this.sleepHours,
    required this.sleepComparison,
    this.steps,
    required this.activityComparison,
    required this.calendarEventCount,
    required this.calendarLoad,
    required this.weather,
    this.locationPattern = 'mostly_home',
  });

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
}

// 2. Interpreted Signal Data Model
class InterpretedSignal {
  final String tag;
  final double strength; // 0.0 to 1.0
  final String source;
  final String explanation;

  InterpretedSignal({
    required this.tag,
    required this.strength,
    required this.source,
    required this.explanation,
  });
}

// 3. Clue Data Model
enum ClueType {
  signalInformed,
  possibleExplanation,
  helpfulAction,
  neutralDistractor,
}

class Clue {
  final String id;
  final String title;
  final String category; // 'sleep', 'movement', 'workload', 'environment', 'social', 'physical', 'recovery', 'neutral'
  final List<String> signalTags;
  final List<String> possibleMeanings;
  final ClueType clueType;
  final double baseWeight;
  final double recentRepeatPenalty;
  
  // Visual placement (percentage coordinates 0.0 to 1.0)
  final double x;
  final double y;
  final IconData icon;

  // AI / Fallback Question
  final String question;
  final List<String> options;

  Clue({
    required this.id,
    required this.title,
    required this.category,
    required this.signalTags,
    required this.possibleMeanings,
    required this.clueType,
    required this.baseWeight,
    required this.recentRepeatPenalty,
    required this.x,
    required this.y,
    required this.icon,
    required this.question,
    required this.options,
  });
}

// 4. User Clue Selection Data Model
class ClueSelection {
  final String clueId;
  final String clueTitle;
  final DateTime selectedAt;
  final String? userMeaning;
  final String? followUpQuestion;
  final String? answerOption;
  final String confidence; // 'clear', 'uncertain', 'skipped'

  ClueSelection({
    required this.clueId,
    required this.clueTitle,
    required this.selectedAt,
    this.userMeaning,
    this.followUpQuestion,
    this.answerOption,
    this.confidence = 'clear',
  });
}

// 5. Completed Daily Entry Data Model
class DailyEntry {
  final String id;
  final String date;
  final DailyContext context;
  final List<InterpretedSignal> interpretedSignals;
  final List<String> displayedClueIds;
  final List<ClueSelection> selectedClues;
  final String generatedSummary;

  DailyEntry({
    required this.id,
    required this.date,
    required this.context,
    required this.interpretedSignals,
    required this.displayedClueIds,
    required this.selectedClues,
    required this.generatedSummary,
  });
}
