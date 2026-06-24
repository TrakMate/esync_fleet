import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:svg_flutter/svg_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/imeiDistSpeedSocModel.dart';
import '../../../utils/appColors.dart';

class Distancespeedchart extends StatefulWidget {
  final List<ChartData>? SpeedDistanceSocData;
  final IMEIDistSpeedSocModel? SpeedDistanceSocModel;

  const Distancespeedchart({
    super.key,
    required this.SpeedDistanceSocData,
    this.SpeedDistanceSocModel,
  });

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

  List<ChartData>? popupChartData;
  String _selectedTimeRange = "12H";
  int? popupTouchedIndex;
  double? popupTouchedY;

  List<ChartData>? _getDataForRange(String range) {
    switch (range) {
      case "1H":
        return widget.SpeedDistanceSocModel?.oneHour;
      case "6H":
        return widget.SpeedDistanceSocModel?.sixHours;
      case "12H":
        return widget.SpeedDistanceSocModel?.twelveHours;
      case "24H":
        return widget.SpeedDistanceSocModel?.oneDay;
      default:
        return widget.SpeedDistanceSocData;
    }
  }

  double _getMaxYForData(List<ChartData>? data) {
    if (data == null || data.isEmpty) return 10;

    double maxSpeed = 0;
    double maxDistance = 0;

    for (var item in data) {
      maxSpeed = max(maxSpeed, item.speed ?? 0);
      maxDistance = max(maxDistance, item.distance ?? 0);
    }

    final maxVal = max(maxSpeed, maxDistance);
    return maxVal == 0 ? 10 : _roundUpMax(maxVal);
  }

  double _roundUpMax(double value) {
    if (value <= 10) return 10;
    if (value <= 50) return 50;
    if (value <= 100) return 100;
    if (value <= 500) return 500;
    if (value <= 1000) return 1000;

    final magnitude = pow(10, value.toInt().toString().length - 1);
    return ((value / magnitude).ceil() * magnitude).toDouble();
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

    if (oldWidget.SpeedDistanceSocData != widget.SpeedDistanceSocData ||
        oldWidget.SpeedDistanceSocModel != widget.SpeedDistanceSocModel) {
      _loadRealData();
      popupChartData = _getDataForRange(_selectedTimeRange);
    }
  }

