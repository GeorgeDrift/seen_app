import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/scene_hotspot.dart';

/// Renders a profile's fixed room illustration with tappable hotspot markers
/// positioned by each [SceneHotspot]'s relative (x, y). Tapped hotspots show
/// a checkmark badge. Purely presentational — no engine calls, no HTTP.
class IllustratedSceneCanvas extends StatelessWidget {
  const IllustratedSceneCanvas({
    super.key,
    required this.scene,
    required this.tappedIds,
    required this.onHotspotTapped,
  });

  final SceneDefinition scene;
  final Set<String> tappedIds;
  final void Function(SceneHotspot hotspot) onHotspotTapped;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.75,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(scene.backgroundAsset, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: scene.hotspots.map((hotspot) {
                      final isTapped = tappedIds.contains(hotspot.id);
                      final left =
                          hotspot.x * constraints.maxWidth - hotspot.radius;
                      final top =
                          hotspot.y * constraints.maxHeight - hotspot.radius;
                      return Positioned(
                        left: left,
                        top: top,
                        child: GestureDetector(
                          onTap: () => onHotspotTapped(hotspot),
                          child: Container(
                            width: hotspot.radius * 2,
                            height: hotspot.radius * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isTapped
                                  ? AppColors.primary.withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.55),
                              border: Border.all(
                                color: isTapped
                                    ? AppColors.primary
                                    : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: isTapped
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
