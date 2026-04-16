import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/appColors.dart';
import '../../components/vehicleStatusLabelHover.dart';

class DynamicSegmentBar extends StatelessWidget {
  final List<Map<String, dynamic>> statuses;
  final double height;

  const DynamicSegmentBar({
    super.key,
    required this.statuses,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Remove 0 count items
    final filtered = statuses.where((s) => (s['count'] as int) > 0).toList();

    if (filtered.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        color: Colors.grey.shade300,
        child: const Text("No data"),
      );
    }

    final total = filtered.fold<int>(0, (sum, s) => sum + (s['count'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // =========================
        //        LEGENDS ABOVE
        // =========================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(filtered.length, (i) {
            final status = filtered[i];
            final label = status['label'] as String;
            final count = status['count'] as int;
            final color = status['color'] as Color;

            double pct = (count / total) * 100;
            double percentRounded = _roundPercent(pct);

            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top label with color bar (your existing StatusLabel widget)
                  StatusLabel(
                    label: label,
                    color: color,
                    isDark: isDark,
                    // onTap: () {
                    //   context.go('/home/devices?status=${label.toLowerCase()}');
                    // },
                    onTap: () {
                      context.go('/home/devices?status=${status['api']}');
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
          children: List.generate(filtered.length, (i) {
            final status = filtered[i];
            final count = status['count'] as int;
            final color = status['color'] as Color;

            final pct = total > 0 ? count / total : 0.0;

            return Expanded(
              flex: maxFlex(pct),
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
