import 'clue.dart';

enum SceneKind { eveningBedroom, morningRoom, rainyReadingNook }

extension SceneKindPresentation on SceneKind {
  String get assetPath {
    switch (this) {
      case SceneKind.eveningBedroom:
        return 'assets/cozy_sunlit_green_living_space.png';
      case SceneKind.morningRoom:
        return 'assets/cozy_plant_filled_bedroom_workspace.png';
      case SceneKind.rainyReadingNook:
        return 'assets/cozy_purple_bedroom_retreat.png';
    }
  }

  String get tapMapAssetPath {
    switch (this) {
      case SceneKind.eveningBedroom:
        return 'assets/open_and_steady_map.json';
      case SceneKind.morningRoom:
        return 'assets/full_and_active_map.json';
      case SceneKind.rainyReadingNook:
        return 'assets/rest_and_reset_map.json';
    }
  }

  String get label {
    switch (this) {
      case SceneKind.eveningBedroom:
        return 'Open and Steady';
      case SceneKind.morningRoom:
        return 'Full and Active';
      case SceneKind.rainyReadingNook:
        return 'Rest and Reset';
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
