import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/appColors.dart';

class OdometerChart extends StatefulWidget {
  final List<double> odometerData;
  final List<String> timeLabels;
  final bool isDark;

  const OdometerChart({
    super.key,
    required this.odometerData,
    required this.timeLabels,
    this.isDark = false,
  });

  @override
  State<OdometerChart> createState() => _OdometerChartState();
}

class _OdometerChartState extends State<OdometerChart> {
  int? touchedIndex;
  double? touchedY;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          LineChart(_buildOdometerChartData(widget.isDark)),

          // 🔹 Custom crosshair overlay
          if (touchedIndex != null && touchedY != null)
            IgnorePointer(
              ignoring: true,
              child: CustomPaint(
                size: Size.infinite,
                painter: CrosshairPainter(
                  xIndex: touchedIndex!,
                  yValue: touchedY!,
                  totalPoints: widget.odometerData.length,
                  isDark: widget.isDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 🔹 Odometer Chart Configuration
  LineChartData _buildOdometerChartData(bool isDark) {
    return LineChartData(
      minY: widget.odometerData.reduce(min) - 1,
      maxY: widget.odometerData.reduce(max) + 1,
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget:
                (value, meta) => Text(
                  "${value.toStringAsFixed(0)} km",
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
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index < 0 || index >= widget.timeLabels.length) {
                return const SizedBox();
              }
              return Text(
                widget.timeLabels[index],
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
      borderData: FlBorderData(show: false),

      /// 🔹 Touch Interaction
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        getTouchLineStart: (_, __) => 0,
        getTouchLineEnd: (_, __) => double.infinity,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes
              .map(
                (index) => TouchedSpotIndicatorData(
                  FlLine(color: Colors.transparent, strokeWidth: 0),
                  FlDotData(show: false),
                ),
              )
              .toList();
        },
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
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            return touchedSpots.map((spot) {
              final value = spot.y.toStringAsFixed(1);
              return LineTooltipItem(
                "Odometer: $value km",
                GoogleFonts.urbanist(
                  color: isDark ? tBlack : tWhite,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
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
          } else if (event is FlTouchEvent && event is! FlPanUpdateEvent) {
            setState(() {
              touchedIndex = null;
              touchedY = null;
            });
          }
        },
      ),

      /// 🔹 Line Bar
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(
            widget.odometerData.length,
            (index) => FlSpot(index.toDouble(), widget.odometerData[index]),
          ),
          isCurved: true,
          color: tBlueSky,
          barWidth: 3,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [tBlueSky.withOpacity(0.3), tBlueSky.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

/// 🔹 Crosshair Painter (unchanged)
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
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;

    final spacing = size.width / (totalPoints - 1);
    final xPos = spacing * xIndex;
    final yPos = size.height * (1 - (yValue / (yValue + 10)).clamp(0, 1));

    _drawDashedLine(
      canvas,
      Offset(xPos, 0),
      Offset(xPos, size.height),
      paint,
      dashWidth,
      dashSpace,
    );
    _drawDashedLine(
      canvas,
      Offset(0, yPos),
      Offset(size.width, yPos),
      paint,
      dashWidth,
      dashSpace,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final path = Path();
    double distance = (end - start).distance;
    final angle = (end - start).direction;
    double drawn = 0;

    while (drawn < distance) {
      final x1 = start.dx + cos(angle) * drawn;
      final y1 = start.dy + sin(angle) * drawn;
      drawn += dashWidth;
      final x2 = start.dx + cos(angle) * min(drawn, distance);
      final y2 = start.dy + sin(angle) * min(drawn, distance);
      path.moveTo(x1, y1);
      path.lineTo(x2, y2);
      drawn += dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
