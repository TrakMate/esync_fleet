import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/appColors.dart';

class SingleDoughnutChart extends StatelessWidget {
  final double currentValue;
  final double avgValue;
  final String title;
  final String unit; // e.g. km/h, %, rpm, °C, V
  final Color primaryColor;
  final bool isDark;

  const SingleDoughnutChart({
    super.key,
    required this.currentValue,
    required this.avgValue,
    required this.title,
    required this.unit,
    required this.primaryColor,
    required this.isDark,
  });

  // 🔹 Define value ranges per metric
  double _getMaxRange(String title) {
    switch (title.toLowerCase()) {
      case 'speed':
        return 150; // km/h
      case 'rpm':
        return 10000; // rpm
      case 'fuel':
        return 100; // %
      case 'voltage':
        return 100; // volts
      case 'temperature':
        return 200; // degrees
      case 'torque':
        return 3500; //Nm
      case 'current':
        return 100;
      default:
        return 100; // fallback
    }
  }

  double _getMinRange(String title) {
    switch (title.toLowerCase()) {
      // case 'temperature':
      //   return -40; // min temp
      // case 'current':
      //   return -100;
      default:
        return 0;
    }
  }

  String _formatValue(double value, String title) {
    switch (title.toLowerCase()) {
      case 'voltage':
      case 'current': // if you add current later
        return value.toStringAsFixed(1); // decimal
      default:
        return value.floor().toString(); // integer
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🔹 Normalize to 0–100% range for chart visuals
    final double min = _getMinRange(title);
    final double max = _getMaxRange(title);
    final bool isNegative = currentValue < 0;

    final double normalizedCurrent =
        ((currentValue.abs() - min) / (max - min)).clamp(0, 1) * 100;
    final double normalizedAvg =
        ((avgValue - min) / (max - min)).clamp(0, 1) * 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔹 Top Label
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 8),

        // 🔹 Doughnut chart
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 35,
                  startDegreeOffset: 270,

                  // sections: [
                  //   PieChartSectionData(
                  //     value: normalizedCurrent,
                  //     color: primaryColor,
                  //     radius: 20,
                  //     showTitle: false,
                  //   ),
                  //   PieChartSectionData(
                  //     value: 100 - normalizedCurrent,
                  //     color: isDark ? Colors.grey[800] : Colors.grey[300],
                  //     radius: 20,
                  //     showTitle: false,
                  //   ),
                  // ],
                  sections:
                      isNegative
                          ? [
                            // 🔴 Negative: draw grey first, then value
                            PieChartSectionData(
                              value: 100 - normalizedCurrent,
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[300],
                              radius: 20,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: normalizedCurrent,
                              color: Colors.red, // negative color
                              radius: 20,
                              showTitle: false,
                            ),
                          ]
                          : [
                            PieChartSectionData(
                              value: normalizedCurrent,
                              color: primaryColor,
                              radius: 20,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: 100 - normalizedCurrent,
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[300],
                              radius: 20,
                              showTitle: false,
                            ),
                          ],
                ),
              ),
            ),

            Text(
              _formatValue(currentValue, title),
              // currentValue.toStringAsFixed(1), // for decimals
              // currentValue.floor().toString(),
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: primaryColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 🔹 Average Value
        Text(
          "Avg: ${avgValue.toStringAsFixed(0)} $unit",
          style: GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),
      ],
    );
  }
}
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     // 🔹 Normalize to 0–100% range for chart visuals
//     final double min = _getMinRange(title);
//     final double max = _getMaxRange(title);
//     final double normalizedCurrent =
//         ((currentValue - min) / (max - min)).clamp(0, 1) * 100;
//     final double normalizedAvg =
//         ((avgValue - min) / (max - min)).clamp(0, 1) * 100;

//     // 🔹 Check if current value is effectively zero (for temperature)
//     final bool isValueZero =
//         title.toLowerCase() == 'temperature' &&
//         (currentValue == 0 || currentValue.abs() < 0.01);
//     final bool isNegative = currentValue < 0;

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // 🔹 Top Label
//         Text(
//           title,
//           style: GoogleFonts.urbanist(
//             fontWeight: FontWeight.bold,
//             fontSize: 12,
//             color: isDark ? tWhite : tBlack,
//           ),
//         ),
//         const SizedBox(height: 8),

//         // 🔹 Doughnut chart
//         Stack(
//           alignment: Alignment.center,
//           children: [
//             SizedBox(
//               width: 110,
//               height: 110,
//               child: PieChart(
//                 PieChartData(
//                   sectionsSpace: 0,
//                   centerSpaceRadius: 35,
//                   startDegreeOffset: 270,
//                   // sections: [
//                   //   PieChartSectionData(
//                   //     value: isValueZero ? 0 : normalizedCurrent,
//                   //     color: isValueZero ? Colors.transparent : primaryColor,
//                   //     radius: 20,
//                   //     showTitle: false,
//                   //   ),
//                   //   PieChartSectionData(
//                   //     value: 100 - (isValueZero ? 0 : normalizedCurrent),
//                   //     color: isDark ? Colors.grey[800] : Colors.grey[300],
//                   //     radius: 20,
//                   //     showTitle: false,
//                   //   ),
//                   // ],
//                   sections:
//                       isNegative
//                           ? [
//                             // 🔴 Negative: draw grey first, then value
//                             PieChartSectionData(
//                               value: 100 - normalizedCurrent,
//                               color:
//                                   isDark ? Colors.grey[800] : Colors.grey[300],
//                               radius: 20,
//                               showTitle: false,
//                             ),
//                             PieChartSectionData(
//                               value: normalizedCurrent,
//                               color: Colors.red, // negative color
//                               radius: 20,
//                               showTitle: false,
//                             ),
//                           ]
//                           : [
//                             PieChartSectionData(
//                               value: normalizedCurrent,
//                               color: primaryColor,
//                               radius: 20,
//                               showTitle: false,
//                             ),
//                             PieChartSectionData(
//                               value: 100 - normalizedCurrent,
//                               color:
//                                   isDark ? Colors.grey[800] : Colors.grey[300],
//                               radius: 20,
//                               showTitle: false,
//                             ),
//                           ],
//                 ),
//               ),
//             ),

//             Text(
//               _formatValue(currentValue, title),
//               style: GoogleFonts.urbanist(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 20,
//                 color: primaryColor,
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 8),

//         // 🔹 Average Value
//         Text(
//           "Avg: ${avgValue.toStringAsFixed(0)} $unit",
//           style: GoogleFonts.urbanist(
//             fontSize: 12,
//             fontWeight: FontWeight.bold,
//             color: isDark ? tWhite : tBlack,
//           ),
//         ),
//       ],
//     );
//   }
// }
