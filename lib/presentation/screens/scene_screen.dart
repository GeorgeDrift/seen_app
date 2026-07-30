import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/clue.dart';
import '../controllers/app_navigation_controller.dart';
import '../controllers/day_flow_controller.dart';
import '../controllers/summary_controller.dart';
import '../widgets/question_sheet.dart';

/// Screen 2 — hidden-object canvas with an intro splash.
/// First shows the "Your scene is ready" landing screen, then transitions
/// into the interactive hidden-object canvas on "Enter the scene".
class SceneScreen extends ConsumerStatefulWidget {
  const SceneScreen({super.key});

  @override
  ConsumerState<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends ConsumerState<SceneScreen> {
  bool _sceneEntered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _sceneEntered
          ? _SceneCanvasScreen(
              key: const ValueKey('canvas'),
              onBack: () => setState(() => _sceneEntered = false),
            )
          : _SceneIntro(
              key: const ValueKey('intro'),
              onBack: () => ref
                  .read(patientStepProvider.notifier)
                  .go(PatientStep.contextPreview),
              onEnter: () => setState(() => _sceneEntered = true),
            ),
    );
  }
}

// ── Intro Screen ─────────────────────────────────────────────────────────────

class _SceneIntro extends StatelessWidget {
  const _SceneIntro({super.key, required this.onBack, required this.onEnter});

  final VoidCallback onBack;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // ── Abstract blob artwork fills top half ─────────────────────────
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _SceneBlobPainter()),

                // Header bar: back button + SEEN
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: onBack,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'SEEN',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Overlay text at bottom of image area
                Positioned(
                  bottom: 28,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR SCENE IS READY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: Color(0xFFD4CAE8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: "Let's take a ",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: -0.4,
                              ),
                            ),
                            TextSpan(
                              text: 'closer look.',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFFC4B5FD),
                                height: 1.2,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'We created a scene for you to explore. Take a look around and notice what brings a moment from your day back to mind.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFFB8AECF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom panel ─────────────────────────────────────────────────
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              children: [
                // "How this works" dark card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.add,
                              size: 15, color: Color(0xFFC4B5FD)),
                          SizedBox(width: 8),
                          Text(
                            'How this works',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Tap anything that brings back a moment from today. An object doesn't have to match your day exactly — it can remind you of something completely different.",
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFFB8AECF),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13102A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FOR EXAMPLE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: Color(0xFF8E8899),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'A cup might remind you of a quiet break, a conversation, or forgetting to eat.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Color(0xFFD4CAE8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F6A9D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: onEnter,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text(
                      'Enter the scene',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
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

// ── Interactive Scene Canvas Screen ──────────────────────────────────────────

class _SceneCanvasScreen extends ConsumerStatefulWidget {
  const _SceneCanvasScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  ConsumerState<_SceneCanvasScreen> createState() =>
      _SceneCanvasScreenState();
}

class _SceneCanvasScreenState extends ConsumerState<_SceneCanvasScreen>
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
    final visibleClues = flow.scene.visibleClues;
    final selectedIds = flow.selections.map((s) => s.clueId).toSet();
    final selectionCount = flow.selections.length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Bar ────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                // Moments found pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F6A9D).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            const Color(0xFF7F6A9D).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 13, color: Color(0xFFC4B5FD)),
                      const SizedBox(width: 6),
                      Text(
                        '$selectionCount moment${selectionCount == 1 ? '' : 's'} found',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC4B5FD),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Hint / info button
                GestureDetector(
                  onTap: flowNotifier.cycleHint,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Title + Subtitle ───────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What brings a part of your day back to mind?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Look around and tap anything that feels familiar, meaningful, or worth remembering.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Scene Image with Clue Spots ───────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Bedroom background image
                        Image.asset(
                          'assets/cozy_bedroom_scene.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            color: const Color(0xFF1A1230),
                            child: const Center(
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.white38, size: 48),
                            ),
                          ),
                        ),

                        // Clue tap spots overlaid on the image
                        ...visibleClues.map((clue) {
                          final isSelected = selectedIds.contains(clue.id);
                          final posX = clue.x * constraints.maxWidth;
                          final posY = clue.y * constraints.maxHeight;

                          return Positioned(
                            left: posX - 22,
                            top: posY - 22,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return GestureDetector(
                                  onTap: () =>
                                      _openQuestionSheet(context, clue),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Pulse ring for unselected
                                      if (!isSelected)
                                        Container(
                                          width: 44 +
                                              (_pulseController.value * 6),
                                          height: 44 +
                                              (_pulseController.value * 6),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF7F6A9D)
                                                .withValues(
                                                    alpha: 0.15 *
                                                        (1 -
                                                            _pulseController
                                                                .value)),
                                          ),
                                        ),
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? const Color(0xFF7F6A9D)
                                              : const Color(0xFF7F6A9D)
                                                  .withValues(alpha: 0.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF7F6A9D)
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_rounded
                                              : clue.icon,
                                          color: Colors.white,
                                          size: isSelected ? 18 : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Bottom Bar ─────────────────────────────────────────────────
          Container(
            color: const Color(0xFFF9F7FE),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                const Text(
                  'You can continue or keep exploring.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8899),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F6A9D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      await ref
                          .read(dailySummaryControllerProvider.notifier)
                          .commit();
                      ref
                          .read(patientStepProvider.notifier)
                          .go(PatientStep.dailySummary);
                    },
                    child: const Text(
                      'Review my moments',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
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

  void _openQuestionSheet(BuildContext context, Clue clue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ClueQuestionSheet(clue: clue),
    );
  }
}

// ── Abstract Blob Background Painter (intro screen) ───────────────────────────

class _SceneBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B1F4A), Color(0xFF1A1230)],
        ).createShader(rect),
    );

    canvas.drawCircle(
      Offset(size.width * 0.0, size.height * 0.15),
      size.width * 0.5,
      Paint()..color = const Color(0xFF4A3870).withValues(alpha: 0.75),
    );

    canvas.drawCircle(
      Offset(size.width * 1.05, size.height * 0.05),
      size.width * 0.45,
      Paint()..color = const Color(0xFF3D2E60).withValues(alpha: 0.80),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.65),
        width: size.width * 0.75,
        height: size.height * 0.55,
      ),
      Paint()..color = const Color(0xFF1A1230).withValues(alpha: 0.60),
    );

    final glowCenter = Offset(size.width * 0.5, size.height * 0.5);
    for (final (radius, alpha) in [
      (size.width * 0.20, 0.06),
      (size.width * 0.15, 0.10),
      (size.width * 0.10, 0.18),
    ]) {
      canvas.drawCircle(
        glowCenter,
        radius,
        Paint()
          ..color = const Color(0xFFF5E6C8).withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    canvas.drawCircle(
      glowCenter,
      size.width * 0.085,
      Paint()..color = const Color(0xFFF2DDB0),
    );

    final curvePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    final curvePath = Path()
      ..moveTo(size.width * 0.55, 0)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.22,
        size.width * 0.38,
        size.height * 0.42,
        size.width * 0.60,
        size.height * 0.80,
      )
      ..lineTo(size.width * 0.72, size.height * 0.82)
      ..cubicTo(
        size.width * 0.56,
        size.height * 0.44,
        size.width * 0.82,
        size.height * 0.20,
        size.width * 0.72,
        0,
      )
      ..close();
    canvas.drawPath(curvePath, curvePaint);

    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    for (final (x, y) in [
      (0.30, 0.18),
      (0.70, 0.28),
      (0.15, 0.38),
      (0.82, 0.15),
      (0.50, 0.08),
    ]) {
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        1.5,
        sparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
