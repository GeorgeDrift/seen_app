import '../../data/models/clue.dart';
import '../../data/models/clue_selection.dart';
import '../../data/models/daily_context.dart';
import '../../data/models/daily_entry.dart';
import '../../data/models/follow_up_question.dart';
import '../../data/models/interpreted_signal.dart';
import '../../data/models/pattern_observation.dart';
import '../../data/models/reflection.dart';
import '../../data/models/scene_composition.dart';
import '../engine/pattern_engine.dart';

/// The single interface presentation-layer code talks to.
///
/// Everything below the surface — HTTP, dio, retries, local fallbacks, the
/// synthetic 14-day dataset — is an implementation detail. Swapping the
/// concrete class (e.g. for tests or a different backend) touches no
/// controller and no widget.
abstract class SeenRepository {
  /// True when there is enough config to actually reach the backend. When
  /// this is false, [followUpQuestion] and [completeDay] still work — they
  /// just return locally-computed values (fallback question / local summary).
  bool get isBackendConfigured;

  /// Deterministic — reads the same local engine every time. No network.
  List<InterpretedSignal> interpretSignals(DailyContext context);

  /// Deterministic — reads the same local engine every time. No network.
  SceneComposition composeScene(
    DailyContext context,
    List<InterpretedSignal> signals, {
    List<String> recentClueIds,
  });

  /// Backend AI call for the follow-up question; falls back to a static
  /// category-based question if the backend is unavailable, times out, or
  /// returns something that fails the safety validation.
  Future<FollowUpQuestion> followUpQuestion({
    required Clue clue,
    required DailyContext context,
    required List<InterpretedSignal> interpretedSignals,
    String? previousMeaning,
  });

  /// Completes the day — asks the backend to persist and to generate the
  /// summary. Falls back to a local summary if the backend isn't reachable.
  /// Always returns a fully-populated [DailyEntry].
  Future<DailyEntry> completeDay({
    required DailyContext context,
    required List<InterpretedSignal> interpretedSignals,
    required List<String> displayedClueIds,
    required List<ClueSelection> selectedClues,
  });

  /// Backend AI call producing a warm narrative reflection from free-text
  /// moments; falls back to a deterministic joined-paragraph reflection if
  /// the backend is unavailable or the call fails.
  Future<Reflection> generateReflection({
    required DailyContext context,
    required List<InterpretedSignal> interpretedSignals,
    required List<Map<String, String>> moments,
  });

  /// Backend AI call regenerating a reflection per the user's own steering
  /// note. Falls back to the original reflection, unchanged, if unavailable —
  /// so "restore original" always has something coherent to show.
  Future<Reflection> refineReflection({
    required String originalReflection,
    required List<Map<String, String>> moments,
    required String steeringText,
  });

  /// The 14-day synthetic history the demo relies on for pattern insights.
  List<DailyEntry> loadHistoricalEntries();

  /// Derived, presentation-ready pattern insights.
  List<PatternInsight> patternInsights(List<DailyEntry> historical);

  /// Raw co-occurrence for two clues — used when we want the numbers rather
  /// than a preformatted phrase.
  Future<PatternObservation> coOccurrence({
    required List<DailyEntry> historical,
    required String clueA,
    required String clueB,
  });
}
