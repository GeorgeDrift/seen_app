import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/scene_catalog.dart';
import '../../data/models/clue_selection.dart';
import '../../data/models/daily_entry.dart';
import '../../data/models/reflection.dart';
import '../../data/models/scene_hotspot.dart';
import '../providers/api_providers.dart';
import 'day_flow_controller.dart';
import 'profile_controller.dart';

/// The stages of the redesigned Today flow: a fixed illustrated room replaces
/// the old hidden-object composition, free-text capture replaces the AI
/// follow-up question, and a single editable narrative reflection replaces
/// the one-line summary.
enum TodayStage {
  glimpse,
  sceneIntro,
  scene,
  reflectionLoading,
  reflection,
  done,
}

/// Maximum moments a user may capture per day. Also enforced server-side
/// via `/day/complete`'s selection cap.
const int kMaxMomentsPerDay = 3;

/// The static prompt shown for every tapped hotspot — there is no
/// per-clue AI question in the redesigned flow.
const String kMomentCapturePrompt =
    'What did this bring to mind from your day?';

class TodayFlowState {
  const TodayFlowState({
    required this.stage,
    required this.moments,
    this.firstReflection,
    this.reflection,
    this.savedEntry,
    this.isBusy = false,
    this.error,
  });

  final TodayStage stage;
  final List<ClueSelection> moments;
  final Reflection? firstReflection; // the original, for "restore original"
  final Reflection? reflection; // the currently displayed one
  final DailyEntry? savedEntry;
  final bool isBusy;
  final String? error;

  TodayFlowState copyWith({
    TodayStage? stage,
    List<ClueSelection>? moments,
    Reflection? firstReflection,
    Reflection? reflection,
    DailyEntry? savedEntry,
    bool? isBusy,
    String? error,
  }) {
    return TodayFlowState(
      stage: stage ?? this.stage,
      moments: moments ?? this.moments,
      firstReflection: firstReflection ?? this.firstReflection,
      reflection: reflection ?? this.reflection,
      savedEntry: savedEntry ?? this.savedEntry,
      isBusy: isBusy ?? this.isBusy,
      error: error,
    );
  }
}

final todayFlowControllerProvider =
    NotifierProvider<TodayFlowController, TodayFlowState>(
      TodayFlowController.new,
    );

class TodayFlowController extends Notifier<TodayFlowState> {
  @override
  TodayFlowState build() {
    // Reset the flow whenever the active profile changes (demo switching).
    ref.watch(activeProfileProvider);
    return const TodayFlowState(stage: TodayStage.glimpse, moments: []);
  }

  SceneDefinition get sceneForActiveProfile =>
      SceneCatalog.forProfile(ref.read(activeProfileProvider).key);

  void enterSceneIntro() =>
      state = state.copyWith(stage: TodayStage.sceneIntro);

  void enterScene() => state = state.copyWith(stage: TodayStage.scene);

  /// Returns whether the moment was accepted (false if already at cap).
  bool addMoment(SceneHotspot hotspot, String text) {
    final flow = ref.read(dayFlowControllerProvider);
    final existing = state.moments.indexWhere((m) => m.clueId == hotspot.id);
    final selection = ClueSelection(
      clueId: hotspot.id,
      clueTitle: hotspot.title,
      selectedAt: DateTime.now(),
      dailyContextDate: flow.context.date,
      userMeaning: text,
      followUpQuestion: kMomentCapturePrompt,
      answerOption: text,
      confidence: 'clear',
    );
    if (existing >= 0) {
      final next = [...state.moments];
      next[existing] = selection;
      state = state.copyWith(moments: next);
      return true;
    }
    if (state.moments.length >= kMaxMomentsPerDay) return false;
    state = state.copyWith(moments: [...state.moments, selection]);
    return true;
  }

  void removeMoment(String hotspotId) {
    state = state.copyWith(
      moments: state.moments.where((m) => m.clueId != hotspotId).toList(),
    );
  }

  /// Moves to the reflection-loading stage and requests the AI narrative.
  Future<void> reviewMoments() async {
    state = state.copyWith(stage: TodayStage.reflectionLoading, error: null);
    final repo = ref.read(seenRepositoryProvider);
    final flow = ref.read(dayFlowControllerProvider);

    final momentsPayload = state.moments
        .map(
          (m) => {
            'clueId': m.clueId,
            'clueTitle': m.clueTitle,
            'text': m.userMeaning ?? '',
          },
        )
        .toList();

    final reflection = await repo.generateReflection(
      context: flow.context,
      interpretedSignals: flow.signals,
      moments: momentsPayload,
    );

    state = state.copyWith(
      stage: TodayStage.reflection,
      firstReflection: reflection,
      reflection: reflection,
    );
  }

  Future<void> refine(String steeringText) async {
    final current = state.reflection;
    if (current == null) return;
    state = state.copyWith(isBusy: true, error: null);

    final repo = ref.read(seenRepositoryProvider);
    final momentsPayload = state.moments
        .map(
          (m) => {
            'clueId': m.clueId,
            'clueTitle': m.clueTitle,
            'text': m.userMeaning ?? '',
          },
        )
        .toList();

    final refined = await repo.refineReflection(
      originalReflection: current.text,
      moments: momentsPayload,
      steeringText: steeringText,
    );

    state = state.copyWith(reflection: refined, isBusy: false);
  }

  void restoreOriginal() {
    if (state.firstReflection == null) return;
    state = state.copyWith(reflection: state.firstReflection);
  }

  void backToMoments() => state = state.copyWith(stage: TodayStage.scene);

  Future<void> saveReflection() async {
    state = state.copyWith(isBusy: true, error: null);
    final repo = ref.read(seenRepositoryProvider);
    final flow = ref.read(dayFlowControllerProvider);
    final scene = sceneForActiveProfile;

    try {
      final entry = await repo.completeDay(
        context: flow.context,
        interpretedSignals: flow.signals,
        displayedClueIds: scene.hotspots.map((h) => h.id).toList(),
        selectedClues: state.moments,
      );
      state = state.copyWith(
        stage: TodayStage.done,
        savedEntry: entry,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}
