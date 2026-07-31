import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/day_progress_store.dart';
import '../../data/models/clue.dart';
import '../../data/models/clue_selection.dart';
import '../../data/models/follow_up_question.dart';
import '../../data/models/scene_composition.dart';
import '../../data/models/scene_tap_map.dart';
import '../controllers/day_flow_controller.dart';
import '../providers/api_providers.dart';
import 'patterns_screen.dart';

/// The bottom nav's "Patterns" tab (index 1) is the only one with a real
/// destination today — "Today" and "Profile" stay local-only restyles since
/// there's nothing to navigate to yet for them.
void _onNavSelect(BuildContext context, int index) {
  if (index == 1) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PatternsScreen()));
  }
}

const _ink = Color(0xff2a2733);
const _muted = Color(0xff8a849a);
const _purple = Color(0xff7b6a9e);
const _softPurple = Color(0xffede9f5);
const _surface = Color(0xfff3f1f8);
const _cream = Color(0xfffaf7f2);
const _white = Color(0xfffdfbff);
const _userName = 'Upasana';

enum _JourneyPage { welcome, intro, moments, preparing, reflection, completed }

class SeenExperience extends ConsumerStatefulWidget {
  const SeenExperience({super.key});

  @override
  ConsumerState<SeenExperience> createState() => _SeenExperienceState();
}

class _SeenExperienceState extends ConsumerState<SeenExperience> {
  _JourneyPage _page = _JourneyPage.welcome;
  bool _editing = false;
  bool _saving = false;
  String _reflection = _fallbackReflection;
  String _originalReflection = _fallbackReflection;
  final TextEditingController _editController = TextEditingController();

  // Populated once the current scene's tap map finishes loading (see
  // _SceneImage.onSceneLoaded) — this is what's actually shown/tappable,
  // which is what `displayedClueIds` should reflect, rather than the old
  // scoring-engine-curated `flow.scene.visibleClues` subset.
  List<String> _currentSceneClueIds = const [];

  void _onSceneLoaded(SceneTapMap map) {
    _currentSceneClueIds = map.items
        .map((t) => t.clueId(map.sceneId))
        .toList();
  }

  static const _fallbackReflection =
      'Today seemed to carry both stillness and unfinished thoughts. '
      'The moments you noticed gave you a small pause — a chance to look '
      'back at what stayed with you. It sounds like today was not defined '
      'by one feeling, but by small moments pulling gently in different '
      'directions.';

