import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../../../utils/appColors.dart';

class Real3DBatteryVertical extends StatefulWidget {
  final double voltage;
  final double width;
  final double height;
  final Duration duration;
  final bool isDark;
  final String? label;
  const Real3DBatteryVertical({
    super.key,
    required this.voltage,
    this.width = 180,
    this.height = 380,
    this.duration = const Duration(milliseconds: 600),
    this.isDark = true,
    this.label,
  });

  @override
  State<Real3DBatteryVertical> createState() => _Real3DBatteryVerticalState();
}

class _Real3DBatteryVerticalState extends State<Real3DBatteryVertical>
    with SingleTickerProviderStateMixin {
  late AnimationController pulseController;

  @override
  void initState() {
    super.initState();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 3.0, end: widget.voltage),
      duration: widget.duration,
      curve: Curves.easeInOutCubic,
      builder: (_, animatedV, __) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _BatteryPainter(
            voltage: animatedV,
            pulse: pulseController.value,
            isDark: isDark,
            label: widget.label,
          ),
        );
      },
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final double voltage;
  final double pulse;
  final bool isDark;
  final String? label;
  _BatteryPainter({
    required this.voltage,
    required this.pulse,
    required this.isDark,
    this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width * 0.42;
    final double metalThickness = size.width * 0.07;

    // Voltage Limits
    const double minV = 3.0;
    const double maxV = 4.5;

    final double v = voltage.clamp(2.5, 4.8);
    final double normalized = ((v - minV) / (maxV - minV)).clamp(0, 1);

    // ----------- SOLID COLOR FILL -----------
    Color getFill(double v) {
      if (v > 4.50) return tBlue; // over-voltage
      if (v <= 3.4) return tRedDark;
      if (v <= 3.8) return tOrange1;
      if (v <= 4.2) return tGreen2;
      return tGreen3;
    }

    final Color fillColor = getFill(v);

    double glow = 12 + (normalized * 22) + pulse * 8;

    // ========================================================
    // 🔘 TOP CAP (unchanged)
    // ========================================================
    final double capHeight = metalThickness * 1.5;

    final topCapRect = Rect.fromLTWH(
      size.width * 0.32,
      -capHeight + 4,
      size.width * 0.35,
      capHeight,
    );

    final topCapPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade200,
              Colors.grey.shade800,
              Colors.grey.shade300,
            ],
          ).createShader(topCapRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(topCapRect, Radius.circular(20)),
      topCapPaint,
    );

    // ========================================================
    // 🔲 STRONG 3D METAL OUTER BODY (kept)
    // ========================================================
    final bodyRect = Rect.fromLTWH(
      size.width * 0.07,
      metalThickness * 1.2,
      size.width * 0.86,
      size.height - metalThickness * 2.8,
    );

    final outerRect = Rect.fromLTWH(
      bodyRect.left - (size.width * 0.03),
      bodyRect.top - (size.width * 0.03),
      bodyRect.width + (size.width * 0.06),
      bodyRect.height + (size.width * 0.06),
    );

    final outerBorderPaint =
        Paint()
          ..shader = LinearGradient(
            colors:
                isDark
                    ? [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade500,
                      Colors.grey.shade200,
                    ]
                    : [
                      Colors.grey.shade900,
                      Colors.grey.shade600,
                      Colors.grey.shade400,
                      Colors.grey.shade700,
                    ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(outerRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.04;

    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, Radius.circular(radius * 0.5)),
      outerBorderPaint,
    );

    // ========================================================
    // 🟩 SOLID FILL (no gradient, neon glow)
    // ========================================================
    final double fillHeight = bodyRect.height * normalized;

    final fillRect = Rect.fromLTWH(
      bodyRect.left,
      bodyRect.bottom - fillHeight,
      bodyRect.width,
      fillHeight,
    );

    final fillPaint =
        Paint()
          ..color = fillColor
          ..maskFilter = MaskFilter.blur(BlurStyle.inner, glow);

    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, Radius.circular(radius * 0.4)),
      fillPaint,
    );

    // ========================================================
    // 🔘 BOTTOM METAL CAP
    // ========================================================
    final bottomCapRect = Rect.fromLTWH(
      size.width * 0.07,
      bodyRect.bottom,
      size.width * 0.86,
      metalThickness * 1.4,
    );

    final bottomCapPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade300,
              Colors.grey.shade700,
              Colors.grey.shade200,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bottomCapRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bottomCapRect, Radius.circular(radius)),
      bottomCapPaint,
    );

    // ========================================================
    // 🔢 VOLTAGE TEXT INSIDE BATTERY
    // ========================================================
    final textPainter = TextPainter(
      text: TextSpan(
        text: "${v.toStringAsFixed(2)} V",
        style: GoogleFonts.urbanist(
          color: isDark ? tWhite : tBlack,
          fontSize: size.width * 0.15,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: fillColor.withOpacity(0.9), blurRadius: 18)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    // define the offset here so label can use it
    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      bodyRect.top + (bodyRect.height * 0.40),
    );

    textPainter.paint(canvas, textOffset);

    // 🏷️ LABEL BELOW VOLTAGE (if provided)
    if (label != null) {
      final labelPainter = TextPainter(
        text: TextSpan(
          text: label!,
          style: GoogleFonts.urbanist(
            color: isDark ? tWhite.withOpacity(0.8) : tBlack.withOpacity(0.8),
            fontSize: size.width * 0.12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();

      final labelOffset = Offset(
        (size.width - labelPainter.width) / 2,
        textOffset.dy + textPainter.height + 6, // 6 px gap
      );
      labelPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
