import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Complete, self-contained Flutter implementation of the ultra-luxury
/// "Style Sync — Design Marketplace" Opening Splash Screen in Dark Salon Theme.
///
/// Features:
/// - Smoked obsidian & espresso noir atmospheric background with soft warm halo
/// - Constellation of slow upward-floating gold particles with horizontal sway
/// - Bespoke two-tone dual "S" monogram (Dark Espresso Roman S + Luminous Ivory Script S)
/// - Real-time calligraphic handwriting path reveal animation (60/120 FPS CustomPainter)
/// - 24k liquid-gold jewel cabochon terminals and crest starlet glint
/// - Stately editorial typography ("STYLE SYNC" + "DESIGN MARKETPLACE")
/// - 3px thickened gold hairline progress bar
/// - "ENTER →" pill action button and replay sequence trigger
class SplashScreen extends StatefulWidget {
  final VoidCallback? onEnter;
  final VoidCallback? onSkip;

  const SplashScreen({
    super.key,
    this.onEnter,
    this.onSkip,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Choreography Animation Controllers
  late AnimationController _handwritingController;
  late AnimationController _fadeContentController;
  late AnimationController _progressController;
  late AnimationController _particleController;

  late Animation<double> _handwritingProgress;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _progressAnimation;

  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    // 1. Continuous particle floating controller (18s slow loop)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // 2. Calligraphic handwriting reveal (1.8 seconds)
    _handwritingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _handwritingProgress = CurvedAnimation(
      parent: _handwritingController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );

    // 3. Staged typography & divider fade-in
    _fadeContentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textFadeAnimation = CurvedAnimation(
      parent: _fadeContentController,
      curve: Curves.easeOut,
    );

    // 4. Hairline loading progress bar (2.4 seconds)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isCompleted = true;
          });
        }
      });

    _startChoreography();
  }

  void _startChoreography() async {
    // Stage 1: Calligraphic logo writes in total stillness
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _handwritingController.forward();

    // Stage 2: Typography "STYLE SYNC" and subtitle fade in
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    _fadeContentController.forward();

    // Stage 3: Golden progress bar begins filling
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _progressController.forward();
  }

  void _replaySequence() {
    setState(() {
      _isCompleted = false;
    });
    _handwritingController.reset();
    _fadeContentController.reset();
    _progressController.reset();
    _startChoreography();
  }

  @override
  void dispose() {
    _handwritingController.dispose();
    _fadeContentController.dispose();
    _progressController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE7DC),
      body: Stack(
        children: [
          // 1. Warm Champagne & Sand Atmospheric Background (#EFE7DC -> #E4D8C7 -> #D5C6B1)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEFE7DC), // Top
                    Color(0xFFE4D8C7), // Middle
                    Color(0xFFD5C6B1), // Bottom
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 2. Flowing Golden Silk Texture (Soft luminous luxury blend)
          Positioned.fill(
            child: Opacity(
              opacity: 0.40,
              child: Image.asset(
                'assets/images/splash_silk_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 3. Soft Gradient Vignette & Blending Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFEFE7DC).withValues(alpha: 0.70),
                    Colors.transparent,
                    const Color(0xFFD5C6B1).withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),

          // 4. Slow Upward Floating Gold Particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: GoldParticlesPainter(_particleController.value),
                );
              },
            ),
          ),

          // 5. Central Ambient Backlight Aura for the Monogram
          Align(
            alignment: const Alignment(0, -0.22),
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFF9EE).withValues(alpha: 0.7),
                    const Color(0xFFE8C47F).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.8],
                ),
              ),
            ),
          ),

          // 4. Main Foreground Content Area
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                const Spacer(flex: 3),

                // Center Stage: Two-Tone Monogram Logo with Handwriting Animation
                AnimatedBuilder(
                  animation: _handwritingProgress,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(146, 146),
                      painter: MonogramHandwritingPainter(
                        progress: _handwritingProgress.value,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 36),

                // Editorial Brand Typography: "STYLE SYNC" & "YOUR STYLE, PERFECTLY IN SYNC"
                AnimatedBuilder(
                  animation: _textFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Text(
                              'STYLE SYNC',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 29,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 10.0,
                                height: 1.1,
                                color: const Color(0xFF241710),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Hairline Accent Divider
                          Container(
                            width: 36,
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF8C6E4E).withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 13),

                          // Italicized Subtitle: "YOUR STYLE, PERFECTLY IN SYNC"
                          Padding(
                            padding: const EdgeInsets.only(left: 2.2),
                            child: Text(
                              'YOUR STYLE, PERFECTLY IN SYNC',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 12.0,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.2,
                                color: const Color(0xFF6F5943).withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Spacer(flex: 4),

                // Bottom Section: Hairline Progress Bar & Enter Action
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      // Thickened (3px) Golden Progress Bar
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 210,
                            height: 3.0,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1F17).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 210 * _progressAnimation.value,
                                height: 3.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2.0),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8A6E4B),
                                      Color(0xFFE2C48B),
                                      Color(0xFFFFFFFF),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFECC47F).withValues(alpha: 0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // "GET STARTED →" Dark Acrylic Pill Button
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: _isCompleted ? 1.0 : 0.0,
                        child: GestureDetector(
                          onTap: _isCompleted ? widget.onEnter : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1F17),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'GET STARTED',
                                  style: TextStyle(
                                    fontFamily: 'Arial',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.0,
                                    color: Color(0xFFFAF7F2),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Color(0xFFFAF7F2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Minimal Replay Icon
                      IconButton(
                        onPressed: _replaySequence,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: Color(0xFF6F5E4C),
                        ),
                        splashRadius: 20,
                        tooltip: 'Replay Sequence',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter that renders the Two-Tone Monogram with smooth Calligraphic
/// handwriting reveal that stays permanently solid and fully visible on screen.
class MonogramHandwritingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  MonogramHandwritingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Normalized scale from 160x160 design viewport
    final double scale = size.width / 160.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Dark Roman Serif S
    final Paint darkRomanPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF382C21),
          Color(0xFF1E140C),
          Color(0xFF120B06),
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 160, 160))
      ..style = PaintingStyle.fill;

    // 2. Light Ivory Script S Swash
    final Paint lightScriptPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF7EFE4),
          Color(0xFFDECDB8),
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 160, 160))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 3. Script Stroke Outline Shadow (prevents washing out against light backgrounds)
    final Paint scriptShadowPaint = Paint()
      ..color = const Color(0x3D2A1F17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // 4. Liquid 24k Gold Accents
    final Paint goldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF0C4),
          Color(0xFFE5C17D),
          Color(0xFFC89758),
          Color(0xFF8C6220),
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 160, 160));

    // Reveal progression: Roman S draws 0.0 -> 0.7, Script S draws 0.2 -> 1.0
    final double p = progress.clamp(0.0, 1.0);
    final double romanProgress = (p / 0.7).clamp(0.0, 1.0);
    final double scriptProgress = ((p - 0.2) / 0.8).clamp(0.0, 1.0);

    // --- A. Draw Light Script S Background Loop ---
    if (scriptProgress > 0.0) {
      final Path pathBack = Path()
        ..moveTo(98, 32)
        ..cubicTo(118, 20, 134, 32, 130, 52)
        ..cubicTo(126, 70, 94, 92, 78, 108)
        ..cubicTo(64, 122, 54, 138, 70, 144)
        ..cubicTo(84, 148, 102, 138, 114, 124);

      final backMetric = pathBack.computeMetrics().first;
      final extractBack = backMetric.extractPath(0.0, backMetric.length * scriptProgress);

      canvas.drawPath(extractBack, scriptShadowPaint);
      canvas.drawPath(extractBack, lightScriptPaint);

      // Gold terminal bulb on script flourish
      if (scriptProgress > 0.85) {
        canvas.drawCircle(const Offset(114, 124), 2.4, goldPaint);
      }
    }

    // --- B. Draw Dark Roman Serif S (Permanent Spine) ---
    if (romanProgress > 0.0) {
      final Path darkSpine = Path()
        ..moveTo(76, 34)
        ..cubicTo(76, 30.5, 78, 28, 83, 27.5)
        ..cubicTo(76, 24, 63, 22, 52, 27)
        ..cubicTo(40, 32, 34, 43, 37, 54)
        ..cubicTo(40, 65, 51, 72, 64, 78)
        ..cubicTo(82, 85, 96, 93, 94, 109)
        ..cubicTo(92, 122, 80, 134, 62, 135)
        ..cubicTo(48, 136, 36, 130, 30, 123)
        ..cubicTo(30, 128, 28, 131, 23, 132)
        ..cubicTo(29, 137, 43, 141, 58, 139)
        ..cubicTo(75, 137, 98, 127, 97, 104)
        ..cubicTo(96, 88, 83, 80, 68, 73)
        ..cubicTo(51, 66, 40, 59, 41, 46)
        ..cubicTo(42, 35, 52, 26, 68, 28)
        ..cubicTo(72, 29, 75, 31, 76, 34)
        ..close();

      canvas.save();
      if (romanProgress < 1.0) {
        final clipPath = Path();
        clipPath.addRect(Rect.fromLTWH(0, 0, 160, 160 * romanProgress));
        canvas.clipPath(clipPath);
      }

      canvas.drawPath(darkSpine, darkRomanPaint);

      // Gold cabochon and teardrop finials
      canvas.drawCircle(const Offset(82, 28), 1.6, goldPaint);
      canvas.drawCircle(const Offset(28, 126), 2.2, goldPaint);
      canvas.restore();
    }

    // --- C. Draw Light Script S Foreground Ligature Crossing ---
    if (scriptProgress > 0.2) {
      final Path pathFore = Path()
        ..moveTo(68, 36)
        ..cubicTo(86, 28, 108, 34, 116, 48)
        ..cubicTo(125, 64, 108, 84, 88, 100)
        ..cubicTo(68, 116, 52, 130, 58, 140)
        ..cubicTo(62, 146, 76, 148, 92, 138);

      final foreMetric = pathFore.computeMetrics().first;
      final extractFore = foreMetric.extractPath(0.0, foreMetric.length * scriptProgress);

      canvas.drawPath(extractFore, scriptShadowPaint);
      canvas.drawPath(extractFore, lightScriptPaint);

      // Micro Starlet Gold Glint at crest
      if (scriptProgress > 0.55) {
        _drawStarlet(canvas, const Offset(116, 48), 4.4, goldPaint);
      }
    }

    canvas.restore();
  }

  void _drawStarlet(Canvas canvas, Offset center, double radius, Paint paint) {
    final Path star = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(star, paint);
  }

  @override
  bool shouldRepaint(covariant MonogramHandwritingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Particle model for slow, unhurried upward drifting gold dust
class GoldParticlesPainter extends CustomPainter {
  final double animationValue;

  static const List<_DustMote> _motes = [
    _DustMote(x: 0.08, speed: 0.85, size: 2.2, swayWidth: 10, seed: 1.2),
    _DustMote(x: 0.16, speed: 0.70, size: 3.2, swayWidth: 14, seed: 3.5),
    _DustMote(x: 0.24, speed: 0.95, size: 1.8, swayWidth: 8, seed: 0.7),
    _DustMote(x: 0.32, speed: 0.65, size: 2.8, swayWidth: 12, seed: 2.1),
    _DustMote(x: 0.40, speed: 1.05, size: 1.6, swayWidth: 6, seed: 4.8),
    _DustMote(x: 0.48, speed: 0.60, size: 3.4, swayWidth: 16, seed: 1.9),
    _DustMote(x: 0.55, speed: 0.88, size: 2.0, swayWidth: 9, seed: 5.3),
    _DustMote(x: 0.63, speed: 0.75, size: 2.6, swayWidth: 11, seed: 2.7),
    _DustMote(x: 0.72, speed: 1.10, size: 1.7, swayWidth: 7, seed: 3.9),
    _DustMote(x: 0.80, speed: 0.68, size: 3.0, swayWidth: 15, seed: 0.4),
    _DustMote(x: 0.88, speed: 0.82, size: 2.2, swayWidth: 10, seed: 4.1),
    _DustMote(x: 0.94, speed: 0.92, size: 1.9, swayWidth: 8, seed: 2.5),
  ];

  GoldParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final mote in _motes) {
      // Calculate continuous vertical position from 1.05 to -0.05
      final double progress = (animationValue * mote.speed + mote.seed) % 1.0;
      final double y = size.height * (1.05 - progress * 1.1);

      // Horizontal sinusoidal sway
      final double sway = math.sin((progress * 2 * math.pi) + mote.seed) * mote.swayWidth;
      final double x = size.width * mote.x + sway;

      // Opacity envelope: Fades in at bottom, glows in center, fades near top
      double opacity = 0.85;
      if (progress < 0.15) {
        opacity = progress / 0.15 * 0.85;
      } else if (progress > 0.85) {
        opacity = (1.0 - progress) / 0.15 * 0.85;
      }

      final Paint paint = Paint()
        ..color = const Color(0xFFECC47F).withValues(alpha: opacity.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

      canvas.drawCircle(Offset(x, y), mote.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GoldParticlesPainter oldDelegate) => true;
}

class _DustMote {
  final double x;
  final double speed;
  final double size;
  final double swayWidth;
  final double seed;

  const _DustMote({
    required this.x,
    required this.speed,
    required this.size,
    required this.swayWidth,
    required this.seed,
  });
}