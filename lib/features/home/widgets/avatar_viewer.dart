import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/models/user_profile.dart';
import '../../../core/theme/app_brand_theme.dart';
import '../../../core/theme/app_motion.dart';

class AvatarViewer extends StatefulWidget {
  final AvatarType avatarType;
  final AvatarBodyShape bodyShape;
  final int skinToneIndex;
  final int hairColorIndex;
  final int hairStyleIndex;

  const AvatarViewer({
    super.key,
    required this.avatarType,
    this.bodyShape = AvatarBodyShape.female,
    this.skinToneIndex = 1,
    this.hairColorIndex = 1,
    this.hairStyleIndex = 3,
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
  bool _reduceMotion = false;

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
      duration: AppMotion.transition,
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = AppMotion.reduceMotion(context);
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _spinController.stop();
      _glowController.stop();
      _floatController.stop();
      _entryController.value = 1;
      return;
    }
    if (!_spinController.isAnimating) _spinController.repeat();
    if (!_glowController.isAnimating) _glowController.repeat(reverse: true);
    if (!_floatController.isAnimating) _floatController.repeat(reverse: true);
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
    final brand = MmmBrandTheme.of(context);

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
              final figureW = figureH * 0.55;

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
                            brand.primaryGradient.colors.first.withValues(
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

                  // Secondary accent glow
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
                            brand.primaryGradient.colors.last.withValues(
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
                  ..._buildParticles(w, h, isDark, brand),

                  // Platform rings
                  Positioned(
                    bottom: h * 0.010,
                    child: _PlatformRings(
                      width: w * 0.58,
                      glow: _glowController.value,
                      isDark: isDark,
                      primary: brand.primaryGradient.colors.first,
                      accent: brand.primaryGradient.colors.last,
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
                                    bodyShape: widget.bodyShape,
                                    yAngle: _yAngle,
                                    isDark: isDark,
                                    skinToneIndex: widget.skinToneIndex,
                                    hairColorIndex: widget.hairColorIndex,
                                    hairStyleIndex: widget.hairStyleIndex,
                                  ),
                                ),
                              ),
                            )
                            .animate(controller: _entryController)
                            .scale(
                              begin: const Offset(0.70, 0.70),
                              end: const Offset(1, 1),
                              curve: AppMotion.curve,
                            )
                            .fadeIn(duration: AppMotion.transition),
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

  List<Widget> _buildParticles(
    double w,
    double h,
    bool isDark,
    MmmBrandTheme brand,
  ) {
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
            color:
                (i.isEven
                        ? brand.primaryGradient.colors.first
                        : brand.primaryGradient.colors.last)
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
  final Color primary;
  final Color accent;

  const _PlatformRings({
    required this.width,
    required this.glow,
    required this.isDark,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.20,
      child: CustomPaint(
        painter: _PlatformPainter(
          glow: glow,
          isDark: isDark,
          primary: primary,
          accent: accent,
        ),
      ),
    );
  }
}

class _PlatformPainter extends CustomPainter {
  final double glow;
  final bool isDark;
  final Color primary;
  final Color accent;

  const _PlatformPainter({
    required this.glow,
    required this.isDark,
    required this.primary,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

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
              primary.withValues(alpha: ringAlpha * 1.6),
              accent.withValues(alpha: ringAlpha * 0.4),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 1 ? 2.0 : 1.0,
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.32,
        height: size.height * 0.32,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            primary.withValues(alpha: 0.22 + glow * 0.14),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_PlatformPainter old) =>
      old.glow != glow || old.primary != primary || old.accent != accent;
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

// ─── Chibi Fashion Figure Painter ─────────────────────────────────────────────

class _FashionFigurePainter extends CustomPainter {
  final AvatarType avatarType;
  final AvatarBodyShape bodyShape;
  final double yAngle;
  final bool isDark;
  final int skinToneIndex;
  final int hairColorIndex;
  final int hairStyleIndex;

  static const _skinPalette = [
    Color(0xFFF5E6D3), // 0: porcelain
    Color(0xFFE8C4A0), // 1: light warm
    Color(0xFFC89B6E), // 2: medium
    Color(0xFFB07840), // 3: medium-tan
    Color(0xFF9A6235), // 4: medium-warm
    Color(0xFF8B5A2B), // 5: medium-dark
    Color(0xFF4A2F1A), // 6: deep
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
    required this.bodyShape,
    required this.yAngle,
    required this.isDark,
    required this.skinToneIndex,
    required this.hairColorIndex,
    required this.hairStyleIndex,
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
      _drawHuman(canvas, size.width, size.height);
    } else {
      _drawPet(
        canvas,
        size.width,
        size.height,
        isDog: avatarType == AvatarType.dog,
      );
    }
  }

  // ─── Human ────────────────────────────────────────────────────────────────

  void _drawHuman(Canvas canvas, double w, double h) {
    final skin = _skinPalette[skinToneIndex.clamp(0, 6)];
    final hair = _hairPalette[hairColorIndex.clamp(0, 5)];
    final skinL = _lit(skin, boost: 0.18);
    final skinD = _shadowed(skin, darken: 0.35);

    // Chibi head geometry — large dominant circle
    const headCx = 0.50;
    const headCy = 0.26;
    const headR = 0.40; // fraction of w

    final hcx = w * headCx;
    final hcy = h * headCy;
    final hr = w * headR;

    final ff = cos(yAngle).abs();

    // 1 — Hair back
    _drawHairBack(canvas, w, h, hair, hcx, hcy, hr);

    // 2 — Body (behind head overlap)
    _drawBody(canvas, w, h, skin, skinL, skinD);

    // 3 — Head
    final headRect = Rect.fromCircle(center: Offset(hcx, hcy), radius: hr);
    canvas.drawCircle(
      Offset(hcx, hcy),
      hr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.28, -0.32),
          radius: 0.72,
          colors: [skinL, skin, skinD],
          stops: const [0.0, 0.46, 1.0],
        ).createShader(headRect),
    );

    // 4 — Face
    if (ff > 0.15) _drawFace(canvas, w, h, skin, skinD, hair, hcx, hcy, hr, ff);

    // 5 — Hair front
    _drawHairFront(canvas, w, h, hair, hcx, hcy, hr, ff);
  }

  void _drawBody(
    Canvas canvas,
    double w,
    double h,
    Color skin,
    Color skinL,
    Color skinD,
  ) {
    // Neck
    final neckCy = h * 0.455;
    final neckRect = Rect.fromCenter(
      center: Offset(w * 0.50, neckCy),
      width: w * 0.18,
      height: h * 0.05,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(neckRect, const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          colors: [skinD, skinL, skinD],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(neckRect),
    );

    if (bodyShape == AvatarBodyShape.female) {
      _drawFemaleBody(canvas, w, h);
    } else {
      _drawMaleBody(canvas, w, h);
    }
  }

  void _drawFemaleBody(Canvas canvas, double w, double h) {
    final topBase = const Color(0xFFD4C5F5);
    final topL = _lit(topBase, boost: 0.10);
    final topD = _shadowed(topBase, darken: 0.22);
    final bodyTop = h * 0.46;

    // Rounded torso
    final bodyRect = Rect.fromLTWH(0, bodyTop, w, h * 0.25);
    final torsoPath = Path()
      ..moveTo(w * 0.20, bodyTop)
      ..lineTo(w * 0.80, bodyTop)
      ..quadraticBezierTo(
        w * 0.90,
        bodyTop + h * 0.07,
        w * 0.87,
        bodyTop + h * 0.14,
      )
      ..quadraticBezierTo(
        w * 0.90,
        bodyTop + h * 0.20,
        w * 0.84,
        bodyTop + h * 0.24,
      )
      ..lineTo(w * 0.16, bodyTop + h * 0.24)
      ..quadraticBezierTo(
        w * 0.10,
        bodyTop + h * 0.20,
        w * 0.13,
        bodyTop + h * 0.14,
      )
      ..quadraticBezierTo(w * 0.10, bodyTop + h * 0.07, w * 0.20, bodyTop)
      ..close();
    canvas.drawPath(
      torsoPath,
      Paint()
        ..shader = LinearGradient(
          colors: [topD, topL, topL, topD],
          stops: const [0.0, 0.28, 0.72, 1.0],
        ).createShader(bodyRect),
    );

    // Skirt
    final skirtBase = const Color(0xFFB8A0E8);
    final skirtL = _lit(skirtBase, boost: 0.08);
    final skirtD = _shadowed(skirtBase, darken: 0.25);
    final skirtTop = bodyTop + h * 0.21;
    final skirtRect = Rect.fromLTWH(0, skirtTop, w, h * 0.30);
    final skirtPath = Path()
      ..moveTo(w * 0.18, skirtTop)
      ..lineTo(w * 0.82, skirtTop)
      ..quadraticBezierTo(
        w * 0.96,
        skirtTop + h * 0.14,
        w * 0.92,
        skirtTop + h * 0.27,
      )
      ..quadraticBezierTo(
        w * 0.88,
        skirtTop + h * 0.29,
        w * 0.50,
        skirtTop + h * 0.27,
      )
      ..quadraticBezierTo(
        w * 0.12,
        skirtTop + h * 0.29,
        w * 0.08,
        skirtTop + h * 0.27,
      )
      ..quadraticBezierTo(w * 0.04, skirtTop + h * 0.14, w * 0.18, skirtTop)
      ..close();
    canvas.drawPath(
      skirtPath,
      Paint()
        ..shader = LinearGradient(
          colors: [skirtD, skirtL, skirtL, skirtD],
          stops: const [0.0, 0.28, 0.72, 1.0],
        ).createShader(skirtRect),
    );

    // Legs (short, below skirt hem)
    final legTop = skirtTop + h * 0.24;
    final skin = _skinPalette[skinToneIndex.clamp(0, 6)];
    final legColor = _shadowed(skin, darken: 0.10);
    for (final isLeft in [true, false]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            isLeft ? w * 0.28 : w * 0.58,
            legTop,
            w * 0.14,
            h * 0.11,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = legColor,
      );
    }

    _drawShoes(canvas, w, h, legTop + h * 0.09, narrow: true);
    _drawArms(canvas, w, h, bodyTop);
  }

  void _drawMaleBody(Canvas canvas, double w, double h) {
    final topBase = const Color(0xFFF0E4D4);
    final topL = _lit(topBase, boost: 0.10);
    final topD = _shadowed(topBase, darken: 0.22);
    final pantsBase = const Color(0xFFB8946A);
    final pantsL = _lit(pantsBase, boost: 0.10);
    final pantsD = _shadowed(pantsBase, darken: 0.28);
    final bodyTop = h * 0.46;

    // Trapezoid torso (wider shoulders)
    final bodyRect = Rect.fromLTWH(0, bodyTop, w, h * 0.22);
    final torsoPath = Path()
      ..moveTo(w * 0.12, bodyTop)
      ..lineTo(w * 0.88, bodyTop)
      ..lineTo(w * 0.82, bodyTop + h * 0.22)
      ..lineTo(w * 0.18, bodyTop + h * 0.22)
      ..close();
    canvas.drawPath(
      torsoPath,
      Paint()
        ..shader = LinearGradient(
          colors: [topD, topL, topL, topD],
          stops: const [0.0, 0.28, 0.72, 1.0],
        ).createShader(bodyRect),
    );

    final pantTop = bodyTop + h * 0.20;
    // Waistband
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.14, pantTop, w * 0.72, h * 0.025),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      Paint()..color = pantsD.withValues(alpha: 0.60),
    );

