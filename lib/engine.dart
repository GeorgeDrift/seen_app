import 'package:flutter/material.dart';
import 'models.dart';

// --- 1. SIGNAL INTERPRETATION ENGINE ---
List<InterpretedSignal> interpretSignals(DailyContext context) {
  final List<InterpretedSignal> signals = [];

  // Sleep Signal
  if (context.sleepHours != null && context.sleepHours! < 6.5) {
    final diff = 6.5 - context.sleepHours!;
    signals.add(InterpretedSignal(
      tag: "short_sleep",
      strength: (diff / 2.0).clamp(0.1, 1.0),
      source: "sleep_hours",
      explanation: "Sleep duration (${context.sleepHours!.toStringAsFixed(1)}h) was below the 6.5h threshold.",
    ));
  } else if (context.sleepHours != null && context.sleepHours! > 8.5) {
    signals.add(InterpretedSignal(
      tag: "long_sleep",
      strength: 0.8,
      source: "sleep_hours",
      explanation: "Sleep duration (${context.sleepHours!.toStringAsFixed(1)}h) was longer than typical baseline.",
    ));
  }

  // Calendar Load Signal
  if (context.calendarLoad == "high" || context.calendarEventCount >= 6) {
    signals.add(InterpretedSignal(
      tag: "high_calendar_load",
      strength: 0.9,
      source: "calendar",
      explanation: "The day included ${context.calendarEventCount} scheduled events.",
    ));
  } else if (context.calendarLoad == "low" || context.calendarEventCount <= 1) {
    signals.add(InterpretedSignal(
      tag: "low_calendar_load",
      strength: 0.7,
      source: "calendar",
      explanation: "Schedule had high spaciousness with only ${context.calendarEventCount} events.",
    ));
  }

  // Activity / Movement Signal
  if (context.activityComparison == "lower" || (context.steps != null && context.steps! < 3000)) {
    signals.add(InterpretedSignal(
      tag: "low_activity",
      strength: 0.75,
      source: "steps",
      explanation: "Movement (${context.steps ?? 0} steps) was lower than usual baseline.",
    ));
  } else if (context.activityComparison == "higher" || (context.steps != null && context.steps! > 8000)) {
    signals.add(InterpretedSignal(
      tag: "high_activity",
      strength: 0.85,
      source: "steps",
      explanation: "Movement (${context.steps ?? 0} steps) was higher than usual baseline.",
    ));
  }

  // Weather Signal
  if (context.weather == "rain" || context.weather == "snow") {
    signals.add(InterpretedSignal(
      tag: "rainy_environment",
      strength: 0.65,
      source: "weather",
      explanation: "Precipitation recorded for this day (${context.weather}).",
    ));
  } else if (context.weather == "sunny") {
    signals.add(InterpretedSignal(
      tag: "sunny_environment",
      strength: 0.70,
      source: "weather",
      explanation: "Clear sunny weather conditions.",
    ));
  }

  return signals;
}

// --- 2. CLUE SCORING ENGINE ---
double scoreClue(Clue clue, List<InterpretedSignal> signals, List<String> recentClueIds) {
  final matchingSignals = signals.where((s) => clue.signalTags.contains(s.tag)).toList();
  final signalScore = matchingSignals.fold<double>(0.0, (sum, s) => sum + s.strength);
  final repetitionPenalty = recentClueIds.contains(clue.id) ? clue.recentRepeatPenalty : 0.0;

  return clue.baseWeight + signalScore - repetitionPenalty;
}

// --- 3. SCENE COMPOSITION ENGINE ---
class SceneComposition {
  final List<Clue> visibleClues;
  final int signalInformedCount;
  final int possibleExplanationCount;
  final int helpfulCount;
  final int distractorCount;

  SceneComposition({
    required this.visibleClues,
    required this.signalInformedCount,
    required this.possibleExplanationCount,
    required this.helpfulCount,
    required this.distractorCount,
  });
}

