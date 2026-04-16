import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg.dart';

import '../../../utils/appColors.dart';

Future<void> showGroupCreateUpdateDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String label,
  String? initialValue,
  String confirmText = "Save",
  String cancelText = "Cancel",
  required Future<void> Function(String value) onConfirm,
}) async {
  final controller = TextEditingController(text: initialValue);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  bool isLoading = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: isDark ? tBlack : tWhite,
            child: SizedBox(
              width: 420,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ---------------- HEADER ----------------
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          // child: Icon(
                          //   Icons.group_rounded,
                          //   color: tBlue,
                          //   size: 22,
                          // ),
                          child: SvgPicture.asset(
                            'icons/group.svg',
                            width: 22,
                            height: 22,
                            color: tBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
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

                    const SizedBox(height: 12),

                    /// ---------------- DESCRIPTION ----------------
                    Text(
                      description,
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark
                                ? tWhite.withOpacity(0.7)
                                : tBlack.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ---------------- FIELD LABEL ----------------
                    RichText(
                      text: TextSpan(
                        text: label,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? tWhite : tBlack,
                        ),
                        children: const [
                          TextSpan(text: ' *', style: TextStyle(color: tRed)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// ---------------- INPUT ----------------
                    TextField(
                      controller: controller,
                      autofocus: true,
                      cursorColor: isDark ? tWhite : tBlack,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        hintText: "Enter group name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.2)
                                    : tBlack.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.5)
                                    : tBlack.withOpacity(0.5),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// ---------------- NOTE ----------------
                    Text(
                      "* Group name is mandatory",
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        color: tRed.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 26),

                    /// ---------------- ACTIONS ----------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                          child: Text(
                            cancelText,
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.7)
                                      : tBlack.withOpacity(0.7),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed:
                              isLoading
                                  ? null
                                  : () async {
                                    final value = controller.text.trim();
                                    if (value.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Group name is required",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => isLoading = true);
                                    try {
                                      await onConfirm(value);
                                      Navigator.pop(dialogContext);
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
