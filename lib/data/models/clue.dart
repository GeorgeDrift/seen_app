import 'package:flutter/material.dart';

/// Combines the backend `Clue` contract with the frontend visual metadata
/// (icon + position on the hidden-object canvas) that the illustrated scene
/// needs.
///
/// The backend never sees `icon`, `x`, `y`, `question`, or `options`; the
/// frontend never sends them back. `toJson` only emits the backend-contract
/// fields so that the follow-up-question endpoint gets exactly what its
/// schema expects (no more, no less — matches the privacy AI-boundary rule).
enum ClueType {
  signalInformed,
  possibleExplanation,
  helpfulAction,
  neutralDistractor,
}

extension ClueTypeCodec on ClueType {
  String get wire {
    switch (this) {
      case ClueType.signalInformed:
        return 'signal_informed';
      case ClueType.possibleExplanation:
        return 'possible_explanation';
      case ClueType.helpfulAction:
        return 'helpful_action';
      case ClueType.neutralDistractor:
        return 'neutral_distractor';
    }
  }

  static ClueType fromWire(String v) {
    switch (v) {
      case 'signal_informed':
        return ClueType.signalInformed;
      case 'possible_explanation':
        return ClueType.possibleExplanation;
      case 'helpful_action':
        return ClueType.helpfulAction;
      default:
        return ClueType.neutralDistractor;
    }
  }
}

class Clue {
  const Clue({
    required this.id,
    required this.title,
    required this.category,
    required this.signalTags,
    required this.possibleMeanings,
    required this.clueType,
    required this.baseWeight,
    required this.recentRepeatPenalty,
    required this.x,
    required this.y,
    required this.icon,
    required this.question,
    required this.options,
    this.assetPath = 'placeholder',
    this.compatibleBackgrounds = const ['placeholder'],
    this.compatibleSlots = const ['placeholder'],
  });

  // Backend contract
  final String id;
  final String title;
  final String assetPath;
  final String
  category; // sleep | movement | workload | environment | social | physical | recovery | neutral
  final List<String> signalTags;
  final List<String> possibleMeanings;
  final List<String> compatibleBackgrounds;
  final List<String> compatibleSlots;
  final ClueType clueType;
  final double baseWeight;
  final double recentRepeatPenalty;

  // Frontend-only fields (never sent to the AI)
  final double x; // 0.0 – 1.0 relative to scene width
  final double y; // 0.0 – 1.0 relative to scene height
  final IconData icon;
  final String question; // local fallback question if AI unavailable
  final List<String> options; // local fallback options

  /// The full JSON body the backend's `/follow-up-question` endpoint expects
  /// under `clue`. Frontend-only fields are intentionally omitted.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'assetPath': assetPath,
    'category': category,
    'signalTags': signalTags,
    'possibleMeanings': possibleMeanings,
    'compatibleBackgrounds': compatibleBackgrounds,
    'compatibleSlots': compatibleSlots,
    'clueType': clueType.wire,
    'baseWeight': baseWeight,
    'recentRepeatPenalty': recentRepeatPenalty,
  };
}
