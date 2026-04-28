import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg.dart';
import '../../../models/CRUDModels/groupsCRUDModel.dart';
import '../../../utils/appColors.dart';

Future<void> showUserCreateUpdateDialog({
  required BuildContext context,
  required String title,
  String? initialUsername,
  String? initialName,
  String? initialPhone,
  List<String> initialGroups = const [],
  String initialRole = "VIEWER",
  bool initialActive = true,
  required List<GroupEntity> allGroups, // dropdown data
  String confirmText = "Save",
  String cancelText = "Cancel",
  required Future<void> Function({
    required String userName,
    required String name,
    required String phone,
    required List<String> groups,
    required String role,
    required bool active,
  })
  onConfirm,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final usernameCtrl = TextEditingController(text: initialUsername);
  final nameCtrl = TextEditingController(text: initialName);
  final phoneCtrl = TextEditingController(text: initialPhone);

  List<String> selectedGroups = List.from(initialGroups);
  String selectedRole = initialRole;
  bool isActive = initialActive;
  bool isLoading = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 650,
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
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// ---------------- HEADER ----------------
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tGreen8.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            // child: Icon(
                            //   Icons.group_rounded,
                            //   color: tBlue,
                            //   size: 22,
                            // ),
                            child: SvgPicture.asset(
                              'icons/user.svg', // 👈 SAME icon as button
                              width: 22,
                              height: 22,
                              color: tGreen8,
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
                      _textField(
                        isDark: isDark,
                        label: "Username",
                        hint: "Enter username",
                        controller: usernameCtrl,
                        disabled: isLoading,
                        note: "* Username is mandatory",
                      ),

                      _textField(
                        isDark: isDark,
                        label: "Full Name",
                        hint: "Enter full name",
                        controller: nameCtrl,
                        disabled: isLoading,
                      ),

                      _textField(
                        isDark: isDark,
                        label: "Phone Number",
                        hint: "Enter mobile number",
                        keyboard: TextInputType.phone,
                        controller: phoneCtrl,
                        disabled: isLoading,
                        note: "* 10 digit number required",
                      ),

                      _groupSelector(
                        isDark,
                        allGroups,
                        selectedGroups,
                        (v) => setState(() => selectedGroups = v),
                      ),

                      const SizedBox(height: 10),

                      _roleChips(
                        isDark,
                        selectedRole,
                        (v) => setState(() => selectedRole = v),
                      ),

                      const SizedBox(height: 10),

                      _activeToggle(
                        isDark,
                        isActive,
                        (v) => setState(() => isActive = v),
                      ),

                      const SizedBox(height: 10),
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
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tGreen8,
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
                                      if (usernameCtrl.text.trim().isEmpty ||
                                          nameCtrl.text.trim().isEmpty ||
                                          phoneCtrl.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "All mandatory fields required",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() => isLoading = true);

                                      try {
                                        await onConfirm(
                                          userName:
                                              usernameCtrl.text
                                                  .trim()
                                                  .toLowerCase(),
                                          name: nameCtrl.text.trim(),
                                          phone: phoneCtrl.text.trim(),
                                          groups: selectedGroups,
                                          role: selectedRole,
                                          active: isActive,
                                        );
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
            ),
          );
        },
      );
    },
  );
}

Widget _textField({
  required bool isDark,
  required String label,
  required String hint,
  required TextEditingController controller,
  required bool disabled,
  bool requiredField = true,
  TextInputType keyboard = TextInputType.text,
  String? note,
  bool autofocus = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ---------------- FIELD LABEL ----------------
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? tWhite : tBlack,
            ),
            children:
                requiredField
                    ? [
                      TextSpan(
                        text: ' *',
                        style: GoogleFonts.urbanist(color: tRed),
                      ),
                    ]
                    : const [],
          ),
        ),

        const SizedBox(height: 5),

        /// ---------------- INPUT ----------------
        TextField(
          controller: controller,
          autofocus: autofocus,
          enabled: !disabled,
          keyboardType: keyboard,
          cursorColor: isDark ? tWhite : tBlack,
          style: GoogleFonts.urbanist(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            filled: false,
            fillColor:
                isDark ? tWhite.withOpacity(0.05) : tBlack.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    isDark ? tWhite.withOpacity(0.2) : tBlack.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),

        /// ---------------- NOTE ----------------
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(
            note,
            style: GoogleFonts.urbanist(
              fontSize: 11,
              color: tRed.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
  );
}

Color _groupColor(String id) {
  final colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.deepOrange,
  ];

  if (id.isEmpty) return Colors.grey;

  return colors[id.hashCode.abs() % colors.length];
}

