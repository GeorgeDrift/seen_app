import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/clue.dart';
import '../controllers/day_flow_controller.dart';

/// The hidden-object canvas. Reads the current scene composition and
/// selections from [dayFlowControllerProvider] and calls back into the
/// controller on tap.
///
/// Purely presentational: no engine calls, no HTTP, no local state beyond
/// the pulse animation. UI-only changes (colors, icon sizes, layout) touch
/// this file only.
class SceneCanvas extends ConsumerStatefulWidget {
  final void Function(Clue clue) onClueTapped;

  const SceneCanvas({super.key, required this.onClueTapped});

  @override
  ConsumerState<SceneCanvas> createState() => _SceneCanvasState();
}

class _SceneCanvasState extends ConsumerState<SceneCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(dayFlowControllerProvider);
    final flowNotifier = ref.read(dayFlowControllerProvider.notifier);

    final ctx = flow.context;
    final scene = flow.scene;
    final visibleClues = scene.visibleClues;
    final selectedIds = flow.selections.map((s) => s.clueId).toSet();
    final hintLevel = flow.hintLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.search, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'SCREEN 2: HIDDEN-OBJECT SCENE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Find three things that felt familiar today.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: hintLevel > 0
                      ? AppColors.amber
                      : Colors.white.withValues(alpha: 0.2),
                  width: hintLevel > 0 ? 1.5 : 1.0,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: flowNotifier.cycleHint,
              icon: Icon(
                Icons.lightbulb,
                size: 14,
                color: hintLevel > 0
                    ? AppColors.amber
                    : AppColors.textSecondary,
              ),
              label: Text(
                hintLevel == 0
                    ? 'Hint'
                    : (hintLevel == 1
                        ? 'Hint: Region Highlight'
                        : 'Hint: Outline Clues'),
                style: TextStyle(
                  fontSize: 11,
                  color: hintLevel > 0 ? AppColors.amber : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scene Items: ${visibleClues.length} total (${scene.signalInformedCount} signal-informed, ${scene.possibleExplanationCount} explanations, ${scene.helpfulCount} restorative, ${scene.distractorCount} distractors)',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
              Text(
                'Selections: ${flow.selections.length}/$kMaxSelectionsPerDay',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.sage,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: RoomBackgroundPainter(
                        weather: ctx.weather,
                        sleepHours: ctx.sleepHours ?? 7.0,
                        calendarLoad: ctx.calendarLoad,
                      ),
                    ),
                  ),
                  if (hintLevel == 1)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: RegionHintPainter(
                            visibleClues: visibleClues,
                            selectedIds: selectedIds,
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: visibleClues.map((clue) {
                            final isSelected =
                                selectedIds.contains(clue.id);
                            final posX = clue.x * constraints.maxWidth;
                            final posY = clue.y * constraints.maxHeight;

                            return Positioned(
                              left: posX - 24,
                              top: posY - 24,
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final pulseVal = _pulseController.value;
                                  final clueColor =
                                      _getClueColor(clue.category, isSelected);
                                  return GestureDetector(
                                    onTap: () =>
                                        widget.onClueTapped(clue),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (hintLevel == 2 && !isSelected)
                                            Container(
                                              width: 40 + (pulseVal * 8),
                                              height: 40 + (pulseVal * 8),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColors.amber,
                                                  width: 2.0,
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: AppColors.amber,
                                                    blurRadius: 10,
                                                  )
                                                ],
                                              ),
                                            ),
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? AppColors.primary
                                                      .withValues(alpha: 0.2)
                                                  : AppColors.backgroundStart
                                                      .withValues(alpha: 0.7),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : clueColor.withValues(
                                                        alpha: 0.6),
                                                width: isSelected ? 2.0 : 1.0,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                          .withValues(alpha: 0.4)
                                                      : clueColor.withValues(
                                                          alpha: 0.25),
                                                  blurRadius: 6 + (pulseVal * 3),
                                                )
                                              ],
                                            ),
                                            child: Icon(
                                              isSelected
                                                  ? Icons.check
                                                  : clue.icon,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : clueColor,
                                              size: 16,
                                            ),
                                          ),
                                          Positioned(
                                            top: 38,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.8),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                clue.title,
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Neutral state recorded: 'Nothing here matched my day'"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.remove_circle_outline,
                          size: 12, color: AppColors.textSecondary),
                      label: const Text(
                        'Nothing here matched my day',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getClueColor(String category, bool isSelected) {
    if (isSelected) return AppColors.primary;
    switch (category) {
      case 'sleep':
        return AppColors.sleep;
      case 'movement':
        return AppColors.steps;
      case 'workload':
        return AppColors.calendar;
      case 'environment':
        return AppColors.weatherRain;
      case 'recovery':
        return AppColors.sage;
      default:
        return AppColors.lavender;
    }
  }
}

/// Vector room background — depth via a subtle window + desk silhouette.
/// Tint shifts based on weather.
class RoomBackgroundPainter extends CustomPainter {
  final String weather;
  final double sleepHours;
  final String calendarLoad;

  RoomBackgroundPainter({
    required this.weather,
    required this.sleepHours,
    required this.calendarLoad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bgGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: weather == 'rain' || weather == 'snow'
          ? [const Color(0xFF0F172A), const Color(0xFF0B101D)]
          : (weather == 'sunny'
              ? [const Color(0xFF1E1E38), const Color(0xFF0F172A)]
              : [const Color(0xFF181B34), const Color(0xFF0F172A)]),
    );

    canvas.drawRect(rect, Paint()..shader = bgGrad.createShader(rect));

    final window = Path()
      ..moveTo(size.width * 0.72, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.50)
      ..lineTo(size.width * 0.65, size.height * 0.42)
      ..close();

    final windowPaint = Paint()
      ..color = weather == 'sunny'
          ? AppColors.amber.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.04);
    canvas.drawPath(window, windowPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(window, borderPaint);

    final desk = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width, size.height * 0.45)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final deskPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawPath(desk, deskPaint);
  }

  @override
  bool shouldRepaint(covariant RoomBackgroundPainter oldDelegate) => false;
}

/// Level-1 hint: soft amber halo around unselected clues.
class RegionHintPainter extends CustomPainter {
  final List<Clue> visibleClues;
  final Set<String> selectedIds;

  RegionHintPainter({required this.visibleClues, required this.selectedIds});

  @override
  void paint(Canvas canvas, Size size) {
    final unselected =
        visibleClues.where((c) => !selectedIds.contains(c.id)).toList();
    if (unselected.isEmpty) return;

    final hintPaint = Paint()
      ..color = AppColors.amber.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    for (final clue in unselected.take(2)) {
      final center = Offset(clue.x * size.width, clue.y * size.height);
      canvas.drawCircle(center, 40, hintPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RegionHintPainter oldDelegate) => true;
}
