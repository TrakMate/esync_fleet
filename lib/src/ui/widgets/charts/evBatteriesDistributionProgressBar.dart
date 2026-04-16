import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/appColors.dart';
import '../../components/vehicleStatusLabelHover.dart';

class BatteryProgressBar extends StatelessWidget {
  final List<int> counts; // [100–90, 90–60, 60–30, 30–0]
  final double height;
  final bool showLabels;

  const BatteryProgressBar({
    super.key,
    required this.counts,
    this.height = 30,
    this.showLabels = false,
  }) : assert(counts.length == 4);

  static const colors = [tGreen3, tBlue, tOrange, tRed];

  static const ranges = ["> 90%", "60% - 90%", "30% - 60%", "< 30%"];

  static const performanceLabels = [
    "Excellent", // > 90%
    "Good", // 60%–90%
    "Moderate", // 30%–60%
    "Poor", // < 30%
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statuses =
        List.generate(4, (i) {
          return {
            'label': performanceLabels[i],
            'count': counts[i],
            'color': colors[i],
            'api': performanceLabels[i].toLowerCase(),
          };
        }).where((s) => (s['count'] as int) > 0).toList();

    final total = statuses.fold<int>(0, (sum, s) => sum + (s['count'] as int));

    if (statuses.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        color: Colors.grey.shade300,
        child: const Text("No data"),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // =========================
        //        LEGENDS ABOVE (Like DynamicSegmentBar)
        // =========================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(statuses.length, (i) {
            final status = statuses[i];
            final label = status['label'] as String;
            final count = status['count'] as int;
            final color = status['color'] as Color;
            final range = ranges[performanceLabels.indexOf(label)];

            double pct = (count / total) * 100;
            double percentRounded = _roundPercent(pct);

            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusLabel(
                    label: "$label ($range)",
                    color: color,
                    isDark: isDark,
                    onTap: () {
                      context.go('/home/devices?SOC=${label.toLowerCase()}');
                    },
                  ),

                  const SizedBox(height: 10),

                  // Count + Percentage
                  Row(
                    children: [
                      Text(
                        "$count",
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "[${percentRounded.toStringAsFixed(0)}%]",
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // =========================
        //        SEGMENT BAR
        // =========================
        Row(
          children: List.generate(statuses.length, (i) {
            final status = statuses[i];
            final count = status['count'] as int;
            final color = status['color'] as Color;
            final label = status['label'] as String;

            final pct = total > 0 ? count / total : 0.0;

            return Expanded(
              flex: maxFlex(pct),
              child: GestureDetector(
                onTap: () {
                  context.go('/home/devices?SOC=${label.toLowerCase()}');
                },
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        spreadRadius: 3,
                        color: color.withOpacity(0.25),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: null,
                  // showLabels
                  //     ? LayoutBuilder(
                  //       builder:
                  //           (_, constraints) =>
                  //               constraints.maxWidth > 40
                  //                   ? Text(
                  //                     "${(pct * 100).toStringAsFixed(0)}%",
                  //                     style: GoogleFonts.urbanist(
                  //                       fontSize: 13,
                  //                       color: tWhite,
                  //                       fontWeight: FontWeight.w600,
                  //                     ),
                  //                   )
                  //                   : const SizedBox.shrink(),
                  //     )
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Minimum flex logic
  int maxFlex(double pct) {
    final flex = (pct * 1000).round();
    return flex > 0 ? flex : 1;
  }

  /// Rounding rule (.5 → ceil)
  double _roundPercent(double value) {
    double decimal = value - value.floor();
    return (decimal >= 0.5) ? value.ceilToDouble() : value.floorToDouble();
  }
}