Widget _groupSelector(
  bool isDark,
  List<GroupEntity> groups,
  List<String> selected,
  ValueChanged<List<String>> onChanged,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// ---------------- LABEL ----------------
      RichText(
        text: TextSpan(
          text: 'Groups',
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? tWhite : tBlack,
          ),
          children: const [TextSpan(text: ' *', style: TextStyle(color: tRed))],
        ),
      ),

      const SizedBox(height: 5),

      /// ---------------- CHIPS ----------------
      Wrap(
        spacing: 5,
        runSpacing: 5,
        children:
            groups.map((g) {
              final id = g.id ?? '';
              final isSelected = selected.contains(id);
              final baseColor = _groupColor(id);

              return FilterChip(
                selected: isSelected,
                showCheckmark: true,
                checkmarkColor: tWhite,
                label: Text(
                  g.name ?? '',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? (tWhite) : baseColor,
                  ),
                ),
                backgroundColor: baseColor.withOpacity(0.12),
                selectedColor: baseColor.withOpacity(0.85),
                side: BorderSide(
                  color: isSelected ? baseColor : Colors.transparent,
                  width: isSelected ? 2 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (v) {
                  final copy = List<String>.from(selected);
                  v ? copy.add(id) : copy.remove(id);
                  onChanged(copy);
                },
              );
            }).toList(),
      ),
    ],
  );
}

Widget _roleChips(
  bool isDark,
  String selectedRole,
  ValueChanged<String> onChanged,
) {
  final roles = [
    {"key": "ADMIN", "label": "Admin", "color": Colors.deepOrange},
    {"key": "VIEWER", "label": "Viewer", "color": Colors.blue},
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// ---------------- LABEL ----------------
      RichText(
        text: TextSpan(
          text: 'Role',
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? tWhite : tBlack,
          ),
          children: const [TextSpan(text: ' *', style: TextStyle(color: tRed))],
        ),
      ),

      const SizedBox(height: 6),

      /// ---------------- CHIPS ----------------
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            roles.map((role) {
              final isSelected = selectedRole == role["key"];
              final color = role["color"] as Color;

              return ChoiceChip(
                selected: isSelected,
                showCheckmark: true,
                checkmarkColor: tWhite,
                label: Text(
                  role["label"] as String,
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? (tWhite) : color,
                  ),
                ),
                backgroundColor: color.withOpacity(0.12),
                selectedColor: color.withOpacity(0.85),
                side: BorderSide(
                  color: isSelected ? color : Colors.transparent,
                  width: isSelected ? 2 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (_) => onChanged(role["key"] as String),
              );
            }).toList(),
      ),
    ],
  );
}

Widget _activeToggle(bool isDark, bool value, ValueChanged<bool> onChanged) {
  return SwitchListTile(
    value: value,
    onChanged: onChanged,
    activeColor: tGreen8,
    inactiveThumbColor:
        isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
    title: Text(
      value ? "Active" : "Inactive",
      style: GoogleFonts.urbanist(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: value ? tGreen8 : tRed,
      ),
    ),
    subtitle: Text(
      "** Inactive users cannot login",
      style: GoogleFonts.urbanist(
        fontSize: 12,
        color: isDark ? tWhite.withOpacity(0.8) : tBlack.withOpacity(0.8),
      ),
    ),
  );
}
