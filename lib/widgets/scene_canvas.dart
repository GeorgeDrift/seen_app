import 'package:flutter/material.dart';
import '../models.dart';
import '../app_state.dart';
import '../theme.dart';

class SceneCanvas extends StatefulWidget {
  final AppState appState;
  final Function(Clue) onClueTapped;

  const SceneCanvas({
    super.key,
    required this.appState,
    required this.onClueTapped,
  });

  @override
  State<SceneCanvas> createState() => _SceneCanvasState();
}

class _SceneCanvasState extends State<SceneCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

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
    final ctx = widget.appState.currentContext;
    final composition = widget.appState.sceneComposition;
    final visibleClues = widget.appState.visibleClues;
    final selections = widget.appState.todaySelections;
    final selectedIds = selections.map((s) => s.clueId).toSet();
    final hintLevel = widget.appState.hintLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target Header Banner
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

            // Hint Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: hintLevel > 0 ? AppColors.amber : Colors.white.withOpacity(0.2),
                  width: hintLevel > 0 ? 1.5 : 1.0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                widget.appState.triggerHint();
              },
              icon: Icon(
                Icons.lightbulb,
                size: 14,
                color: hintLevel > 0 ? AppColors.amber : AppColors.textSecondary,
              ),
              label: Text(
                hintLevel == 0
                    ? 'Hint'
                    : (hintLevel == 1 ? 'Hint: Region Highlight' : 'Hint: Outline Clues'),
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

        // Composition Info Bar
        if (composition != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scene Items: ${visibleClues.length} total (${composition.signalInformedCount} signal-informed, ${composition.possibleExplanationCount} explanations, ${composition.helpfulCount} restorative, ${composition.distractorCount} distractors)',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
                Text(
                  'Selections: ${selections.length}/3',
                  style: const TextStyle(fontSize: 10, color: AppColors.sage, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Interactive Vector Canvas
        AspectRatio(
          aspectRatio: 1.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Vector Room Background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: RoomBackgroundPainter(
                        weather: ctx.weather,
                        sleepHours: ctx.sleepHours ?? 7.0,
                        calendarLoad: ctx.calendarLoad,
                      ),
                    ),
                  ),

                  // Hint Level 1: Region Highlight Pulse
                  if (hintLevel == 1)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: RegionHintPainter(visibleClues: visibleClues, selectedIds: selectedIds),
                        ),
                      ),
                    ),

                  // Canvas Hotspots Stack
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: visibleClues.map((clue) {
                            final isSelected = selectedIds.contains(clue.id);
                            final posX = clue.x * constraints.maxWidth;
                            final posY = clue.y * constraints.maxHeight;

                            return Positioned(
                              left: posX - 24,
                              top: posY - 24,
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final double pulseVal = _pulseController.value;
                                  final Color clueColor = _getClueColor(clue.category, isSelected);

                                  return GestureDetector(
                                    onTap: () => widget.onClueTapped(clue),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Level 2 Hint Outline Glow
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

                                          // Standard Hotspot Base
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? AppColors.primary.withOpacity(0.2)
                                                  : AppColors.backgroundStart.withOpacity(0.7),
                                              border: Border.all(
                                                color: isSelected ? AppColors.primary : clueColor.withOpacity(0.6),
                                                width: isSelected ? 2.0 : 1.0,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isSelected
                                                      ? AppColors.primary.withOpacity(0.4)
                                                      : clueColor.withOpacity(0.25),
                                                  blurRadius: 6 + (pulseVal * 3),
                                                )
                                              ],
                                            ),
                                            child: Icon(
                                              isSelected ? Icons.check : clue.icon,
                                              color: isSelected ? AppColors.primary : clueColor,
                                              size: 16,
                                            ),
                                          ),

                                          // Label Badge
                                          Positioned(
                                            top: 38,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.8),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                clue.title,
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? AppColors.primary : Colors.white,
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

                  // Bottom Neutral Fallback Button (Req 16)
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Neutral state recorded: 'Nothing here matched my day'"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.remove_circle_outline, size: 12, color: AppColors.textSecondary),
                      label: const Text(
                        "Nothing here matched my day",
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
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

// Vector Room Background Painter
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

    // Room Gradient Shader
    final Gradient bgGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: weather == 'rain' || weather == 'snow'
          ? [const Color(0xFF0F172A), const Color(0xFF0B101D)]
          : (weather == 'sunny'
              ? [const Color(0xFF1E1E38), const Color(0xFF0F172A)]
              : [const Color(0xFF181B34), const Color(0xFF0F172A)]),
    );

    canvas.drawRect(rect, Paint()..shader = bgGrad.createShader(rect));

    // Window Vector
    final Path window = Path()
      ..moveTo(size.width * 0.72, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.50)
      ..lineTo(size.width * 0.65, size.height * 0.42)
      ..close();

    final Paint windowPaint = Paint()
      ..color = weather == 'sunny'
          ? AppColors.amber.withOpacity(0.08)
          : Colors.white.withOpacity(0.04);
    canvas.drawPath(window, windowPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(window, borderPaint);

    // Desk Surface Vector
    final Path desk = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width, size.height * 0.45)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final Paint deskPaint = Paint()
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

// Region Hint Painter (Level 1)
class RegionHintPainter extends CustomPainter {
  final List<Clue> visibleClues;
  final Set<String> selectedIds;

  RegionHintPainter({required this.visibleClues, required this.selectedIds});

  @override
  void paint(Canvas canvas, Size size) {
    final unselected = visibleClues.where((c) => !selectedIds.contains(c.id)).toList();
    if (unselected.isEmpty) return;

    final Paint hintPaint = Paint()
      ..color = AppColors.amber.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    for (var clue in unselected.take(2)) {
      final center = Offset(clue.x * size.width, clue.y * size.height);
      canvas.drawCircle(center, 40, hintPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RegionHintPainter oldDelegate) => true;
}
