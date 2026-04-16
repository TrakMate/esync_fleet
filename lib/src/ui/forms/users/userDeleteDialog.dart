import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/appColors.dart';

Future<void> showUserDeleteConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required Future<void> Function() onConfirm,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  bool isLoading = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (_, setState) {
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
                            color: tRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delete_forever_rounded,
                            color: tRed,
                            size: 22,
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
                        color: tRed.withOpacity(0.9),
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
                            "Cancel",
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
                            backgroundColor: tRed,
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
                                    "Delete",
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
