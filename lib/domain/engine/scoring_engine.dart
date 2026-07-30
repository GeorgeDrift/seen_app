import '../../data/models/clue.dart';
import '../../data/models/daily_context.dart';
import '../../data/models/interpreted_signal.dart';
import '../../data/models/scene_composition.dart';

/// Ranks clues by signal match, then composes a balanced scene:
/// 4 signal-informed + 3 possible explanations + 3 helpful + up to 8
/// distractors — matching the requirements guide's recommended composition.
class ScoringEngine {
  const ScoringEngine();

  double scoreClue(
    Clue clue,
    List<InterpretedSignal> signals,
    List<String> recentClueIds,
  ) {
    final signalScore = signals
        .where((s) => clue.signalTags.contains(s.tag))
        .fold<double>(0, (sum, s) => sum + s.strength);
    final repetitionPenalty = recentClueIds.contains(clue.id)
        ? clue.recentRepeatPenalty
        : 0.0;
    return clue.baseWeight + signalScore - repetitionPenalty;
  }

  SceneComposition composeScene(
    DailyContext context,
    List<Clue> catalog,
    List<InterpretedSignal> signals,
    List<String> recentClueIds,
  ) {
    final scored =
        catalog
            .map((c) => MapEntry(c, scoreClue(c, signals, recentClueIds)))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final signalInformed = <Clue>[];
    final explanations = <Clue>[];
    final helpful = <Clue>[];
    final distractors = <Clue>[];

    for (final entry in scored) {
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
          if (distractors.length < 10) distractors.add(clue);
          break;
      }
    }

    final kind = _selectScene(context);
    final visible = <Clue>[
        ...signalInformed,
        ...explanations,
        ...helpful,
        ...distractors,
      ].map((clue) {
        final position = _positions[kind]?[clue.id];
        return position == null
            ? clue
            : clue.copyWithPosition(x: position.$1, y: position.$2);
      }).toList();

    return SceneComposition(
      kind: kind,
      visibleClues: visible,
      signalInformedCount: signalInformed.length,
      possibleExplanationCount: explanations.length,
      helpfulCount: helpful.length,
      distractorCount: distractors.length,
    );
  }

  SceneKind _selectScene(DailyContext context) {
    if (context.weather == 'rain' || context.weather == 'snow') {
      return SceneKind.rainyReadingNook;
    }
    if (context.weather == 'sunny' ||
        (context.steps != null && context.steps! >= 8000)) {
      return SceneKind.morningRoom;
    }
    return SceneKind.eveningBedroom;
  }

  static const Map<SceneKind, Map<String, (double, double)>> _positions = {
    SceneKind.eveningBedroom: {
      'restless_night_01': (0.53, 0.52),
      'meeting_overload_01': (0.91, 0.18),
      'desk_stillness_01': (0.31, 0.53),
      'rain_window_01': (0.49, 0.24),
      'quiet_corner_01': (0.18, 0.88),
      'coffee_cup_01': (0.38, 0.79),
      'walking_shoes_01': (0.12, 0.31),
      'open_book_01': (0.73, 0.77),
      'desk_lamp_01': (0.82, 0.42),
      'house_plant_01': (0.72, 0.34),
      'headphones_01': (0.79, 0.85),
      'water_bottle_01': (0.58, 0.77),
      'notebook_01': (0.70, 0.76),
      'pen_01': (0.88, 0.55),
      'fruit_bowl_01': (0.63, 0.82),
      'dishes_01': (0.72, 0.95),
      'laptop_01': (0.86, 0.50),
      'yoga_mat_01': (0.48, 0.56),
    },
    SceneKind.morningRoom: {
      'restless_night_01': (0.14, 0.52),
      'meeting_overload_01': (0.74, 0.18),
      'desk_stillness_01': (0.72, 0.46),
      'rain_window_01': (0.50, 0.25),
      'quiet_corner_01': (0.84, 0.72),
      'coffee_cup_01': (0.23, 0.72),
      'walking_shoes_01': (0.78, 0.92),
      'open_book_01': (0.49, 0.94),
      'desk_lamp_01': (0.13, 0.28),
      'house_plant_01': (0.27, 0.34),
      'headphones_01': (0.59, 0.70),
      'water_bottle_01': (0.45, 0.61),
      'notebook_01': (0.43, 0.72),
      'pen_01': (0.51, 0.76),
      'fruit_bowl_01': (0.31, 0.62),
      'dishes_01': (0.29, 0.91),
      'laptop_01': (0.76, 0.34),
      'yoga_mat_01': (0.84, 0.84),
    },
    SceneKind.rainyReadingNook: {
      'restless_night_01': (0.22, 0.48),
      'meeting_overload_01': (0.94, 0.22),
      'desk_stillness_01': (0.27, 0.48),
      'rain_window_01': (0.50, 0.22),
      'quiet_corner_01': (0.85, 0.63),
      'coffee_cup_01': (0.16, 0.75),
      'walking_shoes_01': (0.50, 0.63),
      'open_book_01': (0.13, 0.22),
      'desk_lamp_01': (0.16, 0.26),
      'house_plant_01': (0.58, 0.31),
      'headphones_01': (0.47, 0.78),
      'water_bottle_01': (0.73, 0.71),
      'notebook_01': (0.29, 0.80),
      'pen_01': (0.33, 0.80),
      'fruit_bowl_01': (0.58, 0.76),
      'dishes_01': (0.72, 0.85),
      'laptop_01': (0.85, 0.38),
      'yoga_mat_01': (0.58, 0.61),
    },
  };
}
