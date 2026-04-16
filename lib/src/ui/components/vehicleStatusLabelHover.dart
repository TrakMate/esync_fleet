import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/appColors.dart';

class StatusLabel extends StatefulWidget {
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const StatusLabel({
    super.key,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<StatusLabel> createState() => _StatusLabelState();
}

class _StatusLabelState extends State<StatusLabel> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color:
                isHovering
                    ? (widget.isDark
                        ? tWhite.withOpacity(0.1)
                        : tBlack.withOpacity(0.05))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 12, width: 12, color: widget.color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color:
                      isHovering
                          ? widget.color
                          : (widget.isDark ? tWhite : tBlack),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
