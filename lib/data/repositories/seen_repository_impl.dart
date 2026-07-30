import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../domain/engine/fallback_questions.dart';
import '../../domain/engine/pattern_engine.dart';
import '../../domain/engine/scoring_engine.dart';
import '../../domain/engine/signal_engine.dart';
import '../../domain/engine/summary_engine.dart';
import '../../domain/repositories/seen_repository.dart';
import '../local/clue_catalog.dart';
import '../local/historical_dataset.dart';
import '../models/clue.dart';
import '../models/clue_selection.dart';
import '../models/daily_context.dart';
import '../models/daily_entry.dart';
import '../models/follow_up_question.dart';
import '../models/interpreted_signal.dart';
import '../models/pattern_observation.dart';
import '../models/scene_composition.dart';
import '../remote/seen_api.dart';

/// Concrete implementation combining local engines and the remote HTTP API.
///
/// Backend-first for AI (follow-up-question, summary), local-first for
/// deterministic logic (signal interpretation, clue scoring, patterns).
/// If any backend call fails for any reason, the equivalent local
/// computation runs — the demo never breaks because the network broke.
class SeenRepositoryImpl implements SeenRepository {
  SeenRepositoryImpl({
    required SeenApi api,
    SignalEngine? signalEngine,
    ScoringEngine? scoringEngine,
    SummaryEngine? summaryEngine,
    PatternEngine? patternEngine,
    HistoricalDataset? historicalDataset,
    Uuid? uuid,
  })  : _api = api,
        _signalEngine = signalEngine ?? const SignalEngine(),
        _scoringEngine = scoringEngine ?? const ScoringEngine(),
        _summaryEngine = summaryEngine ?? const SummaryEngine(),
        _patternEngine = patternEngine ?? const PatternEngine(),
        _historicalDataset = historicalDataset ?? HistoricalDataset(),
        _uuid = uuid ?? const Uuid();

  final SeenApi _api;
  final SignalEngine _signalEngine;
  final ScoringEngine _scoringEngine;
  final SummaryEngine _summaryEngine;
  final PatternEngine _patternEngine;
  final HistoricalDataset _historicalDataset;
  final Uuid _uuid;

  // Cache the synthetic dataset so switching profiles / navigating away and
  // back doesn't re-shuffle the patterns screen.
  List<DailyEntry>? _cachedHistorical;

  @override
  bool get isBackendConfigured => _api.isConfigured;

  @override
  List<InterpretedSignal> interpretSignals(DailyContext context) =>
      _signalEngine.interpret(context);

  @override
  SceneComposition composeScene(
    DailyContext context,
    List<InterpretedSignal> signals, {
    List<String> recentClueIds = const [],
  }) =>
      _scoringEngine.composeScene(ClueCatalog.all, signals, recentClueIds);

  @override
  Future<FollowUpQuestion> followUpQuestion({
    required Clue clue,
    required DailyContext context,
    required List<InterpretedSignal> interpretedSignals,
    String? previousMeaning,
  }) async {
    if (!_api.isConfigured) {
      return FallbackQuestions.forCategory(clue.category);
    }
    try {
      return await _api.followUpQuestion(
        clue: clue,
        context: context,
        interpretedSignals: interpretedSignals,
        previousMeaning: previousMeaning,
      );
    } on Failure {
      return FallbackQuestions.forCategory(clue.category);
    }
  }

  @override
  Future<DailyEntry> completeDay({
    required DailyContext context,
    required List<InterpretedSignal> interpretedSignals,
    required List<String> displayedClueIds,
    required List<ClueSelection> selectedClues,
  }) async {
    if (_api.isConfigured) {
      try {
        return await _api.completeDay(
          date: context.date,
          context: context,
          interpretedSignals: interpretedSignals,
          displayedClueIds: displayedClueIds,
          selectedClues: selectedClues,
        );
      } on Failure {
        // fall through to local
      }
    }
    return DailyEntry(
      id: _uuid.v4(),
      date: context.date,
      context: context,
      interpretedSignals: interpretedSignals,
      displayedClueIds: displayedClueIds,
      selectedClues: selectedClues,
      generatedSummary: _summaryEngine.buildLocal(selectedClues),
    );
  }

  @override
  List<DailyEntry> loadHistoricalEntries() =>
      _cachedHistorical ??= _historicalDataset.generate();

  @override
  List<PatternInsight> patternInsights(List<DailyEntry> historical) =>
      _patternEngine.insights(historical);

  @override
  Future<PatternObservation> coOccurrence({
    required List<DailyEntry> historical,
    required String clueA,
    required String clueB,
  }) async {
    if (_api.isConfigured) {
      try {
        return await _api.patterns(clueA: clueA, clueB: clueB);
      } on Failure {
        // fall through
      }
    }
    return _patternEngine.coOccurrence(historical, clueA, clueB);
  }
}