  @override
  void initState() {
    super.initState();
    _restoreProgress();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  /// Loads today's in-progress/completed entry (if any) so reopening the app
  /// resumes exactly where the user left off instead of restarting from the
  /// welcome screen. A stored entry from a previous calendar day is ignored
  /// by [DayProgressStore.load] — that's what gives the once-a-day gating.
  Future<void> _restoreProgress() async {
    final store = ref.read(dayProgressStoreProvider);
    final stored = await store.load(todayDateKey());
    if (!mounted || stored == null) return;

    if (stored.selections.isNotEmpty) {
      ref
          .read(dayFlowControllerProvider.notifier)
          .restoreSelections(stored.selections);
    }

    // 'intro'/'preparing' are transient — never resume directly into them.
    final stage = switch (stored.stage) {
      'moments' ||
      'reflection' ||
      'completed' => _JourneyPage.values.byName(stored.stage),
      _ =>
        stored.selections.isNotEmpty
            ? _JourneyPage.moments
            : _JourneyPage.welcome,
    };

    setState(() {
      if (stored.reflection != null && stored.reflection!.isNotEmpty) {
        _reflection = stored.reflection!;
      }
      if (stored.originalReflection != null &&
          stored.originalReflection!.isNotEmpty) {
        _originalReflection = stored.originalReflection!;
      }
      _editController.text = _reflection;
      _page = stage;
    });
  }

  /// Saves the current stage + selections + reflection so it survives an
  /// app restart, scoped to today's date.
  void _persistProgress() {
    final store = ref.read(dayProgressStoreProvider);
    final flow = ref.read(dayFlowControllerProvider);
    store.save(
      StoredDayProgress(
        date: todayDateKey(),
        stage: _page.name,
        selections: flow.selections,
        reflection: _reflection,
        originalReflection: _originalReflection,
      ),
    );
  }

  void _go(_JourneyPage page) {
    if (mounted) setState(() => _page = page);
  }

  Future<void> _openMoment(Clue clue) async {
    final flow = ref.read(dayFlowControllerProvider);
    final existing = flow.selections
        .where((selection) => selection.clueId == clue.id)
        .firstOrNull;

    if (existing == null && flow.selections.length >= kMaxSelectionsPerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can save up to three moments.')),
      );
      return;
    }

    final notifier = ref.read(dayFlowControllerProvider.notifier);
    // Fetched dynamically per-clue (falls back to a category-based static
    // question offline/on failure — see FallbackQuestions — but never the
    // one-size-fits-all prompt every clue used to show).
    final questionFuture = ref
        .read(seenRepositoryProvider)
        .followUpQuestion(
          clue: clue,
          context: flow.context,
          interpretedSignals: flow.signals,
          previousMeaning: notifier.lastAnsweredOption,
        );

    final meaning = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 430),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _MomentSheet(
          clue: clue,
          initialMeaning: existing?.userMeaning,
          questionFuture: questionFuture,
        ),
      ),
    );

    if (!mounted || meaning == null || meaning.trim().isEmpty) return;

    final question = await questionFuture;
    final accepted = notifier.addSelection(
      ClueSelection(
        clueId: clue.id,
        clueTitle: clue.title,
        selectedAt: DateTime.now(),
        dailyContextDate: flow.context.date,
        userMeaning: meaning.trim(),
        followUpQuestion: question.question,
        answerOption: meaning.trim(),
      ),
    );

    if (!accepted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can save up to three moments.')),
      );
      return;
    }
    _persistProgress();
  }

  Future<void> _prepareReflection() async {
    final flow = ref.read(dayFlowControllerProvider);
    if (flow.selections.isEmpty) return;

    _go(_JourneyPage.preparing);

    final repo = ref.read(seenRepositoryProvider);
    final moments = flow.selections
        .map(
          (s) => {
            'clueId': s.clueId,
            'clueTitle': s.clueTitle,
            'text': s.userMeaning ?? s.answerOption ?? '',
          },
        )
        .toList();

    final reflectionFuture = repo.generateReflection(
      context: flow.context,
      interpretedSignals: flow.signals,
      moments: moments,
    );
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 1800));
    final reflection = await reflectionFuture;
    await minDelay;
    if (!mounted) return;

    final next = reflection.text.trim().isNotEmpty
        ? reflection.text.trim()
        : _fallbackReflection;

    setState(() {
      _originalReflection = next;
      _reflection = next;
      _editController.text = next;
      _editing = false;
      _page = _JourneyPage.reflection;
    });
    _persistProgress();
  }

  void _beginEditing() {
    setState(() {
      _editController.text = _reflection;
      _editing = true;
      _page = _JourneyPage.reflection;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editController.text = _reflection;
      _editing = false;
    });
  }

  void _saveChanges() {
    final edited = _editController.text.trim();
    setState(() {
      if (edited.isNotEmpty) _reflection = edited;
      _editing = false;
    });
    _persistProgress();
  }

  Future<void> _saveReflection() async {
    if (_saving) return;
    setState(() => _saving = true);

    final repo = ref.read(seenRepositoryProvider);
    final flow = ref.read(dayFlowControllerProvider);
    await repo.completeDay(
      context: flow.context,
      interpretedSignals: flow.signals,
      displayedClueIds: _currentSceneClueIds.isNotEmpty
          ? _currentSceneClueIds
          : flow.scene.visibleClues.map((c) => c.id).toList(),
      selectedClues: flow.selections,
    );
    if (!mounted) return;

    setState(() {
      _saving = false;
      _page = _JourneyPage.completed;
    });
    _persistProgress();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(dayFlowControllerProvider);
    final isDark = _page == _JourneyPage.intro;

    final screen = switch (_page) {
      _JourneyPage.welcome => _WelcomeScreen(
        key: const ValueKey('welcome'),
        flow: flow,
        onExplore: () => _go(_JourneyPage.intro),
      ),
      _JourneyPage.intro => _SceneIntroScreen(
        key: const ValueKey('intro'),
        onBack: () => _go(_JourneyPage.welcome),
        onEnter: () => _go(_JourneyPage.moments),
      ),
      _JourneyPage.moments => _MomentsScreen(
        key: const ValueKey('moments'),
        flow: flow,
        onBack: () => _go(_JourneyPage.intro),
        onSelect: _openMoment,
        onReview: _prepareReflection,
        onSceneLoaded: _onSceneLoaded,
      ),
      _JourneyPage.preparing => const _PreparingScreen(
        key: ValueKey('preparing'),
      ),
      _JourneyPage.reflection => _ReflectionScreen(
        key: const ValueKey('reflection'),
        reflection: _reflection,
        originalReflection: _originalReflection,
        editController: _editController,
        editing: _editing,
        saving: _saving,
        onBack: () => _go(_JourneyPage.moments),
        onEdit: _beginEditing,
        onCancel: _cancelEditing,
        onRestore: () =>
            setState(() => _editController.text = _originalReflection),
        onSaveChanges: _saveChanges,
        onSaveReflection: _saveReflection,
      ),
      _JourneyPage.completed => _CompletedScreen(
        key: const ValueKey('completed'),
        flow: flow,
        reflection: _reflection,
        onRead: () {
          setState(() {
            _editing = false;
            _page = _JourneyPage.reflection;
          });
        },
        onEdit: _beginEditing,
        onAddThought: () => _go(_JourneyPage.moments),
      ),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _surface,
        body: DecoratedBox(
          decoration: const BoxDecoration(color: _surface),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.025, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: screen,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({
    super.key,
    required this.flow,
    required this.onExplore,
  });

  final DayFlowState flow;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final sleep = _formatSleep(flow.context.sleepHours);
    final steps = _formatNumber(flow.context.steps ?? 0);
    final weather = _titleCase(flow.context.weather);

    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          const _SystemTop(),
          const _BrandBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderIllustration(
                    imagePath: 'assets/cozy_evening_header.png',
                  ),
                  const SizedBox(height: 22),
                  Text(_dateLabel(), style: _kicker()),
                  const SizedBox(height: 14),
                  Text('Good evening,', style: _display(height: 1.35)),
                  Text(
                    '$_userName.',
                    style: _display(color: _purple, italic: true, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  Text("Let's talk about today.", style: _serifTitle()),
                  const SizedBox(height: 12),
                  Text(
                    "You don't have to remember everything. We'll help "
                    'you find a place to begin.',
                    style: _bodyStyle(),
                  ),
                  const SizedBox(height: 20),
                  _GlimpseCard(
                    sleep: sleep,
                    steps: steps,
                    weather: weather,
                    calendar: _calendarLoadLabel(flow.context.calendarEventCount),
                  ),
                  const SizedBox(height: 28),
                  _PrimaryButton(
                    label: '✦   Explore my day',
                    onPressed: onExplore,
                    borderRadius: 18,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_purple, Color(0xff5e4e80)],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _BottomNavigation(onSelect: (index) => _onNavSelect(context, index)),
        ],
      ),
    );
  }
}

