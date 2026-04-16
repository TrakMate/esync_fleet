import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// import '../../../models/dashboardDetailsModel.dart';
import '../../../models/alertDashboardModel.dart';
import '../../../models/alertGraphModel.dart';
import '../../../utils/appColors.dart';

class AlertsChart extends StatefulWidget {
  // final List<AlertsGraph> weeklyData;
  // final List<AlertGraphforMonth> monthlyData;
  final List<WeeklyAlertsGraph> weeklyData;
  final List<MonthlyAlertsGraph> monthlyData;
  const AlertsChart({
    super.key,
    required this.weeklyData,
    required this.monthlyData,
  });

  @override
  State<AlertsChart> createState() => _AlertsChartState();
}

class _AlertsChartState extends State<AlertsChart> {
  String _viewMode = "weekly";
  int? touchedIndex;
  double? touchedY;
  final NumberFormat format = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
  }

  List<Map<String, dynamic>> get chartData {
    if (_viewMode == "weekly") {
      return widget.weeklyData.map((e) {
        return {
          "label": e.day ?? "",
          "critical": e.critical ?? 0,
          "nonCritical": e.nonCritical ?? 0,
        };
      }).toList();
    } else {
      return widget.monthlyData.map((e) {
        return {
          "label": e.week ?? "",
          "critical": e.critical ?? 0,
          "nonCritical": e.nonCritical ?? 0,
        };
      }).toList();
    }
  }

  void _updateView(String mode) {
    setState(() {
      _viewMode = mode;
      touchedIndex = null;
      touchedY = null;
    });
  }

  double get maxY {
    if (chartData.isEmpty) return 1;
    return chartData
        .map((e) => max(e['critical'], e['nonCritical']))
        .reduce(max)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alerts',
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

        // 🔹 Chart
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              BarChart(
                BarChartData(
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
                                color:
                                    isDark
                                        ? Colors.white70
                                        : tBlack.withOpacity(0.7),
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

                  // 🔹 Tooltip & Touch
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
                          format.format(data["critical"] ?? 0),
                          format.format(data["nonCritical"] ?? 0),
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
                          showingTooltipIndicators:
                              touchedIndex == i ? [0, 1] : [],
                          barRods: [
                            BarChartRodData(
                              toY: item["critical"].toDouble(),
                              color: tOrange1.withOpacity(0.9),
                              width: 10,
                              borderRadius: BorderRadius.circular(0),
                            ),
                            BarChartRodData(
                              toY: item["nonCritical"].toDouble(),
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
                      maxY: maxY,
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
          children: [
            _LegendItem(color: tOrange1, label: "Critical Alerts"),
            const SizedBox(width: 10),
            _LegendItem(color: tBlueSky, label: "Non-Critical Alerts"),
          ],
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
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? tWhite : tBlack) : Colors.transparent,
          // borderRadius: BorderRadius.circular(5),
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
    final spacing = size.width / (chartDataLength + 1);
    final xPos = spacing * (xIndex + 1);
    final yPos = size.height * (1 - (yValue / 100).clamp(0, 1));

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

// 🔹 Legend item widget
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
