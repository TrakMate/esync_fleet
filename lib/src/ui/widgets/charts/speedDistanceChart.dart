import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:svg_flutter/svg_flutter.dart';
import '../../../models/imeiDistSpeedSocModel.dart';
import '../../../utils/appColors.dart';

class SpeedDistanceChart extends StatefulWidget {
  // final List<DistanceSpeedSocEntities>? SpeedDistanceSocData;
  final List<ChartData>? SpeedDistanceSocData;

  final IMEIDistSpeedSocModel? SpeedDistanceSocModel;
  const SpeedDistanceChart({
    super.key,
    required this.SpeedDistanceSocData,
    this.SpeedDistanceSocModel,
  });

  @override
  State<SpeedDistanceChart> createState() => _SpeedDistanceChartState();
}

class _SpeedDistanceChartState extends State<SpeedDistanceChart> {
  final double speedLimit = 80;
  List<FlSpot> speedData = [];
  List<FlSpot> distanceData = [];
  List<FlSpot> socData = [];
  List<String> timeLabels = [];
  List<ChartData>? popupChartData;
  String _selectedTimeRange = "12hrs";
  int? touchedIndex;
  double? touchedY;
  int? popupTouchedIndex;
  double? popupTouchedY;
  String selectedTimeRange = "1hrs";
  double _getMaxY() {
    final maxSpeed =
        speedData.isEmpty ? 0.0 : speedData.map((e) => e.y).reduce(max);

    final maxDistance =
        distanceData.isEmpty ? 0.0 : distanceData.map((e) => e.y).reduce(max);

    final maxSoc = socData.isEmpty ? 0.0 : socData.map((e) => e.y).reduce(max);

    final maxVal = max(max(maxSpeed, maxDistance), maxSoc);

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

  double _getMaxYForData(List<ChartData>? data) {
    if (data == null || data.isEmpty) return 10;

    double maxSpeed = 0;
    double maxDistance = 0;
    double maxSoc = 0;

    for (var item in data) {
      maxSpeed = max(maxSpeed, item.speed ?? 0);
      maxDistance = max(maxDistance, item.distance ?? 0);
      maxSoc = max(maxSoc, item.soc?.toDouble() ?? 0);
    }

    final maxVal = max(max(maxSpeed, maxDistance), maxSoc);
    return maxVal == 0 ? 10 : _roundUpMax(maxVal);
  }

  double get chartInterval => _getMaxY() / 5;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  List<ChartData>? _getDataForRange(String range) {
    switch (range) {
      case "1hrs":
        return widget.SpeedDistanceSocModel?.oneHour;
      case "6hrs":
        return widget.SpeedDistanceSocModel?.sixHours;
      case "12hrs":
        return widget.SpeedDistanceSocModel?.twelveHours;
      case "24hrs":
        return widget.SpeedDistanceSocModel?.oneDay;
      default:
        return widget.SpeedDistanceSocData;
    }
  }

  void _loadRealData() {
    speedData.clear();
    distanceData.clear();
    socData.clear();

    // Always use 12-hour data for main chart
    final entities =
        widget.SpeedDistanceSocModel?.twelveHours ??
        widget.SpeedDistanceSocData ??
        [];

    if (entities.isEmpty) {
      setState(() {});
      return;
    }

    timeLabels = entities.map((e) => e.time ?? "").toList();

    for (int i = 0; i < entities.length; i++) {
      final e = entities[i];
      speedData.add(FlSpot(i.toDouble(), (e.speed ?? 0).toDouble()));
      distanceData.add(FlSpot(i.toDouble(), (e.distance ?? 0).toDouble()));
      socData.add(FlSpot(i.toDouble(), (e.soc ?? 0).toDouble()));
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant SpeedDistanceChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.SpeedDistanceSocData != widget.SpeedDistanceSocData ||
        oldWidget.SpeedDistanceSocModel != widget.SpeedDistanceSocModel) {
      _loadRealData();
      // Reset popup data when widget updates
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
            // Initialize with 1H data when popup opens
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
                  height: MediaQuery.of(context).size.height * 0.55,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 35,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        // crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'icons/linechart.svg',
                            height: 24,
                            width: 24,
                            color: isDark ? tWhite : tBlack,
                          ),
                          const SizedBox(width: 10),

                          Text(
                            'Speed-Distance-SOC Chart',
                            style: GoogleFonts.urbanist(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? tWhite : tBlack,
                            ),
                          ),

                          const SizedBox(width: 16),
                          // Tabs container
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? tWhite : tBlack,
                              ),
                            ),
                            child: Row(
                              children: [
                                _TimeTab(
                                  "1hrs",
                                  _selectedTimeRange == "1hrs",
                                  isDark,
                                  setState,
                                ),
                                _TimeTab(
                                  "6hrs",
                                  _selectedTimeRange == "6hrs",
                                  isDark,
                                  setState,
                                ),
                                _TimeTab(
                                  "12hrs",
                                  _selectedTimeRange == "12hrs",
                                  isDark,
                                  setState,
                                ),
                                _TimeTab(
                                  "24hrs",
                                  _selectedTimeRange == "24hrs",
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
                              Icons.fullscreen_exit,
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
                                      // Use popup-specific setState
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _LegendItem(color: tGreen, label: "Distance"),
                          SizedBox(width: 10),
                          _LegendItem(color: tBlue, label: "Speed"),
                          SizedBox(width: 10),
                          _LegendItem(color: tOrange, label: "SOC"),
                        ],
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

  LineChartData _buildPopupChartData(
    bool isPopup,
    bool isDark, {
    List<ChartData>? chartData,
    required Function(int?, double?) onTouch,
  }) {
    final data =
        chartData ??
        widget.SpeedDistanceSocModel?.twelveHours ??
        widget.SpeedDistanceSocData ??
        [];

    final localSpeedData = <FlSpot>[];
    final localDistanceData = <FlSpot>[];
    final localSocData = <FlSpot>[];
    final localTimeLabels = <String>[];

    for (int i = 0; i < data.length; i++) {
      final e = data[i];
      localSpeedData.add(FlSpot(i.toDouble(), (e.speed ?? 0).toDouble()));
      localDistanceData.add(FlSpot(i.toDouble(), (e.distance ?? 0).toDouble()));
      localSocData.add(FlSpot(i.toDouble(), (e.soc ?? 0).toDouble()));
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
    final maxSoc =
        localSocData.isEmpty ? 0.0 : localSocData.map((e) => e.y).reduce(max);
    final maxVal = max(max(maxSpeed, maxDistance), maxSoc);
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
                  fontWeight: FontWeight.w800,
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
            interval: 2,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();

              if (index < 0 || index >= localTimeLabels.length) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  localTimeLabels[index],
                  style: GoogleFonts.urbanist(
                    fontSize: 11,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),

      // lineTouchData: LineTouchData(
      //   touchSpotThreshold: 20,
      //   enabled: true,
      //   handleBuiltInTouches: true,
      //   getTouchedSpotIndicator: (barData, spotIndexes) {
      //     return spotIndexes.map((spotIndex) {
      //       return TouchedSpotIndicatorData(
      //         FlLine(color: Colors.transparent, strokeWidth: 0),
      //         FlDotData(show: false),
      //       );
      //     }).toList();
      //   },
      //   touchTooltipData: LineTouchTooltipData(
      //     tooltipRoundedRadius: 10,
      //     tooltipPadding: const EdgeInsets.symmetric(
      //       horizontal: 12,
      //       vertical: 8,
      //     ),
      //     fitInsideHorizontally: true,
      //     fitInsideVertically: true,
      //     getTooltipColor: (spots) => isDark ? tWhite : tBlack,
      //     getTooltipItems: (spots) {
      //       return spots.map((spot) {
      //         String label;
      //         String unit;
      //         Color color;

      //         switch (spot.barIndex) {
      //           case 0:
      //             label = "Speed";
      //             unit = "km/h";
      //             color = tBlue;
      //             break;
      //           case 1:
      //             label = "Distance";
      //             unit = "km";
      //             color = tGreen;
      //             break;
      //           case 2:
      //             label = "SOC";
      //             unit = "%";
      //             color = tOrange;
      //             break;
      //           default:
      //             label = "";
      //             unit = "";
      //             color = Colors.grey;
      //         }

      //         return LineTooltipItem(
      //           "",
      //           const TextStyle(),
      //           textAlign: TextAlign.left,
      //           children: [
      //             TextSpan(
      //               text: "● ",
      //               style: TextStyle(color: color, fontSize: 10),
      //             ),
      //             TextSpan(
      //               text: "$label : ",
      //               style: GoogleFonts.urbanist(
      //                 color: isDark ? tBlack : tWhite,
      //                 fontSize: 10,
      //               ),
      //             ),
      //             TextSpan(
      //               text: "${spot.y.toStringAsFixed(1)} $unit",
      //               style: GoogleFonts.urbanist(
      //                 color: isDark ? tBlack : tWhite,
      //                 fontSize: 10,
      //                 fontWeight: FontWeight.w600,
      //               ),
      //             ),
      //           ],
      //         );
      //       }).toList();
      //     },
      //   ),
      //   touchCallback: (event, response) {
      //     if (response != null &&
      //         response.lineBarSpots != null &&
      //         response.lineBarSpots!.isNotEmpty) {
      //       final spot = response.lineBarSpots!.first;
      //       onTouch(spot.x.toInt(), spot.y);
      //     } else {
      //       onTouch(null, null);
      //     }
      //   },
      // ),
      lineTouchData: LineTouchData(
        touchSpotThreshold: 20,
        enabled: true,
        handleBuiltInTouches: true,

        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.asMap().entries.map((entry) {
            final index = entry.key;
            final spotIndex = entry.value;

            final lineColor = barData.color ?? Colors.grey;

            return TouchedSpotIndicatorData(
              const FlLine(color: Colors.transparent, strokeWidth: 0),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: tWhite,
                    strokeWidth: 4,
                    strokeColor: lineColor,
                  );
                },
              ),
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
                case 2:
                  label = "SOC";
                  unit = "%";
                  color = tOrange;
                  break;
                default:
                  label = "";
                  unit = "";
                  color = Colors.grey;
              }

              return LineTooltipItem(
                "",
                const TextStyle(),
                textAlign: TextAlign.left,
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
        LineChartBarData(
          spots: localSocData,
          isCurved: false,
          color: tOrange,
          barWidth: 2,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [tOrange.withOpacity(0.3), tOrange.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _TimeTab(
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
          // Reset popup touched values when switching tabs
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
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? tBlue : (isDark ? tWhite : tBlack),
          ),
        ),
      ),
    );
  } //   return GestureDetector(

  //     onTap: () {
  //       setState(() {
  //         selectedTimeRange = label;
  //       });
  //     },
  //     child: Container(
  //       margin: const EdgeInsets.symmetric(horizontal: 8),
  //       padding: const EdgeInsets.only(bottom: 4),
  //       decoration: BoxDecoration(
  //         border: Border(
  //           bottom: BorderSide(
  //             color: isSelected ? tBlue : Colors.transparent,
  //             width: 2,
  //           ),
  //         ),
  //       ),
  //       child: Text(
  //         label,
  //         style: GoogleFonts.urbanist(
  //           fontSize: 11,
  //           fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
  //           color: isSelected ? tBlue : (isDark ? tWhite : tBlack),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (speedData.isEmpty ||
        distanceData.isEmpty ||
        socData.isEmpty ||
        timeLabels.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text("No chart data")),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            SvgPicture.asset(
              'icons/linechart.svg',
              height: 16,
              width: 16,
              color: isDark ? tWhite : tBlack,
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Text(
                'Speed-Distance-SOC Chart',
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
                  clipData: FlClipData.none(),
                  minX: 0,
                  maxX:
                      timeLabels.isEmpty
                          ? 0
                          : (timeLabels.length - 1).toDouble(),
                  minY: 0,
                  maxY: _getMaxY(),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    // leftTitles: const AxisTitles(
                    //   sideTitles: SideTitles(showTitles: false),
                    // ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: chartInterval,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              NumberFormat.compact().format(value.round()),
                              style: GoogleFonts.urbanist(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? tWhite : tBlack,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 18,
                        interval: isMobile ? 2 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= timeLabels.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              timeLabels[index],
                              style: GoogleFonts.urbanist(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? tWhite : tBlack,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),

                  //  lineTouchData: LineTouchData(
                  //                     enabled: true,
                  //                     handleBuiltInTouches: true,

                  //                     getTouchedSpotIndicator: (barData, spotIndexes) {
                  //                       return spotIndexes.map((spotIndex) {
                  //                         return TouchedSpotIndicatorData(
                  //                           const FlLine(
                  //                             color: Colors.transparent,
                  //                             strokeWidth: 0,
                  //                           ),
                  //                           const FlDotData(show: false),
                  //                         );
                  //                       }).toList();
                  //                     },

                  //                     // 🔥 TOOLTIP (same behavior as your original chart)
                  //                     touchTooltipData: LineTouchTooltipData(
                  //                       tooltipRoundedRadius: 10,
                  //                       tooltipPadding: const EdgeInsets.symmetric(
                  //                         horizontal: 12,
                  //                         vertical: 8,
                  //                       ),

                  //                       fitInsideHorizontally: true,
                  //                       fitInsideVertically: true,

                  //                       getTooltipColor:
                  //                           (touchedSpots) =>
                  //                               Theme.of(context).brightness == Brightness.dark
                  //                                   ? tWhite
                  //                                   : tBlack,

                  //                       getTooltipItems: (touchedSpots) {
                  //                         if (touchedSpots.isEmpty) return [];

                  //                         return touchedSpots.map((spot) {
                  //                           String label;
                  //                           String unit;
                  //                           Color indicatorColor;

                  //                           switch (spot.barIndex) {
                  //                             case 0:
                  //                               label = "Speed";
                  //                               unit = "km/h";
                  //                               indicatorColor = tBlue;
                  //                               break;
                  //                             case 1:
                  //                               label = "Distance";
                  //                               unit = "km";
                  //                               indicatorColor = tGreen;
                  //                               break;
                  //                             case 2:
                  //                               label = "SOC";
                  //                               unit = "%";
                  //                               indicatorColor = tOrange;
                  //                               break;
                  //                             default:
                  //                               label = "";
                  //                               unit = "";
                  //                               indicatorColor = tGrey;
                  //                           }

                  //                           return LineTooltipItem(
                  //                             "",
                  //                             const TextStyle(),
                  //                             textAlign: TextAlign.left,
                  //                             children: [
                  //                               TextSpan(
                  //                                 text: "● ",
                  //                                 style: TextStyle(
                  //                                   color: indicatorColor,
                  //                                   fontSize: 10,
                  //                                   fontWeight: FontWeight.bold,
                  //                                 ),
                  //                               ),
                  //                               TextSpan(
                  //                                 text: "$label : ",
                  //                                 style: GoogleFonts.urbanist(
                  //                                   color:
                  //                                       Theme.of(context).brightness ==
                  //                                               Brightness.dark
                  //                                           ? tBlack
                  //                                           : tWhite,
                  //                                   fontSize: 10,
                  //                                   fontWeight: FontWeight.w500,
                  //                                 ),
                  //                               ),
                  //                               TextSpan(
                  //                                 text: spot.y.toStringAsFixed(1),
                  //                                 style: GoogleFonts.urbanist(
                  //                                   color:
                  //                                       Theme.of(context).brightness ==
                  //                                               Brightness.dark
                  //                                           ? tBlack
                  //                                           : tWhite,
                  //                                   fontSize: 10,
                  //                                   fontWeight: FontWeight.w600,
                  //                                 ),
                  //                               ),
                  //                               TextSpan(
                  //                                 text: " $unit",
                  //                                 style: GoogleFonts.urbanist(
                  //                                   color:
                  //                                       Theme.of(context).brightness ==
                  //                                               Brightness.dark
                  //                                           ? tBlack
                  //                                           : tWhite,
                  //                                   fontSize: 10,
                  //                                 ),
                  //                               ),
                  //                             ],
                  //                           );
                  //                         }).toList();
                  //                       },
                  //                     ),

                  //                     touchCallback: (event, response) {
                  //                       if (response != null &&
                  //                           response.lineBarSpots != null &&
                  //                           response.lineBarSpots!.isNotEmpty) {
                  //                         final spot = response.lineBarSpots!.first;

                  //                         setState(() {
                  //                           touchedIndex = spot.x.toInt();
                  //                           touchedY = spot.y;
                  //                         });
                  //                       } else {
                  //                         setState(() {
                  //                           touchedIndex = null;
                  //                           touchedY = null;
                  //                         });
                  //                       }
                  //                     },
                  //                   ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,

                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final spotIndex = entry.value;

                        // Store the color from barData to use in getDotPainter
                        final lineColor = barData.color ?? Colors.grey;

                        return TouchedSpotIndicatorData(
                          const FlLine(
                            color: Colors.transparent,
                            strokeWidth: 0,
                          ),
                          FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: tWhite,
                                strokeWidth: 4,
                                strokeColor: lineColor,
                              );
                            },
                          ),
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
                      getTooltipColor:
                          (touchedSpots) => isDark ? tWhite : tBlack,
                      getTooltipItems: (touchedSpots) {
                        if (touchedSpots.isEmpty) return [];

                        return touchedSpots.map((spot) {
                          String label;
                          String unit;
                          Color indicatorColor;

                          // Use spot.barIndex to identify the line
                          switch (spot.barIndex) {
                            case 0:
                              label = "Speed";
                              unit = "km/h";
                              indicatorColor = tBlue;
                              break;
                            case 1:
                              label = "Distance";
                              unit = "km";
                              indicatorColor = tGreen;
                              break;
                            case 2:
                              label = "SOC";
                              unit = "%";
                              indicatorColor = tOrange;
                              break;
                            default:
                              label = "";
                              unit = "";
                              indicatorColor = tGrey;
                          }

                          return LineTooltipItem(
                            "",
                            const TextStyle(),
                            textAlign: TextAlign.left,
                            children: [
                              TextSpan(
                                text: "● ",
                                style: TextStyle(
                                  color: indicatorColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: "$label : ",
                                style: GoogleFonts.urbanist(
                                  color: isDark ? tBlack : tWhite,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: spot.y.toStringAsFixed(1),
                                style: GoogleFonts.urbanist(
                                  color: isDark ? tBlack : tWhite,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: " $unit",
                                style: GoogleFonts.urbanist(
                                  color: isDark ? tBlack : tWhite,
                                  fontSize: 10,
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
                      isCurved: false,
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
                      isCurved: false,
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
                    LineChartBarData(
                      spots: socData,
                      isCurved: false,
                      color: tOrange,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            tOrange.withOpacity(0.35),
                            tOrange.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Custom crosshair overlay
              // if (touchedIndex != null && touchedY != null)
              if (touchedIndex != null &&
                  touchedY != null &&
                  speedData.length > 1)
                IgnorePointer(
                  ignoring: true,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CrosshairPainter(
                      xIndex: touchedIndex!,
                      yValue: touchedY!,
                      totalPoints: speedData.length,
                      maxY: _getMaxY(),
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
            SizedBox(width: 10),
            _LegendItem(color: tOrange, label: "SOC"),
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
    // final spacing = size.width / (totalPoints - 1);
    final chartWidth = size.width;
    final chartHeight = size.height;

    final xRatio = totalPoints <= 1 ? 0 : xIndex / (totalPoints - 1);
    final xPos = chartWidth * xRatio;

    final yRatio = (yValue / maxY).clamp(0.0, 1.0);
    final yPos = chartHeight * (1 - yRatio);

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
