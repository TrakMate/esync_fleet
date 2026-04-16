import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../../utils/appColors.dart';

class FleetTitleBar extends StatelessWidget {
  final bool isDark;
  final String title;

  const FleetTitleBar({super.key, required this.isDark, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ---------------- Home Button ----------------
        TextButton(
          onPressed: () {
            context.go('/fleetmodeselection');
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            foregroundColor: tBlue,
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'icons/home.svg',
                width: 18,
                height: 18,
                color: tBlue,
              ),
              const SizedBox(width: 5),
              Text(
                'Home',
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: tBlue,
                ),
              ),
            ],
          ),
        ),

        // -------- Slash Divider --------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "/",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
            ),
          ),
        ),

        // ---------------- Dynamic Title ----------------
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),
      ],
    );
  }
}
