import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:seen_app/data/models/scene_tap_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bundled scene maps contain valid normalized targets', (
    tester,
  ) async {
    final expectedMaps = {
      'assets/rest_and_reset_map.json': (
        image: 'cozy_purple_bedroom_retreat.png',
        count: 17,
      ),
      'assets/full_and_active_map.json': (
        image: 'cozy_plant_filled_bedroom_workspace.png',
        count: 20,
      ),
      'assets/open_and_steady_map.json': (
        image: 'cozy_sunlit_green_living_space.png',
        count: 20,
      ),
    };

    for (final entry in expectedMaps.entries) {
      final map = await SceneTapMap.load(entry.key);
      expect(map.imageName, entry.value.image);
      expect(map.imageSize, const Size(941, 1672));
      expect(map.items, hasLength(entry.value.count));
      for (final target in map.items) {
        expect(target.tapArea.left, inInclusiveRange(0, 1));
        expect(target.tapArea.top, inInclusiveRange(0, 1));
        expect(target.tapArea.right, inInclusiveRange(0, 1));
        expect(target.tapArea.bottom, inInclusiveRange(0, 1));
        expect(target.tapArea.width, greaterThan(0));
        expect(target.tapArea.height, greaterThan(0));
        expect(target.checkmarkPosition.dx, inInclusiveRange(0, 1));
        expect(target.checkmarkPosition.dy, inInclusiveRange(0, 1));
      }
    }
  });

  group('SceneTapMap', () {
    test('parses and scales target rectangles and checkmark anchors', () {
      final map = SceneTapMap.fromJson({
        'sceneId': 'rest_and_reset',
        'image': 'scene.png',
        'imageWidth': 941,
        'imageHeight': 1672,
        'items': [
          {
            'id': 'coffee_mug',
            'label': 'Coffee mug',
            'tapAreaNormalized': {
              'x': 0.2,
              'y': 0.4,
              'width': 0.1,
              'height': 0.08,
            },
            'checkmarkPosition': {'x': 0.28, 'y': 0.41},
          },
        ],
      });

      final target = map.items.single;
      expect(map.imageSize, const Size(941, 1672));
      expect(target.tapArea, const Rect.fromLTWH(0.2, 0.4, 0.1, 0.08));
      expect(target.checkmarkPosition, const Offset(0.28, 0.41));
      expect(target.clueId(map.sceneId), 'rest_and_reset_coffee_mug');

      const canvas = Size(470.5, 836);
      final area = target.tapAreaFor(canvas);
      expect(area.left, closeTo(94.1, 0.0001));
      expect(area.top, closeTo(334.4, 0.0001));
      expect(area.width, closeTo(47.05, 0.0001));
      expect(area.height, closeTo(66.88, 0.0001));
      final checkmark = target.checkmarkFor(canvas);
      expect(checkmark.dx, closeTo(131.74, 0.0001));
      expect(checkmark.dy, closeTo(342.76, 0.0001));
    });
  });
}
