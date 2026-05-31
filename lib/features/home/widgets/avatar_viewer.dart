import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/models/user_profile.dart';
import '../../../core/theme/app_colors.dart';

class AvatarViewer extends StatefulWidget {
  final AvatarType avatarType;
  final int skinToneIndex;
  final int hairColorIndex;

  const AvatarViewer({
    super.key,
    required this.avatarType,
    this.skinToneIndex = 1,
    this.hairColorIndex = 1,
  });

  @override
  State<AvatarViewer> createState() => _AvatarViewerState();
}

class _AvatarViewerState extends State<AvatarViewer>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _glowController;
  late final AnimationController _entryController;
  late final AnimationController _floatController;

  double _yAngle = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _spinController.addListener(() {
      if (!_isDragging) {
        setState(() => _yAngle = _spinController.value * 2 * pi);
      }
    });

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _glowController.dispose();
    _entryController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _resumeAutoSpin() {
    final normalised = (_yAngle / (2 * pi)).abs() % 1.0;
    _spinController.value = normalised;
    _spinController.repeat();
  }

  static Matrix4 _perspective(double yAngle) => Matrix4.identity()
    ..setEntry(3, 2, 0.0016)
    ..rotateY(yAngle);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _spinController,
        _glowController,
        _floatController,
      ]),
      builder: (context, _) {
        final floatOffset = _floatController.value * 7.0 - 3.5;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) {
            _isDragging = true;
            _spinController.stop();
          },
          onHorizontalDragUpdate: (d) {
            setState(() => _yAngle += d.delta.dx * 0.016);
          },
          onHorizontalDragEnd: (_) {
            _isDragging = false;
            _resumeAutoSpin();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final figureH = h * 0.80;
              final figureW = figureH * 0.36;

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Ambient glow
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.20),
                          radius: 0.88,
                          colors: [
                            AppColors.seedColor.withValues(
                              alpha: isDark
                                  ? 0.11 + _glowController.value * 0.08
                                  : 0.05 + _glowController.value * 0.03,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Secondary accent glow (pink tint)
                  Positioned(
                    right: -w * 0.1,
                    top: h * 0.2,
                    child: Container(
                      width: w * 0.5,
                      height: w * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.gradientEnd.withValues(
                              alpha: isDark
                                  ? 0.07 + _glowController.value * 0.04
                                  : 0.03,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Shimmer particles
                  ..._buildParticles(w, h, isDark),

                  // Platform rings
                  Positioned(
                    bottom: h * 0.010,
                    child: _PlatformRings(
                      width: w * 0.58,
                      glow: _glowController.value,
                      isDark: isDark,
                    ),
                  ),

                  // Figure
                  Positioned(
                    top: h * 0.015 + floatOffset,
                    child:
                        Transform(
                              transform: _perspective(_yAngle),
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: figureW,
                                height: figureH,
                                child: CustomPaint(
                                  painter: _FashionFigurePainter(
                                    avatarType: widget.avatarType,
                                    yAngle: _yAngle,
                                    isDark: isDark,
                                    skinToneIndex: widget.skinToneIndex,
                                    hairColorIndex: widget.hairColorIndex,
                                  ),
                                ),
                              ),
                            )
                            .animate(controller: _entryController)
                            .scale(
                              begin: const Offset(0.70, 0.70),
                              end: const Offset(1, 1),
                              curve: Curves.elasticOut,
                            )
                            .fadeIn(duration: 500.ms),
                  ),

                  // Drag hint
                  Positioned(
                    bottom: h * 0.085,
                    child: _DragHint(
                      opacity:
                          (1.0 - (_yAngle.abs() / (pi * 1.5)).clamp(0.0, 1.0))
                              .clamp(0.0, 1.0),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles(double w, double h, bool isDark) {
    const positions = [
      [0.10, 0.12],
      [0.88, 0.20],
      [0.06, 0.52],
      [0.94, 0.58],
      [0.18, 0.76],
      [0.82, 0.38],
    ];
    const phases = [0.0, 0.28, 0.55, 0.12, 0.72, 0.44];

    return List.generate(positions.length, (i) {
      final phase = (_glowController.value + phases[i]) % 1.0;
      final alpha = sin(phase * pi).clamp(0.0, 1.0);
      return Positioned(
        left: w * positions[i][0],
        top: h * positions[i][1],
        child: Container(
          width: i.isEven ? 3 : 2,
          height: i.isEven ? 3 : 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (i.isEven ? AppColors.seedColor : AppColors.gradientEnd)
                .withValues(alpha: isDark ? alpha * 0.55 : alpha * 0.28),
          ),
        ),
      );
    });
  }
}

// ─── Platform Rings ───────────────────────────────────────────────────────────

class _PlatformRings extends StatelessWidget {
  final double width;
  final double glow;
  final bool isDark;

  const _PlatformRings({
    required this.width,
    required this.glow,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.20,
      child: CustomPaint(
        painter: _PlatformPainter(glow: glow, isDark: isDark),
      ),
    );
  }
}

class _PlatformPainter extends CustomPainter {
  final double glow;
  final bool isDark;

  const _PlatformPainter({required this.glow, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 3 concentric ellipses (outermost → innermost)
    for (int ring = 3; ring >= 1; ring--) {
      final scale = ring / 3.0;
      final ringAlpha = (isDark ? 0.08 : 0.05) + glow * 0.08 * (4 - ring) / 3.0;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * scale,
          height: size.height * scale,
        ),
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.seedColor.withValues(alpha: ringAlpha * 1.6),
              AppColors.gradientEnd.withValues(alpha: ringAlpha * 0.4),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 1 ? 2.0 : 1.0,
      );
    }

    // Centre filled glow spot
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.32,
        height: size.height * 0.32,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.seedColor.withValues(alpha: 0.22 + glow * 0.14),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_PlatformPainter old) => old.glow != glow;
}

// ─── Drag Hint ────────────────────────────────────────────────────────────────

class _DragHint extends StatelessWidget {
  final double opacity;
  const _DragHint({required this.opacity});

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.01) return const SizedBox.shrink();
    return Opacity(
      opacity: opacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chevron_left_rounded,
            size: 13,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          Text(
            'drag to rotate',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 13,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }
}

// ─── Fashion Figure Painter ───────────────────────────────────────────────────

class _FashionFigurePainter extends CustomPainter {
  final AvatarType avatarType;
  final double yAngle;
  final bool isDark;
  final int skinToneIndex;
  final int hairColorIndex;

  static const _skinPalette = [
    Color(0xFFF5E6D3), // 0: porcelain
    Color(0xFFE8C4A0), // 1: light warm
    Color(0xFFC89B6E), // 2: medium
    Color(0xFF8B5A2B), // 3: medium-dark
    Color(0xFF4A2F1A), // 4: deep
  ];

  static const _hairPalette = [
    Color(0xFF12090A), // 0: black
    Color(0xFF2C1810), // 1: dark brown
    Color(0xFF6B3A2A), // 2: warm brown
    Color(0xFFC9A96E), // 3: blonde
    Color(0xFF8B3A1C), // 4: auburn
    Color(0xFFD4CFC8), // 5: platinum
  ];

  const _FashionFigurePainter({
    required this.avatarType,
    required this.yAngle,
    required this.isDark,
    required this.skinToneIndex,
    required this.hairColorIndex,
  });

  double get _rightFactor => cos(yAngle - pi / 6).clamp(0.0, 1.0);
  double get _leftFactor => cos(yAngle + pi / 6).clamp(0.0, 1.0);

  Color _lit(Color c, {double boost = 0.0}) {
    final r = (c.r + boost * _rightFactor).clamp(0.0, 1.0);
    final g = (c.g + boost * _rightFactor).clamp(0.0, 1.0);
    final b = (c.b + boost * _rightFactor).clamp(0.0, 1.0);
    return Color.fromARGB(
      255,
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
    );
  }

  Color _shadowed(Color c, {double darken = 0.0}) {
    final f = 1.0 - darken * (1.0 - _leftFactor);
    return Color.fromARGB(
      255,
      (c.r * 255 * f).round().clamp(0, 255),
      (c.g * 255 * f).round().clamp(0, 255),
      (c.b * 255 * f).round().clamp(0, 255),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (avatarType == AvatarType.human) {
      _drawHuman(canvas, size);
    } else {
      _drawPet(canvas, size, isDog: avatarType == AvatarType.dog);
    }
  }

  void _drawHuman(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final skin = _skinPalette[skinToneIndex.clamp(0, 4)];
    final hair = _hairPalette[hairColorIndex.clamp(0, 5)];
    final skinL = _lit(skin, boost: 0.17);
    final skinM = skin;
    final skinD = _shadowed(skin, darken: 0.36);

    // Outfit: elegant ivory top + warm camel trousers
    final topBase = const Color(0xFFF0E4D4);
    final topL = _lit(topBase, boost: 0.10);
    final topD = _shadowed(topBase, darken: 0.22);

    final pantsBase = const Color(0xFFB8946A);
    final pantsL = _lit(pantsBase, boost: 0.10);
    final pantsD = _shadowed(pantsBase, darken: 0.28);

    final shoeColor = _shadowed(const Color(0xFF2C1A0E), darken: 0.1);

    // 1 — Hair back
    _paintHairBack(canvas, w, h, hair);

    // 2 — Head
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.070),
      width: w * 0.50,
      height: h * 0.118,
    );
    canvas.drawOval(
      headRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.30, -0.35),
          radius: 0.68,
          colors: [skinL, skinM, skinD],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(headRect),
    );

    // 3 — Face
    final ff = cos(yAngle).abs();
    if (ff > 0.18) _paintFace(canvas, w, h, skinL, skinD, hair, ff);

    // 4 — Neck
    final neckRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.153),
      width: w * 0.15,
      height: h * 0.054,
    );
    canvas.drawRect(
      neckRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [skinD, skinL, skinD],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(neckRect),
    );

    // 5 — Outfit top
    _paintOutfitTop(canvas, w, h, topL, topD);

    // 6 — Outfit trousers
    _paintTrousers(canvas, w, h, pantsL, pantsD);

    // 7 — Shoes
    _paintShoes(canvas, w, h, shoeColor);

    // 8 — Arms (over outfit, skin-coloured)
    _paintArm(canvas, w, h, skinL, skinM, skinD, isLeft: true);
    _paintArm(canvas, w, h, skinL, skinM, skinD, isLeft: false);

    // 9 — Hair front
    _paintHairFront(canvas, w, h, hair, ff);
  }

  void _paintHairBack(Canvas canvas, double w, double h, Color hair) {
    final p = Paint()..color = _shadowed(hair, darken: 0.22);
    // Main mass
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.060),
        width: w * 0.58,
        height: h * 0.112,
      ),
      p,
    );
    // Side tendrils
    for (final dx in [0.16, 0.84]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * dx, h * 0.085),
          width: w * 0.11,
          height: h * 0.072,
        ),
        p,
      );
    }
  }

  void _paintFace(
    Canvas canvas,
    double w,
    double h,
    Color skinL,
    Color skinD,
    Color hair,
    double ff,
  ) {
    // Eyebrows
    final browPaint = Paint()
      ..color = hair.withValues(alpha: 0.72 * ff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round;
    for (final side in [-1, 1]) {
      final cx = w * (side < 0 ? 0.385 : 0.615);
      canvas.drawPath(
        Path()
          ..moveTo(cx - w * 0.055, h * 0.0580)
          ..quadraticBezierTo(cx, h * 0.0530, cx + w * 0.055, h * 0.0590),
        browPaint,
      );
    }

    // Eyes
    for (final side in [-1, 1]) {
      final ex = w * (side < 0 ? 0.385 : 0.615);
      final ey = h * 0.076;
      final eyeW = w * 0.098;
      final eyeH = h * 0.033;

      // White
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, ey), width: eyeW, height: eyeH),
        Paint()..color = Colors.white.withValues(alpha: 0.88 * ff),
      );
      // Iris (warm brown)
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex, ey + h * 0.001),
          width: eyeW * 0.56,
          height: eyeH * 0.88,
        ),
        Paint()..color = Color.fromARGB((0.90 * ff * 255).round(), 65, 42, 28),
      );
      // Pupil
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex, ey + h * 0.001),
          width: eyeW * 0.26,
          height: eyeH * 0.66,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.88 * ff),
      );
      // Glint
      canvas.drawCircle(
        Offset(ex - eyeW * 0.14, ey - eyeH * 0.18),
        eyeW * 0.088,
        Paint()..color = Colors.white.withValues(alpha: 0.78 * ff),
      );
      // Upper lash arc
      canvas.drawArc(
        Rect.fromCenter(center: Offset(ex, ey), width: eyeW, height: eyeH),
        pi,
        pi,
        false,
        Paint()
          ..color = hair.withValues(alpha: 0.78 * ff)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }

    // Nose (very subtle)
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.50, h * 0.083)
        ..lineTo(w * 0.488, h * 0.093)
        ..quadraticBezierTo(w * 0.50, h * 0.097, w * 0.512, h * 0.093),
      Paint()
        ..color = skinD.withValues(alpha: 0.32 * ff)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );

    // Lips
    // Upper
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.420, h * 0.1020)
        ..quadraticBezierTo(w * 0.462, h * 0.0968, w * 0.500, h * 0.1022)
        ..quadraticBezierTo(w * 0.538, h * 0.0968, w * 0.580, h * 0.1020)
        ..quadraticBezierTo(w * 0.554, h * 0.1072, w * 0.500, h * 0.1065)
        ..quadraticBezierTo(w * 0.446, h * 0.1072, w * 0.420, h * 0.1020)
        ..close(),
      Paint()..color = Color.fromARGB((0.72 * ff * 255).round(), 210, 138, 128),
    );
    // Lower
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.420, h * 0.1020)
        ..quadraticBezierTo(w * 0.500, h * 0.1125, w * 0.580, h * 0.1020)
        ..quadraticBezierTo(w * 0.554, h * 0.1068, w * 0.500, h * 0.1062)
        ..quadraticBezierTo(w * 0.446, h * 0.1068, w * 0.420, h * 0.1020)
        ..close(),
      Paint()..color = Color.fromARGB((0.62 * ff * 255).round(), 218, 152, 142),
    );

    // Cheek blush (soft ovals, no blur — Impeller safe)
    for (final cx in [w * 0.305, w * 0.695]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, h * 0.089),
          width: w * 0.115,
          height: h * 0.024,
        ),
        Paint()..color = const Color(0xFFE8A4A0).withValues(alpha: 0.20 * ff),
      );
    }
  }

  void _paintOutfitTop(
    Canvas canvas,
    double w,
    double h,
    Color topL,
    Color topD,
  ) {
    final rect = Rect.fromLTWH(0, h * 0.148, w, h * 0.33);
    final path = Path()
      ..moveTo(w * 0.08, h * 0.180)
      ..lineTo(w * 0.92, h * 0.180)
      ..cubicTo(w * 0.88, h * 0.305, w * 0.80, h * 0.348, w * 0.77, h * 0.464)
      ..lineTo(w * 0.23, h * 0.464)
      ..cubicTo(w * 0.20, h * 0.348, w * 0.12, h * 0.305, w * 0.08, h * 0.180)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [topD, topL, topL, topD],
          stops: const [0.0, 0.26, 0.74, 1.0],
        ).createShader(rect),
    );

    // Crew-neck line
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.36, h * 0.180)
        ..quadraticBezierTo(w * 0.50, h * 0.202, w * 0.64, h * 0.180),
      Paint()
        ..color = topD.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );

    // Subtle centre seam
    canvas.drawLine(
      Offset(w * 0.50, h * 0.205),
      Offset(w * 0.50, h * 0.440),
      Paint()
        ..color = topD.withValues(alpha: 0.12)
        ..strokeWidth = 0.7,
    );
  }

  void _paintTrousers(
    Canvas canvas,
    double w,
    double h,
    Color pantsL,
    Color pantsD,
  ) {
    final rect = Rect.fromLTWH(0, h * 0.455, w, h * 0.44);
    final shading = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [pantsD, pantsL, pantsL, pantsD],
        stops: const [0.0, 0.28, 0.72, 1.0],
      ).createShader(rect);

    // Left leg
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.23, h * 0.464)
        ..lineTo(w * 0.50, h * 0.464)
        ..quadraticBezierTo(w * 0.50, h * 0.512, w * 0.38, h * 0.512)
        ..lineTo(w * 0.26, h * 0.882)
        ..lineTo(w * 0.14, h * 0.882)
        ..quadraticBezierTo(w * 0.13, h * 0.512, w * 0.23, h * 0.464)
        ..close(),
      shading,
    );

    // Right leg
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.77, h * 0.464)
        ..quadraticBezierTo(w * 0.87, h * 0.512, w * 0.86, h * 0.882)
        ..lineTo(w * 0.74, h * 0.882)
        ..lineTo(w * 0.62, h * 0.512)
        ..quadraticBezierTo(w * 0.50, h * 0.512, w * 0.50, h * 0.464)
        ..lineTo(w * 0.77, h * 0.464)
        ..close(),
      shading,
    );

    // Waistband
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.14, h * 0.452, w * 0.72, h * 0.024),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      ),
      Paint()..color = pantsD.withValues(alpha: 0.55),
    );

    // Crease lines
    for (final pair in [
      [w * 0.20, w * 0.215],
      [w * 0.80, w * 0.785],
    ]) {
      canvas.drawLine(
        Offset(pair[0], h * 0.515),
        Offset(pair[1], h * 0.840),
        Paint()
          ..color = pantsD.withValues(alpha: 0.20)
          ..strokeWidth = 0.7,
      );
    }
  }

  void _paintShoes(Canvas canvas, double w, double h, Color shoeColor) {
    for (final isLeft in [true, false]) {
      final bx = isLeft ? w * 0.20 : w * 0.64;
      final tipX = isLeft ? w * 0.06 : w * 0.94;
      final path = Path()
        ..moveTo(bx, h * 0.880)
        ..lineTo(bx + (isLeft ? w * 0.14 : -w * 0.14), h * 0.880)
        ..lineTo(tipX, h * 0.902)
        ..quadraticBezierTo(
          isLeft ? w * 0.04 : w * 0.96,
          h * 0.924,
          bx,
          h * 0.922,
        )
        ..close();
      canvas.drawPath(path, Paint()..color = shoeColor);
      // Highlight
      canvas.drawPath(
        Path()
          ..moveTo(bx + (isLeft ? w * 0.038 : -w * 0.038), h * 0.884)
          ..quadraticBezierTo(
            bx + (isLeft ? w * 0.015 : -w * 0.015),
            h * 0.892,
            tipX + (isLeft ? w * 0.048 : -w * 0.048),
            h * 0.898,
          ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintArm(
    Canvas canvas,
    double w,
    double h,
    Color skinL,
    Color skinM,
    Color skinD, {
    required bool isLeft,
  }) {
    final sx = isLeft ? w * 0.10 : w * 0.90;
    final ex = isLeft ? w * 0.04 : w * 0.96;
    final ey = h * 0.355;
    final hx = isLeft ? w * 0.10 : w * 0.90;
    final hy = h * 0.490;

    final armRect = Rect.fromLTWH(
      isLeft ? 0 : w * 0.52,
      h * 0.18,
      w * 0.48,
      h * 0.35,
    );

    canvas.drawPath(
      Path()
        ..moveTo(sx, h * 0.193)
        ..quadraticBezierTo(ex, ey, hx, hy),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isLeft ? [skinD, skinL] : [skinL, skinD],
        ).createShader(armRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.088
        ..strokeCap = StrokeCap.round,
    );

    // Hand oval
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(hx, hy + h * 0.015),
        width: w * 0.082,
        height: w * 0.056,
      ),
      Paint()..color = skinM,
    );
  }

  void _paintHairFront(
    Canvas canvas,
    double w,
    double h,
    Color hair,
    double ff,
  ) {
    final p = Paint()..color = hair;

    // Top hairline arc
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.24, h * 0.048)
        ..quadraticBezierTo(w * 0.50, h * 0.014, w * 0.76, h * 0.048)
        ..quadraticBezierTo(w * 0.70, h * 0.030, w * 0.50, h * 0.025)
        ..quadraticBezierTo(w * 0.30, h * 0.030, w * 0.24, h * 0.048)
        ..close(),
      p,
    );

    // Chignon bun
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.034),
        width: w * 0.20,
        height: h * 0.036,
      ),
      Paint()..color = _lit(hair, boost: 0.07),
    );

    // Face-framing wisps (visible from front)
    if (ff > 0.28) {
      final wispPaint = Paint()
        ..color = hair.withValues(alpha: ff * 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      for (final isLeft in [true, false]) {
        canvas.drawPath(
          Path()
            ..moveTo(w * (isLeft ? 0.27 : 0.73), h * 0.048)
            ..quadraticBezierTo(
              w * (isLeft ? 0.21 : 0.79),
              h * 0.072,
              w * (isLeft ? 0.235 : 0.765),
              h * 0.090,
            ),
          wispPaint,
        );
      }
    }
  }

  // ─── Pet ──────────────────────────────────────────────────────────────────

  void _drawPet(Canvas canvas, Size size, {required bool isDog}) {
    final w = size.width;
    final h = size.height;

    final furBase = isDark
        ? (isDog ? const Color(0xFFBB9458) : const Color(0xFFCDAF96))
        : (isDog ? const Color(0xFFD4AA70) : const Color(0xFFE8D4C0));
    final furL = _lit(furBase, boost: 0.13);
    final furD = _shadowed(furBase, darken: 0.30);
    final furAccent = isDog
        ? _shadowed(const Color(0xFF6B4220), darken: 0.10)
        : const Color(0xFF7A5C4A);

    // Body — slightly chunkier oval
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.54),
        width: w * 0.62,
        height: h * 0.40,
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [furD, furL, furD],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(Rect.fromLTWH(w * 0.04, h * 0.30, w * 0.92, h * 0.44)),
    );

    // Inner belly patch (lighter)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.56),
        width: w * 0.32,
        height: h * 0.25,
      ),
      Paint()..color = furL.withValues(alpha: 0.45),
    );

    // Head
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.195),
      w * 0.235,
      Paint()
        ..shader =
            RadialGradient(
              center: const Alignment(0.28, -0.30),
              radius: 0.70,
              colors: [furL, furBase, furD],
            ).createShader(
              Rect.fromCenter(
                center: Offset(w * 0.50, h * 0.195),
                width: w * 0.48,
                height: w * 0.48,
              ),
            ),
    );

    // Ears
    if (isDog) {
      // Floppy dog ears
      for (final isLeft in [true, false]) {
        final ex = isLeft ? w * 0.24 : w * 0.76;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(ex, h * 0.155),
            width: w * 0.16,
            height: h * 0.18,
          ),
          Paint()..color = furD,
        );
        // Inner ear
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(ex, h * 0.158),
            width: w * 0.09,
            height: h * 0.10,
          ),
          Paint()..color = furAccent.withValues(alpha: 0.55),
        );
      }
    } else {
      // Pointed cat ears with inner triangle
      for (final isLeft in [true, false]) {
        final tipX = w * (isLeft ? 0.29 : 0.71);
        final baseL = w * (isLeft ? 0.20 : 0.62);
        final baseR = w * (isLeft ? 0.38 : 0.80);
        canvas.drawPath(
          Path()
            ..moveTo(baseL, h * 0.118)
            ..lineTo(tipX, h * 0.020)
            ..lineTo(baseR, h * 0.118)
            ..close(),
          Paint()..color = furD,
        );
        // Inner pink
        canvas.drawPath(
          Path()
            ..moveTo(baseL + w * 0.022, h * 0.112)
            ..lineTo(tipX, h * 0.038)
            ..lineTo(baseR - w * 0.022, h * 0.112)
            ..close(),
          Paint()..color = const Color(0xFFE8A0B0).withValues(alpha: 0.65),
        );
      }
    }

    // Face
    final ff = cos(yAngle).abs();
    if (ff > 0.22) {
      // Eyes
      for (final isLeft in [true, false]) {
        final ex = w * (isLeft ? 0.390 : 0.610);
        final ey = h * 0.190;
        canvas.drawCircle(
          Offset(ex, ey),
          w * 0.042,
          Paint()..color = Colors.black.withValues(alpha: 0.82 * ff),
        );
        // Iris colour
        canvas.drawCircle(
          Offset(ex, ey),
          w * 0.028,
          Paint()
            ..color =
                (isDog ? const Color(0xFF5C3A1A) : const Color(0xFF4A8C5C))
                    .withValues(alpha: 0.90 * ff),
        );
        // Pupil
        canvas.drawCircle(
          Offset(ex, ey),
          isDog ? w * 0.014 : w * 0.010,
          Paint()..color = Colors.black.withValues(alpha: ff),
        );
        // Glint
        canvas.drawCircle(
          Offset(ex - w * 0.010, ey - w * 0.010),
          w * 0.009,
          Paint()..color = Colors.white.withValues(alpha: 0.80 * ff),
        );
        // Cat: almond eyelid line
        if (!isDog) {
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(ex, ey),
              width: w * 0.086,
              height: w * 0.054,
            ),
            pi,
            pi,
            false,
            Paint()
              ..color = Colors.black.withValues(alpha: 0.50 * ff)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4,
          );
        }
      }

      // Nose
      if (isDog) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.50, h * 0.225),
            width: w * 0.100,
            height: h * 0.040,
          ),
          Paint()..color = Colors.black.withValues(alpha: 0.80 * ff),
        );
        // Nostrils
        for (final nx in [w * 0.465, w * 0.535]) {
          canvas.drawCircle(
            Offset(nx, h * 0.228),
            w * 0.014,
            Paint()..color = const Color(0xFF2A1A1A).withValues(alpha: ff),
          );
        }
      } else {
        // Cat nose — small triangle
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.50, h * 0.214)
            ..lineTo(w * 0.474, h * 0.228)
            ..lineTo(w * 0.526, h * 0.228)
            ..close(),
          Paint()..color = const Color(0xFFE87090).withValues(alpha: 0.90 * ff),
        );
        // Mouth lines
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.50, h * 0.228)
            ..quadraticBezierTo(w * 0.464, h * 0.240, w * 0.44, h * 0.235),
          Paint()
            ..color = furD.withValues(alpha: 0.55 * ff)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.50, h * 0.228)
            ..quadraticBezierTo(w * 0.536, h * 0.240, w * 0.56, h * 0.235),
          Paint()
            ..color = furD.withValues(alpha: 0.55 * ff)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        );
        // Whiskers
        for (final side in [-1, 1]) {
          for (final angle in [-0.12, 0.0, 0.12]) {
            final wStartX = w * (0.50 + side * 0.038);
            final wStartY = h * 0.230;
            canvas.drawLine(
              Offset(wStartX, wStartY),
              Offset(wStartX + side * w * 0.22, wStartY + angle * h),
              Paint()
                ..color = furBase.withValues(alpha: 0.35 * ff)
                ..strokeWidth = 0.8,
            );
          }
        }
      }

      // Dog: happy mouth
      if (isDog) {
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.42, h * 0.245)
            ..quadraticBezierTo(w * 0.50, h * 0.270, w * 0.58, h * 0.245),
          Paint()
            ..color = const Color(0xFF3A1A1A).withValues(alpha: 0.55 * ff)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
        // Tongue
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.50, h * 0.268),
            width: w * 0.090,
            height: h * 0.032,
          ),
          Paint()..color = const Color(0xFFE86070).withValues(alpha: 0.85 * ff),
        );
      }
    }

    // Legs
    for (final pair in [
      [w * 0.26, h * 0.785],
      [w * 0.42, h * 0.785],
      [w * 0.58, h * 0.785],
      [w * 0.74, h * 0.785],
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(pair[0], pair[1]),
            width: w * 0.095,
            height: h * 0.19,
          ),
          const Radius.circular(12),
        ),
        Paint()..color = furD,
      );
      // Paw pad
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pair[0], pair[1] + h * 0.095),
          width: w * 0.085,
          height: h * 0.032,
        ),
        Paint()
          ..color = (isDog ? const Color(0xFF7A4A28) : const Color(0xFFD4A8B0))
              .withValues(alpha: 0.75),
      );
    }

    // Tail
    if (isDog) {
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.78, h * 0.440)
          ..quadraticBezierTo(w * 1.08, h * 0.330, w * 0.98, h * 0.195),
        Paint()
          ..color = furD
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.058
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // Cat: elegant curved tail
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.76, h * 0.470)
          ..cubicTo(
            w * 1.05,
            h * 0.380,
            w * 1.10,
            h * 0.200,
            w * 0.82,
            h * 0.155,
          ),
        Paint()
          ..color = furD
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.048
          ..strokeCap = StrokeCap.round,
      );
    }

    // Collar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.328),
          width: w * 0.38,
          height: h * 0.028,
        ),
        const Radius.circular(6),
      ),
      Paint()
        ..color = (isDog ? AppColors.accentGold : AppColors.gradientEnd)
            .withValues(alpha: 0.90),
    );
    // Collar gem
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.328),
      w * 0.022,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_FashionFigurePainter old) =>
      old.yAngle != yAngle ||
      old.avatarType != avatarType ||
      old.isDark != isDark ||
      old.skinToneIndex != skinToneIndex ||
      old.hairColorIndex != hairColorIndex;
}