SceneComposition composeScene(List<Clue> catalog, List<InterpretedSignal> signals, List<String> recentClueIds) {
  // Score all catalog clues
  final Scored = catalog.map((clue) {
    return MapEntry(clue, scoreClue(clue, signals, recentClueIds));
  }).toList();

  // Sort by score descending
  Scored.sort((a, b) => b.value.compareTo(a.value));

  final List<Clue> signalInformed = [];
  final List<Clue> explanations = [];
  final List<Clue> helpful = [];
  final List<Clue> distractors = [];

  for (var entry in Scored) {
    final clue = entry.key;
    switch (clue.clueType) {
      case ClueType.signalInformed:
        if (signalInformed.length < 4) signalInformed.add(clue);
        break;
      case ClueType.possibleExplanation:
        if (explanations.length < 3) explanations.add(clue);
        break;
      case ClueType.helpfulAction:
        if (helpful.length < 3) helpful.add(clue);
        break;
      case ClueType.neutralDistractor:
        if (distractors.length < 8) distractors.add(clue);
        break;
    }
  }

  final finalClues = [...signalInformed, ...explanations, ...helpful, ...distractors];

  return SceneComposition(
    visibleClues: finalClues,
    signalInformedCount: signalInformed.length,
    possibleExplanationCount: explanations.length,
    helpfulCount: helpful.length,
    distractorCount: distractors.length,
  );
}

// --- 4. PREDEFINED DEMO PROFILES ---
class DemoProfiles {
  static final DailyContext profileA = DailyContext(
    date: '2026-07-29',
    sleepHours: 5.4,
    sleepComparison: 'lower',
    steps: 2100,
    activityComparison: 'lower',
    calendarEventCount: 7,
    calendarLoad: 'high',
    weather: 'rain',
    locationPattern: 'mostly_home',
  );

  static final DailyContext profileB = DailyContext(
    date: '2026-07-29',
    sleepHours: 7.8,
    sleepComparison: 'typical',
    steps: 10300,
    activityComparison: 'higher',
    calendarEventCount: 2,
    calendarLoad: 'low',
    weather: 'sunny',
    locationPattern: 'mostly_out',
  );

  static final DailyContext profileC = DailyContext(
    date: '2026-07-29',
    sleepHours: 8.1,
    sleepComparison: 'typical',
    steps: 3200,
    activityComparison: 'lower',
    calendarEventCount: 0,
    calendarLoad: 'low',
    weather: 'cloudy',
    locationPattern: 'mostly_home',
  );
}

// --- 5. CATEGORY-BASED FALLBACK QUESTIONS ENGINE ---
Map<String, Map<String, dynamic>> getFallbackQuestions() {
  return {
    'sleep': {
      'question': 'How did this affect your energy today?',
      'options': ['Lower energy', 'Harder to focus', 'Did not affect me', 'Not sure'],
    },
    'workload': {
      'question': 'How did this schedule or workload feel today?',
      'options': ['Manageable', 'Energizing', 'Draining', 'Not sure'],
    },
    'movement': {
      'question': 'What was behind your physical activity level today?',
      'options': ['Needed physical movement', 'Felt stuck at desk', 'Felt restorative rest', 'Not sure'],
    },
    'social': {
      'question': 'How did this interaction feel?',
      'options': ['Supportive', 'Draining', 'Neutral', 'Not sure'],
    },
    'recovery': {
      'question': 'What did this moment mean to you today?',
      'options': ['Helped me recover', 'Felt isolating', 'Felt neutral', 'Not sure'],
    },
    'environment': {
      'question': 'How did your surroundings impact your mindset?',
      'options': ['Created cozy focus', 'Made me feel restless', 'Had no impact', 'Not sure'],
    },
  };
}

// --- 6. DAILY SUMMARY GENERATOR ---
// Strictly uses confirmed user meanings only (no false causal claims)
String generateConfirmedDailySummary(List<ClueSelection> selections) {
  if (selections.isEmpty) {
    return "No moments annotated for today yet.";
  }

  final parts = <String>[];
  for (var sel in selections) {
    if (sel.userMeaning != null && sel.confidence != 'skipped') {
      parts.add("${sel.clueTitle} was marked as '${sel.userMeaning}'");
    }
  }

  if (parts.isEmpty) {
    return "Explored clues, but no explicit meanings recorded.";
  }

  return "Today's Contextual Log: ${parts.join("; ")}.";
}

