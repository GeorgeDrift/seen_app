import 'package:flutter_riverpod/flutter_riverpod.dart';

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

const int kMinSelectionsPerDay = 3;
const int kMaxSelectionsPerDay = 5;

class DayFlowController extends Notifier<DayFlowState> {
  static const List<String> _recentClueIds = <String>[];

  @override
  DayFlowState build() {
    // React to profile changes automatically.
    final profile = ref.watch(activeProfileProvider);
    final repo = ref.watch(seenRepositoryProvider);

    final signals = repo.interpretSignals(profile.context);
    final scene = repo.composeScene(
      profile.context,
      signals,
      recentClueIds: _recentClueIds,
    );

    // Selections and hint reset when the profile changes.
    return DayFlowState(
      context: profile.context,
      signals: signals,
      scene: scene,
      selections: const [],
      recentClueIds: _recentClueIds,
      hintLevel: 0,
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
      state = state.copyWith(selections: next);
      return true;
    }
    if (state.selections.length >= kMaxSelectionsPerDay) return false;
    state = state.copyWith(selections: [...state.selections, selection]);
    return true;
  }

  void removeSelection(String clueId) {
    state = state.copyWith(
      selections: state.selections.where((s) => s.clueId != clueId).toList(),
    );
  }

  void clearSelections() {
    state = state.copyWith(selections: const []);
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
