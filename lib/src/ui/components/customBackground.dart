// import 'dart:math';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';

// class FuturisticHudBackground extends StatefulWidget {
//   const FuturisticHudBackground({super.key});

//   @override
//   State<FuturisticHudBackground> createState() =>
//       _FuturisticHudBackgroundState();
// }

// class _FuturisticHudBackgroundState extends State<FuturisticHudBackground>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//   late final List<_Particle> _particles;
//   final int _particleCount = 60;

//   @override
//   void initState() {
//     super.initState();

//     // Animation controller drives everything. Long duration for slow motion.
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 12),
//     )..repeat();

//     // Initialize lightweight particle data once
//     final rng = Random(1234);
//     _particles = List.generate(_particleCount, (i) {
//       final t = rng.nextDouble();
//       return _Particle(
//         angle: rng.nextDouble() * 2 * pi,
//         radiusFactor: 0.15 + rng.nextDouble() * 0.85,
//         speed: 0.0006 + rng.nextDouble() * 0.0018,
//         size: 1.0 + rng.nextDouble() * 2.6,
//         oscillation: 0.2 + rng.nextDouble() * 0.6,
//         baseOffset: Offset(rng.nextDouble(), rng.nextDouble()),
//         hue: (200 + rng.nextInt(120)) % 360,
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, _) {
//         return CustomPaint(
//           painter: _HudPainter(
//             progress: _controller.value,
//             isDark: isDark,
//             particles: _particles,
//           ),
//           child: Container(),
//         );
//       },
//     );
//   }
// }

// /// Particle lightweight model
// class _Particle {
//   double angle;
//   double radiusFactor; // 0..1 (relative to radius)
//   double speed; // angular speed multiplier
//   double size;
//   double oscillation;
//   Offset baseOffset; // small offset to jitter
//   int hue; // color hue

//   _Particle({
//     required this.angle,
//     required this.radiusFactor,
//     required this.speed,
//     required this.size,
//     required this.oscillation,
//     required this.baseOffset,
//     required this.hue,
//   });
// }

// /// Main painter that composes layers
// class _HudPainter extends CustomPainter {
//   final double progress; // 0..1
//   final bool isDark;
//   final List<_Particle> particles;

//   _HudPainter({
//     required this.progress,
//     required this.isDark,
//     required this.particles,
//   });

//   final Paint _gridPaint = Paint()..style = PaintingStyle.stroke;
//   final Paint _circlePaint = Paint()..style = PaintingStyle.stroke;
//   final Paint _neonPaint = Paint()..style = PaintingStyle.stroke;
//   final Paint _meshPaint = Paint()..style = PaintingStyle.stroke;
//   final Paint _trianglePaint = Paint()..style = PaintingStyle.fill;
//   final Paint _dangerPaint = Paint()..style = PaintingStyle.fill;
//   final Paint _particlePaint = Paint()..style = PaintingStyle.fill;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width * 0.5, size.height * 0.42);
//     final radius = min(size.width, size.height) * 0.46;

//     // Parallax offset: subtle slow movement
//     final parallaxX = sin(progress * 2 * pi) * (size.width * 0.01);
//     final parallaxY = cos(progress * 2 * pi * 0.7) * (size.height * 0.008);
//     canvas.save();
//     canvas.translate(parallaxX, parallaxY);

//     _drawBackgroundGradient(canvas, size);
//     _drawGrid(canvas, size);
//     _drawConcentricCircles(canvas, center, radius);
//     _drawRadarSweep(canvas, center, radius);
//     _drawFovTriangle(canvas, center, radius);
//     _drawDangerZone(canvas, center, radius);
//     _drawNeonCircuitLines(canvas, size, center, radius);
//     _draw3dMesh(canvas, size, center, radius);
//     _drawParticles(canvas, size, center, radius);

//     canvas.restore();
//   }

//   void _drawBackgroundGradient(Canvas canvas, Size size) {
//     final rect = Offset.zero & size;
//     final g = ui.Gradient.radial(
//       Offset(size.width * 0.5, size.height * 0.4),
//       max(size.width, size.height) * 0.9,
//       [_colorFromHue(210, 0.06), _colorFromHue(210, 0.02)],
//     );
//     final paint = Paint()..shader = g;
//     canvas.drawRect(rect, paint);
//   }

//   void _drawGrid(Canvas canvas, Size size) {
//     // Grid lines
//     final step = 36.0;
//     _gridPaint
//       ..color = (isDark ? Colors.blueAccent : Colors.blue).withOpacity(0.06)
//       ..strokeWidth = 1.0;
//     for (double x = 0; x <= size.width; x += step) {
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
//     }
//     for (double y = 0; y <= size.height; y += step) {
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
//     }

//     // Scanning horizontal band (animated moving scanline)
//     final bandHeight = 28.0;
//     final bandY = (size.height + bandHeight) * (progress % 1.0) - bandHeight;
//     final bandRect = Rect.fromLTWH(0, bandY, size.width, bandHeight);
//     final bandPaint =
//         Paint()
//           ..shader = ui.Gradient.linear(bandRect.topLeft, bandRect.topRight, [
//             Colors.transparent,
//             _colorFromHue(200, 0.06),
//             Colors.transparent,
//           ]);
//     canvas.drawRect(bandRect, bandPaint);
//   }

//   void _drawConcentricCircles(Canvas canvas, Offset center, double radius) {
//     _circlePaint
//       ..color = _colorFromHue(200, 0.10)
//       ..strokeWidth = 1.6;

//     for (int i = 1; i <= 4; i++) {
//       canvas.drawCircle(center, radius * (i / 4), _circlePaint);
//     }
//   }

//   void _drawRadarSweep(Canvas canvas, Offset center, double radius) {
//     final sweepAngle = progress * 2 * pi;
//     final sweepPaint =
//         Paint()
//           ..shader = ui.Gradient.sweep(
//             center,
//             [
//               _colorFromHue(195, 0.28),
//               _colorFromHue(195, 0.12),
//               Colors.transparent,
//             ],
//             [0.0, 0.55, 1.0],
//             TileMode.clamp,
//           )
//           ..blendMode = BlendMode.plus;

//     canvas.save();
//     canvas.translate(center.dx, center.dy);
//     canvas.rotate(sweepAngle);
//     canvas.drawArc(
//       Rect.fromCircle(center: Offset.zero, radius: radius),
//       0,
//       pi * 0.26,
//       true,
//       sweepPaint,
//     );
//     canvas.restore();

//     // small sweep tip glow
//     final tipAngle = sweepAngle + (pi * 0.13);
//     final tip = Offset(
//       center.dx + cos(tipAngle) * radius * 0.95,
//       center.dy + sin(tipAngle) * radius * 0.95,
//     );
//     final tipPaint =
//         Paint()
//           ..color = _colorFromHue(190, 0.85)
//           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
//     canvas.drawCircle(tip, 6.0, tipPaint);
//   }

//   void _drawFovTriangle(Canvas canvas, Offset center, double radius) {
//     // A triangular Field-of-View cone in front of the 'car' (center bottom area)
//     // We'll create a triangle pointing downward from center area
//     final coneLength = radius * 1.05;
//     final coneHalfWidth = radius * 0.25;
//     final angleCenter = -pi / 2; // pointing upward? adjust to taste
//     final p1 = center.translate(0, radius * 0.25);
//     final p2 = Offset(
//       p1.dx + cos(angleCenter - 0.25) * coneLength,
//       p1.dy + sin(angleCenter - 0.25) * coneLength,
//     );
//     final p3 = Offset(
//       p1.dx + cos(angleCenter + 0.25) * coneLength,
//       p1.dy + sin(angleCenter + 0.25) * coneLength,
//     );

//     // fill with semi-transparent gradient
//     final path =
//         Path()
//           ..moveTo(p1.dx, p1.dy)
//           ..lineTo(p2.dx, p2.dy)
//           ..lineTo(p3.dx, p3.dy)
//           ..close();

//     final gradient = ui.Gradient.linear(
//       p1,
//       Offset(center.dx, center.dy - radius * 0.8),
//       [_colorFromHue(180, 0.12), _colorFromHue(180, 0.02)],
//     );
//     _trianglePaint..shader = gradient as ui.Gradient?;
//     canvas.drawPath(path, _trianglePaint);

//     // triangle border neon
//     _neonPaint
//       ..shader = ui.Gradient.linear(p2, p3, [
//         _colorFromHue(180, 0.6),
//         _colorFromHue(250, 0.7),
//       ])
//       ..strokeWidth = 1.4
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
//     canvas.drawPath(
//       Path()
//         ..moveTo(p2.dx, p2.dy)
//         ..lineTo(p1.dx, p1.dy)
//         ..lineTo(p3.dx, p3.dy),
//       _neonPaint,
//     );
//   }

//   void _drawDangerZone(Canvas canvas, Offset center, double radius) {
//     // Danger zone: a red sector near bottom-right of the HUD to indicate approaching hazard
//     final start = progress * 2 * pi * 0.6 + pi / 6;
//     final sweep = pi * 0.18;
//     final r = radius * 0.72;
//     final dangerPaint =
//         Paint()
//           ..shader = ui.Gradient.radial(center, r * 1.2, [
//             Colors.transparent,
//             _colorFromHue(10, 0.14),
//             _colorFromHue(10, 0.28),
//           ])
//           ..blendMode = BlendMode.multiply;
//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: r),
//       start,
//       sweep,
//       true,
//       dangerPaint,
//     );

//     // danger rim
//     final rimPaint =
//         Paint()
//           ..color = Colors.redAccent.withOpacity(0.65)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 2.0
//           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: r),
//       start,
//       sweep,
//       false,
//       rimPaint,
//     );
//   }

//   void _drawNeonCircuitLines(
//     Canvas canvas,
//     Size size,
//     Offset center,
//     double radius,
//   ) {
//     // Simple stylized neon "circuit" paths emanating from center
//     _meshPaint
//       ..color = _colorFromHue(200, 0.25)
//       ..strokeWidth = 0.9;

//     final pathCount = 5;
//     final rng = Random(42);
//     for (int i = 0; i < pathCount; i++) {
//       final angle =
//           (i / pathCount) * 2 * pi + sin(progress * 2 * pi + i) * 0.08;
//       final start = Offset(
//         center.dx + cos(angle) * radius * 0.55,
//         center.dy + sin(angle) * radius * 0.55,
//       );
//       final mid = Offset(
//         start.dx + cos(angle + 0.6) * radius * 0.15,
//         start.dy + sin(angle + 0.6) * radius * 0.12,
//       );
//       final end = Offset(
//         start.dx + cos(angle) * radius * (0.9 + rng.nextDouble() * 0.15),
//         start.dy + sin(angle) * radius * (0.9 + rng.nextDouble() * 0.15),
//       );

//       final path =
//           Path()
//             ..moveTo(start.dx, start.dy)
//             ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
//       // neon glow stroke
//       _neonPaint
//         ..shader = ui.Gradient.linear(start, end, [
//           _colorFromHue(200 + i * 8, 0.7),
//           _colorFromHue(260 - i * 12, 0.7),
//         ])
//         ..strokeWidth = 1.4
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
//       canvas.drawPath(path, _neonPaint);

//       // fine inner line
//       _meshPaint..color = _colorFromHue(200 + i * 6, 0.18);
//       _meshPaint.strokeWidth = 0.8;
//       canvas.drawPath(path, _meshPaint);
//     }
//   }

//   void _draw3dMesh(Canvas canvas, Size size, Offset center, double radius) {
//     // Stylized 3D mesh: radial lines + arcs to imply depth
//     _meshPaint
//       ..color = _colorFromHue(210, 0.08)
//       ..strokeWidth = 0.8;

//     final rings = 6;
//     for (int r = 1; r <= rings; r++) {
//       final rr = radius * (r / rings) * 0.98;
//       canvas.drawArc(
//         Rect.fromCircle(center: center, radius: rr),
//         -pi / 2,
//         pi,
//         false,
//         _meshPaint,
//       );
//     }

//     // radial spokes
//     for (int s = 0; s < 24; s++) {
//       final a = (s / 24) * pi - pi / 2 + sin(progress * 2 * pi + s) * 0.02;
//       final p = Offset(
//         center.dx + cos(a) * radius,
//         center.dy + sin(a) * radius * 0.5,
//       );
//       canvas.drawLine(center, p, _meshPaint);
//     }
//   }

//   void _drawParticles(Canvas canvas, Size size, Offset center, double radius) {
//     final t = progress * 2 * pi;
//     for (var p in particles) {
//       // update angle per-frame (without modifying list too much)
//       final angle = p.angle + t * p.speed * 30;
//       final rr =
//           radius *
//           p.radiusFactor *
//           (0.45 +
//               0.55 *
//                   (0.5 + 0.5 * sin(t * p.oscillation + p.baseOffset.dx * 10)));
//       final pos = Offset(
//         center.dx + cos(angle) * rr + (p.baseOffset.dx - 0.5) * 10,
//         center.dy + sin(angle) * rr + (p.baseOffset.dy - 0.5) * 8,
//       );

//       // shimmer size & alpha
//       final alpha = 0.3 + 0.7 * (0.5 + 0.5 * sin(t * (1.0 + p.oscillation)));
//       final col =
//           HSVColor.fromAHSV(alpha, p.hue.toDouble(), 0.85, 0.95).toColor();
//       _particlePaint.color = col;
//       canvas.drawCircle(pos, p.size, _particlePaint);

//       // trailing glow for some particles
//       if (p.size > 2.0) {
//         final glow =
//             Paint()
//               ..color = col.withOpacity(0.08)
//               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
//         canvas.drawCircle(pos, p.size * 3.2, glow);
//       }
//     }
//   }

//   Color _colorFromHue(int hue, double opacity) {
//     final c =
//         HSVColor.fromAHSV(
//           opacity,
//           hue.toDouble() % 360,
//           0.6,
//           isDark ? 0.9 : 0.85,
//         ).toColor();
//     return c;
//   }

//   @override
//   bool shouldRepaint(covariant _HudPainter oldDelegate) => true;
// }

import 'dart:math';

import 'package:flutter/material.dart';

class TechGridPainter extends CustomPainter {
  final double tick;
  final bool isDark;

  TechGridPainter({required this.tick, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    final gridColor = (isDark ? Colors.white : Colors.black).withOpacity(0.02);

    paint.color = gridColor;

    // slight offset animation
    final offset = tick * 40;

    final double step = 28;
    for (double x = -step + (offset % step); x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -step + (offset % step); y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // bold center axis lines (subtle)
    final centerPaint =
        Paint()
          ..color = (isDark ? Colors.tealAccent : Colors.orangeAccent)
              .withOpacity(0.02)
          ..strokeWidth = 1.6;
    // vertical center
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.25, size.height),
      centerPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, 0),
      Offset(size.width * 0.6, size.height),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TechGridPainter oldDelegate) =>
      oldDelegate.tick != tick;
}

class ScanningLinesPainter extends CustomPainter {
  final double offset;

  ScanningLinesPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // draw 3 thin scanning lines with gradient alpha that move horizontally
    final lineHeight = 2.2;
    for (int i = 0; i < 4; i++) {
      final progress = (offset + i * 0.18) % 1.0;
      final y = size.height * (0.12 + i * 0.22);
      final startX = -size.width * 0.6 + (size.width * 1.6 * progress);
      final rect = Rect.fromLTWH(startX, y, size.width * 0.6, lineHeight);
      final g = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.06),
          Colors.white.withOpacity(0.0),
        ],
      );
      paint.shader = g.createShader(rect);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ScanningLinesPainter oldDelegate) =>
      oldDelegate.offset != offset;
}

