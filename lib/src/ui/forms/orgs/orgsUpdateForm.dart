import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg.dart';

import '../../../utils/appColors.dart';

Future<void> showOrgCreateUpdateDialog({
  required BuildContext context,
  required String title,
  required String confirmText,

  String? initialName,
  int initialDeviceType = 1,

  required Future<void> Function({
    required String name,
    required int deviceType,
  })
  onConfirm,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final nameCtrl = TextEditingController(text: initialName);
  int selectedType = initialDeviceType;
  bool isLoading = false;
  final LayerLink layerLink = LayerLink();
  OverlayEntry? overlayEntry;
  final GlobalKey dropdownKey = GlobalKey();

  final List<Map<String, dynamic>> fleetTypes = [
    {"label": "ICE", "value": 1},
    {"label": "EV", "value": 2},
    {"label": "Both", "value": 3},
  ];

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 420,
              decoration: BoxDecoration(
                color: isDark ? tBlack : tWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔹 HEADER
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tGreen8.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SvgPicture.asset(
                            'icons/org.svg',
                            width: 22,
                            height: 22,
                            color: tGreen8,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          title,
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// 🔹 NAME FIELD
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? tWhite : tBlack,
                        ),
                        children: [
                          const TextSpan(text: "Organization Name "),
                          const TextSpan(
                            text: "*",

                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      enabled: !isLoading,
                      cursorColor: isDark ? tWhite : tBlack,

                      style: GoogleFonts.urbanist(
                        color: isDark ? tWhite : tBlack,
                      ),

                      decoration: InputDecoration(
                        hintText: "Enter organization name",
                        hintStyle: GoogleFonts.urbanist(
                          color:
                              isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.5),
                        ),
                        filled: false,
                        fillColor: isDark ? tBlack : tWhite,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color:
                                isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.2),
                          ),
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color:
                                isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.2),
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.6)
                                    : tBlack.withOpacity(0.6),
                          ),
                        ),

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// 🔹 DEVICE TYPE
                    // Text(
                    //   "Organization Fleet Type *",
                    //   style: GoogleFonts.urbanist(
                    //     fontSize: 13,
                    //     fontWeight: FontWeight.w600,
                    //     color: isDark ? tWhite : tBlack,
                    //   ),
                    // ),
                    // const SizedBox(height: 6),

                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     CompositedTransformTarget(
                    //       link: _layerLink,
                    //       child: GestureDetector(
                    //         onTap:
                    //             isLoading
                    //                 ? null
                    //                 : () {
                    //                   if (_overlayEntry == null) {
                    //                     final overlay = Overlay.of(context);

                    //                     _overlayEntry = OverlayEntry(
                    //                       builder: (context) {
                    //                         return Positioned(
                    //                           width: 380,
                    //                           child: CompositedTransformFollower(
                    //                             link: _layerLink,
                    //                             offset: const Offset(0, 45),
                    //                             showWhenUnlinked: false,
                    //                             child: Material(
                    //                               color: Colors.transparent,
                    //                               child: Container(
                    //                                 decoration: BoxDecoration(
                    //                                   color:
                    //                                       isDark
                    //                                           ? tBlack
                    //                                               .withOpacity(
                    //                                                 0.95,
                    //                                               )
                    //                                           : Colors.white,
                    //                                   border: Border.all(
                    //                                     color:
                    //                                         isDark
                    //                                             ? tWhite
                    //                                                 .withOpacity(
                    //                                                   0.1,
                    //                                                 )
                    //                                             : Colors
                    //                                                 .grey
                    //                                                 .shade300,
                    //                                     width: 1.2,
                    //                                   ),
                    //                                   boxShadow: [
                    //                                     if (!isDark)
                    //                                       BoxShadow(
                    //                                         color: Colors.black
                    //                                             .withOpacity(
                    //                                               0.04,
                    //                                             ),
                    //                                         blurRadius: 12,
                    //                                         offset:
                    //                                             const Offset(
                    //                                               0,
                    //                                               4,
                    //                                             ),
                    //                                       ),
                    //                                   ],
                    //                                 ),
                    //                                 child: ListView(
                    //                                   padding: EdgeInsets.zero,
                    //                                   shrinkWrap: true,
                    //                                   children:
                    //                                       fleetTypes.map((
                    //                                         type,
                    //                                       ) {
                    //                                         return InkWell(
                    //                                           onTap: () {
                    //                                             setState(() {
                    //                                               selectedType =
                    //                                                   type["value"];
                    //                                             });

                    //                                             _overlayEntry
                    //                                                 ?.remove();
                    //                                             _overlayEntry =
                    //                                                 null;
                    //                                           },
                    //                                           child: Container(
                    //                                             padding:
                    //                                                 const EdgeInsets.symmetric(
                    //                                                   horizontal:
                    //                                                       12,
                    //                                                   vertical:
                    //                                                       10,
                    //                                                 ),
                    //                                             child: Text(
                    //                                               type["label"],
                    //                                               style: GoogleFonts.urbanist(
                    //                                                 fontSize:
                    //                                                     12,
                    //                                                 fontWeight:
                    //                                                     FontWeight
                    //                                                         .w600,
                    //                                                 color:
                    //                                                     isDark
                    //                                                         ? tWhite
                    //                                                         : Colors.black87,
                    //                                               ),
                    //                                             ),
                    //                                           ),
                    //                                         );
                    //                                       }).toList(),
                    //                                 ),
                    //                               ),
                    //                             ),
                    //                           ),
                    //                         );
                    //                       },
                    //                     );

                    //                     overlay.insert(_overlayEntry!);
                    //                   } else {
                    //                     _overlayEntry?.remove();
                    //                     _overlayEntry = null;
                    //                   }
                    //                 },
                    //         child: Container(
                    //           width: double.infinity,
                    //           height: 42,
                    //           padding: const EdgeInsets.symmetric(
                    //             horizontal: 12,
                    //           ),
                    //           decoration: BoxDecoration(
                    //             color: isDark ? tBlack : tWhite,
                    //             borderRadius: BorderRadius.circular(10),
                    //             border: Border.all(
                    //               color:
                    //                   isDark
                    //                       ? tWhite.withOpacity(0.2)
                    //                       : tBlack.withOpacity(0.2),
                    //             ),
                    //           ),
                    //           child: Row(
                    //             mainAxisAlignment:
                    //                 MainAxisAlignment.spaceBetween,
                    //             children: [
                    //               Text(
                    //                 fleetTypes.firstWhere(
                    //                   (e) => e["value"] == selectedType,
                    //                 )["label"],
                    //                 style: GoogleFonts.urbanist(
                    //                   fontSize: 14,
                    //                   fontWeight: FontWeight.w500,
                    //                   color: isDark ? tWhite : tBlack,
                    //                 ),
                    //               ),
                    //               Icon(
                    //                 Icons.expand_more_rounded,
                    //                 size: 20,
                    //                 color:
                    //                     isDark
                    //                         ? tWhite.withOpacity(0.8)
                    //                         : Colors.grey.shade700,
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? tWhite : tBlack,
                        ),
                        children: [
                          const TextSpan(text: "Organization Fleet Type "),
                          const TextSpan(
                            text: "*",

                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    CompositedTransformTarget(
                      key: dropdownKey,
                      link: layerLink,
                      child: GestureDetector(
                        onTap:
                            isLoading
                                ? null
                                : () {
                                  if (overlayEntry == null) {
                                    final RenderBox renderBox =
                                        dropdownKey.currentContext!
                                                .findRenderObject()
                                            as RenderBox;

                                    final size = renderBox.size;

                                    overlayEntry = OverlayEntry(
                                      builder: (context) {
                                        return Positioned(
                                          width: size.width,
                                          child: CompositedTransformFollower(
                                            link: layerLink,
                                            offset: const Offset(0, 50),
                                            showWhenUnlinked: false,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      isDark
                                                          ? tBlack.withOpacity(
                                                            0.95,
                                                          )
                                                          : Colors.white,
                                                  border: Border.all(
                                                    color:
                                                        isDark
                                                            ? tWhite
                                                                .withOpacity(
                                                                  0.2,
                                                                )
                                                            : tBlack
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                    width: 1.2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  boxShadow: [
                                                    if (!isDark)
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.04),
                                                        blurRadius: 12,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                child: ListView(
                                                  padding: EdgeInsets.zero,
                                                  shrinkWrap: true,
                                                  children:
                                                      fleetTypes.map((type) {
                                                        return InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              selectedType =
                                                                  type["value"];
                                                            });

                                                            overlayEntry
                                                                ?.remove();
                                                            overlayEntry = null;
                                                          },
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 10,
                                                                ),
                                                            child: Text(
                                                              type["label"],
                                                              style: GoogleFonts.urbanist(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    isDark
                                                                        ? tWhite
                                                                        : Colors
                                                                            .black87,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    Overlay.of(context).insert(overlayEntry!);
                                  } else {
                                    overlayEntry?.remove();
                                    overlayEntry = null;
                                  }
                                },
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? tBlack : tWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.4)
                                      : tBlack.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                fleetTypes.firstWhere(
                                  (e) => e["value"] == selectedType,
                                  orElse: () => {"label": "Select Type"},
                                )["label"],
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? tWhite : Colors.black87,
                                ),
                              ),
                              Icon(
                                Icons.expand_more_rounded,
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.7)
                                        : Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 🔹 ACTIONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? tWhite : tBlack,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tGreen8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed:
                              isLoading
                                  ? null
                                  : () async {
                                    if (nameCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Name is required"),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => isLoading = true);

                                    try {
                                      await onConfirm(
                                        name: nameCtrl.text.trim(),
                                        deviceType: selectedType,
                                      );
                                      // Navigator.pop(dialogContext);
                                      Navigator.of(context).pop();
                                    } catch (e) {
                                      setState(() => isLoading = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  },
                          child:
                              isLoading
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    confirmText,
                                    style: GoogleFonts.urbanist(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: tWhite,
                                    ),
                                  ),
                        ),
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