  void _showChartPopup(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (popupChartData == null) {
              popupChartData = _getDataForRange(_selectedTimeRange);
            }

            return Dialog(
              backgroundColor: isDark ? tBlack : tWhite,
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? tBlack : tWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.2)
                              : tBlack.withOpacity(0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        spreadRadius: 2,
                        color:
                            isDark
                                ? tWhite.withOpacity(0.15)
                                : tBlack.withOpacity(0.15),
                      ),
                    ],
                  ),
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "📊 Speed-Distance Chart",
                            style: GoogleFonts.urbanist(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? tWhite : tBlack,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color:
                                  isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.black.withOpacity(0.04),
                            ),
                            child: Row(
                              children: [
                                _popupTimeTab(
                                  "1H",
                                  _selectedTimeRange == "1H",
                                  isDark,
                                  setState,
                                ),
                                _popupTimeTab(
                                  "6H",
                                  _selectedTimeRange == "6H",
                                  isDark,
                                  setState,
                                ),
                                _popupTimeTab(
                                  "12H",
                                  _selectedTimeRange == "12H",
                                  isDark,
                                  setState,
                                ),
                                _popupTimeTab(
                                  "24H",
                                  _selectedTimeRange == "24H",
                                  isDark,
                                  setState,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: isDark ? tWhite : tBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                LineChart(
                                  _buildPopupChartData(
                                    true,
                                    isDark,
                                    chartData: popupChartData,
                                    onTouch: (index, y) {
                                      setState(() {
                                        popupTouchedIndex = index;
                                        popupTouchedY = y;
                                      });
                                    },
                                  ),
                                  key: ValueKey(popupChartData?.length ?? 0),
                                ),
                                if (popupTouchedIndex != null &&
                                    popupTouchedY != null &&
                                    popupChartData != null)
                                  IgnorePointer(
                                    ignoring: true,
                                    child: CustomPaint(
                                      size: Size(
                                        constraints.maxWidth,
                                        constraints.maxHeight,
                                      ),
                                      painter: CrosshairPainter(
                                        xIndex: popupTouchedIndex!,
                                        yValue: popupTouchedY!,
                                        totalPoints:
                                            popupChartData?.length ?? 0,
                                        maxY: _getMaxYForData(popupChartData),
                                        isDark: isDark,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              'icons/line_chart.svg',
              height: 16,
              width: 16,
              color: isDark ? tWhite : tBlack,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Speed-Distance Chart',
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),
            ),
            InkWell(
              onTap: () => _showChartPopup(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.fullscreen,
                  size: 18,
                  color: isDark ? tWhite : tBlack,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
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
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
                      // belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            tBlue.withOpacity(0.35),
                            tBlue.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: distanceData,
                      isCurved: true,
                      color: tGreen,
                      barWidth: 2,
                      // belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            tGreen.withOpacity(0.35),
                            tGreen.withOpacity(0.05),
                          ],
                        ),
                      ),
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
                      maxY: _getMaxY(), // Add this parameter

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

  Widget _popupTimeTab(
    String label,
    bool isSelected,
    bool isDark,
    StateSetter setState,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeRange = label;
          popupChartData = _getDataForRange(label);
          // Reset POPUP variables, not main chart variables
          popupTouchedIndex = null;
          popupTouchedY = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? tBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? tBlue : (isDark ? tWhite : tBlack),
          ),
        ),
      ),
    );
  }

  LineChartData _buildPopupChartData(
    bool isPopup,
    bool isDark, {
    List<ChartData>? chartData,
    required Function(int?, double?) onTouch,
  }) {
    final data = chartData ?? widget.SpeedDistanceSocData ?? [];

    final localSpeedData = <FlSpot>[];
    final localDistanceData = <FlSpot>[];
    final localTimeLabels = <String>[];

    for (int i = 0; i < data.length; i++) {
      final e = data[i];
      localSpeedData.add(FlSpot(i.toDouble(), (e.speed ?? 0).toDouble()));
      localDistanceData.add(FlSpot(i.toDouble(), (e.distance ?? 0).toDouble()));
      localTimeLabels.add(e.time ?? "");
    }

    final maxSpeed =
        localSpeedData.isEmpty
            ? 0.0
            : localSpeedData.map((e) => e.y).reduce(max);
    final maxDistance =
        localDistanceData.isEmpty
            ? 0.0
            : localDistanceData.map((e) => e.y).reduce(max);
    final maxVal = max(maxSpeed, maxDistance);
    final chartMaxY = maxVal == 0 ? 10.0 : _roundUpMax(maxVal);
    final chartInterval = chartMaxY / 5;

    return LineChartData(
      clipData: FlClipData.none(),
      minX: 0,
      maxX: (localTimeLabels.length - 1).toDouble(),
      minY: 0,
      maxY: chartMaxY,
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: chartInterval,
            getTitlesWidget: (value, meta) {
              return Text(
                NumberFormat.compact().format(value),
                style: GoogleFonts.urbanist(
                  fontSize: 11,
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
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 18,
            interval: isPopup ? 1 : 2,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= localTimeLabels.length) {
                return const SizedBox.shrink();
              }
              return Text(
                localTimeLabels[index],
                style: GoogleFonts.urbanist(
                  fontSize: 11,
                  color: isDark ? tWhite : tBlack,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchSpotThreshold: 20,
        enabled: true,
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((spotIndex) {
            final spot = barData.spots[spotIndex];
            return TouchedSpotIndicatorData(
              FlLine(color: Colors.transparent, strokeWidth: 0),
              FlDotData(show: false),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 10,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipColor: (spots) => isDark ? tWhite : tBlack,
          getTooltipItems: (spots) {
            return spots.map((spot) {
              String label;
              String unit;
              Color color;

              switch (spot.barIndex) {
                case 0:
                  label = "Speed";
                  unit = "km/h";
                  color = tBlue;
                  break;
                case 1:
                  label = "Distance";
                  unit = "km";
                  color = tGreen;
                  break;
                default:
                  label = "";
                  unit = "";
                  color = Colors.grey;
              }

              return LineTooltipItem(
                "",
                const TextStyle(),
                children: [
                  TextSpan(
                    text: "● ",
                    style: TextStyle(color: color, fontSize: 10),
                  ),
                  TextSpan(
                    text: "$label : ",
                    style: GoogleFonts.urbanist(
                      color: isDark ? tBlack : tWhite,
                      fontSize: 10,
                    ),
                  ),
                  TextSpan(
                    text: "${spot.y.toStringAsFixed(1)} $unit",
                    style: GoogleFonts.urbanist(
                      color: isDark ? tBlack : tWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
        touchCallback: (event, response) {
          if (response != null &&
              response.lineBarSpots != null &&
              response.lineBarSpots!.isNotEmpty) {
            final spot = response.lineBarSpots!.first;
            onTouch(spot.x.toInt(), spot.y);
          } else {
            onTouch(null, null);
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
              style: GoogleFonts.urbanist(fontSize: 10, color: tRed),
              labelResolver: (_) => "Speed Limit: ${speedLimit.toInt()} km/h",
            ),
          ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: localSpeedData,
          isCurved: false,
          color: tBlue,
          barWidth: 2,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [tBlue.withOpacity(0.3), tBlue.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        LineChartBarData(
          spots: localDistanceData,
          isCurved: false,
          color: tGreen,
          barWidth: 2,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [tGreen.withOpacity(0.3), tGreen.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
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
  final double maxY;
  final bool isDark;

  CrosshairPainter({
    required this.xIndex,
    required this.yValue,
    required this.totalPoints,
    required this.maxY,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalPoints <= 1 || maxY <= 0) return;
    final paint =
        Paint()
          ..color = isDark ? Colors.white70 : Colors.black54
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final chartWidth = size.width;
    final chartHeight = size.height;

    final xRatio = totalPoints <= 1 ? 0 : xIndex / (totalPoints - 1);
    final xPos = chartWidth * xRatio;

    final yRatio = (yValue / maxY).clamp(0.0, 1.0);
    final yPos = chartHeight * (1 - yRatio);

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