class RadarSweepPainter extends CustomPainter {
  final double rotation;
  final Color color;
  final bool isDark;

  RadarSweepPainter({
    required this.rotation,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.45;

    // base circle rings
    final ringPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withOpacity(0.10);

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3), ringPaint);
    }

    // rotating sweep (a soft arc)
    final sweepPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withOpacity(0.45),
              color.withOpacity(0.14),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.plus;

    // arc path
    final path = Path();
    final sweepAngle = pi / 2.2; // ~80 degrees arc
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      rotation - sweepAngle / 2,
      sweepAngle,
      false,
    );
    path.close();

    canvas.drawPath(path, sweepPaint);

    // center dot
    final dotPaint = Paint()..color = color.withOpacity(0.9);
    canvas.drawCircle(center, 4.8, dotPaint);

    // small blips (simulate detected objects) - stationary for low perf
    final blipPaint = Paint()..color = Colors.redAccent.withOpacity(0.86);
    final blipAng = rotation + 0.9;
    final blipPos = Offset(
      center.dx + cos(blipAng) * radius * 0.62,
      center.dy + sin(blipAng) * radius * 0.62,
    );
    canvas.drawCircle(
      blipPos,
      6,
      blipPaint..color = Colors.orangeAccent.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant RadarSweepPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

class FloatingShape extends StatelessWidget {
  final Animation<double> anim;
  final Widget child;
  final double size;
  final double speed;
  final double amplitude;

  const FloatingShape({
    super.key,
    required this.anim,
    required this.child,
    this.size = 100,
    this.speed = 1.0,
    this.amplitude = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final t = anim.value * 2 * pi * speed;
        final dx = sin(t * 0.9) * amplitude;
        final dy = cos(t * 1.1) * (amplitude / 2);
        final r = sin(t * 0.6) * 0.06;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(angle: r, child: child),
        );
      },
    );
  }
}
