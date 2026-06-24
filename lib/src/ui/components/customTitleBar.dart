import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../utils/appColors.dart';

class FleetTitleBar extends StatelessWidget {
  final bool isDark;
  final String title;
  final List<BreadcrumbItem>? breadcrumbs;

  const FleetTitleBar({
    super.key,
    required this.isDark,
    required this.title,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

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
            foregroundColor: tGreen8,
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'icons/home.svg',
                width: isMobile ? 16 : 18,
                height: isMobile ? 16 : 18,
                color: tGreen8,
              ),
              const SizedBox(width: 5),
              Text(
                'Home',
                style: GoogleFonts.urbanist(
                  fontSize: isMobile ? 12 : 15,
                  fontWeight: FontWeight.w600,
                  color: tGreen8,
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

        if (breadcrumbs != null && breadcrumbs!.isNotEmpty)
          _buildBreadcrumbItem(
            context,
            breadcrumbs![0].label,
            breadcrumbs![0].onTap,
            isDark,
          ),

        if (breadcrumbs != null && breadcrumbs!.length > 1)
          ..._buildAdditionalBreadcrumbs(context, breadcrumbs!, isDark),

        if (breadcrumbs == null || breadcrumbs!.isEmpty)
          Text(
            title,
            style: GoogleFonts.urbanist(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: isDark ? tWhite : tBlack,
            ),
          ),
      ],
    );
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    String label,
    VoidCallback? onTap,
    bool isDark,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.urbanist(
          fontSize: isMobile ? 16 : 20,
          fontWeight: FontWeight.bold,
          color: onTap != null ? tGreen8 : (isDark ? tWhite : tBlack),
          // decoration: onTap != null ? TextDecoration.underline : null,
        ),
      ),
    );
  }

  List<Widget> _buildAdditionalBreadcrumbs(
    BuildContext context,
    List<BreadcrumbItem> breadcrumbs,
    bool isDark,
  ) {
    final widgets = <Widget>[];

    for (int i = 1; i < breadcrumbs.length; i++) {
      widgets.add(
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
      );

      widgets.add(
        _buildBreadcrumbItem(
          context,
          breadcrumbs[i].label,
          breadcrumbs[i].onTap,
          isDark,
        ),
      );
    }

    return widgets;
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.label, this.onTap});
}
