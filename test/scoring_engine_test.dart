import 'package:flutter_test/flutter_test.dart';
import 'package:seen_app/data/local/clue_catalog.dart';
import 'package:seen_app/data/models/daily_context.dart';
import 'package:seen_app/data/models/scene_composition.dart';
import 'package:seen_app/domain/engine/scoring_engine.dart';

/// Builds a [DailyContext] with just the fields the scene-classification
/// rules read (sleepHours → Recovery, steps → Activation,
/// calendarLoad/screenTimeHours → Load); everything else is a neutral
/// placeholder since [ScoringEngine._selectScene] doesn't look at it.
DailyContext _context({
  double? sleepHours,
  int? steps,
  required String calendarLoad,
  double? screenTimeHours,
}) {
  return DailyContext(
    date: '2026-01-01',
    sleepHours: sleepHours,
    sleepComparison: 'unknown',
    steps: steps,
    activityComparison: 'unknown',
    calendarEventCount: 0,
    calendarLoad: calendarLoad,
    weather: 'cloudy', // must have zero effect on the outcome
    screenTimeHours: screenTimeHours,
  );
}

void main() {
  const engine = ScoringEngine();

  SceneKind kindFor(DailyContext context) =>
      engine.composeScene(context, ClueCatalog.all, const [], const []).kind;

  group('ScoringEngine._selectScene — Recovery/Activation/Load table', () {
    test('Low/Low/Low -> Rest and Reset', () {
      final kind = kindFor(
        _context(sleepHours: 5.0, steps: 1000, calendarLoad: 'low'),
      );
      expect(kind, SceneKind.rainyReadingNook);
    });

    test('Low/Low/High -> Full and Active (Load wins over low Recovery)', () {
      final kind = kindFor(
        _context(sleepHours: 5.0, steps: 1000, calendarLoad: 'high'),
      );
      expect(kind, SceneKind.morningRoom);
    });

    test('Low/High/Low -> Open and Steady (high Activation blocks Rest and Reset)', () {
      final kind = kindFor(
        _context(sleepHours: 5.0, steps: 9000, calendarLoad: 'low'),
      );
      expect(kind, SceneKind.eveningBedroom);
    });

    test('Low/High/Medium -> Full and Active', () {
      final kind = kindFor(
        _context(sleepHours: 5.0, steps: 9000, calendarLoad: 'moderate'),
      );
      expect(kind, SceneKind.morningRoom);
    });

    test('Medium/Medium/Medium -> Open and Steady (default)', () {
      final kind = kindFor(
        _context(sleepHours: 7.0, steps: 5000, calendarLoad: 'moderate'),
      );
      expect(kind, SceneKind.eveningBedroom);
    });

    test('High/High/Low -> Open and Steady', () {
      final kind = kindFor(
        _context(sleepHours: 9.0, steps: 9000, calendarLoad: 'low'),
      );
      expect(kind, SceneKind.eveningBedroom);
    });

    test('High/Low/High -> Full and Active (Load always wins)', () {
      final kind = kindFor(
        _context(sleepHours: 9.0, steps: 1000, calendarLoad: 'high'),
      );
      expect(kind, SceneKind.morningRoom);
    });

    test('missing sleep/steps default to Medium -> Open and Steady', () {
      final kind = kindFor(
        _context(sleepHours: null, steps: null, calendarLoad: 'moderate'),
      );
      expect(kind, SceneKind.eveningBedroom);
    });

    test('screen time alone can push Load to High even with a light calendar', () {
      final kind = kindFor(
        _context(
          sleepHours: 7.0,
          steps: 5000,
          calendarLoad: 'low',
          screenTimeHours: 6.5,
        ),
      );
      expect(kind, SceneKind.morningRoom);
    });

    test('missing screen time falls back to calendar level alone', () {
      final kind = kindFor(
        _context(
          sleepHours: 7.0,
          steps: 5000,
          calendarLoad: 'low',
          screenTimeHours: null,
        ),
      );
      expect(kind, SceneKind.eveningBedroom);
    });
  });
}
