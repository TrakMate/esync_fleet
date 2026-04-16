import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// import '../../../models/dashboardDetailsModel.dart';
import '../../../models/vehicleDashboardModel.dart';
import '../../../utils/appColors.dart';

class VehicleUtilizationChart extends StatefulWidget {
  // final List<VehicleutliGraph> weeklyData;
  // final List<VehicleutliGraphforMonth> monthlyData;

  final List<WeeklyVehicleUtilization> weeklyData;
  final List<MonthlyVehicleUtilization> monthlyData;

  const VehicleUtilizationChart({
    super.key,
    required this.weeklyData,
    required this.monthlyData,
  });

  @override
  State<VehicleUtilizationChart> createState() =>
      _VehicleUtilizationChartState();
}

class _VehicleUtilizationChartState extends State<VehicleUtilizationChart> {
  String _viewMode = "weekly";
  int? touchedIndex;
  double? touchedY;

  @override
  void initState() {
    super.initState();
  }

  final NumberFormat format = NumberFormat('#,##,###');

  List<Map<String, dynamic>> get chartData {
    if (_viewMode == "weekly") {
      return widget.weeklyData.map((e) {
        return {
          "label": e.day ?? "",
          "utilization": e.active ?? 0,
          "nonutilization": e.inactive ?? 0,
        };
      }).toList();
    } else {
      return widget.monthlyData.map((e) {
        return {
          "label": e.week ?? "",
          "utilization": e.active ?? 0,
          "nonutilization": e.inactive ?? 0,
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
        .map(
          (e) => max(
            (e['utilization'] as num).toDouble(),
            (e['nonutilization'] as num).toDouble(),
          ),
        )
        .reduce(max);
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
              'Vehicle Utilization ',
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

                  // 🔹 Tooltip
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 10,
                      tooltipPadding: const EdgeInsets.all(10),
                      getTooltipColor: (group) => isDark ? tWhite : tBlack,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = chartData[group.x.toInt()];
                        final colors = [tGreen, tGrey];
                        final labels = ["Utilized", "Non-Utilized"];
                        // final values = [
                        //   data["utilization"].toString(),
                        //   data["nonutilization"].toString(),
                        // ];
                        final values = [
                          format.format(data["utilization"]),
                          format.format(data["nonutilization"]),
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
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 6,
                          showingTooltipIndicators:
                              touchedIndex == i ? [0, 1] : [],
                          barRods: [
                            BarChartRodData(
                              toY: (item["utilization"] as num).toDouble(),
                              color: tGreen.withOpacity(0.9),
                              width: 10,
                              borderRadius: BorderRadius.circular(0),
                            ),
                            BarChartRodData(
                              toY: (item["nonutilization"] as num).toDouble(),
                              color: tGrey.withOpacity(0.9),
                              width: 10,
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
          children: const [
            _LegendItem(color: tGreen, label: "Utilized"),
            SizedBox(width: 10),
            _LegendItem(color: tGrey, label: "Non-Utilized"),
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
          color: isSelected ? (isDark ? tWhite : tBlack) : tTransparent,
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

/// 🔹 Crosshair painter (same as before)
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

    const double dashWidth = 5;
    const double dashSpace = 4;
    final spacing = size.width / (chartDataLength + 1);
    final xPos = spacing * (xIndex + 1);
    final yPos = size.height * (1 - (yValue / maxY).clamp(0, 1));

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
