import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedShapesBackground extends StatefulWidget {
  const AnimatedShapesBackground({super.key});

  @override
  State<AnimatedShapesBackground> createState() =>
      _AnimatedShapesBackgroundState();
}

class _AnimatedShapesBackgroundState extends State<AnimatedShapesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Shape> _shapes;

  final int numShapes = 20; // number of shapes

  //Define a soft color palette (you can tweak this)
  final List<Color> colorPalette = [
    Colors.white70,
    Colors.cyanAccent,
    Colors.purpleAccent,
    Colors.blueAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
    Colors.amberAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    final random = Random();
    _shapes = List.generate(numShapes, (index) {
      final type = ShapeType.values[random.nextInt(ShapeType.values.length)];
      final dx = random.nextDouble();
      final dy = random.nextDouble();
      final size = 20 + random.nextDouble() * 60;
      final speed = 0.1 + random.nextDouble() * 0.5;
      final color = colorPalette[random.nextInt(colorPalette.length)];
      return _Shape(type, dx, dy, size, speed, color);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ShapesPainter(_shapes, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

enum ShapeType { circle, square, triangle, diamond, hexagon }

class _Shape {
  final ShapeType type;
  final double dx;
  final double dy;
  final double size;
  final double speed;
  final Color color;

  _Shape(this.type, this.dx, this.dy, this.size, this.speed, this.color);
}

class _ShapesPainter extends CustomPainter {
  final List<_Shape> shapes;
  final double progress;

  _ShapesPainter(this.shapes, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var shape in shapes) {
      final offsetY = (shape.dy + progress * shape.speed) % 1.0;
      final offsetX = (shape.dx + progress * shape.speed * 0.3) % 1.0;
      final offset = Offset(offsetX * size.width, offsetY * size.height);
      paint.color = shape.color;

      switch (shape.type) {
        case ShapeType.circle:
          canvas.drawCircle(offset, shape.size / 2, paint);
          break;
        case ShapeType.square:
          final rect = Rect.fromCenter(
            center: offset,
            width: shape.size,
            height: shape.size,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(8)),
            paint,
          );
          break;
        case ShapeType.triangle:
          final path =
              Path()
                ..moveTo(offset.dx, offset.dy - shape.size / 2)
                ..lineTo(offset.dx - shape.size / 2, offset.dy + shape.size / 2)
                ..lineTo(offset.dx + shape.size / 2, offset.dy + shape.size / 2)
                ..close();
          canvas.drawPath(path, paint);
          break;
        case ShapeType.diamond:
          final path =
              Path()
                ..moveTo(offset.dx, offset.dy - shape.size / 2)
                ..lineTo(offset.dx - shape.size / 2, offset.dy)
                ..lineTo(offset.dx, offset.dy + shape.size / 2)
                ..lineTo(offset.dx + shape.size / 2, offset.dy)
                ..close();
          canvas.drawPath(path, paint);
          break;
        case ShapeType.hexagon:
          final path = Path();
          for (int i = 0; i < 6; i++) {
            final angle = (pi / 3) * i;
            final x = offset.dx + shape.size / 2 * cos(angle);
            final y = offset.dy + shape.size / 2 * sin(angle);
            if (i == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }
          path.close();
          canvas.drawPath(path, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
