/// A single tappable object rendered over a profile's fixed room illustration.
///
/// Unlike the old `Clue` model, a hotspot carries no scoring metadata — the
/// room image is pre-illustrated per profile, so every object in it is
/// simply tappable; there's no signal-informed/distractor composition.
class SceneHotspot {
  const SceneHotspot({
    required this.id,
    required this.title,
    required this.category,
    required this.x,
    required this.y,
    this.radius = 28,
  });

  final String id;
  final String title;
  final String
  category; // sleep | movement | workload | environment | recovery | neutral
  final double x; // 0.0 – 1.0 relative to image width
  final double y; // 0.0 – 1.0 relative to image height
  final double radius;
}

/// One profile's fixed room illustration plus its tappable hotspots.
class SceneDefinition {
  const SceneDefinition({
    required this.profileKey,
    required this.backgroundAsset,
    required this.hotspots,
  });

  final String profileKey; // 'a' | 'b' | 'c'
  final String backgroundAsset;
  final List<SceneHotspot> hotspots;
}
