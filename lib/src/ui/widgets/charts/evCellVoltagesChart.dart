import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/appColors.dart';

class MultiCellVoltageChart extends StatefulWidget {
  final List<List<double>> cellVoltages; // 16 cells
  final List<String> timeLabels;
  final bool isDark;

  const MultiCellVoltageChart({
    super.key,
    required this.cellVoltages,
    required this.timeLabels,
    this.isDark = false,
  });

  @override
  State<MultiCellVoltageChart> createState() => _MultiCellVoltageChartState();
}

class _MultiCellVoltageChartState extends State<MultiCellVoltageChart> {
  int? touchedIndex;
  double? touchedY;

  // 16 Unique Colors
  final List<Color> cellColors24 = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.lightGreen,
    Colors.teal,
    Colors.cyan,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.lime,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.blueGrey,
    Colors.amber,
    Colors.lightBlue,
    Colors.deepOrangeAccent,
    Colors.greenAccent,
    Colors.redAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          LineChart(_buildChartData(widget.isDark)),

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

  LineChartData _buildChartData(bool isDark) {
    /// Flatten all voltages to compute dynamic min/max
    final allValues = widget.cellVoltages.expand((e) => e).toList();

    return LineChartData(
      minY: allValues.reduce(min) - 0.05,
      maxY: allValues.reduce(max) + 0.05,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget:
                (value, _) => Text(
                  value.toStringAsFixed(2),
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

      /// TOUCH INTERACTION
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
          getTooltipItems: (spots) {
            if (spots.isEmpty) return [];
            return spots.map((spot) {
              return LineTooltipItem(
                "Cell ${spot.barIndex + 1}: ${spot.y.toStringAsFixed(3)}V",
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

      /// MULTI-LINE
      lineBarsData: List.generate(16, (cellIndex) {
        final color = cellColors24[cellIndex % cellColors24.length];

        return LineChartBarData(
          spots: List.generate(
            widget.cellVoltages[cellIndex].length,
            (i) => FlSpot(i.toDouble(), widget.cellVoltages[cellIndex][i]),
          ),
          isCurved: true,
          barWidth: 1,
          color: color,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        );
      }),
    );
  }
}

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
    final yPos = size.height * (1 - (yValue / (yValue + 1000)).clamp(0, 1));

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
