import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/imeiGraphModel.dart';
import '../../../utils/appColors.dart';

class DeviceTripsChart extends StatefulWidget {
  final List<WeeklyTripsGraph> weeklyData;
  final List<MonthlyTripsGraph> monthlyData;

  const DeviceTripsChart({
    super.key,
    required this.weeklyData,
    required this.monthlyData,
  });

  @override
  State<DeviceTripsChart> createState() => _DeviceTripsChartState();
}

class _DeviceTripsChartState extends State<DeviceTripsChart> {
  String _viewMode = "weekly";
  List<Map<String, dynamic>> chartData = [];
  int? touchedIndex;
  double? touchedY;

  double _getMaxY() {
    if (chartData.isEmpty) return 100;

    double maxValue = 0;

    for (final e in chartData) {
      final trips = (e["trips"] ?? 0).toDouble();
      final distance = (e["distance"] ?? 0).toDouble();
      final hours = (e["hours"] ?? 0).toDouble();

      maxValue = max(maxValue, trips);
      maxValue = max(maxValue, distance);
      maxValue = max(maxValue, hours);
    }

    return maxValue == 0 ? 100 : maxValue;
  }

  @override
  void initState() {
    super.initState();
    _prepareChartData();
  }

  double parseNumber(String? value) {
    if (value == null || value.isEmpty) return 0;

    // Remove all non-numeric characters except dot
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');

    return double.tryParse(cleaned) ?? 0;
  }

  void _prepareChartData() {
    if (_viewMode == "weekly") {
      chartData =
          widget.weeklyData.map((e) {
            return {
              "label": e.day ?? e.date ?? "",
              "trips": e.trips ?? 0,
              "distance": parseNumber(e.distance),
              "hours": parseNumber(e.operatedHours),
            };
          }).toList();
    } else {
      chartData =
          widget.monthlyData.map((e) {
            return {
              "label": e.week ?? "",
              "trips": e.trips ?? 0,
              "distance": parseNumber(e.distance),
              "hours": parseNumber(e.operatedHours),
            };
          }).toList();
    }
  }

  double _maxTrips() =>
      chartData.isEmpty
          ? 0
          : chartData
              .map((e) => (e["trips"] ?? 0).toDouble())
              .reduce((a, b) => a > b ? a : b);

  double _maxDistance() =>
      chartData.isEmpty
          ? 0
          : chartData
              .map((e) => (e["distance"] ?? 0).toDouble())
              .reduce((a, b) => a > b ? a : b);

  double _maxHours() =>
      chartData.isEmpty
          ? 0
          : chartData
              .map((e) => (e["hours"] ?? 0).toDouble())
              .reduce((a, b) => a > b ? a : b);

  double _norm(double value, double maxValue) {
    if (maxValue == 0) return 1; // show thin bar
    return (value / maxValue) * 100;
  }

