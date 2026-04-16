import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/appColors.dart';

class MultiSensorTemperatureChart extends StatefulWidget {
  final List<List<double>> tempValues; // 10 sensors
  final List<String> timeLabels;
  final bool isDark;

  const MultiSensorTemperatureChart({
    super.key,
    required this.tempValues,
    required this.timeLabels,
    this.isDark = false,
  });

  @override
  State<MultiSensorTemperatureChart> createState() =>
      _MultiSensorTemperatureChartState();
}

class _MultiSensorTemperatureChartState
    extends State<MultiSensorTemperatureChart> {
  int? touchedIndex;
  double? touchedY;

  /// Colors for 10 sensors
  final List<Color> tempColors10 = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.lightGreen,
    Colors.blue,
    Colors.cyan,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          LineChart(_buildChart(widget.isDark)),

          if (touchedIndex != null && touchedY != null)
            IgnorePointer(
              ignoring: true,
              child: CustomPaint(
                size: Size.infinite,
                painter: CrosshairPainter(
                  xIndex: touchedIndex!,
                  yValue: touchedY!,
                  totalPoints: widget.timeLabels.length,
                  isDark: widget.isDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  LineChartData _buildChart(bool isDark) {
    final allValues = widget.tempValues.expand((e) => e).toList();

    return LineChartData(
      minY: allValues.reduce(min) - 2,
      maxY: allValues.reduce(max) + 2,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget:
                (value, _) => Text(
                  "${value.toStringAsFixed(0)}°C",
                  style: GoogleFonts.urbanist(
                    fontSize: 8,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, _) {
              int i = value.toInt();
              if (i < 0 || i >= widget.timeLabels.length) {
                return const SizedBox();
              }
              return Text(
                widget.timeLabels[i],
                style: GoogleFonts.urbanist(
                  fontSize: 8,
                  color: isDark ? tWhite : tBlack,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      /// TOUCH
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        getTouchedSpotIndicator:
            (barData, indexes) =>
                indexes
                    .map(
                      (i) => TouchedSpotIndicatorData(
                        FlLine(color: Colors.transparent, strokeWidth: 0),
                        FlDotData(show: false),
                      ),
                    )
                    .toList(),
        getTouchLineStart: (_, __) => 0,
        getTouchLineEnd: (_, __) => double.infinity,
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 10,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          tooltipBorder: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipColor: (_) => isDark ? tWhite : tBlack,
          getTooltipItems: (spots) {
            return spots.map((spot) {
              return LineTooltipItem(
                "Sensor ${spot.barIndex + 1}: ${spot.y.toStringAsFixed(1)}°C",
                GoogleFonts.urbanist(
                  color: isDark ? tBlack : tWhite,
                  fontSize: 10,
                ),
              );
            }).toList();
          },
        ),

        touchCallback: (event, response) {
          if (response != null &&
              response.lineBarSpots != null &&
              response.lineBarSpots!.isNotEmpty) {
            final spot = response.lineBarSpots!.first;
            setState(() {
              touchedIndex = spot.x.toInt();
              touchedY = spot.y;
            });
          } else {
            setState(() {
              touchedIndex = null;
              touchedY = null;
            });
          }
        },
      ),

      /// MULTI-LINE (10 sensors)
      lineBarsData: List.generate(widget.tempValues.length, (sensorIndex) {
        final color = tempColors10[sensorIndex % tempColors10.length];

        return LineChartBarData(
          spots: List.generate(
            widget.tempValues[sensorIndex].length,
            (i) => FlSpot(i.toDouble(), widget.tempValues[sensorIndex][i]),
          ),
          isCurved: true,
          barWidth: 1.2,
          color: color,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        );
      }),
    );
  }
}

/// SAME CROSSHAIR PAINTER AS YOUR VOLTAGE CHART
class CrosshairPainter extends CustomPainter {
  final int xIndex;
  final double yValue;
  final int totalPoints;
  final bool isDark;

  CrosshairPainter({
    required this.xIndex,
    required this.yValue,
    required this.totalPoints,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isDark ? Colors.white70 : Colors.black54
          ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 4.0;

    final spacing = size.width / (totalPoints - 1);
    final xPos = spacing * xIndex;

    final yPos = size.height * (1 - (yValue / 120).clamp(0, 1));

    _drawDashed(
      canvas,
      Offset(xPos, 0),
      Offset(xPos, size.height),
      paint,
      dashWidth,
      dashSpace,
    );
    _drawDashed(
      canvas,
      Offset(0, yPos),
      Offset(size.width, yPos),
      paint,
      dashWidth,
      dashSpace,
    );
  }

  void _drawDashed(
    Canvas c,
    Offset start,
    Offset end,
    Paint p,
    double dashW,
    double dashS,
  ) {
    final path = Path();
    final total = (end - start).distance;
    final angle = (end - start).direction;
    double drawn = 0;

    while (drawn < total) {
      final x1 = start.dx + cos(angle) * drawn;
      final y1 = start.dy + sin(angle) * drawn;

      drawn += dashW;

      final x2 = start.dx + cos(angle) * min(drawn, total);
      final y2 = start.dy + sin(angle) * min(drawn, total);

      path.moveTo(x1, y1);
      path.lineTo(x2, y2);

      drawn += dashS;
    }

    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
