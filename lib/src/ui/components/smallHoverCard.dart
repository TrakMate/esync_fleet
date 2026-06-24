import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../utils/appColors.dart';
import 'hoverWrapper.dart';

// class SmallHoverCard extends StatelessWidget {
//   final String value;
//   final String label;
//   final Color labelColor;
//   final String icon;
//   final Color iconColor;
//   final Color bgColor;
//   final bool isDark;
//   final bool enableHover;
//   final double? width; // DYNAMIC WIDTH
//   final double? height; // Optional small height

//   const SmallHoverCard({
//     super.key,
//     required this.value,
//     required this.label,
//     required this.labelColor,
//     required this.icon,
//     required this.iconColor,
//     required this.bgColor,
//     required this.isDark,
//     this.enableHover = true,
//     this.width,
//     this.height,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isMobile = MediaQuery.of(context).size.width < 600;

//     Widget card(bool hover) {
//       return AnimatedContainer(
//         width: width,
//         height: height,
//         padding: const EdgeInsets.all(10),
//         duration: const Duration(milliseconds: 200),
//         decoration: BoxDecoration(
//           color: isDark ? tBlack : tWhite,
//           border: Border.all(
//             width: hover ? 1.5 : 0,
//             color: hover ? iconColor.withOpacity(0.7) : Colors.transparent,
//           ),
//           boxShadow: [
//             BoxShadow(
//               blurRadius: 12,
//               spreadRadius: 2,
//               color:
//                   isDark ? tWhite.withOpacity(0.12) : tBlack.withOpacity(0.1),
//             ),
//           ],
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Container(
//               width: 35,
//               height: 35,
//               decoration: BoxDecoration(
//                 color: bgColor,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Center(
//                 child: SvgPicture.asset(
//                   icon,
//                   width: 18,
//                   height: 18,
//                   color: iconColor,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   label,
//                   style: GoogleFonts.urbanist(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: labelColor,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   value,
//                   style: GoogleFonts.urbanist(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: isDark ? tWhite : tBlack,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       );
//     }

//     if (!enableHover) {
//       return card(false);
//     }

//     return HoverWrapper(builder: (hover) => card(hover));
//   }
// }

class SmallHoverCard extends StatelessWidget {
  final String value;
  final String label;
  final Color labelColor;
  final String icon;
  final Color iconColor;
  final Color bgColor;
  final bool isDark;
  final bool enableHover;
  final double? width;
  final double? height;

  const SmallHoverCard({
    super.key,
    required this.value,
    required this.label,
    required this.labelColor,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.isDark,
    this.enableHover = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget card(bool hover) {
      return AnimatedContainer(
        width: width,
        height: height,
        padding: const EdgeInsets.all(10),
        duration: const Duration(milliseconds: 200),

        decoration: BoxDecoration(
          color: isDark ? tBlack : tWhite,
          borderRadius: BorderRadius.circular(20),
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

        /// =========================
        /// MOBILE LAYOUT
        /// =========================
        child:
            isMobile
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// ICON + LABEL
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),

                          child: Center(
                            child: SvgPicture.asset(
                              icon,
                              width: 16,
                              height: 16,
                              color: iconColor,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.urbanist(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// VALUE
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                  ],
                )
                /// =========================
                /// TABLET + DESKTOP (OLD UI)
                /// =========================
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: Center(
                        child: SvgPicture.asset(
                          icon,
                          width: 18,
                          height: 18,
                          color: iconColor,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            value,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.urbanist(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? tWhite : tBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      );
    }

    if (!enableHover) {
      return card(false);
    }

    return HoverWrapper(builder: (hover) => card(hover));
  }
}
