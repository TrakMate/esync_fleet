import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/appColors.dart';

Future<void> showResetPasswordDialog({
  required BuildContext context,
  required String userName,
  required Future<void> Function(String password) onConfirm,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final newPwdCtrl = TextEditingController();
  final confirmPwdCtrl = TextEditingController();

  bool isLoading = false;
  bool showNewPwd = false;
  bool showConfirmPwd = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (_, setState) {
          return Dialog(
            backgroundColor: isDark ? tBlack : tWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: tBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Reset Password",
                              style: GoogleFonts.urbanist(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? tWhite : tBlack,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userName,
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.6)
                                        : tBlack.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    /// ---------------- DESCRIPTION ----------------
                    Text(
                      "Set a new password for this user. The user will need to login again using the new password.",
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

                    const SizedBox(height: 18),

                    /// ---------------- NEW PASSWORD ----------------
                    _passwordField(
                      isDark: isDark,
                      label: "New Password",
                      hint: "Enter new password",
                      controller: newPwdCtrl,
                      obscure: !showNewPwd,
                      toggle: () => setState(() => showNewPwd = !showNewPwd),
                    ),

                    const SizedBox(height: 12),

                    /// ---------------- CONFIRM PASSWORD ----------------
                    _passwordField(
                      isDark: isDark,
                      label: "Confirm Password",
                      hint: "Re-enter password",
                      controller: confirmPwdCtrl,
                      obscure: !showConfirmPwd,
                      toggle:
                          () =>
                              setState(() => showConfirmPwd = !showConfirmPwd),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "* Minimum 6 characters required",
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: tRed.withOpacity(0.8),
                      ),
                    ),

                    const SizedBox(height: 24),

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
                            backgroundColor: tBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
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
                                    final newPwd = newPwdCtrl.text.trim();
                                    final confirmPwd =
                                        confirmPwdCtrl.text.trim();

                                    if (newPwd.length < 6) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Password must be at least 6 characters",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    if (newPwd != confirmPwd) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Passwords do not match",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => isLoading = true);
                                    try {
                                      await onConfirm(newPwd);
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
                                    "Reset Password",
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

Widget _passwordField({
  required bool isDark,
  required String label,
  required String hint,
  required TextEditingController controller,
  required bool obscure,
  required VoidCallback toggle,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.urbanist(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? tWhite : tBlack,
        ),
      ),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        obscureText: obscure,
        cursorColor: isDark ? tWhite : tBlack,
        style: GoogleFonts.urbanist(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          filled: false,
          fillColor:
              isDark ? tWhite.withOpacity(0.05) : tBlack.withOpacity(0.03),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              size: 20,
            ),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? tWhite.withOpacity(0.2) : tBlack.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    ],
  );
}