    // Trouser legs
    final pantsRect = Rect.fromLTWH(0, pantTop, w, h * 0.38);
    final pantShading = Paint()
      ..shader = LinearGradient(
        colors: [pantsD, pantsL, pantsL, pantsD],
        stops: const [0.0, 0.28, 0.72, 1.0],
      ).createShader(pantsRect);

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.18, pantTop + h * 0.02)
        ..lineTo(w * 0.49, pantTop + h * 0.02)
        ..lineTo(w * 0.46, pantTop + h * 0.33)
        ..lineTo(w * 0.16, pantTop + h * 0.33)
        ..close(),
      pantShading,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.51, pantTop + h * 0.02)
        ..lineTo(w * 0.82, pantTop + h * 0.02)
        ..lineTo(w * 0.84, pantTop + h * 0.33)
        ..lineTo(w * 0.54, pantTop + h * 0.33)
        ..close(),
      pantShading,
    );

    _drawShoes(canvas, w, h, pantTop + h * 0.32, narrow: false);
    _drawArms(canvas, w, h, bodyTop);
  }

  void _drawShoes(
    Canvas canvas,
    double w,
    double h,
    double shoeTop, {
    required bool narrow,
  }) {
    final shoeColor = _shadowed(const Color(0xFF2C1A0E), darken: 0.10);
    final shoeW = narrow ? w * 0.22 : w * 0.26;
    for (final isLeft in [true, false]) {
      final sx = isLeft ? w * 0.12 : (narrow ? w * 0.50 : w * 0.53);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sx, shoeTop, shoeW, h * 0.055),
          const Radius.circular(8),
        ),
        Paint()..color = shoeColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            sx + shoeW * 0.10,
            shoeTop + h * 0.008,
            shoeW * 0.44,
            h * 0.018,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
    }
  }

  void _drawArms(Canvas canvas, double w, double h, double bodyTop) {
    final skin = _skinPalette[skinToneIndex.clamp(0, 6)];
    final skinL = _lit(skin, boost: 0.15);
    final skinD = _shadowed(skin, darken: 0.30);

    for (final isLeft in [true, false]) {
      final sx = isLeft ? w * 0.14 : w * 0.86;
      final ex = isLeft ? w * 0.05 : w * 0.95;
      final ey = bodyTop + h * 0.24;
      final armRect = Rect.fromLTWH(
        isLeft ? 0 : w * 0.50,
        bodyTop,
        w * 0.50,
        h * 0.28,
      );
      canvas.drawPath(
        Path()
          ..moveTo(sx, bodyTop + h * 0.04)
          ..quadraticBezierTo(ex, bodyTop + h * 0.14, ex, ey),
        Paint()
          ..shader = LinearGradient(
            colors: isLeft ? [skinD, skinL] : [skinL, skinD],
          ).createShader(armRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.11
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex, ey + h * 0.012),
          width: w * 0.10,
          height: w * 0.07,
        ),
        Paint()..color = skin,
      );
    }
  }

  void _drawFace(
    Canvas canvas,
    double w,
    double h,
    Color skin,
    Color skinD,
    Color hair,
    double hcx,
    double hcy,
    double hr,
    double ff,
  ) {
    final eyeY = hcy + hr * 0.14;
    final eyeSpread = hr * 0.50;
    final eyeR = hr * 0.27;

    for (final side in [-1, 1]) {
      final ex = hcx + side * eyeSpread;
      canvas.drawCircle(
        Offset(ex, eyeY),
        eyeR,
        Paint()..color = Colors.white.withValues(alpha: 0.92 * ff),
      );
      canvas.drawCircle(
        Offset(ex, eyeY + eyeR * 0.05),
        eyeR * 0.68,
        Paint()..color = Color.fromARGB((0.88 * ff * 255).round(), 52, 36, 20),
      );
      canvas.drawCircle(
        Offset(ex, eyeY + eyeR * 0.05),
        eyeR * 0.38,
        Paint()..color = Colors.black.withValues(alpha: 0.90 * ff),
      );
      canvas.drawCircle(
        Offset(ex - eyeR * 0.28, eyeY - eyeR * 0.28),
        eyeR * 0.20,
        Paint()..color = Colors.white.withValues(alpha: 0.90 * ff),
      );
      // Lash arc
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(ex, eyeY),
          width: eyeR * 2,
          height: eyeR * 2,
        ),
        pi,
        pi,
        false,
        Paint()
          ..color = hair.withValues(alpha: 0.70 * ff)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }

    // Cheek blush (no blur — Impeller safe)
    for (final side in [-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(hcx + side * hr * 0.65, hcy + hr * 0.38),
          width: hr * 0.36,
          height: hr * 0.17,
        ),
        Paint()..color = const Color(0xFFE8A4A0).withValues(alpha: 0.25 * ff),
      );
    }

    // Mouth
    canvas.drawPath(
      Path()
        ..moveTo(hcx - hr * 0.18, hcy + hr * 0.50)
        ..quadraticBezierTo(
          hcx,
          hcy + hr * 0.65,
          hcx + hr * 0.18,
          hcy + hr * 0.50,
        ),
      Paint()
        ..color = const Color(0xFFD4847A).withValues(alpha: 0.80 * ff)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  // ─── Hair Styles ──────────────────────────────────────────────────────────

  void _drawHairBack(
    Canvas canvas,
    double w,
    double h,
    Color hair,
    double hcx,
    double hcy,
    double hr,
  ) {
    final style = hairStyleIndex.clamp(0, 5);
    final dark = _shadowed(hair, darken: 0.24);

    if (style == 3) {
      // Long straight — back panels
      for (final side in [-1, 1]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              hcx + side * hr * 0.98 - (side < 0 ? hr * 0.60 : 0),
              hcy,
              hr * 0.60,
              h * 0.44,
            ),
            const Radius.circular(12),
          ),
          Paint()..color = dark,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(hcx, hcy - hr * 0.30),
          width: hr * 2.10,
          height: hr * 1.20,
        ),
        Paint()..color = dark,
      );
    } else if (style == 4) {
      // Ponytail — back cap + tail
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(hcx, hcy - hr * 0.28),
          width: hr * 2.05,
          height: hr * 1.10,
        ),
        Paint()..color = dark,
      );
      canvas.drawPath(
        Path()
          ..moveTo(hcx - hr * 0.14, hcy - hr * 0.88)
          ..quadraticBezierTo(
            hcx - hr * 0.22,
            hcy + h * 0.14,
            hcx + hr * 0.08,
            hcy + h * 0.21,
          )
          ..quadraticBezierTo(
            hcx + hr * 0.22,
            hcy + h * 0.14,
            hcx + hr * 0.14,
            hcy - hr * 0.88,
          ),
        Paint()..color = dark,
      );
    } else if (style == 5) {
      // Bob — back mass to chin
      canvas.drawPath(
        Path()
          ..moveTo(hcx - hr * 0.90, hcy - hr * 0.15)
          ..quadraticBezierTo(
            hcx - hr * 1.05,
            hcy + hr * 0.60,
            hcx - hr * 0.85,
            hcy + hr * 0.88,
          )
          ..lineTo(hcx + hr * 0.85, hcy + hr * 0.88)
          ..quadraticBezierTo(
            hcx + hr * 1.05,
            hcy + hr * 0.60,
            hcx + hr * 0.90,
            hcy - hr * 0.15,
          )
          ..quadraticBezierTo(
            hcx,
            hcy - hr * 1.08,
            hcx - hr * 0.90,
            hcy - hr * 0.15,
          )
          ..close(),
        Paint()..color = dark,
      );
    } else {
      // All other styles — generic back mass
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(hcx, hcy - hr * 0.28),
          width: hr * 2.10,
          height: hr * 1.22,
        ),
        Paint()..color = dark,
      );
    }
  }

  void _drawHairFront(
    Canvas canvas,
    double w,
    double h,
    Color hair,
    double hcx,
    double hcy,
    double hr,
    double ff,
  ) {
    final style = hairStyleIndex.clamp(0, 5);
    final base = Paint()..color = hair;
    final lit = Paint()..color = _lit(hair, boost: 0.08);

    // Crown coverage path (shared by most styles)
    void crownArc() {
      canvas.drawPath(
        Path()
          ..moveTo(hcx - hr * 0.90, hcy - hr * 0.18)
          ..quadraticBezierTo(
            hcx,
            hcy - hr * 1.06,
            hcx + hr * 0.90,
            hcy - hr * 0.18,
          )
          ..quadraticBezierTo(
            hcx + hr * 0.68,
            hcy - hr * 0.65,
            hcx,
            hcy - hr * 0.85,
          )
          ..quadraticBezierTo(
            hcx - hr * 0.68,
            hcy - hr * 0.65,
            hcx - hr * 0.90,
            hcy - hr * 0.18,
          )
          ..close(),
        base,
      );
    }

    if (style == 0) {
      // Short Tousled — spiky crown
      crownArc();
      for (final dx in [-0.32, -0.05, 0.22, 0.50]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(hcx + hr * dx, hcy - hr * 0.98),
            width: hr * 0.30,
            height: hr * 0.38,
          ),
          lit,
        );
      }
    } else if (style == 1) {
      // Side Swept — sweep over forehead
      canvas.drawPath(
        Path()
          ..moveTo(hcx - hr * 0.90, hcy - hr * 0.18)
          ..quadraticBezierTo(
            hcx - hr * 0.10,
            hcy - hr * 1.10,
            hcx + hr * 0.88,
            hcy - hr * 0.25,
          )
          ..quadraticBezierTo(
            hcx + hr * 0.60,
            hcy - hr * 0.72,
            hcx - hr * 0.10,
            hcy - hr * 0.85,
          )
          ..quadraticBezierTo(
            hcx - hr * 0.55,
            hcy - hr * 0.55,
            hcx - hr * 0.90,
            hcy - hr * 0.18,
          )
          ..close(),
        base,
      );
      canvas.drawPath(
        Path()
          ..moveTo(hcx - hr * 0.90, hcy - hr * 0.18)
          ..quadraticBezierTo(
            hcx - hr * 0.70,
            hcy + hr * 0.05,
            hcx - hr * 0.55,
            hcy + hr * 0.22,
          )
          ..quadraticBezierTo(
            hcx - hr * 0.40,
            hcy - hr * 0.10,
            hcx - hr * 0.60,
            hcy - hr * 0.40,
          )
          ..quadraticBezierTo(
            hcx - hr * 0.75,
            hcy - hr * 0.35,
            hcx - hr * 0.90,
            hcy - hr * 0.18,
          )
          ..close(),
        lit,
      );
    } else if (style == 2) {
      // Undercut — large crown puff + side strip
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(hcx, hcy - hr * 0.70),
          width: hr * 1.60,
          height: hr * 0.90,
        ),
        base,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(hcx - hr * 0.10, hcy - hr * 0.82),
          width: hr * 0.80,
          height: hr * 0.28,
        ),
        lit,
      );
      for (final side in [-1, 1]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(hcx + side * hr * 0.88, hcy + hr * 0.05),
            width: hr * 0.30,
            height: hr * 0.55,
          ),
          Paint()..color = _shadowed(hair, darken: 0.22),
        );
      }
    } else if (style == 3) {
      // Long Straight — crown + face-framing side strands
      crownArc();
      for (final side in [-1, 1]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              hcx + side * hr * 0.82 - (side < 0 ? hr * 0.44 : 0),
              hcy + hr * 0.20,
              hr * 0.44,
              h * 0.26,
            ),
            const Radius.circular(10),
          ),
          Paint()..color = hair.withValues(alpha: 0.90),
        );
      }
    } else if (style == 4) {
      // Ponytail — crown + bun highlight
      crownArc();
      canvas.drawCircle(Offset(hcx, hcy - hr * 1.00), hr * 0.20, lit);
      // Bun wrap line
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(hcx, hcy - hr * 1.00),
          width: hr * 0.40,
          height: hr * 0.40,
        ),
        pi * 0.3,
        pi * 1.4,
        false,
        Paint()
          ..color = _shadowed(hair, darken: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // Bob — crown + side panels
      crownArc();
      for (final side in [-1, 1]) {
        canvas.drawPath(
          Path()
            ..moveTo(hcx + side * hr * 0.88, hcy - hr * 0.18)
            ..quadraticBezierTo(
              hcx + side * hr * 1.00,
              hcy + hr * 0.35,
              hcx + side * hr * 0.90,
              hcy + hr * 0.84,
            )
            ..quadraticBezierTo(
              hcx + side * hr * 0.70,
              hcy + hr * 0.87,
              hcx + side * hr * 0.60,
              hcy + hr * 0.79,
            )
            ..quadraticBezierTo(
              hcx + side * hr * 0.74,
              hcy + hr * 0.40,
              hcx + side * hr * 0.72,
              hcy - hr * 0.10,
            )
            ..close(),
          base,
        );
      }
    }
  }

  // ─── Pet ──────────────────────────────────────────────────────────────────

  void _drawPet(Canvas canvas, double w, double h, {required bool isDog}) {
    final furBase = isDark
        ? (isDog ? const Color(0xFFBB9458) : const Color(0xFFCDAF96))
        : (isDog ? const Color(0xFFD4AA70) : const Color(0xFFE8D4C0));
    final furL = _lit(furBase, boost: 0.14);
    final furD = _shadowed(furBase, darken: 0.32);
    final accent = isDog
        ? _shadowed(const Color(0xFF6B4220), darken: 0.10)
        : const Color(0xFF7A5C4A);

    if (isDog) {
      _drawChibiDog(canvas, w, h, furBase, furL, furD, accent);
    } else {
      _drawChibiCat(canvas, w, h, furBase, furL, furD);
    }
  }

  void _drawChibiDog(
    Canvas canvas,
    double w,
    double h,
    Color fur,
    Color furL,
    Color furD,
    Color accent,
  ) {
    final hcx = w * 0.50;
    final hcy = h * 0.28;
    final hr = w * 0.42;

    // Floppy ears
    for (final isLeft in [true, false]) {
      final ex = isLeft ? hcx - hr * 0.75 : hcx + hr * 0.75;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex, hcy + hr * 0.30),
          width: hr * 0.58,
          height: hr * 1.10,
        ),
        Paint()..color = furD,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex, hcy + hr * 0.32),
          width: hr * 0.32,
          height: hr * 0.68,
        ),
        Paint()..color = accent.withValues(alpha: 0.45),
      );
    }

    // Body
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.70),
      width: w * 0.55,
      height: h * 0.22,
    );
    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          colors: [furD, furL, furD],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(bodyRect),
    );

    // Legs
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * (0.16 + i * 0.22), h * 0.78, w * 0.14, h * 0.12),
          const Radius.circular(7),
        ),
        Paint()..color = furD,
      );
    }

    // Tail
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.84, h * 0.68)
        ..quadraticBezierTo(w * 0.98, h * 0.58, w * 0.92, h * 0.50)
        ..quadraticBezierTo(w * 0.88, h * 0.45, w * 0.80, h * 0.52),
      Paint()
        ..color = furD
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09
        ..strokeCap = StrokeCap.round,
    );

    // Head
    final headRect = Rect.fromCircle(center: Offset(hcx, hcy), radius: hr);
    canvas.drawCircle(
      Offset(hcx, hcy),
      hr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.28, -0.28),
          radius: 0.72,
          colors: [furL, fur, furD],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(headRect),
    );

    // Collar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(hcx, hcy + hr * 0.88),
          width: hr * 0.80,
          height: hr * 0.18,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFE04040),
    );

    final ff = cos(yAngle).abs();
    if (ff > 0.15) {
      for (final side in [-1, 1]) {
        final ex = hcx + side * hr * 0.44;
        final ey = hcy + hr * 0.10;
        final er = hr * 0.22;
        canvas.drawCircle(
          Offset(ex, ey),
          er,
          Paint()..color = Colors.white.withValues(alpha: 0.90 * ff),
        );
        canvas.drawCircle(
          Offset(ex, ey),
          er * 0.65,
          Paint()
            ..color = Color.fromARGB((0.85 * ff * 255).round(), 55, 35, 15),
        );
        canvas.drawCircle(
          Offset(ex, ey),
          er * 0.35,
          Paint()..color = Colors.black.withValues(alpha: 0.88 * ff),
        );
        canvas.drawCircle(
          Offset(ex - er * 0.28, ey - er * 0.28),
          er * 0.20,
          Paint()..color = Colors.white.withValues(alpha: 0.88 * ff),
        );
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(hcx, hcy + hr * 0.50),
          width: hr * 0.32,
          height: hr * 0.20,
        ),
        Paint()..color = const Color(0xFF2C1A0E).withValues(alpha: 0.80 * ff),
      );
      canvas.drawPath(
        Path()
          ..moveTo(hcx - hr * 0.22, hcy + hr * 0.58)
          ..quadraticBezierTo(
            hcx,
            hcy + hr * 0.72,
            hcx + hr * 0.22,
            hcy + hr * 0.58,
          ),
        Paint()
          ..color = const Color(0xFF2C1A0E).withValues(alpha: 0.65 * ff)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
      for (final side in [-1, 1]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(hcx + side * hr * 0.62, hcy + hr * 0.42),
            width: hr * 0.30,
            height: hr * 0.14,
          ),
          Paint()..color = const Color(0xFFE89090).withValues(alpha: 0.22 * ff),
        );
      }
    }
  }

  void _drawChibiCat(
    Canvas canvas,
    double w,
    double h,
    Color fur,
    Color furL,
    Color furD,
  ) {
    final hcx = w * 0.50;
    final hcy = h * 0.26;
    final hr = w * 0.40;

    // Pointed ears
    for (final isLeft in [true, false]) {
      final ex = isLeft ? hcx - hr * 0.72 : hcx + hr * 0.72;
      final tip = Offset(
        ex + (isLeft ? -hr * 0.18 : hr * 0.18),
        hcy - hr * 1.10,
      );
      final b1 = Offset(ex - hr * 0.30, hcy - hr * 0.35);
      final b2 = Offset(ex + hr * 0.30, hcy - hr * 0.35);
      canvas.drawPath(
        Path()
          ..moveTo(b1.dx, b1.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(b2.dx, b2.dy)
          ..close(),
        Paint()..color = furD,
      );
      canvas.drawPath(
        Path()
          ..moveTo(b1.dx + hr * 0.08, b1.dy)
          ..lineTo(tip.dx, tip.dy + hr * 0.14)
          ..lineTo(b2.dx - hr * 0.08, b2.dy)
          ..close(),
        Paint()..color = const Color(0xFFE8A0B0).withValues(alpha: 0.70),
      );
    }

    // Body
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.68),
      width: w * 0.50,
      height: h * 0.20,
    );
    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          colors: [furD, furL, furD],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(bodyRect),
    );

    // Legs
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * (0.18 + i * 0.20), h * 0.76, w * 0.12, h * 0.12),
          const Radius.circular(6),
        ),
        Paint()..color = furD,
      );
    }

    // Tail
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.82, h * 0.66)
        ..cubicTo(w * 1.10, h * 0.62, w * 1.12, h * 0.48, w * 0.88, h * 0.44),
      Paint()
        ..color = furD
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08
        ..strokeCap = StrokeCap.round,
    );

    // Head
    final headRect = Rect.fromCircle(center: Offset(hcx, hcy), radius: hr);
    canvas.drawCircle(
      Offset(hcx, hcy),
      hr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.28, -0.28),
          radius: 0.72,
          colors: [furL, fur, furD],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(headRect),
    );

    // Collar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(hcx, hcy + hr * 0.88),
          width: hr * 0.72,
          height: hr * 0.16,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFE040A0),
    );

    final ff = cos(yAngle).abs();
    if (ff > 0.15) {
      for (final side in [-1, 1]) {
        final ex = hcx + side * hr * 0.44;
        final ey = hcy + hr * 0.08;
        final er = hr * 0.20;
        final eyePath = Path()
          ..moveTo(ex - er * 1.20, ey)
          ..quadraticBezierTo(ex, ey - er * 0.85, ex + er * 1.20, ey)
          ..quadraticBezierTo(ex, ey + er * 0.85, ex - er * 1.20, ey)
          ..close();
        canvas.drawPath(
          eyePath,
          Paint()..color = Colors.white.withValues(alpha: 0.88 * ff),
        );
        canvas.drawCircle(
          Offset(ex, ey),
          er * 0.55,
          Paint()
            ..color = Color.fromARGB((0.85 * ff * 255).round(), 30, 90, 40),
        );
        canvas.drawCircle(
          Offset(ex, ey),
          er * 0.28,
          Paint()..color = Colors.black.withValues(alpha: 0.88 * ff),
        );
        canvas.drawCircle(
          Offset(ex - er * 0.24, ey - er * 0.24),
          er * 0.18,
          Paint()..color = Colors.white.withValues(alpha: 0.88 * ff),
        );
      }
      // Nose
      canvas.drawPath(
        Path()
          ..moveTo(hcx, hcy + hr * 0.44)
          ..lineTo(hcx - hr * 0.10, hcy + hr * 0.52)
          ..lineTo(hcx + hr * 0.10, hcy + hr * 0.52)
          ..close(),
        Paint()..color = const Color(0xFFE090A0).withValues(alpha: 0.80 * ff),
      );
      // Whiskers
      final wPaint = Paint()
        ..color = furD.withValues(alpha: 0.38 * ff)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round;
      for (final side in [-1, 1]) {
        for (int i = 0; i < 3; i++) {
          final wy = hcy + hr * (0.42 + i * 0.10);
          canvas.drawLine(
            Offset(hcx + side * hr * 0.10, wy),
            Offset(hcx + side * hr * 0.85, wy + i * hr * 0.04),
            wPaint,
          );
        }
      }
      // Mouth
      canvas.drawPath(
        Path()
          ..moveTo(hcx - hr * 0.16, hcy + hr * 0.58)
          ..quadraticBezierTo(
            hcx,
            hcy + hr * 0.70,
            hcx + hr * 0.16,
            hcy + hr * 0.58,
          ),
        Paint()
          ..color = const Color(0xFF2C1A0E).withValues(alpha: 0.50 * ff)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
      // Blush
      for (final side in [-1, 1]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(hcx + side * hr * 0.60, hcy + hr * 0.42),
            width: hr * 0.28,
            height: hr * 0.12,
          ),
          Paint()..color = const Color(0xFFE89090).withValues(alpha: 0.20 * ff),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FashionFigurePainter old) =>
      old.yAngle != yAngle ||
      old.avatarType != avatarType ||
      old.bodyShape != bodyShape ||
      old.isDark != isDark ||
      old.skinToneIndex != skinToneIndex ||
      old.hairColorIndex != hairColorIndex ||
      old.hairStyleIndex != hairStyleIndex;
}
