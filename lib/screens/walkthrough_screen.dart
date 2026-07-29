import 'dart:math' as math;
import 'package:flutter/material.dart';

class WalkthroughScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const WalkthroughScreen({super.key, required this.onComplete});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _emojiController;
  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _emojiScaleAnim;

  static const List<_WTPage> _pages = [
    _WTPage(
      gradient: [Color(0xFF2D1B69), Color(0xFF11003E)],
      accentColor: Color(0xFFAB7FF5),
      glowColor: Color(0xFF7C3AED),
      emoji: '👁️',
      tagline: 'Your story,\nyour meaning.',
      subtitle:
          'Seen transforms your daily signals into a visual scene — and asks what those moments actually meant to you.',
      illustration: _IllustrationType.eye,
    ),
    _WTPage(
      gradient: [Color(0xFF0D3D56), Color(0xFF0A1628)],
      accentColor: Color(0xFF38BDF8),
      glowColor: Color(0xFF0284C7),
      emoji: '🌿',
      tagline: 'How do you\nfeel today?',
      subtitle:
          'Seen gathers your sleep, steps, calendar and weather — then builds a personalised scene from your day.',
      illustration: _IllustrationType.mood,
    ),
    _WTPage(
      gradient: [Color(0xFF1A3A2A), Color(0xFF0A1A12)],
      accentColor: Color(0xFF34D399),
      glowColor: Color(0xFF059669),
      emoji: '🎯',
      tagline: 'Find familiar\nmoments.',
      subtitle:
          'Explore a rich hidden-object scene. Select 3 things that felt familiar — then answer one gentle question.',
      illustration: _IllustrationType.scene,
    ),
    _WTPage(
      gradient: [Color(0xFF3B1F4E), Color(0xFF1A0A2E)],
      accentColor: Color(0xFFF472B6),
      glowColor: Color(0xFFDB2777),
      emoji: '✨',
      tagline: 'Your program\nis ready.',
      subtitle:
          'Over time, Seen maps patterns you choose — giving you and your therapist meaningful, honest insights.',
      illustration: _IllustrationType.program,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _pulseAnim =
        Tween<double>(begin: 0.92, end: 1.08).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _floatAnim = Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _emojiScaleAnim =
        Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
      parent: _emojiController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _emojiController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _emojiController.reset();
    _emojiController.forward();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page.gradient,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Skip button ──────────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: GestureDetector(
                    onTap: widget.onComplete,
                    child: AnimatedOpacity(
                      opacity: _currentPage < _pages.length - 1 ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Page view ────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _emojiController.reset();
                    _emojiController.forward();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _PageContent(
                      page: _pages[index],
                      pulseAnim: _pulseAnim,
                      floatAnim: _floatAnim,
                      emojiScaleAnim: _emojiScaleAnim,
                    );
                  },
                ),
              ),

              // ── Dot indicators + CTA ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? page.accentColor
                                : Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // CTA Button
                    GestureDetector(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              page.accentColor,
                              page.glowColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: page.glowColor.withOpacity(0.45),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentPage < _pages.length - 1
                                ? 'Continue'
                                : 'Get Started',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (_currentPage == _pages.length - 1) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _goToPage(0),
                        child: Text(
                          'Review walkthrough',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Page Content Widget
// ─────────────────────────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _WTPage page;
  final Animation<double> pulseAnim;
  final Animation<double> floatAnim;
  final Animation<double> emojiScaleAnim;

  const _PageContent({
    required this.page,
    required this.pulseAnim,
    required this.floatAnim,
    required this.emojiScaleAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // ── Illustration / Emoji ────────────────────────────
          Expanded(
            flex: 5,
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([pulseAnim, floatAnim]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, floatAnim.value),
                    child: Transform.scale(
                      scale: pulseAnim.value,
                      child: child,
                    ),
                  );
                },
                child: _buildIllustration(),
              ),
            ),
          ),

          // ── Text ────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  page.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.18,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.6,
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return ScaleTransition(
      scale: emojiScaleAnim,
      child: SizedBox(
        width: 280,
        height: 280,
        child: CustomPaint(
          painter: _IllustrationPainter(
            type: page.illustration,
            accentColor: page.accentColor,
            glowColor: page.glowColor,
            emoji: page.emoji,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Custom Painter
// ─────────────────────────────────────────────────────────────────────────────

enum _IllustrationType { eye, mood, scene, program }

class _IllustrationPainter extends CustomPainter {
  final _IllustrationType type;
  final Color accentColor;
  final Color glowColor;
  final String emoji;

  const _IllustrationPainter({
    required this.type,
    required this.accentColor,
    required this.glowColor,
    required this.emoji,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ── Ambient glow ─────────────────────────────────────────
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withOpacity(0.35),
          glowColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    // ── Concentric rings ─────────────────────────────────────
    final ringPaint = Paint()
      ..color = accentColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * 0.28 * i, ringPaint);
    }

    // ── Type-specific extras ──────────────────────────────────
    switch (type) {
      case _IllustrationType.mood:
        _drawMoodRings(canvas, center, radius);
        break;
      case _IllustrationType.scene:
        _drawSceneDots(canvas, center, radius);
        break;
      case _IllustrationType.program:
        _drawProgramCards(canvas, center, radius);
        break;
      default:
        break;
    }

    // ── Central emoji ─────────────────────────────────────────
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 80)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
        canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawMoodRings(Canvas canvas, Offset center, double radius) {
    // draw 5 mood emoji dots in arc
    final emojis = ['😔', '😢', '😐', '🙂', '😊'];
    for (int i = 0; i < emojis.length; i++) {
      final angle = math.pi + (i / (emojis.length - 1)) * math.pi;
      final x = center.dx + radius * 0.78 * math.cos(angle);
      final y = center.dy + radius * 0.78 * math.sin(angle);

      // Highlight active (last)
      if (i == emojis.length - 1) {
        final highlightPaint = Paint()
          ..color = accentColor.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(x, y), 20, highlightPaint);
      }

      final tp = TextPainter(
        text: TextSpan(
            text: emojis[i],
            style: TextStyle(fontSize: i == emojis.length - 1 ? 28 : 20)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  void _drawSceneDots(Canvas canvas, Offset center, double radius) {
    final rng = math.Random(42);
    final dotPaint = Paint()..color = accentColor.withOpacity(0.3);
    for (int i = 0; i < 20; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final r = radius * (0.5 + rng.nextDouble() * 0.45);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3 + rng.nextDouble() * 4, dotPaint);
    }
  }

  void _drawProgramCards(Canvas canvas, Offset center, double radius) {
    final cardPaint = Paint()
      ..color = accentColor.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = accentColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final offsets = [
      Offset(center.dx - 60, center.dy - 100),
      Offset(center.dx + 20, center.dy - 80),
      Offset(center.dx - 80, center.dy + 10),
    ];
    final sizes = [
      const Size(80, 48),
      const Size(70, 42),
      const Size(60, 36),
    ];

    for (int i = 0; i < offsets.length; i++) {
      final rect =
          RRect.fromRectAndRadius(offsets[i] & sizes[i], const Radius.circular(10));
      canvas.drawRRect(rect, cardPaint);
      canvas.drawRRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.accentColor != accentColor;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Page Data Model
// ─────────────────────────────────────────────────────────────────────────────

class _WTPage {
  final List<Color> gradient;
  final Color accentColor;
  final Color glowColor;
  final String emoji;
  final String tagline;
  final String subtitle;
  final _IllustrationType illustration;

  const _WTPage({
    required this.gradient,
    required this.accentColor,
    required this.glowColor,
    required this.emoji,
    required this.tagline,
    required this.subtitle,
    required this.illustration,
  });
}
