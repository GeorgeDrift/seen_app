import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/day_progress_store.dart';
import '../../data/models/clue.dart';
import '../../data/models/clue_selection.dart';
import '../../data/models/scene_composition.dart';
import '../../data/models/scene_tap_map.dart';
import '../controllers/day_flow_controller.dart';
import '../providers/api_providers.dart';

const _ink = Color(0xff2a2733);
const _muted = Color(0xff8a849a);
const _purple = Color(0xff7b6a9e);
const _softPurple = Color(0xffede9f5);
const _surface = Color(0xfff3f1f8);
const _cream = Color(0xfffaf7f2);
const _white = Color(0xfffdfbff);
const _userName = 'Upasana';
const _phoneCanvasWidth = 430.0;

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
        const SnackBar(content: Text('You can save up to five moments.')),
      );
      return;
    }

    final meaning = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 430),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _MomentSheet(clue: clue, initialMeaning: existing?.userMeaning),
      ),
    );

    if (!mounted || meaning == null || meaning.trim().isEmpty) return;

    final accepted = ref
        .read(dayFlowControllerProvider.notifier)
        .addSelection(
          ClueSelection(
            clueId: clue.id,
            clueTitle: clue.title,
            selectedAt: DateTime.now(),
            dailyContextDate: flow.context.date,
            userMeaning: meaning.trim(),
            followUpQuestion: 'What did this bring to mind from your day?',
            answerOption: meaning.trim(),
          ),
        );

    if (!accepted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can save up to five moments.')),
      );
      return;
    }
    _persistProgress();
  }

  Future<void> _prepareReflection() async {
    final flow = ref.read(dayFlowControllerProvider);
    if (flow.selections.length < kMinSelectionsPerDay) return;

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
      displayedClueIds: flow.scene.visibleClues.map((c) => c.id).toList(),
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
        sceneLabel: flow.scene.label,
        onBack: () => _go(_JourneyPage.welcome),
        onEnter: () => _go(_JourneyPage.moments),
      ),
      _JourneyPage.moments => _MomentsScreen(
        key: const ValueKey('moments'),
        flow: flow,
        onBack: () => _go(_JourneyPage.intro),
        onSelect: _openMoment,
        onReview: _prepareReflection,
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
        backgroundColor: isDark ? const Color(0xff0d0816) : _surface,
        body: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff0d0816) : _surface,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = AnimatedSwitcher(
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
              );

              if (kIsWeb && constraints.maxWidth >= 700) {
                return Center(
                  child: SizedBox(
                    width: _phoneCanvasWidth,
                    height: constraints.maxHeight,
                    child: content,
                  ),
                );
              }

              return SizedBox.expand(child: content);
            },
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
    final screen = MediaQuery.sizeOf(context);
    final compact = screen.height < 720;
    final horizontal = screen.width < 360 ? 18.0 : 24.0;
    final headerHeight = (screen.height * 0.23).clamp(140.0, 192.0);

    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          const _SystemTop(),
          const _BrandBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                4,
                horizontal,
                compact ? 18 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderIllustration(height: headerHeight),
                  SizedBox(height: compact ? 14 : 22),
                  Text(_dateLabel(), style: _kicker()),
                  SizedBox(height: compact ? 8 : 14),
                  Text(
                    'Good evening,',
                    style: _display(size: compact ? 26 : 30),
                  ),
                  Text(
                    '$_userName.',
                    style: _display(
                      color: _purple,
                      italic: true,
                      size: compact ? 26 : 30,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 14),
                  Text("Let's talk about today.", style: _serifTitle()),
                  SizedBox(height: compact ? 7 : 12),
                  Text(
                    "You don't have to remember everything. We'll help "
                    'you find a place to begin.',
                    style: _bodyStyle(),
                  ),
                  SizedBox(height: compact ? 12 : 20),
                  _GlimpseCard(sleep: sleep, steps: steps, weather: weather),
                  SizedBox(height: compact ? 10 : 14),
                  _PrimaryButton(
                    label: '✦   Explore my day',
                    onPressed: onExplore,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneIntroScreen extends StatelessWidget {
  const _SceneIntroScreen({
    super.key,
    required this.sceneLabel,
    required this.onBack,
    required this.onEnter,
  });

  final String sceneLabel;
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
              stops: [0.18, 0.46, 0.72],
              colors: [Color(0x00110b1b), Color(0x33110b1b), Color(0xee0d0816)],
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
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SEEN',
                    style: _lora(
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _BottomAlignedScroll(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 27),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR SCENE IS READY',
                      style: _kicker(color: Colors.white),
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(17),
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
                                  color: Colors.white,
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
                              color: const Color(0xffded7e6),
                              size: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: const Border(
                                left: BorderSide(
                                  color: Color(0xffa78bc8),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FOR EXAMPLE',
                                  style: _kicker(
                                    color: const Color(0xffaa9bc1),
                                    size: 10,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'A cup might remind you of a quiet break, '
                                  'a conversation, or forgetting to eat.',
                                  style: _bodyStyle(
                                    color: const Color(0xffc9c1d2),
                                    size: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _PrimaryButton(
                      label: 'Enter the scene   →',
                      onPressed: onEnter,
                      background: const Color(0xff8069a4),
                    ),
                  ],
                ),
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
  });

  final DayFlowState flow;
  final VoidCallback onBack;
  final ValueChanged<Clue> onSelect;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final selectedIds = flow.selections
        .map((selection) => selection.clueId)
        .toSet();
    final count = selectedIds.length;
    final screen = MediaQuery.sizeOf(context);
    final compact = screen.height < 700;
    final horizontal = screen.width < 360 ? 16.0 : 24.0;

    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          const _SystemTop(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              0,
              horizontal,
              compact ? 7 : 12,
            ),
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
            padding: EdgeInsets.fromLTRB(
              horizontal,
              0,
              horizontal,
              compact ? 8 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What brings a part of your day back to mind?',
                  style: _serifTitle(size: compact ? 18 : 20, height: 1.24),
                ),
                const SizedBox(height: 3),
                Text(
                  'Look around and tap anything that feels familiar, '
                  'meaningful, or worth remembering.',
                  style: _bodyStyle(size: compact ? 12 : 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: _SceneImage(
              scene: flow.scene,
              selectedIds: selectedIds,
              onSelect: onSelect,
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              horizontal,
              compact ? 10 : 17,
              horizontal,
              (compact ? 12 : 20) + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: _white,
              border: Border(top: BorderSide(color: Color(0x197b6a9e))),
              boxShadow: [
                BoxShadow(
                  color: Color(0x177b6a9e),
                  blurRadius: 14,
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
                SizedBox(height: compact ? 8 : 12),
                _PrimaryButton(
                  label: count == 0 ? 'Continue' : 'Review my moments',
                  onPressed: count == 0 ? null : onReview,
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
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        decoration: const BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 22),
            Text('How this works', style: _serifTitle()),
            const SizedBox(height: 10),
            Text(
              "Tap anything that brings back a moment from today. "
              "It does not need to match your day literally.",
              style: _bodyStyle(size: 14),
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
  });

  final SceneComposition scene;
  final Set<String> selectedIds;
  final ValueChanged<Clue> onSelect;

  @override
  State<_SceneImage> createState() => _SceneImageState();
}

class _SceneImageState extends State<_SceneImage> {
  late Future<SceneTapMap> _tapMap;

  @override
  void initState() {
    super.initState();
    _tapMap = SceneTapMap.load(widget.scene.kind.tapMapAssetPath);
  }

  @override
  void didUpdateWidget(covariant _SceneImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.kind != widget.scene.kind) {
      _tapMap = SceneTapMap.load(widget.scene.kind.tapMapAssetPath);
    }
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
        SafeArea(
          child: _AlignedScroll(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 342),
              padding: const EdgeInsets.fromLTRB(32, 39, 32, 34),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.79),
                borderRadius: BorderRadius.circular(27),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '◉  SEEN',
                    style: _lora(
                      color: const Color(0xff4a4260),
                      fontSize: 14,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 55),
                  Text(
                    'Bringing your day',
                    style: _display(size: 27),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'together.',
                    style: _display(size: 27, color: _purple, italic: true),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 17),
                  Text(
                    "We're using the moments you shared to prepare a "
                    'reflection you can review and shape.',
                    style: _bodyStyle(color: const Color(0xff4a4260), size: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 34),
                  const _AnimatedDots(),
                  const SizedBox(height: 21),
                  Text(
                    'Preparing your reflection…',
                    style: _bodyStyle(color: const Color(0xff5c5570), size: 13),
                  ),
                ],
              ),
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
    final screen = MediaQuery.sizeOf(context);
    final compact = screen.height < 700;
    final horizontal = screen.width < 360 ? 18.0 : 24.0;

    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          const _SystemTop(),
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 0),
            child: Row(
              children: [
                _RoundButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: onBack,
                ),
                const Spacer(),
                Text(
                  'SEEN',
                  style: _lora(fontSize: 15, letterSpacing: 1.5, color: _ink),
                ),
                const Spacer(),
                const SizedBox(width: 36),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              compact ? 8 : 14,
              horizontal,
              compact ? 10 : 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: _serifTitle(size: compact ? 21 : 23, height: 1.22),
                    children: [
                      const TextSpan(text: "Here's what your day "),
                      TextSpan(
                        text: 'seems to hold.',
                        style: _serifTitle(
                          size: compact ? 21 : 23,
                          height: 1.22,
                          color: _purple,
                          italic: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
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
              padding: EdgeInsets.fromLTRB(
                horizontal,
                4,
                horizontal,
                compact ? 14 : 24,
              ),
              child: _SoftCard(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 21),
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
                              fontSize: 16,
                              height: 1.52,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit reflection'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _purple,
                              side: const BorderSide(color: Color(0xffded6e6)),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
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
                horizontal,
                compact ? 9 : 14,
                horizontal,
                (compact ? 10 : 18) + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: const BoxDecoration(
                color: _white,
                border: Border(top: BorderSide(color: Color(0x197b6a9e))),
              ),
              child: Column(
                children: [
                  _PrimaryButton(
                    label: saving ? 'Saving…' : 'Save reflection',
                    onPressed: saving ? null : onSaveReflection,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onBack,
                    child: Text(
                      'Go back to my moments',
                      style: _sans(
                        color: _muted,
                        size: 12,
                        decoration: TextDecoration.underline,
                      ),
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
        Text('MAKE IT SOUND MORE LIKE YOU', style: _kicker(color: _purple)),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          minLines: MediaQuery.sizeOf(context).height < 700 ? 6 : 9,
          maxLines: MediaQuery.sizeOf(context).height < 700 ? 9 : 13,
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
              borderSide: const BorderSide(color: Color(0xffded6e6)),
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
            style: _sans(color: const Color(0xffa89ec4), size: 12),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(label: 'Cancel', onPressed: onCancel),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _PrimaryButton(
                label: 'Save changes',
                onPressed: onSave,
                compact: true,
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
    final screen = MediaQuery.sizeOf(context);
    final compact = screen.height < 720;
    final horizontal = screen.width < 360 ? 18.0 : 24.0;
    final headerHeight = (screen.height * 0.22).clamp(132.0, 184.0);
    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          const _SystemTop(),
          const _BrandBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                4,
                horizontal,
                compact ? 14 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderIllustration(height: headerHeight),
                  SizedBox(height: compact ? 14 : 22),
                  Text(_dateLabel(), style: _kicker()),
                  SizedBox(height: compact ? 8 : 14),
                  Text(
                    "You're done reflecting",
                    style: _display(size: compact ? 24 : 27),
                  ),
                  Text(
                    'for today, $_userName.',
                    style: _display(
                      size: compact ? 24 : 27,
                      color: _purple,
                      italic: true,
                    ),
                  ),
                  SizedBox(height: compact ? 7 : 12),
                  Text(
                    'You took a moment to look back, notice what stood out, '
                    'and put your day into words. Nice work showing up for '
                    'yourself today.',
                    style: _bodyStyle(size: 14),
                  ),
                  SizedBox(height: compact ? 13 : 22),
                  _SoftCard(
                    padding: const EdgeInsets.fromLTRB(20, 21, 20, 17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("TODAY'S REFLECTION", style: _kicker()),
                        const SizedBox(height: 13),
                        Text(
                          reflection,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: _lora(color: _ink, fontSize: 15, height: 1.5),
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
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: onAddThought,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add another thought'),
                      style: TextButton.styleFrom(foregroundColor: _purple),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentSheet extends StatefulWidget {
  const _MomentSheet({required this.clue, required this.initialMeaning});

  final Clue clue;
  final String? initialMeaning;

  @override
  State<_MomentSheet> createState() => _MomentSheetState();
}

class _MomentSheetState extends State<_MomentSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialMeaning ?? '',
  );

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
        10,
        24,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 25),
          Text(widget.clue.title.toUpperCase(), style: _kicker()),
          const SizedBox(height: 10),
          Text(
            'What did this bring to mind from your day?',
            style: _serifTitle(size: 21),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            style: _sans(color: _ink, size: 14),
            decoration: InputDecoration(
              hintText: 'A moment, feeling, person, task, or memory...',
              hintStyle: _sans(color: const Color(0xffaaa3b4), size: 14),
              filled: true,
              fillColor: _surface,
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xffded6e6)),
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
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                  label: 'Save this moment',
                  compact: true,
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
  });

  final String sleep;
  final String steps;
  final String weather;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(19, 19, 16, 18),
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
                backgroundColor: _softPurple,
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
                icon: Icons.schedule_rounded,
                label: 'TIME',
                value: _clockTime(),
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _softPurple,
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
      ),
    );
  }
}

class _HeaderIllustration extends StatelessWidget {
  const _HeaderIllustration({this.height = 192});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Image.asset(
          'assets/cozy_reflection_header.png',
          fit: BoxFit.cover,
        ),
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

class _BottomAlignedScroll extends StatelessWidget {
  const _BottomAlignedScroll({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _AlignedScroll(
      alignment: Alignment.bottomCenter,
      padding: padding,
      child: child,
    );
  }
}

class _AlignedScroll extends StatelessWidget {
  const _AlignedScroll({
    required this.alignment,
    required this.padding,
    required this.child,
  });

  final Alignment alignment;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight.isFinite
            ? math.max(0.0, constraints.maxHeight - padding.vertical)
            : 0.0;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Align(alignment: alignment, child: child),
          ),
        );
      },
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
        Text(label, style: _sans(color: _muted, size: 11)),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
    this.background = _purple,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool compact;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 48 : 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          disabledBackgroundColor: const Color(0xffd4cfe4),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xffa8a0bc),
          elevation: onPressed == null ? 0 : 4,
          shadowColor: _purple.withValues(alpha: 0.32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
          ),
          textStyle: _sans(size: compact ? 13 : 15, weight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

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
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _sans(size: 13, weight: FontWeight.w500),
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
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: light
            ? Colors.white.withValues(alpha: 0.12)
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
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
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
        width: 39,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xffd9d1ed),
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
            if (i < 2) const SizedBox(width: 10),
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
}) {
  return _lora(
    color: color,
    fontSize: size,
    height: 1.12,
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

TextStyle _kicker({Color color = _muted, double size = 11}) {
  return _sans(
    color: color,
    size: size,
    weight: FontWeight.w700,
    letterSpacing: 1.1,
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
