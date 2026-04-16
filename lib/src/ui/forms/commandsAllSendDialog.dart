import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/CRUDModels/groupsCRUDModel.dart';
import '../../utils/appColors.dart';

Future<void> showSendCommandDialog({
  required BuildContext context,
  required List<GroupEntity> allGroups,
  // required List<String> Function(String groupId) getImeisByGroup,
  // required Future<void> Function(List<String> imeis, String command) onConfirm,
  required Future<void> Function(List<String> groupIds, String command)
  onConfirm,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  String selectedGroupId = "";
  String selectedCommand = "";
  final customCommandCtrl = TextEditingController();
  bool isLoading = false;

  final predefinedCommands = ["SHOW CONFIG", "SHOW IOSTATUS", "START OTA"];

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: isDark ? tBlack : tWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 520,
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
                          child: Icon(Icons.terminal, color: tBlue),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Send Command",
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// ---------------- GROUP ----------------
                    _groupSelectorSingle(
                      isDark,
                      allGroups,
                      selectedGroupId,
                      (v) => setState(() => selectedGroupId = v),
                    ),

                    const SizedBox(height: 16),

                    /// ---------------- PREDEFINED COMMANDS ----------------
                    Text(
                      "Quick Commands",
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          predefinedCommands.map((cmd) {
                            final isSelected = selectedCommand == cmd;
                            return ChoiceChip(
                              selected: isSelected,
                              label: Text(
                                cmd,
                                style: GoogleFonts.urbanist(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected
                                          ? (isDark ? tBlack : tWhite)
                                          : tBlue,
                                ),
                              ),
                              selectedColor: tBlue.withOpacity(0.9),
                              backgroundColor: tBlue.withOpacity(0.12),
                              onSelected: (_) {
                                setState(() {
                                  selectedCommand = cmd;
                                  customCommandCtrl.clear();
                                });
                              },
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 16),

                    /// ---------------- CUSTOM COMMAND ----------------
                    Text(
                      "Custom Command",
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),

                    const SizedBox(height: 6),

                    TextField(
                      controller: customCommandCtrl,
                      enabled: !isLoading,
                      style: GoogleFonts.urbanist(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Enter custom command",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) {
                        setState(() => selectedCommand = "");
                      },
                    ),

                    const SizedBox(height: 20),

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
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // onPressed:
                          // isLoading
                          //     ? null
                          //     : () async {
                          //       final command =
                          //           customCommandCtrl.text.trim().isNotEmpty
                          //               ? customCommandCtrl.text.trim()
                          //               : selectedCommand;

                          //       if (selectedGroup.isEmpty ||
                          //           command.isEmpty) {
                          //         ScaffoldMessenger.of(
                          //           context,
                          //         ).showSnackBar(
                          //           const SnackBar(
                          //             content: Text(
                          //               "Group and Command are required",
                          //             ),
                          //           ),
                          //         );
                          //         return;
                          //       }

                          //       setState(() => isLoading = true);

                          //       try {
                          //         final imeis = getImeisByGroup(
                          //           selectedGroup,
                          //         );

                          //         if (imeis.isEmpty) {
                          //           throw Exception(
                          //             "No devices found in selected group",
                          //           );
                          //         }

                          //         await onConfirm(imeis, command);
                          //         Navigator.pop(dialogContext);
                          //       } catch (e) {
                          //         setState(() => isLoading = false);
                          //         ScaffoldMessenger.of(
                          //           context,
                          //         ).showSnackBar(
                          //           SnackBar(content: Text(e.toString())),
                          //         );
                          //       }
                          //     },
                          onPressed:
                              isLoading
                                  ? null
                                  : () async {
                                    final command =
                                        customCommandCtrl.text.trim().isNotEmpty
                                            ? customCommandCtrl.text.trim()
                                            : selectedCommand;

                                    if (selectedGroupId.isEmpty ||
                                        command.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Group and Command are required",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => isLoading = true);

                                    try {
                                      await onConfirm([
                                        selectedGroupId,
                                      ], command);
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
                                    "Send",
                                    style: GoogleFonts.urbanist(
                                      fontWeight: FontWeight.w700,
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

Widget _groupSelectorSingle(
  bool isDark,
  List<GroupEntity> groups,
  String selected,
  ValueChanged<String> onChanged,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// ---------------- LABEL ----------------
      RichText(
        text: TextSpan(
          text: 'Group',
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
        spacing: 6,
        runSpacing: 6,
        children:
            groups.map((g) {
              final id = g.id ?? '';
              final isSelected = selected == id;
              final baseColor = _groupColor(id);

              return ChoiceChip(
                selected: isSelected,
                showCheckmark: true,
                checkmarkColor: isDark ? tBlack : tWhite,
                label: Text(
                  g.name ?? '',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? (isDark ? tBlack : tWhite) : baseColor,
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
                onSelected: (_) => onChanged(id),
              );
            }).toList(),
      ),
    ],
  );
}
