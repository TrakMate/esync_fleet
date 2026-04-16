import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/imeiDistSpeedSocModel.dart';
import '../../../utils/appColors.dart';

class Distancespeedchart extends StatefulWidget {
  final List<Data>? SpeedDistanceSocData;
  const Distancespeedchart({super.key, required this.SpeedDistanceSocData});

  @override
  State<Distancespeedchart> createState() => _DistancespeedchartState();
}

class _DistancespeedchartState extends State<Distancespeedchart> {
  final double speedLimit = 80;
  List<FlSpot> speedData = [];
  List<FlSpot> distanceData = [];
  List<String> timeLabels = [];

  int? touchedIndex;
  double? touchedY;

  double _getMaxY() {
    final maxSpeed =
        speedData.isEmpty ? 0.0 : speedData.map((e) => e.y).reduce(max);

    final maxDistance =
        distanceData.isEmpty ? 0.0 : distanceData.map((e) => e.y).reduce(max);

    final maxVal = max(maxSpeed, maxDistance);

    return maxVal == 0 ? 1 : maxVal + 10;
  }

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  void _loadRealData() {
    speedData.clear();
    distanceData.clear();

    final entities = widget.SpeedDistanceSocData ?? [];

    if (entities.isEmpty) {
      setState(() {});
      return;
    }

    timeLabels = entities.map((e) => e.time ?? "").toList();

    for (int i = 0; i < entities.length; i++) {
      final e = entities[i];

      speedData.add(FlSpot(i.toDouble(), (e.speed ?? 0).toDouble()));
      distanceData.add(FlSpot(i.toDouble(), (e.distance ?? 0).toDouble()));
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant Distancespeedchart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.SpeedDistanceSocData != widget.SpeedDistanceSocData) {
      _loadRealData();
    }
  }
  // void _generateDummyData() {
  //   final random = Random();
  //   speedData = List.generate(
  //     24,
  //     (i) => FlSpot(i.toDouble(), 40 + random.nextInt(60).toDouble()),
  //   );
  //   distanceData = List.generate(
  //     24,
  //     (i) => FlSpot(i.toDouble(), (i * 2 + random.nextDouble())),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Speed-Distance',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: Stack(
            children: [
              LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget:
                            (value, _) => Text(
                              '${value.toInt() + 1}h',
                              style: GoogleFonts.urbanist(
                                fontSize: 10,
                                color: isDark ? tWhite : tBlack,
                              ),
                            ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),

                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true, //keeps tooltip working
                    getTouchLineStart: (_, __) => 0,
                    getTouchLineEnd: (_, __) => double.infinity,

                    // Hide FLChart's default vertical indicator & dots
                    getTouchedSpotIndicator:
                        (barData, spotIndexes) =>
                            spotIndexes.map((index) {
                              return TouchedSpotIndicatorData(
                                FlLine(
                                  color: Colors.transparent,
                                  strokeWidth: 0,
                                ),
                                FlDotData(show: false),
                              );
                            }).toList(),

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
                      getTooltipColor:
                          (touchedSpots) => isDark ? tWhite : tBlack,
                      getTooltipItems: (touchedSpots) {
                        if (touchedSpots.isEmpty) return [];

                        return touchedSpots.map((spot) {
                          final isSpeed = spot.bar.color == tBlue;
                          final label = isSpeed ? "Speed" : "Distance";
                          final unit = isSpeed ? "km/h" : "km";
                          final value = spot.y.toStringAsFixed(1);

                          return LineTooltipItem(
                            "$label: $value $unit",
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
                      } else if (event is FlTouchEvent &&
                          event is! FlPanUpdateEvent) {
                        setState(() {
                          touchedIndex = null;
                          touchedY = null;
                        });
                      }
                    },
                  ),

                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: speedLimit,
                        color: tRed,
                        strokeWidth: 1,
                        dashArray: [8, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: GoogleFonts.urbanist(
                            fontSize: 10,
                            color: tRed,
                          ),
                          labelResolver:
                              (_) => "Speed Limit: ${speedLimit.toInt()} km/h",
                        ),
                      ),
                    ],
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: speedData,
                      isCurved: true,
                      color: tBlue,
                      barWidth: 2,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: distanceData,
                      isCurved: true,
                      color: tGreen,
                      barWidth: 2,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),

              // Custom crosshair overlay
              if (touchedIndex != null && touchedY != null)
                IgnorePointer(
                  ignoring: true,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CrosshairPainter(
                      xIndex: touchedIndex!,
                      yValue: touchedY!,
                      totalPoints: speedData.length,
                      isDark: isDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LegendItem(color: tGreen, label: "Distance"),
            SizedBox(width: 10),
            _LegendItem(color: tBlue, label: "Speed"),
          ],
        ),
      ],
    );
  }
}

/// 🔹 Custom Crosshair Painter — draws X and Y dashed lines
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
    final yPos = size.height * (1 - (yValue / 100).clamp(0, 1));

    // Vertical dashed line
    _drawDashedLine(
      canvas,
      Offset(xPos, 0),
      Offset(xPos, size.height),
      paint,
      dashWidth,
      dashSpace,
    );

    // Horizontal dashed line
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

/// 🔹 Legend Item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
