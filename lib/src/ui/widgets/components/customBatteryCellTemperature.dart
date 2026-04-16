import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/appColors.dart';

/// Glass-only 3D Thermometer
/// Mercury rises continuously from bulb → tube → top
/// Temperature label dynamically displayed under the bulb
/// Dynamic status label under the temperature value
class Thermometer3D extends StatelessWidget {
  final double temperature; // current temperature in °C
  final double minTemp;
  final double maxTemp;
  final double height;
  final double width;
  final Duration animationDuration;
  final String? label;

  const Thermometer3D({
    Key? key,
    required this.temperature,
    this.minTemp = 15,
    this.maxTemp = 45,
    this.height = 320,
    this.width = 90,
    this.animationDuration = const Duration(milliseconds: 600),
    this.label,
  }) : super(key: key);

  double _clampedFraction() {
    final t = temperature.clamp(minTemp, maxTemp);
    return (t - minTemp) / (maxTemp - minTemp);
  }

  @override
  Widget build(BuildContext context) {
    final frac = _clampedFraction();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: width,
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: frac),
        duration: animationDuration,
        curve: Curves.easeOutCubic,
        builder: (context, animatedFrac, _) {
          return CustomPaint(
            painter: _ThermometerPainter(
              fraction: animatedFrac,
              minTemp: minTemp,
              maxTemp: maxTemp,
              currentTemp: temperature,
              isDark: isDark,
              label: label,
            ),
            size: Size(width, height),
          );
        },
      ),
    );
  }
}

class _ThermometerPainter extends CustomPainter {
  final double fraction;
  final double minTemp;
  final double maxTemp;
  final double currentTemp;
  final bool isDark;
  final String? label;

  _ThermometerPainter({
    required this.fraction,
    required this.minTemp,
    required this.maxTemp,
    required this.currentTemp,
    required this.isDark,
    this.label,
  });

  // Color mapping based on temperature
  Color _colorForTemp(double t) {
    if (t < 20) return tBlue;
    if (t < 30) return tGreen3;
    if (t < 38) return tOrange1;
    return tRed;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Geometry
    final bulbRadius = w * 0.3;
    final tubeWidth = w * 0.3;
    final tubeLeft = (w - tubeWidth) / 2;
    final tubeRight = tubeLeft + tubeWidth;
    final tubeTop = h * 0.06;
    final bulbCenter = Offset(w / 2, h - bulbRadius - 40);
    final tubeBottom = bulbCenter.dy + bulbRadius * 0.35;

    // ----- Metallic outer shell -----
    final metallicPath = Path();
    metallicPath.addOval(
      Rect.fromCircle(center: bulbCenter, radius: bulbRadius),
    );
    metallicPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(tubeLeft, tubeTop, tubeRight, tubeBottom),
        Radius.circular(tubeWidth * 0.8),
      ),
    );

    final metallicPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, tubeTop),
            Offset(0, tubeBottom),
            [
              Colors.grey.shade300,
              Colors.grey.shade100,
              Colors.grey.shade400,
              Colors.grey.shade200,
            ],
            [0.0, 0.3, 0.7, 1.0],
          )
          ..style = PaintingStyle.fill;
    canvas.drawPath(metallicPath, metallicPaint);

    // 3D highlight for metallic effect
    final highlightPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(tubeLeft, tubeTop),
            Offset(tubeRight, tubeBottom),
            [Colors.white.withOpacity(0.4), Colors.transparent],
          )
          ..blendMode = BlendMode.lighten;
    canvas.drawPath(metallicPath, highlightPaint);

    // ----- Glass inner layer for mercury -----
    final glassPath = Path();
    glassPath.addOval(
      Rect.fromCircle(center: bulbCenter, radius: bulbRadius * 0.85),
    );
    final neckRect = Rect.fromCenter(
      center: Offset(w / 2, bulbCenter.dy - bulbRadius * 0.55),
      width: tubeWidth * 1.1,
      height: bulbRadius * 0.8,
    );
    glassPath.addOval(neckRect);
    final tubeRect = Rect.fromLTRB(tubeLeft, tubeTop, tubeRight, tubeBottom);
    glassPath.addRRect(
      RRect.fromRectAndRadius(tubeRect, Radius.circular(tubeWidth * 0.6)),
    );

    final glassPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(tubeLeft, tubeTop),
            Offset(tubeRight, tubeBottom),
            [
              Colors.grey.shade100.withOpacity(0.9),
              Colors.grey.shade300.withOpacity(0.9),
            ],
          )
          ..style = PaintingStyle.fill;
    canvas.drawPath(glassPath, glassPaint);

    // ----- Mercury -----
    canvas.save();
    canvas.clipPath(glassPath);
    final bulbBottom = bulbCenter.dy + bulbRadius;
    final fullHeight = bulbBottom - tubeTop;
    final mercuryTopY = bulbBottom - fullHeight * fraction;

    final mercuryRect = Rect.fromLTRB(
      tubeLeft - w * 0.15,
      mercuryTopY,
      tubeRight + w * 0.15,
      bulbBottom + h * 0.2,
    );

    final mercuryPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(mercuryRect.left, mercuryRect.top),
            Offset(mercuryRect.right, mercuryRect.bottom),
            [
              _colorForTemp(currentTemp).withOpacity(0.95),
              _colorForTemp(currentTemp).withOpacity(0.75),
            ],
          )
          ..style = PaintingStyle.fill;

    canvas.drawRect(mercuryRect, mercuryPaint);

    // Inner glossy highlight
    final innerHighlight =
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(tubeLeft, tubeTop),
            Offset(tubeRight, tubeTop),
            [Colors.white.withOpacity(0.36), Colors.transparent],
          )
          ..blendMode = BlendMode.lighten;

    canvas.drawRect(tubeRect.deflate(tubeWidth * 0.55), innerHighlight);
    canvas.restore();

    // ----- Temperature value text -----
    final labelOffsetY = bulbCenter.dy + bulbRadius + 8;
    final tempPainter = TextPainter(
      text: TextSpan(
        text: "${currentTemp.toStringAsFixed(1)}°C",
        style: GoogleFonts.urbanist(
          fontSize: w * 0.14,
          fontWeight: FontWeight.w600,
          color: isDark ? tWhite : tBlack,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tempPainter.layout();
    tempPainter.paint(
      canvas,
      Offset((w - tempPainter.width) / 2, labelOffsetY),
    );

    // Dynamic label under temperature
    if (label != null) {
      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.urbanist(
            fontSize: w * 0.12,
            fontWeight: FontWeight.w600,
            color: isDark ? tWhite.withOpacity(0.8) : tBlack.withOpacity(0.8),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          (w - labelPainter.width) / 2,
          labelOffsetY + tempPainter.height + 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThermometerPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.currentTemp != currentTemp ||
      oldDelegate.isDark != isDark;
}
