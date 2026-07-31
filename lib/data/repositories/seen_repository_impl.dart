import 'dart:developer' as developer;

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
import '../models/health_week_day.dart';
import '../models/health_week_insights.dart';
import '../models/interpreted_signal.dart';
import '../models/pattern_observation.dart';
import '../models/reflection.dart';
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
  }) : _api = api,
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
  }) {
    final scene = _scoringEngine.composeScene(
      context,
      ClueCatalog.all,
      signals,
      recentClueIds,
    );
    // The scene image only changes when this input changes — logged so a
    // "the scene never changes" report can be diagnosed from the device's
    // own logs: is composeScene actually being fed different sleep/steps/
    // calendar values, or is the same (fallback) DailyContext being reused?
    developer.log(
      'composeScene -> kind=${scene.kind} '
      '(sleepHours=${context.sleepHours}, steps=${context.steps}, '
      'calendarEventCount=${context.calendarEventCount}, '
      'calendarLoad=${context.calendarLoad}, '
      'screenTimeHours=${context.screenTimeHours})',
      name: 'Scene',
    );
    return scene;
  }

  @override
  Future<FollowUpQuestion> followUpQuestion({
    required Clue clue,
    required DailyContext context,
    required List<InterpretedSignal> interpretedSignals,
    String? previousMeaning,
  }) async {
    if (!_api.isConfigured) {
      _logFallback('followUpQuestion', 'backend not configured');
      return FallbackQuestions.forCategory(clue.category);
    }
    try {
      final result = await _api.followUpQuestion(
        clue: clue,
        context: context,
        interpretedSignals: interpretedSignals,
        previousMeaning: previousMeaning,
      );
      _logSuccess('followUpQuestion');
      return result;
    } on Failure catch (e) {
      _logFallback('followUpQuestion', '${e.runtimeType}: ${e.message}');
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
        final result = await _api.completeDay(
          date: context.date,
          context: context,
          interpretedSignals: interpretedSignals,
          displayedClueIds: displayedClueIds,
          selectedClues: selectedClues,
        );
        _logSuccess('completeDay');
        return result;
      } on Failure catch (e) {
        _logFallback('completeDay', '${e.runtimeType}: ${e.message}');
        // fall through to local
      }
    } else {
      _logFallback('completeDay', 'backend not configured');
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
  Future<Reflection> generateReflection({
    required DailyContext context,
    required List<InterpretedSignal> interpretedSignals,
    required List<Map<String, String>> moments,
    String? additionalInput,
  }) async {
    if (_api.isConfigured) {
      try {
        final result = await _api.generateReflection(
          context: context,
          interpretedSignals: interpretedSignals,
          moments: moments,
          additionalInput: additionalInput,
        );
        _logSuccess('generateReflection');
        return result;
      } on Failure catch (e) {
        _logFallback('generateReflection', '${e.runtimeType}: ${e.message}');
        // fall through to local
      }
    } else {
      _logFallback('generateReflection', 'backend not configured');
    }
    return _localReflection(moments);
  }

  @override
  Future<Reflection> refineReflection({
    required String originalReflection,
    required List<Map<String, String>> moments,
    required String steeringText,
  }) async {
    if (_api.isConfigured) {
      try {
        final result = await _api.refineReflection(
          originalReflection: originalReflection,
          moments: moments,
          steeringText: steeringText,
        );
        _logSuccess('refineReflection');
        return result;
      } on Failure catch (e) {
        _logFallback('refineReflection', '${e.runtimeType}: ${e.message}');
        // fall through — keep the existing reflection unchanged
      }
    } else {
      _logFallback('refineReflection', 'backend not configured');
    }
    return Reflection(
      text: originalReflection,
      generatedAt: DateTime.now(),
      isEdited: true,
    );
  }

  /// Fully offline, non-AI safety net — deliberately does no safety-language
  /// analysis of its own (that only runs on the backend path), so it never
  /// claims `safetyState: 'needs_immediate_support'`.
  Reflection _localReflection(List<Map<String, String>> moments) {
    if (moments.isEmpty) {
      return Reflection(
        text:
            'No moments were captured today — this entry was saved with no reflection.',
        generatedAt: DateTime.now(),
        confidence: 'low',
        needsUserReview: true,
      );
    }
    final fragments = moments
        .map((m) => '${m['clueTitle']} brought to mind ${m['text']}')
        .join('; ');
    return Reflection(
      text: 'Today included $fragments.',
      generatedAt: DateTime.now(),
      cluesUsed: moments.map((m) => m['clueTitle'] ?? '').toList(),
      confidence: 'low',
      needsUserReview: true,
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
        final result = await _api.patterns(clueA: clueA, clueB: clueB);
        _logSuccess('coOccurrence');
        return result;
      } on Failure catch (e) {
        _logFallback('coOccurrence', '${e.runtimeType}: ${e.message}');
        // fall through
      }
    } else {
      _logFallback('coOccurrence', 'backend not configured');
    }
    return _patternEngine.coOccurrence(historical, clueA, clueB);
  }

  @override
  Future<WeeklyInsights> weeklyInsights(List<HealthWeekDay> days) async {
    if (_api.isConfigured) {
      try {
        final result = await _api.weeklyInsights(days);
        _logSuccess('weeklyInsights');
        return result;
      } on Failure catch (e) {
        _logFallback('weeklyInsights', '${e.runtimeType}: ${e.message}');
        // fall through to local
      }
    } else {
      _logFallback('weeklyInsights', 'backend not configured');
    }
    return _fallbackWeeklyInsights;
  }

  /// Same "not enough data" copy the AI itself is instructed to fall back to
  /// when evidence is weak — kept in sync with the backend's own
  /// `weeklyInsightsEngine.ts` fallback so offline/dev builds render
  /// something coherent rather than something contradictory.
  static const WeeklyInsights _fallbackWeeklyInsights = WeeklyInsights(
    patternWorthNoticing: WeeklyPatternInsight(
      title: 'A pattern worth noticing',
      summary:
          'Your reflections contain meaningful moments, but a consistent '
          'connection has not emerged across this week yet.',
      supportingDayCount: 0,
      supportingDates: [],
      signals: [],
      commonClues: [],
      confidence: 'low',
    ),
    whatMayBeHelping: WeeklyHelpingInsight(
      title: '',
      summary: '',
      supportingReflectionCount: 0,
      supportingDates: [],
      signals: [],
      confidence: 'low',
    ),
    themes: [],
  );

  void _logSuccess(String method) {
    developer.log('$method -> backend call succeeded.', name: 'Backend');
  }

  void _logFallback(String method, String reason) {
    developer.log(
      '$method -> using LOCAL fallback ($reason).',
      name: 'Backend',
    );
  }
}
