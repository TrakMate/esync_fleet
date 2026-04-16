import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/appColors.dart';

class TripsOverviewDoughnutChart extends StatelessWidget {
  final double avgValue;
  final String title;
  final String unit;
  final Color primaryColor;
  final bool isDark;

  const TripsOverviewDoughnutChart({
    super.key,
    required this.avgValue,
    required this.title,
    required this.unit,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    // 🔹 Clamp avgValue to 0–100 for visualization
    final double normalizedAvg = avgValue.clamp(0, 100);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isDarkTheme ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 8),

        // Doughnut
        SizedBox(
          width: 110,
          height: 110,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 35,
              startDegreeOffset: 270,
              sections: [
                PieChartSectionData(
                  value: normalizedAvg,
                  color: primaryColor,
                  radius: 20,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: 100 - normalizedAvg,
                  color: isDarkTheme ? Colors.grey[800] : Colors.grey[300],
                  radius: 20,
                  showTitle: false,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Unit text
        Text(
          "Avg: $avgValue $unit",
          style: GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? tWhite : tBlack,
          ),
        ),
      ],
    );
  }
}
