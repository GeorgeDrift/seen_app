import 'package:flutter/material.dart';
import '../models/clue.dart';

/// The full set of clues the scene-composition engine picks from.
///
/// Kept as a static list rather than something loaded off the wire because
/// each entry carries frontend-only visual metadata (`icon`, `x`, `y`,
/// fallback `question`/`options`) that the backend contract doesn't include.
/// Keeping it here also means the entire hidden-object scene works offline
/// if the backend or AI ever go down mid-demo.
class ClueCatalog {
  const ClueCatalog._();

  static final List<Clue> all = [
    // ── Signal-Informed Clues ────────────────────────────────
    Clue(
      id: 'restless_night_01',
      title: 'Restless Night',
      category: 'sleep',
      signalTags: const ['short_sleep'],
      possibleMeanings: const [
        'Lower energy',
        'Harder to focus',
        'Did not affect me',
        'Not sure',
      ],
      clueType: ClueType.signalInformed,
      baseWeight: 0.8,
      recentRepeatPenalty: 0.2,
      x: 0.22,
      y: 0.35,
      icon: Icons.bedtime,
      question: 'You logged short sleep today. How did this impact your state?',
      options: const [
        'Lower energy',
        'Harder to focus',
        'Did not affect me',
        'Not sure',
      ],
    ),
    Clue(
      id: 'meeting_overload_01',
      title: 'Meeting Overload',
      category: 'workload',
      signalTags: const ['high_calendar_load'],
      possibleMeanings: const [
        'Manageable',
        'Energizing',
        'Draining',
        'Not sure',
      ],
      clueType: ClueType.signalInformed,
      baseWeight: 0.85,
      recentRepeatPenalty: 0.25,
      x: 0.40,
      y: 0.45,
      icon: Icons.calendar_month,
      question: 'Your schedule was packed today. How did managing this feel?',
      options: const ['Manageable', 'Energizing', 'Draining', 'Not sure'],
    ),
    Clue(
      id: 'desk_stillness_01',
      title: 'Stationary Desk Chair',
      category: 'movement',
      signalTags: const ['low_activity'],
      possibleMeanings: const [
        'Deep focus session',
        'Felt physically trapped',
        'Chose recovery',
        'Not sure',
      ],
      clueType: ClueType.signalInformed,
      baseWeight: 0.75,
      recentRepeatPenalty: 0.2,
      x: 0.58,
      y: 0.62,
      icon: Icons.chair,
      question: 'With low movement today, what was behind staying seated?',
      options: const [
        'Deep focus session',
        'Felt physically trapped',
        'Chose recovery',
        'Not sure',
      ],
    ),
    Clue(
      id: 'rain_window_01',
      title: 'Rain-flecked Window',
      category: 'environment',
      signalTags: const ['rainy_environment'],
      possibleMeanings: const [
        'Cozy atmosphere',
        'Dampened my mood',
        'Felt neutral',
        'Not sure',
      ],
      clueType: ClueType.signalInformed,
      baseWeight: 0.7,
      recentRepeatPenalty: 0.15,
      x: 0.84,
      y: 0.20,
      icon: Icons.opacity,
      question: 'It rained today. How did the grey weather feel to you?',
      options: const [
        'Cozy atmosphere',
        'Dampened my mood',
        'Felt neutral',
        'Not sure',
      ],
    ),

    // ── Possible Explanations ─────────────────────────────────
    Clue(
      id: 'quiet_corner_01',
      title: 'Quiet Corner',
      category: 'recovery',
      signalTags: const ['high_calendar_load', 'short_sleep', 'low_activity'],
      possibleMeanings: const [
        'Restorative solitude',
        'Sensory recovery',
        'Felt disconnected',
        'Not sure',
      ],
      clueType: ClueType.possibleExplanation,
      baseWeight: 0.65,
      recentRepeatPenalty: 0.25,
      x: 0.15,
      y: 0.60,
      icon: Icons.deck,
      question:
          'You selected Quiet Corner. What did this moment give you today?',
      options: const [
        'Restorative solitude',
        'Sensory recovery',
        'Felt disconnected',
        'Not sure',
      ],
    ),
    Clue(
      id: 'coffee_cup_01',
      title: 'Empty Espresso Cup',
      category: 'sleep',
      signalTags: const ['short_sleep', 'high_calendar_load'],
      possibleMeanings: const [
        'Survival fuel',
        'Cozy morning ritual',
        'Jittery overdrive',
        'Not sure',
      ],
      clueType: ClueType.possibleExplanation,
      baseWeight: 0.7,
      recentRepeatPenalty: 0.2,
      x: 0.48,
      y: 0.55,
      icon: Icons.coffee,
      question: 'What did this caffeine boost actually represent today?',
      options: const [
        'Survival fuel',
        'Cozy morning ritual',
        'Jittery overdrive',
        'Not sure',
      ],
    ),

    // ── Helpful / Restorative Clues ───────────────────────────
    Clue(
      id: 'walking_shoes_01',
      title: 'Walking Shoes',
      category: 'movement',
      signalTags: const ['high_activity', 'sunny_environment'],
      possibleMeanings: const [
        'Workout to clear head',
        'Active transit',
        'Social walk',
        'Not sure',
      ],
      clueType: ClueType.helpfulAction,
      baseWeight: 0.75,
      recentRepeatPenalty: 0.2,
      x: 0.75,
      y: 0.76,
      icon: Icons.directions_run,
      question: 'You clocked high movement today. What motivated you to move?',
      options: const [
        'Workout to clear head',
        'Active transit',
        'Social walk',
        'Not sure',
      ],
    ),
    Clue(
      id: 'open_book_01',
      title: 'Open Journal',
      category: 'recovery',
      signalTags: const ['low_calendar_load'],
      possibleMeanings: const [
        'Rejuvenating freedom',
        'Anxious listlessness',
        'Peaceful break',
        'Not sure',
      ],
      clueType: ClueType.helpfulAction,
      baseWeight: 0.6,
      recentRepeatPenalty: 0.15,
      x: 0.64,
      y: 0.45,
      icon: Icons.menu_book,
      question:
          'Your schedule was open. How did you experience this spaciousness?',
      options: const [
        'Rejuvenating freedom',
        'Anxious listlessness',
        'Peaceful break',
        'Not sure',
      ],
    ),

    // ── Neutral Distractors ───────────────────────────────────
    Clue(
      id: 'desk_lamp_01',
      title: 'Desk Lamp',
      category: 'neutral',
      signalTags: const [],
      possibleMeanings: const [
        'Late night focus',
        'Ambient room light',
        'Felt neutral',
        'Not sure',
      ],
      clueType: ClueType.neutralDistractor,
      baseWeight: 0.4,
      recentRepeatPenalty: 0.05,
      x: 0.32,
      y: 0.38,
      icon: Icons.light,
      question: 'You tapped the Desk Lamp. Did this moment stand out?',
      options: const [
        'Late night focus',
        'Ambient room light',
        'Felt neutral',
        'Not sure',
      ],
    ),
    Clue(
      id: 'house_plant_01',
      title: 'House Plant',
      category: 'neutral',
      signalTags: const [],
      possibleMeanings: const [
        'Calming indoor nature',
        'Felt neutral',
        'Not sure',
      ],
      clueType: ClueType.neutralDistractor,
      baseWeight: 0.4,
      recentRepeatPenalty: 0.05,
      x: 0.10,
      y: 0.25,
      icon: Icons.local_florist,
      question: 'You selected the House Plant. What did it bring to your day?',
      options: const ['Calming indoor nature', 'Felt neutral', 'Not sure'],
    ),
    Clue(
      id: 'headphones_01',
      title: 'Headphones',
      category: 'neutral',
      signalTags: const [],
      possibleMeanings: const [
        'Focused music work',
        'Blocking out noise',
        'Felt neutral',
        'Not sure',
      ],
      clueType: ClueType.neutralDistractor,
      baseWeight: 0.45,
      recentRepeatPenalty: 0.05,
      x: 0.52,
      y: 0.70,
      icon: Icons.headphones,
      question: 'Did wearing headphones play a role in your day?',
      options: const [
        'Focused music work',
        'Blocking out noise',
        'Felt neutral',
        'Not sure',
      ],
    ),
    Clue(
      id: 'water_bottle_01',
      title: 'Water Bottle',
      category: 'neutral',
      signalTags: const [],
      possibleMeanings: const [
        'Staying hydrated',
        'Ordinary daily item',
        'Not sure',
      ],
      clueType: ClueType.neutralDistractor,
      baseWeight: 0.35,
      recentRepeatPenalty: 0.05,
      x: 0.68,
      y: 0.58,
      icon: Icons.local_drink,
      question: 'You tapped the Water Bottle. What did this represent?',
      options: const ['Staying hydrated', 'Ordinary daily item', 'Not sure'],
    ),
  ];

  static Clue? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
