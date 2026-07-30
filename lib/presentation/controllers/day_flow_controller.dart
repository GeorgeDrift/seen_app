import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/day_progress_store.dart';
import '../../data/models/clue_selection.dart';
import '../../data/models/daily_context.dart';
import '../../data/models/interpreted_signal.dart';
import '../../data/models/scene_composition.dart';
import '../providers/api_providers.dart';
import 'profile_controller.dart';

/// Everything that describes the *current day the user is annotating* — the
/// derived signals, the composed scene, the selections so far, and the
/// hint state.
class DayFlowState {
  const DayFlowState({
    required this.context,
    required this.signals,
    required this.scene,
    required this.selections,
    required this.recentClueIds,
    this.hintLevel = 0,
  });

  final DailyContext context;
  final List<InterpretedSignal> signals;
  final SceneComposition scene;
  final List<ClueSelection> selections;
  final List<String> recentClueIds;
  final int hintLevel; // 0 = off, 1 = region, 2 = outline

  DayFlowState copyWith({
    DailyContext? context,
    List<InterpretedSignal>? signals,
    SceneComposition? scene,
    List<ClueSelection>? selections,
    List<String>? recentClueIds,
    int? hintLevel,
  }) {
    return DayFlowState(
      context: context ?? this.context,
      signals: signals ?? this.signals,
      scene: scene ?? this.scene,
      selections: selections ?? this.selections,
      recentClueIds: recentClueIds ?? this.recentClueIds,
      hintLevel: hintLevel ?? this.hintLevel,
    );
  }
}

/// Consolidates the derived pipeline (context → signals → scene) into one
/// place so widgets never call the engine directly.
///
/// The controller re-derives whenever the active profile changes (i.e.
/// [activeProfileProvider] emits). Selections/hint are the only pieces of
/// UI-driven state that live inside the notifier.
final dayFlowControllerProvider =
    NotifierProvider<DayFlowController, DayFlowState>(DayFlowController.new);

/// Maximum clues a user may select per day. Also enforced server-side.
const int kMaxSelectionsPerDay = 3;

class DayFlowController extends Notifier<DayFlowState> {
  // Mirrors state.selections/recentClueIds/hintLevel — kept as fields (not
  // read off `state`) so build() can carry them across a profile refresh
  // (e.g. passive data arriving) without a round-trip through `state`, which
  // isn't set yet on the very first build().
  List<ClueSelection> _selections = const [];
  List<String> _recentClueIds = const [];
  int _hintLevel = 0;
  String? _lastDate;

  @override
  DayFlowState build() {
    // React to profile changes automatically.
    final profile = ref.watch(activeProfileProvider);
    final repo = ref.watch(seenRepositoryProvider);

    // Only reset selections/hint on an actual day change (or first-ever
    // build) — NOT every time the profile refreshes (e.g. passive data
    // resolving after moments have already been picked), which used to
    // silently wipe the user's in-progress selections mid-session.
    final today = todayDateKey();
    if (_lastDate != today) {
      _lastDate = today;
      _selections = const [];
      _recentClueIds = const [];
      _hintLevel = 0;
    }

    final signals = repo.interpretSignals(profile.context);
    final scene = repo.composeScene(
      profile.context,
      signals,
      recentClueIds: _recentClueIds,
    );

    return DayFlowState(
      context: profile.context,
      signals: signals,
      scene: scene,
      selections: _selections,
      recentClueIds: _recentClueIds,
      hintLevel: _hintLevel,
    );
  }

  /// User picked a clue → recorded/replaced its selection.
  /// Returns whether the selection was accepted (false if already at cap).
  bool addSelection(ClueSelection selection) {
    final existing = state.selections.indexWhere(
      (s) => s.clueId == selection.clueId,
    );
    if (existing >= 0) {
      final next = [...state.selections];
      next[existing] = selection;
      _selections = next;
      state = state.copyWith(selections: next);
      return true;
    }
    if (state.selections.length >= kMaxSelectionsPerDay) return false;
    final next = [...state.selections, selection];
    _selections = next;
    state = state.copyWith(selections: next);
    return true;
  }

  void removeSelection(String clueId) {
    final next = state.selections.where((s) => s.clueId != clueId).toList();
    _selections = next;
    state = state.copyWith(selections: next);
  }

  void clearSelections() {
    _selections = const [];
    state = state.copyWith(selections: const []);
  }

  /// Restores selections previously saved to disk (same calendar day only —
  /// callers are expected to have already checked the stored date).
  void restoreSelections(List<ClueSelection> selections) {
    _selections = selections;
    state = state.copyWith(selections: selections);
  }

  /// Advance the 0→1→2→0 hint cycle.
  void cycleHint() {
    state = state.copyWith(hintLevel: (state.hintLevel + 1) % 3);
  }

  void resetHint() => state = state.copyWith(hintLevel: 0);

  /// The most recent selection's chosen option — used as `previousMeaning`
  /// when asking the AI for the next follow-up so it can build continuity
  /// without seeing raw calendar/location/PII data.
  String? get lastAnsweredOption {
    for (final s in state.selections.reversed) {
      if (s.confidence != 'skipped' && s.answerOption != null) {
        return s.answerOption;
      }
    }
    return null;
  }
}