  @override
  void didUpdateWidget(covariant DeviceTripsChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.weeklyData != widget.weeklyData ||
        oldWidget.monthlyData != widget.monthlyData) {
      setState(() {
        _prepareChartData();
        touchedIndex = null;
        touchedY = null;
      });
    }
  }

  void _updateView(String mode) {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
      _prepareChartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trips',
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? tWhite : tBlack,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: tGrey.withOpacity(0.1),
                // borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  _buildToggleButton("Weekly"),
                  _buildToggleButton("Monthly"),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Chart
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            return Text(
                              chartData[value.toInt()]["label"],
                              style: GoogleFonts.urbanist(
                                fontSize: 11,
                                color: isDark ? tWhite : tBlack,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),

                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 10,
                      tooltipPadding: const EdgeInsets.all(10),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (group) => isDark ? tWhite : tBlack,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = chartData[group.x.toInt()];
                        final legendColors = [tBlue, tGreen, tPink];
                        final legendLabels = ["Trips", "Distance", "Hours"];
                        final legendValues = [
                          "${data["trips"]}",
                          "${data["distance"]} km",
                          "${data["hours"]} h",
                        ];

                        final spans = <TextSpan>[
                          TextSpan(
                            text: "${data["label"]}\n",
                            style: GoogleFonts.urbanist(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? tBlack : tWhite,
                            ),
                          ),
                        ];

                        for (int i = 0; i < legendLabels.length; i++) {
                          spans.add(
                            TextSpan(
                              text: "● ",
                              style: TextStyle(
                                color: legendColors[i],
                                fontSize: 12,
                              ),
                            ),
                          );
                          spans.add(
                            TextSpan(
                              text: "${legendLabels[i]}: ${legendValues[i]}\n",
                              style: GoogleFonts.urbanist(
                                color: isDark ? tBlack : tWhite,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }

                        return BarTooltipItem(
                          '',
                          const TextStyle(),
                          children: spans,
                          textAlign: TextAlign.start,
                        );
                      },
                    ),

                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        setState(() {
                          touchedIndex = null;
                          touchedY = null;
                        });
                        return;
                      }

                      setState(() {
                        touchedIndex = response.spot!.touchedBarGroupIndex;
                        touchedY = response.spot!.touchedRodData.toY;
                      });
                    },
                  ),

                  extraLinesData: ExtraLinesData(
                    verticalLines:
                        touchedIndex != null
                            ? [
                              VerticalLine(
                                x: touchedIndex!.toDouble(),
                                color: isDark ? Colors.white38 : Colors.black38,
                                strokeWidth: 1,
                                dashArray: [5, 4],
                              ),
                            ]
                            : [],
                  ),

                  barGroups:
                      chartData.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;

                        final maxTrips = _maxTrips();
                        final maxDistance = _maxDistance();
                        final maxHours = _maxHours();
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 5,
                          showingTooltipIndicators:
                              touchedIndex == i ? [0, 1, 2] : [],

                          barRods: [
                            BarChartRodData(
                              toY: _norm(item["trips"].toDouble(), maxTrips),
                              color: tBlue.withOpacity(0.9),
                              width: 8,
                              borderRadius: BorderRadius.circular(0),
                            ),
                            BarChartRodData(
                              toY: _norm(
                                item["distance"].toDouble(),
                                maxDistance,
                              ),
                              color: tGreen.withOpacity(0.9),
                              width: 8,
                              borderRadius: BorderRadius.circular(0),
                            ),
                            BarChartRodData(
                              toY: _norm(item["hours"].toDouble(), maxHours),
                              color: tPink.withOpacity(0.9),
                              width: 8,
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),

              if (touchedIndex != null && touchedY != null)
                IgnorePointer(
                  ignoring: true,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CrosshairPainter(
                      xIndex: touchedIndex!,
                      yValue: touchedY!,
                      chartDataLength: chartData.length,
                      maxY: _getMaxY(),
                      isDark: isDark,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 5),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: tBlue.withOpacity(0.9), label: "Trips"),
            SizedBox(width: 6),
            _LegendItem(
              color: tGreen.withOpacity(0.9),
              label: "Distance Travelled",
            ),
            SizedBox(width: 6),
            _LegendItem(color: tPink.withOpacity(0.9), label: "Opertion Hours"),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label) {
    final isSelected = _viewMode == label.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _updateView(label.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? tWhite : tBlack) : Colors.transparent,
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                isSelected
                    ? (isDark ? tBlack : tWhite)
                    : (isDark ? tWhite : tBlack),
          ),
        ),
      ),
    );
  }
}

class CrosshairPainter extends CustomPainter {
  final int xIndex;
  final double yValue;
  final int chartDataLength;
  final double maxY;
  final bool isDark;

  CrosshairPainter({
    required this.xIndex,
    required this.yValue,
    required this.chartDataLength,
    required this.maxY,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isDark ? tWhite : tBlack
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashArray = [5, 4];

    // final double spacing = size.width / (chartDataLength + 1);
    // final double xPos = spacing * (xIndex + 1);
    final double xPos = size.width * ((xIndex + 0.5) / chartDataLength);

    // final double yPos = size.height * (1 - (yValue / 100).clamp(0, 1));
    final safeY = max(yValue, 1);
    final double yPos = size.height * (1 - (safeY / maxY).clamp(0, 1));

    // Draw dashed vertical line
    _drawDashedLine(
      canvas,
      Offset(xPos, 0),
      Offset(xPos, size.height),
      paint,
      dashArray,
    );

    // Draw dashed horizontal line
    _drawDashedLine(
      canvas,
      Offset(0, yPos),
      Offset(size.width, yPos),
      paint,
      dashArray,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
    List<int> dashArray,
  ) {
    const double dashWidth = 5;
    const double dashSpace = 4;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = sqrt(dx * dx + dy * dy);
    final double angle = atan2(dy, dx);
    double start = 0;
    final path = Path();

    while (start < distance) {
      final x1 = p1.dx + cos(angle) * start;
      final y1 = p1.dy + sin(angle) * start;
      start += dashWidth;
      final x2 = p1.dx + cos(angle) * min(start, distance);
      final y2 = p1.dy + sin(angle) * min(start, distance);
      path.moveTo(x1, y1);
      path.lineTo(x2, y2);
      start += dashSpace;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Legend item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
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
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? tWhite
                    : tBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