class _SceneIntroScreen extends StatelessWidget {
  const _SceneIntroScreen({
    super.key,
    required this.onBack,
    required this.onEnter,
  });

  final VoidCallback onBack;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/figma_intro_background.png', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.30, 0.40, 0.57, 1.0],
              colors: [
                Color(0x00080512),
                Color(0xb8080512),
                Color(0xeb080512),
                Color(0xf706030e),
              ],
            ),
          ),
        ),
        Column(
          children: [
            const _SystemTop(light: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 2, 24, 0),
              child: Row(
                children: [
                  _RoundButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: onBack,
                    light: true,
                    fillOpacity: 0.15,
                    showBorder: true,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SEEN',
                    style: _lora(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.02,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR SCENE IS READY',
                    style: _kicker(
                      color: Colors.white,
                      weight: FontWeight.w500,
                      letterSpacing: 1.43,
                    ),
                  ),
                  const SizedBox(height: 18),
                  RichText(
                    text: TextSpan(
                      style: _display(color: Colors.white, size: 28),
                      children: [
                        const TextSpan(text: "Let's take a "),
                        TextSpan(
                          text: 'closer look.',
                          style: _display(
                            color: const Color(0xffc4a8e8),
                            size: 28,
                            italic: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'We created a scene for you to explore. Take a look '
                    'around and notice what brings a moment from your day '
                    'back to mind.',
                    style: _bodyStyle(
                      color: Colors.white,
                      size: 14,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.13),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Color(0xffc4a8e8),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'How this works',
                              style: _sans(
                                color: const Color(0xfff2ede4),
                                size: 13,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        Text(
                          "Tap anything that brings back a moment from today. "
                          "An object doesn't have to match your day exactly — "
                          'it can remind you of something completely different.',
                          style: _bodyStyle(
                            color: const Color(
                              0xffebe4f8,
                            ).withValues(alpha: 0.88),
                            size: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                0xffc4a8e8,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FOR EXAMPLE',
                                style: _kicker(
                                  color: const Color(
                                    0xffc4a8e8,
                                  ).withValues(alpha: 0.7),
                                  size: 11,
                                  weight: FontWeight.w600,
                                  letterSpacing: 0.88,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'A cup might remind you of a quiet break, '
                                'a conversation, or forgetting to eat.',
                                style: _bodyStyle(
                                  color: const Color(
                                    0xffebe4f8,
                                  ).withValues(alpha: 0.7),
                                  size: 12,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  _PrimaryButton(
                    label: 'Enter the scene   →',
                    onPressed: onEnter,
                    borderRadius: 18,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _purple.withValues(alpha: 0.95),
                        const Color(0xff5e4e80).withValues(alpha: 0.98),
                      ],
                    ),
                    borderColor: Colors.white.withValues(alpha: 0.15),
                    textStyle: _sans(
                      color: Colors.white,
                      size: 16,
                      weight: FontWeight.w600,
                      letterSpacing: 0.16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MomentsScreen extends StatelessWidget {
  const _MomentsScreen({
    super.key,
    required this.flow,
    required this.onBack,
    required this.onSelect,
    required this.onReview,
    required this.onSceneLoaded,
  });

  final DayFlowState flow;
  final VoidCallback onBack;
  final ValueChanged<Clue> onSelect;
  final VoidCallback onReview;
  final ValueChanged<SceneTapMap> onSceneLoaded;

  @override
  Widget build(BuildContext context) {
    final selectedIds = flow.selections
        .map((selection) => selection.clueId)
        .toSet();
    final count = selectedIds.length;

    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          const _SystemTop(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              children: [
                _RoundButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: onBack,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xfff0ebf8),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      if (count > 0) ...[
                        const Icon(
                          Icons.check_circle,
                          color: _purple,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        '$count ${count == 1 ? 'moment' : 'moments'} found',
                        style: _sans(
                          color: count > 0 ? _purple : _muted,
                          size: 12,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _RoundButton(
                  icon: Icons.help_outline_rounded,
                  onPressed: () => _showSceneHelp(context),
                  size: 32,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What brings a part of your day back to mind?',
                  style: _serifTitle(size: 20, height: 1.24),
                ),
                const SizedBox(height: 3),
                Text(
                  'Look around and tap anything that feels familiar, '
                  'meaningful, or worth remembering.',
                  style: _bodyStyle(size: 13),
                ),
              ],
            ),
          ),
          Expanded(
            // _SceneImage sizes itself from its tap map's own aspect ratio
            // (each room image is ~941×1672, not 1:1) and scrolls
            // internally — no outer fixed AspectRatio/SingleChildScrollView
            // needed here, unlike the old single-square-image approach.
            child: _SceneImage(
              scene: flow.scene,
              selectedIds: selectedIds,
              onSelect: onSelect,
              onSceneLoaded: onSceneLoaded,
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              17,
              24,
              28 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: _white,
              border: Border(top: BorderSide(color: Color(0x197b6a9e))),
              boxShadow: [
                BoxShadow(
                  color: Color(0x177b6a9e),
                  blurRadius: 24,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  count == 0
                      ? 'Start with anything that catches your attention.'
                      : 'You can continue or keep exploring.',
                  style: _bodyStyle(size: 12.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _PrimaryButton(
                  label: count == 0 ? 'Continue' : 'Review my moments',
                  onPressed: count == 0 ? null : onReview,
                  textStyle: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showSceneHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 430),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 24),
            Text('How this works', style: _serifTitle(size: 20, height: 1.5)),
            const SizedBox(height: 14),
            Text(
              "Tap anything that brings back a moment from today. The "
              "object doesn't have to match exactly — it can remind you "
              "of something completely different.",
              style: _bodyStyle(
                color: const Color(0xff5c5570),
                size: 14,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example',
                    style: _sans(
                      color: _purple,
                      size: 12,
                      weight: FontWeight.w600,
                      letterSpacing: 0.48,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A cup might remind you of a quiet break, a '
                    'conversation, or forgetting to eat.',
                    style: _bodyStyle(
                      color: const Color(0xff5c5570),
                      size: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              label: 'Got it',
              borderRadius: 14,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneImage extends StatefulWidget {
  const _SceneImage({
    required this.scene,
    required this.selectedIds,
    required this.onSelect,
    required this.onSceneLoaded,
  });

  final SceneComposition scene;
  final Set<String> selectedIds;
  final ValueChanged<Clue> onSelect;
  final ValueChanged<SceneTapMap> onSceneLoaded;

  @override
  State<_SceneImage> createState() => _SceneImageState();
}

class _SceneImageState extends State<_SceneImage> {
  late Future<SceneTapMap> _tapMap;

  @override
  void initState() {
    super.initState();
    _loadTapMap();
  }

  @override
  void didUpdateWidget(covariant _SceneImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.kind != widget.scene.kind) {
      _loadTapMap();
    }
  }

  void _loadTapMap() {
    _tapMap = SceneTapMap.load(widget.scene.kind.tapMapAssetPath);
    _tapMap.then((map) {
      if (mounted) widget.onSceneLoaded(map);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SceneTapMap>(
      future: _tapMap,
      builder: (context, snapshot) {
        final tapMap = snapshot.data;
        if (tapMap == null) {
          return SingleChildScrollView(
            child: Image.asset(
              widget.scene.assetPath,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(
              constraints.maxWidth,
              constraints.maxWidth / tapMap.imageSize.aspectRatio,
            );
            return SingleChildScrollView(
              child: SizedBox.fromSize(
                size: canvasSize,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Image.asset(
                      widget.scene.assetPath,
                      width: canvasSize.width,
                      height: canvasSize.height,
                      fit: BoxFit.fill,
                    ),
                    for (final target in tapMap.items)
                      Positioned.fromRect(
                        rect: target.tapAreaFor(canvasSize),
                        child: Semantics(
                          button: true,
                          label: target.label,
                          selected: widget.selectedIds.contains(
                            target.clueId(tapMap.sceneId),
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                widget.onSelect(target.asClue(tapMap.sceneId)),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    for (final target in tapMap.items)
                      if (widget.selectedIds.contains(
                        target.clueId(tapMap.sceneId),
                      ))
                        _SceneCheckmark(
                          position: target.checkmarkFor(canvasSize),
                          canvasSize: canvasSize,
                        ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SceneCheckmark extends StatelessWidget {
  const _SceneCheckmark({required this.position, required this.canvasSize});

  static const _size = 25.0;
  final Offset position;
  final Size canvasSize;

  @override
  Widget build(BuildContext context) {
    final left = (position.dx - _size / 2)
        .clamp(0.0, math.max(0.0, canvasSize.width - _size))
        .toDouble();
    final top = (position.dy - _size / 2)
        .clamp(0.0, math.max(0.0, canvasSize.height - _size))
        .toDouble();
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: _size,
          height: _size,
          decoration: const BoxDecoration(
            color: _purple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

class _PreparingScreen extends StatelessWidget {
  const _PreparingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/figma_loading_background.png', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(color: _softPurple.withValues(alpha: 0.52)),
        ),
        Center(
          child: Container(
            width: 342,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(36, 36, 36, 32),
            decoration: BoxDecoration(
              color: _white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '◉  SEEN',
                  style: _lora(
                    color: const Color(0xff4a4260),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.05,
                  ),
                ),
                const SizedBox(height: 55),
                Text(
                  'Bringing your day',
                  style: _display(size: 27, height: 1.25),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'together.',
                  style: _display(
                    size: 27,
                    color: _purple,
                    italic: true,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 17),
                Text(
                  "We're using the moments you shared to prepare a "
                  'reflection you can review and shape.',
                  style: _bodyStyle(
                    color: const Color(0xff3a3448),
                    size: 14,
                    height: 1.65,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 44),
                const _AnimatedDots(),
                const SizedBox(height: 28),
                Text(
                  'Preparing your reflection…',
                  style: _sans(
                    color: const Color(0xff5c5570),
                    size: 12,
                    height: 1.5,
                    letterSpacing: 0.48,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReflectionScreen extends StatelessWidget {
  const _ReflectionScreen({
    super.key,
    required this.reflection,
    required this.originalReflection,
    required this.editController,
    required this.editing,
    this.saving = false,
    required this.onBack,
    required this.onEdit,
    required this.onCancel,
    required this.onRestore,
    required this.onSaveChanges,
    required this.onSaveReflection,
  });

  final String reflection;
  final String originalReflection;
  final TextEditingController editController;
  final bool editing;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onRestore;
  final VoidCallback onSaveChanges;
  final VoidCallback onSaveReflection;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          const _SystemTop(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Row(
              children: [
                _RoundButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: onBack,
                ),
                const Spacer(),
                Text(
                  'SEEN',
                  style: _lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                    color: _ink,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 36),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: _serifTitle(size: 24, height: 1.25),
                    children: [
                      const TextSpan(text: "Here's what your day "),
                      TextSpan(
                        text: 'seems to hold.',
                        style: _serifTitle(
                          size: 24,
                          height: 1.25,
                          color: _purple,
                          italic: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "This is a starting point. Change anything that doesn't "
                  'feel like you.',
                  style: _bodyStyle(size: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: _SoftCard(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 21),
                borderRadius: 20,
                boxShadow: [
                  BoxShadow(color: _purple.withValues(alpha: 0.06)),
                  BoxShadow(
                    color: _purple.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
                child: editing
                    ? _ReflectionEditor(
                        controller: editController,
                        originalReflection: originalReflection,
                        onCancel: onCancel,
                        onRestore: onRestore,
                        onSave: onSaveChanges,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reflection,
                            style: _lora(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 13),
                            label: const Text('Edit reflection'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _purple,
                              side: BorderSide(
                                color: _purple.withValues(alpha: 0.25),
                              ),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              textStyle: _sans(
                                size: 13,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (!editing)
            Container(
              padding: EdgeInsets.fromLTRB(
                24,
                14,
                24,
                28 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: _surface,
                border: const Border(top: BorderSide(color: Color(0x197b6a9e))),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _PrimaryButton(
                    label: saving ? 'Saving…' : 'Save reflection',
                    onPressed: saving ? null : onSaveReflection,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_purple, Color(0xff5e4e80)],
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onBack,
                    child: Text(
                      'Go back to my moments',
                      style: _sans(color: _muted, size: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReflectionEditor extends StatelessWidget {
  const _ReflectionEditor({
    required this.controller,
    required this.originalReflection,
    required this.onCancel,
    required this.onRestore,
    required this.onSave,
  });

  final TextEditingController controller;
  final String originalReflection;
  final VoidCallback onCancel;
  final VoidCallback onRestore;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MAKE IT SOUND MORE LIKE YOU',
          style: _kicker(color: _purple, weight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          minLines: 9,
          maxLines: 13,
          style: _lora(color: _ink, fontSize: 15, height: 1.5),
          decoration: InputDecoration(
            hintText: originalReflection,
            hintStyle: _lora(
              color: const Color(0xffaaa3b4),
              fontSize: 15,
              height: 1.5,
            ),
            filled: true,
            fillColor: _surface,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _purple.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _purple, width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 9),
        TextButton(
          onPressed: onRestore,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Restore original version',
            style: _sans(color: const Color(0xffa89ec4), size: 12, height: 1.5),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                label: 'Cancel',
                onPressed: onCancel,
                textSize: 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _PrimaryButton(
                label: 'Save changes',
                onPressed: onSave,
                compact: true,
                textStyle: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompletedScreen extends StatelessWidget {
  const _CompletedScreen({
    super.key,
    required this.flow,
    required this.reflection,
    required this.onRead,
    required this.onEdit,
    required this.onAddThought,
  });

  final DayFlowState flow;
  final String reflection;
  final VoidCallback onRead;
  final VoidCallback onEdit;
  final VoidCallback onAddThought;

  @override
  Widget build(BuildContext context) {
    final count = flow.selections.length;
    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          const _SystemTop(),
          const _BrandBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderIllustration(
                    height: 192,
                    imagePath: 'assets/cozy-completed-header.png',
                  ),
                  const SizedBox(height: 22),
                  Text(_dateLabel(), style: _kicker()),
                  const SizedBox(height: 14),
                  Text(
                    "You're done reflecting",
                    style: _display(size: 26, height: 1.25),
                  ),
                  Text(
                    'for today, $_userName.',
                    style: _display(
                      size: 26,
                      color: _purple,
                      italic: true,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You took a moment to look back, notice what stood out, '
                    'and put your day into words. Nice work showing up for '
                    'yourself today.',
                    style: _bodyStyle(
                      color: const Color(0xff6e6880),
                      size: 14,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SoftCard(
                    padding: const EdgeInsets.fromLTRB(20, 21, 20, 17),
                    borderRadius: 20,
                    boxShadow: [
                      BoxShadow(color: _purple.withValues(alpha: 0.07)),
                      BoxShadow(
                        color: _purple.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TODAY'S REFLECTION",
                          style: _kicker(weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 13),
                        Text(
                          reflection,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: _lora(color: _ink, fontSize: 14, height: 1.65),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 15,
                          runSpacing: 6,
                          children: [
                            _MetaItem(
                              icon: Icons.check_circle_outline,
                              label:
                                  '$count ${count == 1 ? 'moment' : 'moments'} reflected on',
                            ),
                            _MetaItem(
                              icon: Icons.schedule_outlined,
                              label: 'Saved at ${_clockTime()}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _PrimaryButton(
                                label: 'Read full reflection',
                                onPressed: onRead,
                                compact: true,
                                textStyle: const TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _SecondaryButton(
                                label: 'Edit',
                                onPressed: onEdit,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _GlimpseSummaryCard(
                    sleep: _formatSleep(flow.context.sleepHours),
                    steps: _formatNumber(flow.context.steps ?? 0),
                    weather: _titleCase(flow.context.weather),
                    calendar: _calendarLoadLabel(flow.context.calendarEventCount),
                  ),
                ],
              ),
            ),
          ),
          _BottomNavigation(onSelect: (index) => _onNavSelect(context, index)),
        ],
      ),
    );
  }
}

class _MomentSheet extends StatefulWidget {
  const _MomentSheet({
    required this.clue,
    required this.initialMeaning,
    required this.questionFuture,
  });

  final Clue clue;
  final String? initialMeaning;

  /// Resolves to a clue-specific question (AI-generated, or a category-based
  /// fallback if the backend is unavailable) — never the same generic
  /// prompt for every clue.
  final Future<FollowUpQuestion> questionFuture;

  @override
  State<_MomentSheet> createState() => _MomentSheetState();
}

class _MomentSheetState extends State<_MomentSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialMeaning ?? '',
  );
  String? _question;

  @override
  void initState() {
    super.initState();
    widget.questionFuture.then((q) {
      if (mounted) setState(() => _question = q.question);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        40 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 25),
          Text(
            widget.clue.title.toUpperCase(),
            style: _kicker(weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            _question ?? 'What did this bring to mind from your day?',
            style: _serifTitle(size: 20, height: 1.3),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            style: _sans(color: _ink, size: 15),
            decoration: InputDecoration(
              hintText: 'A moment, feeling, person, task, or memory...',
              hintStyle: _sans(color: _ink.withValues(alpha: 0.5), size: 15),
              filled: true,
              fillColor: _surface,
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _purple.withValues(alpha: 0.18)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _purple, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  textSize: 15,
                  borderRadius: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                  label: 'Save this moment',
                  compact: true,
                  borderRadius: 14,
                  textStyle: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(context, _controller.text.trim()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlimpseCard extends StatelessWidget {
  const _GlimpseCard({
    required this.sleep,
    required this.steps,
    required this.weather,
    required this.calendar,
  });

  final String sleep;
  final String steps;
  final String weather;
  final String calendar;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(19, 19, 16, 18),
      color: _white,
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A glimpse of your day', style: _serifTitle(size: 17)),
                    const SizedBox(height: 2),
                    Text(
                      'Here are a few things we noticed',
                      style: _bodyStyle(size: 12),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xfff0ebf8),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Metric(
                icon: Icons.nightlight_round,
                label: 'SLEEP',
                value: sleep,
                color: const Color(0xff9c87cc),
              ),
              _Metric(
                icon: Icons.directions_walk_rounded,
                label: 'MOVEMENT',
                value: steps,
                color: const Color(0xff86b3d0),
              ),
              _Metric(
                icon: Icons.cloudy_snowing,
                label: 'WEATHER',
                value: weather,
                color: const Color(0xff87acd2),
              ),
              _Metric(
                icon: Icons.event_note_rounded,
                label: 'CALENDAR',
                value: calendar,
                color: const Color(0xffd89459),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xfff0ebf8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            style: _sans(color: _muted, size: 9, letterSpacing: 0.55),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: _sans(
              color: _ink,
              size: 11.5,
              weight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIllustration extends StatelessWidget {
  const _HeaderIllustration({
    this.height = 192,
    this.imagePath = 'assets/cozy_reflection_header.png',
  });

  final double height;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            const Icon(Icons.radar_rounded, size: 19, color: _purple),
            const SizedBox(width: 7),
            Text(
              'SEEN',
              style: _lora(color: _ink, fontSize: 16, letterSpacing: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemTop extends StatelessWidget {
  const _SystemTop({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    if (inset > 0) return SizedBox(height: inset);

    final color = light ? Colors.white : _ink;
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            Text(
              _clockTime(includePeriod: false),
              style: _sans(color: color, size: 13, weight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.signal_cellular_alt, size: 15, color: color),
            const SizedBox(width: 6),
            Icon(Icons.wifi, size: 14, color: color),
            const SizedBox(width: 6),
            Icon(Icons.battery_full_rounded, size: 19, color: color),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatefulWidget {
  const _BottomNavigation({this.onSelect});

  /// Called whenever a tab is tapped, in addition to the local restyle
  /// below. Optional so existing call sites that don't pass it keep the
  /// original (purely decorative, no navigation) behavior.
  final ValueChanged<int>? onSelect;

  @override
  State<_BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<_BottomNavigation> {
  int _selected = 0;

  void _select(int index) {
    setState(() => _selected = index);
    widget.onSelect?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82 + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      color: _white,
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.calendar_today_outlined,
              label: 'Today',
              selected: _selected == 0,
              onTap: () => _select(0),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.show_chart_rounded,
              label: 'Patterns',
              selected: _selected == 1,
              onTap: () => _select(1),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: _selected == 2,
              onTap: () => _select(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _purple : const Color(0xffc4b8d8);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 4),
          Text(label, style: _sans(color: color, size: 11)),
          const SizedBox(height: 6),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: selected ? _purple : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xffa89ec4)),
        const SizedBox(width: 5),
        Text(label, style: _sans(color: _muted, size: 12)),
      ],
    );
  }
}

class _GlimpseSummaryCard extends StatelessWidget {
  const _GlimpseSummaryCard({
    required this.sleep,
    required this.steps,
    required this.weather,
    required this.calendar,
  });

  final String sleep;
  final String steps;
  final String weather;
  final String calendar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A GLIMPSE OF THE DAY', style: _kicker(weight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GlimpseStat(
                  label: 'SLEEP',
                  value: sleep,
                  color: const Color(0xff8b7db8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GlimpseStat(
                  label: 'STEPS',
                  value: steps,
                  color: const Color(0xff7a9bb5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GlimpseStat(
                  label: 'WEATHER',
                  value: weather,
                  color: const Color(0xff7a9bb5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GlimpseStat(
                  label: 'CALENDAR',
                  value: calendar,
                  color: const Color(0xffc4956a),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlimpseStat extends StatelessWidget {
  const _GlimpseStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _sans(
            color: _muted,
            size: 10,
            weight: FontWeight.w500,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _sans(color: color, size: 12, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
    this.gradient,
    this.borderRadius,
    this.textStyle,
    this.borderColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool compact;
  final Gradient? gradient;
  final double? borderRadius;
  final TextStyle? textStyle;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (compact ? 12.0 : 16.0);
    final button = SizedBox(
      width: double.infinity,
      height: compact ? 48 : 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: gradient != null ? Colors.transparent : _purple,
          disabledBackgroundColor: const Color(0xffd4cfe4),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xffa8a0bc),
          elevation: (onPressed == null || gradient != null) ? 0 : 4,
          shadowColor: _purple.withValues(alpha: 0.32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle:
              textStyle ??
              _sans(size: compact ? 13 : 15, weight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );

    if (gradient == null) return button;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: button,
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    this.textSize = 13,
    this.borderRadius = 12,
  });

  final String label;
  final VoidCallback onPressed;
  final double textSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _softPurple,
          foregroundColor: const Color(0xff4a4260),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: _sans(size: textSize, weight: FontWeight.w500),
        ),
        child: Text(label),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onPressed,
    this.light = false,
    this.size = 36,
    this.fillOpacity = 0.12,
    this.showBorder = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool light;
  final double size;
  final double fillOpacity;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: light
            ? Colors.white.withValues(alpha: fillOpacity)
            : const Color(0xffede9f5),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(
            icon,
            size: size * 0.45,
            color: light ? Colors.white : _purple,
          ),
        ),
      ),
    );

    if (!showBorder) return button;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: button,
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    required this.padding,
    this.color = _cream,
    this.borderRadius = 21,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow:
            boxShadow ??
            const [
              BoxShadow(
                color: Color(0x147b6a9e),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
      ),
      child: child,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xffd4cfe8),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            Opacity(
              opacity:
                  0.35 +
                  0.65 *
                      ((math.sin(_controller.value * math.pi * 2 - i) + 1) / 2),
              child: const CircleAvatar(radius: 5, backgroundColor: _purple),
            ),
            if (i < 2) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

TextStyle _lora({
  Color color = _ink,
  double fontSize = 14,
  double? height,
  FontWeight fontWeight = FontWeight.w400,
  FontStyle fontStyle = FontStyle.normal,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: 'Lora',
    color: color,
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
  );
}

TextStyle _display({
  Color color = _ink,
  double size = 29,
  bool italic = false,
  double height = 1.12,
}) {
  return _lora(
    color: color,
    fontSize: size,
    height: height,
    fontWeight: FontWeight.w500,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  );
}

TextStyle _serifTitle({
  Color color = _ink,
  double size = 22,
  double height = 1.18,
  bool italic = false,
}) {
  return _lora(
    color: color,
    fontSize: size,
    height: height,
    fontWeight: FontWeight.w500,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  );
}

TextStyle _sans({
  Color color = _ink,
  double size = 13,
  double height = 1.4,
  FontWeight weight = FontWeight.w400,
  double letterSpacing = 0,
  TextDecoration? decoration,
}) {
  return TextStyle(
    fontFamily: 'DMSans',
    color: color,
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );
}

TextStyle _bodyStyle({
  Color color = _muted,
  double size = 13,
  double height = 1.5,
}) {
  return _sans(color: color, size: size, height: height);
}

TextStyle _kicker({
  Color color = _muted,
  double size = 11,
  FontWeight weight = FontWeight.w700,
  double letterSpacing = 1.1,
}) {
  return _sans(
    color: color,
    size: size,
    weight: weight,
    letterSpacing: letterSpacing,
  );
}

String _formatSleep(double? hours) {
  if (hours == null) return '—';
  final whole = hours.floor();
  final minutes = ((hours - whole) * 60).round();
  return '${whole}h ${minutes}m';
}

String _formatNumber(int value) {
  final source = value.toString();
  return source.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  final normalized = value == 'rain' ? 'rainy' : value;
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}

/// 0-2 events: Free · 3-5: Moderate · 6+: Busy.
String _calendarLoadLabel(int eventCount) {
  if (eventCount < 3) return 'Free';
  if (eventCount <= 5) return 'Moderate';
  return 'Busy';
}

String _dateLabel() {
  final now = DateTime.now();
  const weekdays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  const months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
}

String _clockTime({bool includePeriod = true}) {
  final now = TimeOfDay.now();
  final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
  final minute = now.minute.toString().padLeft(2, '0');
  if (!includePeriod) return '$hour:$minute';
  return '$hour:$minute ${now.period == DayPeriod.am ? 'AM' : 'PM'}';
}
