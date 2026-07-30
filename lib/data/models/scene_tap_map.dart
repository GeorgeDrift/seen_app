import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'clue.dart';

class SceneTapMap {
  const SceneTapMap({
    required this.sceneId,
    required this.imageName,
    required this.imageSize,
    required this.items,
  });

  final String sceneId;
  final String imageName;
  final Size imageSize;
  final List<SceneTapTarget> items;

  static Future<SceneTapMap> load(String assetPath) async {
    final source = await rootBundle.loadString(assetPath);
    return SceneTapMap.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  factory SceneTapMap.fromJson(Map<String, dynamic> json) {
    return SceneTapMap(
      sceneId: json['sceneId'] as String,
      imageName: json['image'] as String,
      imageSize: Size(
        (json['imageWidth'] as num).toDouble(),
        (json['imageHeight'] as num).toDouble(),
      ),
      items: (json['items'] as List<dynamic>)
          .map((item) => SceneTapTarget.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class SceneTapTarget {
  const SceneTapTarget({
    required this.id,
    required this.label,
    required this.tapArea,
    required this.checkmarkPosition,
  });

  final String id;
  final String label;
  final Rect tapArea;
  final Offset checkmarkPosition;

  factory SceneTapTarget.fromJson(Map<String, dynamic> json) {
    final area = json['tapAreaNormalized'] as Map<String, dynamic>;
    final checkmark = json['checkmarkPosition'] as Map<String, dynamic>;
    return SceneTapTarget(
      id: json['id'] as String,
      label: json['label'] as String,
      tapArea: Rect.fromLTWH(
        (area['x'] as num).toDouble(),
        (area['y'] as num).toDouble(),
        (area['width'] as num).toDouble(),
        (area['height'] as num).toDouble(),
      ),
      checkmarkPosition: Offset(
        (checkmark['x'] as num).toDouble(),
        (checkmark['y'] as num).toDouble(),
      ),
    );
  }

  String clueId(String sceneId) => '${sceneId}_$id';

  Clue asClue(String sceneId) {
    final category = _categoryFor(id);
    final options = _optionsFor(category);
    return Clue(
      id: clueId(sceneId),
      title: label,
      assetPath: id,
      category: category,
      signalTags: const [],
      possibleMeanings: options,
      compatibleBackgrounds: [sceneId],
      compatibleSlots: [id],
      clueType: ClueType.neutralDistractor,
      baseWeight: 0.4,
      recentRepeatPenalty: 0.05,
      x: checkmarkPosition.dx,
      y: checkmarkPosition.dy,
      icon: _iconFor(category),
      question: 'What did the $label bring to mind from your day?',
      options: options,
    );
  }

  Rect tapAreaFor(Size canvasSize) {
    return Rect.fromLTWH(
      tapArea.left * canvasSize.width,
      tapArea.top * canvasSize.height,
      tapArea.width * canvasSize.width,
      tapArea.height * canvasSize.height,
    );
  }

  Offset checkmarkFor(Size canvasSize) {
    return Offset(
      checkmarkPosition.dx * canvasSize.width,
      checkmarkPosition.dy * canvasSize.height,
    );
  }

  static String _categoryFor(String id) {
    if (RegExp(
      r'bed|blanket|pillow|slipper|tissue|throw|hoodie',
    ).hasMatch(id)) {
      return 'recovery';
    }
    if (RegExp(r'shoe|yoga|duffel|backpack').hasMatch(id)) {
      return 'movement';
    }
    if (RegExp(r'coffee|snack|fruit|dish|takeout|water').hasMatch(id)) {
      return 'physical';
    }
    if (id.contains('plant')) return 'environment';
    if (RegExp(
      r'laptop|planner|notebook|book|folder|desk|chair|phone',
    ).hasMatch(id)) {
      return 'workload';
    }
    return 'neutral';
  }

  static List<String> _optionsFor(String category) {
    return switch (category) {
      'recovery' => const [
        'A moment of rest',
        'Comfort or safety',
        'Feeling tired',
        'Something else',
        'Not sure',
      ],
      'movement' => const [
        'Being active',
        'Going somewhere',
        'Needing movement',
        'Something else',
        'Not sure',
      ],
      'physical' => const [
        'Food or hydration',
        'A daily routine',
        'Taking care of myself',
        'Something else',
        'Not sure',
      ],
      'environment' => const [
        'My surroundings',
        'A calming moment',
        'Being at home',
        'Something else',
        'Not sure',
      ],
      'workload' => const [
        'Work or study',
        'Planning something',
        'A task or responsibility',
        'Something else',
        'Not sure',
      ],
      _ => const [
        'A daily routine',
        'A person or place',
        'A feeling',
        'Something else',
        'Not sure',
      ],
    };
  }

  static IconData _iconFor(String category) {
    return switch (category) {
      'recovery' => Icons.bedtime_outlined,
      'movement' => Icons.directions_walk_outlined,
      'physical' => Icons.local_dining_outlined,
      'environment' => Icons.local_florist_outlined,
      'workload' => Icons.work_outline,
      _ => Icons.circle_outlined,
    };
  }
}
