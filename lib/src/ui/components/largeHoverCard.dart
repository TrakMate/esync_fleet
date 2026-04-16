import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../utils/appColors.dart';
import 'hoverWrapper.dart';

class LargeHoverCard extends StatelessWidget {
  final String value;
  final String label;
  final Color labelColor;
  final String icon;
  final Color iconColor;
  final Color bgColor;
  final bool isDark;
  final double? height;

  const LargeHoverCard({
    super.key,
    required this.value,
    required this.label,
    required this.labelColor,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.isDark,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return HoverWrapper(
      builder: (hover) {
        return AnimatedContainer(
          width: 190,
          height: height ?? 185,
          padding: const EdgeInsets.all(15),
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            border: Border.all(
              width: hover ? 1.5 : 0,
              color: hover ? iconColor.withOpacity(0.7) : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                spreadRadius: 2,
                color:
                    isDark ? tWhite.withOpacity(0.12) : tBlack.withOpacity(0.1),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ICON BOX
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    width: 28,
                    height: 28,
                    color: iconColor,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                value,
                style: GoogleFonts.urbanist(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                label,
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? tWhite : tBlack,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
