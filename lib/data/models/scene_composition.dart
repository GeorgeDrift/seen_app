import 'clue.dart';

/// The output of the local clue-scoring engine — the ranked/selected clue
/// list that becomes the hidden-object scene, plus a compositional summary
/// for the "why this scene" debug/demo overlay.
class SceneComposition {
  const SceneComposition({
    required this.visibleClues,
    required this.signalInformedCount,
    required this.possibleExplanationCount,
    required this.helpfulCount,
    required this.distractorCount,
  });

  final List<Clue> visibleClues;
  final int signalInformedCount;
  final int possibleExplanationCount;
  final int helpfulCount;
  final int distractorCount;

  static const empty = SceneComposition(
    visibleClues: [],
    signalInformedCount: 0,
    possibleExplanationCount: 0,
    helpfulCount: 0,
    distractorCount: 0,
  );
}