// --- 7. MASTER CLUE TAXONOMY & CATALOG ---
List<Clue> getFullClueCatalog() {
  return [
    // Signal-Informed Clues
    Clue(
      id: 'restless_night_01',
      title: 'Restless Night',
      category: 'sleep',
      signalTags: ['short_sleep'],
      possibleMeanings: ['Lower energy', 'Harder to focus', 'Did not affect me', 'Not sure'],
      clueType: ClueType.signalInformed,
      baseWeight: 0.8,
      recentRepeatPenalty: 0.2,
      x: 0.22,
      y: 0.35,
      icon: Icons.bedtime,
      question: 'You logged short sleep today. How did this impact your state?',
      options: ['Lower energy', 'Harder to focus', 'Did not affect me', 'Not sure'],
    ),
    Clue(
      id: 'meeting_overload_01',
      title: 'Meeting Overload',
      category: 'workload',
      signalTags: ['high_calendar_load'],
      possibleMeanings: ['Manageable', 'Energizing', 'Draining', 'Not sure'],
      clueType: ClueType.signalInformed,
      baseWeight: 0.85,
      recentRepeatPenalty: 0.25,
      x: 0.40,
      y: 0.45,
      icon: Icons.calendar_month,
      question: 'Your schedule was packed today. How did managing this feel?',
      options: ['Manageable', 'Energizing', 'Draining', 'Not sure'],
    ),
    Clue(
      id: 'desk_stillness_01',
      title: 'Stationary Desk Chair',
      category: 'movement',
      signalTags: ['low_activity'],
      possibleMeanings: ['Deep focus session', 'Felt physically trapped', 'Chose recovery', 'Not sure'],
      clueType: ClueType.signalInformed,
      baseWeight: 0.75,
      recentRepeatPenalty: 0.2,
      x: 0.58,
      y: 0.62,
      icon: Icons.chair,
      question: 'With low movement today, what was behind staying seated?',
      options: ['Deep focus session', 'Felt physically trapped', 'Chose recovery', 'Not sure'],
    ),
    Clue(
      id: 'rain_window_01',
      title: 'Rain-flecked Window',
      category: 'environment',
      signalTags: ['rainy_environment'],
      possibleMeanings: ['Cozy atmosphere', 'Dampened my mood', 'Felt neutral', 'Not sure'],
      clueType: ClueType.signalInformed,
      baseWeight: 0.7,
      recentRepeatPenalty: 0.15,
      x: 0.84,
      y: 0.20,
      icon: Icons.opacity,
      question: 'It rained today. How did the grey weather feel to you?',
      options: ['Cozy atmosphere', 'Dampened my mood', 'Felt neutral', 'Not sure'],
    ),

    // Possible Explanations
    Clue(
      id: 'quiet_corner_01',
      title: 'Quiet Corner',
      category: 'recovery',
      signalTags: ['high_calendar_load', 'short_sleep', 'low_activity'],
      possibleMeanings: ['Restorative solitude', 'Sensory recovery', 'Felt disconnected', 'Not sure'],
      clueType: ClueType.possibleExplanation,
      baseWeight: 0.65,
      recentRepeatPenalty: 0.25,
      x: 0.15,
      y: 0.60,
      icon: Icons.deck,
      question: 'You selected Quiet Corner. What did this moment give you today?',
      options: ['Restorative solitude', 'Sensory recovery', 'Felt disconnected', 'Not sure'],
    ),
    Clue(
      id: 'coffee_cup_01',
      title: 'Empty Espresso Cup',
      category: 'sleep',
      signalTags: ['short_sleep', 'high_calendar_load'],
      possibleMeanings: ['Survival fuel', 'Cozy morning ritual', 'Jittery overdrive', 'Not sure'],
      clueType: ClueType.possibleExplanation,
      baseWeight: 0.7,
      recentRepeatPenalty: 0.2,
      x: 0.48,
      y: 0.55,
      icon: Icons.coffee,
      question: 'What did this caffeine boost actually represent today?',
      options: ['Survival fuel', 'Cozy morning ritual', 'Jittery overdrive', 'Not sure'],
    ),

    // Helpful / Restorative Clues
    Clue(
      id: 'walking_shoes_01',
      title: 'Walking Shoes',
      category: 'movement',
      signalTags: ['high_activity', 'sunny_environment'],
      possibleMeanings: ['Workout to clear head', 'Active transit', 'Social walk', 'Not sure'],
      clueType: ClueType.helpfulAction,
      baseWeight: 0.75,
      recentRepeatPenalty: 0.2,
      x: 0.75,
      y: 0.76,
      icon: Icons.directions_run,
      question: 'You clocked high movement today. What motivated you to move?',
      options: ['Workout to clear head', 'Active transit', 'Social walk', 'Not sure'],
    ),
    Clue(
      id: 'open_book_01',
      title: 'Open Journal',
      category: 'recovery',
      signalTags: ['low_calendar_load'],
      possibleMeanings: ['Rejuvenating freedom', 'Anxious listlessness', 'Peaceful break', 'Not sure'],
      clueType: ClueType.helpfulAction,
      baseWeight: 0.6,
      recentRepeatPenalty: 0.15,
      x: 0.64,
      y: 0.45,
      icon: Icons.menu_book,
      question: 'Your schedule was open. How did you experience this spaciousness?',
      options: ['Rejuvenating freedom', 'Anxious listlessness', 'Peaceful break', 'Not sure'],
    ),

    // Neutral Distractors
    Clue(
      id: 'desk_lamp_01',
      title: 'Desk Lamp',
      category: 'neutral',
      signalTags: [],
      possibleMeanings: ['Late night focus', 'Ambient room light', 'Felt neutral', 'Not sure'],
      clueType: ClueType.neutralDistractor,
      baseWeight: 0.4,
      recentRepeatPenalty: 0.05,
      x: 0.32,
      y: 0.38,
      icon: Icons.light,
      question: 'You tapped the Desk Lamp. Did this moment stand out?',
      options: ['Late night focus', 'Ambient room light', 'Felt neutral', 'Not sure'],
    ),
    Clue(
      id: 'house_plant_01',
      title: 'House Plant',
      category: 'neutral',
      signalTags: [],
      possibleMeanings: ['Calming indoor nature', 'Felt neutral', 'Not sure'],
      clueType: ClueType.neutralDistractor,
      baseWeight: 0.4,
      recentRepeatPenalty: 0.05,
      x: 0.10,
      y: 0.25,
      icon: Icons.local_florist,
      question: 'You selected the House Plant. What did it bring to your day?',
      options: ['Calming indoor nature', 'Felt neutral', 'Not sure'],
    ),
    Clue(
      id: 'headphones_01',
      title: 'Headphones',
      category: 'neutral',
      signalTags: [],
      possibleMeanings: ['Focused music work', 'Blocking out noise', 'Felt neutral', 'Not sure'],
      clueType: ClueType.neutralDistractor,
      baseWeight: 0.45,
      recentRepeatPenalty: 0.05,
      x: 0.52,
      y: 0.70,
      icon: Icons.headphones,
      question: 'Did wearing headphones play a role in your day?',
      options: ['Focused music work', 'Blocking out noise', 'Felt neutral', 'Not sure'],
    ),
    Clue(
      id: 'water_bottle_01',
      title: 'Water Bottle',
      category: 'neutral',
      signalTags: [],
      possibleMeanings: ['Staying hydrated', 'Ordinary daily item', 'Not sure'],
      clueType: ClueType.neutralDistractor,
      baseWeight: 0.35,
      recentRepeatPenalty: 0.05,
      x: 0.68,
      y: 0.58,
      icon: Icons.local_drink,
      question: 'You tapped the Water Bottle. What did this represent?',
      options: ['Staying hydrated', 'Ordinary daily item', 'Not sure'],
    ),
  ];
}
