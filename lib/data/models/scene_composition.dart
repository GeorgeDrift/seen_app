import 'clue.dart';

enum SceneKind { eveningBedroom, morningRoom, rainyReadingNook }

extension SceneKindPresentation on SceneKind {
  String get assetPath {
    switch (this) {
      case SceneKind.eveningBedroom:
        return 'assets/cozy_bedroom_scene.png';
      case SceneKind.morningRoom:
        return 'assets/cozy_morning_scene.png';
      case SceneKind.rainyReadingNook:
        return 'assets/cozy_rainy_scene.png';
    }
  }

  String get label {
    switch (this) {
      case SceneKind.eveningBedroom:
        return 'Evening bedroom';
      case SceneKind.morningRoom:
        return 'Sunlit room';
      case SceneKind.rainyReadingNook:
        return 'Rainy reading nook';
    }
  }
}

/// The output of the local clue-scoring engine — the ranked/selected clue
/// list that becomes the hidden-object scene, plus a compositional summary
/// for the "why this scene" debug/demo overlay.
class SceneComposition {
  const SceneComposition({
    required this.kind,
    required this.visibleClues,
    required this.signalInformedCount,
    required this.possibleExplanationCount,
    required this.helpfulCount,
    required this.distractorCount,
  });

  final SceneKind kind;
  final List<Clue> visibleClues;
  final int signalInformedCount;
  final int possibleExplanationCount;
  final int helpfulCount;
  final int distractorCount;

  static const empty = SceneComposition(
    kind: SceneKind.eveningBedroom,
    visibleClues: [],
    signalInformedCount: 0,
    possibleExplanationCount: 0,
    helpfulCount: 0,
    distractorCount: 0,
  );

  String get assetPath => kind.assetPath;
  String get label => kind.label;
}
