import '../../data/models/clue.dart';
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
    final repetitionPenalty =
        recentClueIds.contains(clue.id) ? clue.recentRepeatPenalty : 0.0;
    return clue.baseWeight + signalScore - repetitionPenalty;
  }

  SceneComposition composeScene(
    List<Clue> catalog,
    List<InterpretedSignal> signals,
    List<String> recentClueIds,
  ) {
    final scored = catalog
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
          if (distractors.length < 8) distractors.add(clue);
          break;
      }
    }

    return SceneComposition(
      visibleClues: [
        ...signalInformed,
        ...explanations,
        ...helpful,
        ...distractors,
      ],
      signalInformedCount: signalInformed.length,
      possibleExplanationCount: explanations.length,
      helpfulCount: helpful.length,
      distractorCount: distractors.length,
    );
  }
}
