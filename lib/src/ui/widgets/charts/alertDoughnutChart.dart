import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:svg_flutter/svg.dart';

import '../../../utils/appColors.dart';

class AlertsDonutChart extends StatelessWidget {
  final int critical;
  final int nonCritical;
  final int avgCritical;
  final int avgNonCritical;
  final String title;

  const AlertsDonutChart({
    super.key,
    required this.critical,
    required this.nonCritical,
    required this.avgCritical,
    required this.avgNonCritical,
    this.title = "Critical & Non-Critical Alerts",
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasData = critical > 0 || nonCritical > 0;

    return Column(
      children: [
        /// Title
        Row(
          children: [
            SvgPicture.asset(
              'icons/pie_chart.svg',
              height: 16,
              width: 16,
              color: isDark ? tWhite : tBlack,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        /// Donut Chart
        Expanded(
          child: CircularDoughnutChart(
            values:
                hasData ? [critical.toDouble(), nonCritical.toDouble()] : [1],
            colors: hasData ? [tOrange, tBlueSky] : [Colors.grey],
            labels: hasData ? ["Critical", "Non-Critical"] : ["No Data"],
            centerText: NumberFormat('#,##,###').format(critical + nonCritical),
            centerSubText: hasData ? "Total Alerts" : "No Data",
            strokeWidth: 30,
          ),
        ),

        if (hasData) ...[
          const SizedBox(height: 10),

          Text(
            "Critical: $avgCritical%   •   Non-Critical: $avgNonCritical%",
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ],
      ],
    );
  }
}

class CircularLegendItem {
  final String label;
  final Color color;
  final double value;

  const CircularLegendItem({
    required this.label,
    required this.color,
    required this.value,
  });
}

class CircularDoughnutChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final List<String> labels;
  final double strokeWidth;
  final String? centerText;
  final String? centerSubText;
  final double gap;

  const CircularDoughnutChart({
    super.key,
    required this.values,
    required this.colors,
    required this.labels,
    this.strokeWidth = 20,
    this.centerText,
    this.centerSubText,
    this.gap = 2,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (_, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _CircularDoughnutPainter(
                values: values,
                colors: colors,
                labels: labels,
                strokeWidth: strokeWidth,
                gap: gap,
                textColor: isDark ? tWhite : tBlack,
              ),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerText ?? "",
                  style: GoogleFonts.urbanist(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),

                if (centerSubText != null)
                  Text(
                    centerSubText!,
                    style: GoogleFonts.urbanist(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CircularDoughnutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final List<String> labels;
  final double strokeWidth;
  final double gap;
  final Color textColor;

  _CircularDoughnutPainter({
    required this.values,
    required this.colors,
    required this.labels,
    required this.strokeWidth,
    required this.gap,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);

    // if (total == 0) return;

    // REMOVE ZERO VALUES
    final filteredItems = <Map<String, dynamic>>[];

    for (int i = 0; i < values.length; i++) {
      if (values[i] > 0) {
        filteredItems.add({
          "value": values[i],
          "color": colors[i],
          "label": labels[i],
        });
      }
    }

    final filteredValues =
        filteredItems.map((e) => e["value"] as double).toList();

    final filteredColors =
        filteredItems.map((e) => e["color"] as Color).toList();

    final filteredLabels =
        filteredItems.map((e) => e["label"] as String).toList();

    final center = size.center(Offset.zero);

    // final radius = (size.width / 2) - strokeWidth;
    final radius = size.width * 0.35;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // DEFAULT BACKGROUND RING
    final backgroundPaint =
        Paint()
          ..color = textColor.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt
          ..isAntiAlias = true;

    // Draw full circle background
    canvas.drawArc(rect, 0, 2 * pi, false, backgroundPaint);

    double startAngle = -pi / 2;

    if (filteredItems.isEmpty) {
      return;
    }
    // for (int i = 0; i < values.length; i++) {
    for (int i = 0; i < filteredValues.length; i++) {
      // final sweepAngle = (values[i] / total) * (2 * pi);
      final sweepAngle = (filteredValues[i] / total) * (2 * pi);

      final adjustedSweep = sweepAngle - (gap * pi / 180);

      final paint =
          Paint()
            // ..color = colors[i]
            ..color = filteredColors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.butt
            ..isAntiAlias = true;

      // DRAW ARC
      canvas.drawArc(rect, startAngle, adjustedSweep, false, paint);

      // ---------- LINE + LABEL ----------
      final middleAngle = startAngle + adjustedSweep / 2;

      final lineStart = Offset(
        center.dx + cos(middleAngle) * radius,
        center.dy + sin(middleAngle) * radius,
      );

      final lineEnd = Offset(
        center.dx + cos(middleAngle) * (radius + 12),
        center.dy + sin(middleAngle) * (radius + 12),
      );

      final horizontalEnd = Offset(
        lineEnd.dx + (cos(middleAngle) > 0 ? 15 : -15),
        lineEnd.dy,
      );

      final linePaint =
          Paint()
            // ..color = colors[i]
            ..color = filteredColors[i]
            ..strokeWidth = 1.5;

      canvas.drawLine(lineStart, lineEnd, linePaint);

      canvas.drawLine(lineEnd, horizontalEnd, linePaint);

      // LABEL
      final percent = ((filteredValues[i] / total) * 100);

      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: "${filteredLabels[i]}\n",
              style: GoogleFonts.urbanist(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            TextSpan(
              text: NumberFormat('#,##,###').format(filteredValues[i].toInt()),
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout(maxWidth: 70);
      textPainter.layout();

      final labelOffset = Offset(
        cos(middleAngle) > 0
            ? horizontalEnd.dx + 4
            : horizontalEnd.dx - textPainter.width - 4,
        horizontalEnd.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, labelOffset);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
