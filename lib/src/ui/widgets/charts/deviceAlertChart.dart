import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/imeiGraphModel.dart';
import '../../../utils/appColors.dart';

class DeviceAlertsChart extends StatefulWidget {
  final List<WeeklyAlertsGraph> alertsGraph;
  final List<MonthlyAlertsGraph> alertGraphforMonth;

  const DeviceAlertsChart({
    super.key,
    required this.alertsGraph,
    required this.alertGraphforMonth,
  });

  @override
  State<DeviceAlertsChart> createState() => _DeviceAlertsChartState();
}

class _DeviceAlertsChartState extends State<DeviceAlertsChart> {
  String _viewMode = "weekly";
  int? touchedIndex;
  double? touchedY;

  List<Map<String, dynamic>> _buildChartData() {
    if (_viewMode == "weekly") {
      return widget.alertsGraph.map((e) {
        return {
          "label": e.day,
          "critical": e.critical ?? 0,
          "nonCritical": e.nonCritical ?? 0,
        };
      }).toList();
    } else {
      return widget.alertGraphforMonth.map((e) {
        return {
          "label": e.week,
          "critical": e.critical ?? 0,
          "nonCritical": e.nonCritical ?? 0,
        };
      }).toList();
    }
  }

  double _getMaxY(List<Map<String, dynamic>> chartData) {
    if (chartData.isEmpty) return 10;

    double maxVal = 0;
    for (final e in chartData) {
      maxVal = max(maxVal, (e["critical"] as num).toDouble());
      maxVal = max(maxVal, (e["nonCritical"] as num).toDouble());
    }
    return maxVal == 0 ? 1 : maxVal;
  }

  void _updateView(String mode) {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
      touchedIndex = null;
      touchedY = null;
    });
  }

  bool hasAnyAlerts(List<Map<String, dynamic>> data) {
    for (final e in data) {
      final c = double.tryParse(e["critical"].toString()) ?? 0;
      final n = double.tryParse(e["nonCritical"].toString()) ?? 0;
      if (c > 0 || n > 0) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chartData = _buildChartData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Alerts",
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? tWhite : tBlack,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: tGrey.withOpacity(0.1)),
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

        // 🔹 Chart
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              BarChart(
                BarChartData(
                  minY: 0,
                  maxY: _getMaxY(chartData),
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

                  // 🔹 Touch
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
                        final colors = [tOrange1, tBlueSky];
                        final labels = ["Critical", "Non-Critical"];
                        final values = [
                          data["critical"].toString(),
                          data["nonCritical"].toString(),
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

                        for (int i = 0; i < labels.length; i++) {
                          spans.add(
                            TextSpan(
                              text: "● ",
                              style: TextStyle(color: colors[i], fontSize: 12),
                            ),
                          );
                          spans.add(
                            TextSpan(
                              text: "${labels[i]}: ${values[i]}\n",
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

                  // 🔹 Vertical line indicator
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

                  // 🔹 Bars
                  barGroups:
                      chartData.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 6,
                          barRods: [
                            BarChartRodData(
                              toY: (item["critical"] as num).toDouble(),
                              color: tOrange1.withOpacity(0.9),
                              width: 10,
                              borderRadius: BorderRadius.circular(0),
                            ),
                            BarChartRodData(
                              toY: (item["nonCritical"] as num).toDouble(),
                              color: tBlueSky.withOpacity(0.9),
                              width: 10,
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),

              // 🔹 Crosshair overlay (dashed lines)
              if (touchedIndex != null && touchedY != null)
                IgnorePointer(
                  ignoring: true,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CrosshairPainter(
                      xIndex: touchedIndex!,
                      yValue: touchedY!,
                      chartDataLength: chartData.length,
                      maxY: _getMaxY(chartData) * 1.3,
                      isDark: isDark,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 5),

        // 🔹 Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LegendItem(color: tOrange1, label: "Critical Alerts"),
            SizedBox(width: 10),
            _LegendItem(color: tBlueSky, label: "Non-Critical Alerts"),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          "Alerts",
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 40),

        // Message
        Center(
          child: Text(
            message,
            style: GoogleFonts.urbanist(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? tWhite.withOpacity(0.7) : tBlack.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  // 🔹 Toggle Button
  Widget _buildToggleButton(String label) {
    final isSelected = _viewMode == label.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _updateView(label.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: isSelected ? (isDark ? tWhite : tBlack) : Colors.transparent,
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

// 🔹 Crosshair painter for dashed guide lines
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
    // final spacing = size.width / (chartDataLength + 1);
    // final xPos = spacing * (xIndex + 1);
    final xPos = size.width * ((xIndex + 0.5) / chartDataLength);

    // final yPos = size.height * (1 - (yValue / 100).clamp(0, 1));
    final safeY = max(yValue, 1);
    final double yPos = size.height * (1 - (safeY / maxY).clamp(0, 1));

    _drawDashedLine(
      canvas,
      Offset(xPos, 0),
      Offset(xPos, size.height),
      paint,
      dashArray,
    );
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
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final angle = atan2(dy, dx);
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

// 🔹 Legend item
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
