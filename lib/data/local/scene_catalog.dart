import '../models/demo_profile.dart';
import '../models/scene_hotspot.dart';

/// The single, canonical hidden-object scene shared by every profile — the
/// real Figma-exported illustration a teammate found on a separate branch
/// (the earlier per-profile room set was a placeholder pending that export).
/// Coordinates are hand-estimated (0.0–1.0) directly off that image. Only
/// the passive-data stats and signals vary between demo profiles, not the
/// room art.
class SceneCatalog {
  const SceneCatalog._();

  static const _bedroomScene = SceneDefinition(
    profileKey: 'shared',
    backgroundAsset: 'assets/cozy_bedroom_scene.png',
    hotspots: [
      SceneHotspot(
        id: 'coat_sweater',
        title: 'Coat on the Hook',
        category: 'neutral',
        x: 0.12,
        y: 0.28,
      ),
      SceneHotspot(
        id: 'window_moon',
        title: 'Window at Night',
        category: 'environment',
        x: 0.49,
        y: 0.20,
      ),
      SceneHotspot(
        id: 'shelf_frames',
        title: 'Shelf & Photo Frames',
        category: 'neutral',
        x: 0.86,
        y: 0.14,
      ),
      SceneHotspot(
        id: 'plant_left',
        title: 'House Plant',
        category: 'environment',
        x: 0.72,
        y: 0.30,
      ),
      SceneHotspot(
        id: 'plant_right',
        title: 'Tall House Plant',
        category: 'environment',
        x: 0.93,
        y: 0.32,
      ),
      SceneHotspot(
        id: 'desk_lamp',
        title: 'Desk Lamp',
        category: 'environment',
        x: 0.82,
        y: 0.42,
      ),
      SceneHotspot(
        id: 'laptop',
        title: 'Open Laptop',
        category: 'workload',
        x: 0.87,
        y: 0.49,
      ),
      SceneHotspot(
        id: 'bed_pillow',
        title: 'Made Bed',
        category: 'sleep',
        x: 0.25,
        y: 0.45,
      ),
      SceneHotspot(
        id: 'nightstand',
        title: 'Nightstand',
        category: 'sleep',
        x: 0.18,
        y: 0.58,
      ),
      SceneHotspot(
        id: 'yarn_basket',
        title: 'Basket of Yarn',
        category: 'recovery',
        x: 0.15,
        y: 0.87,
      ),
      SceneHotspot(
        id: 'coffee_mug',
        title: 'Warm Mug',
        category: 'recovery',
        x: 0.38,
        y: 0.79,
      ),
      SceneHotspot(
        id: 'tissue_box',
        title: 'Tissue Box',
        category: 'neutral',
        x: 0.47,
        y: 0.76,
      ),
      SceneHotspot(
        id: 'water_bottle',
        title: 'Water Bottle',
        category: 'neutral',
        x: 0.58,
        y: 0.77,
      ),
      SceneHotspot(
        id: 'snack_bowl',
        title: 'Snack Bowl',
        category: 'neutral',
        x: 0.62,
        y: 0.85,
      ),
      SceneHotspot(
        id: 'books_stack',
        title: 'Stacked Books',
        category: 'workload',
        x: 0.68,
        y: 0.79,
      ),
      SceneHotspot(
        id: 'headphones',
        title: 'Headphones',
        category: 'recovery',
        x: 0.79,
        y: 0.85,
      ),
    ],
  );

  static SceneDefinition forProfile(DemoProfileKey key) => _bedroomScene;

  static SceneDefinition forProfileKeyString(String key) => _bedroomScene;
}
