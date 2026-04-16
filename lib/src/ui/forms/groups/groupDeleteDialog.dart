import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/appColors.dart';

Future<void> showGroupConfirmDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = "Delete",
  String cancelText = "Cancel",
  Color confirmColor = tRed,
  IconData icon = Icons.delete_forever_rounded,
  required Future<void> Function() onConfirm,
}) async {
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
                            color: confirmColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: confirmColor, size: 22),
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

                    const SizedBox(height: 14),

                    /// ---------------- MESSAGE ----------------
                    Text(
                      message,
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

                    const SizedBox(height: 10),

                    /// ---------------- WARNING NOTE ----------------
                    Text(
                      "This action cannot be undone.",
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: confirmColor.withOpacity(0.9),
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
                            backgroundColor: confirmColor,
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
                                    setState(() => isLoading = true);
                                    try {
                                      await onConfirm();
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
