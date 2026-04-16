import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg.dart';
import '../../../models/CRUDModels/groupsCRUDModel.dart';
import '../../../utils/appColors.dart';

Future<void> showDeviceCreateUpdateDialog({
  required BuildContext context,
  required String title,

  // Initial values
  required String initialImei,
  String? initialVehicleNo,
  String? initialDeviceType,
  String? initialBatteryNo,
  String? initialGroupId,
  String? initialVehicleModel,
  String? initialDealerCode,
  String? initialRtoNumber,
  String? initialFgCode,

  required List<GroupEntity> allGroups,

  String confirmText = "Save",
  String cancelText = "Cancel",

  required Future<void> Function({
    required String imei,
    required String vehicleNo,
    required String deviceType,
    required String batteryNo,
    required String group,
    required String vehicleModel,
    required String dealerCode,
    required String rtoNumber,
    required String fgCode,
  })
  onConfirm,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final imeiCtrl = TextEditingController(text: initialImei);
  final vehicleNoCtrl = TextEditingController(text: initialVehicleNo ?? "");
  final batteryNoCtrl = TextEditingController(text: initialBatteryNo ?? "");
  final vehicleModelCtrl = TextEditingController(
    text: initialVehicleModel ?? "",
  );
  final dealerCodeCtrl = TextEditingController(text: initialDealerCode ?? "");
  final rtoCtrl = TextEditingController(text: initialRtoNumber ?? "");
  final fgCodeCtrl = TextEditingController(text: initialFgCode ?? "");

  String selectedDeviceType = initialDeviceType ?? "NON_EV";
  String selectedGroup = initialGroupId ?? "";

  bool isLoading = false;

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
              width: 600,
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
                              color: tBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SvgPicture.asset(
                              'icons/device.svg',
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
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              isDark: isDark,
                              label: "IMEI",
                              hint: "Enter IMEI",
                              controller: imeiCtrl,
                              disabled: initialImei.isNotEmpty,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _textField(
                              isDark: isDark,
                              label: "Vehicle Number",
                              hint: "TN01AB1234",
                              controller: vehicleNoCtrl,
                              disabled: isLoading,
                            ),
                          ),
                        ],
                      ),

                      _deviceTypeChips(
                        isDark,
                        selectedDeviceType,
                        (v) => setState(() => selectedDeviceType = v),
                      ),
                      const SizedBox(height: 10),

                      if (selectedDeviceType != "NON_EV") ...[
                        _textField(
                          isDark: isDark,
                          label: "Battery Number",
                          hint: "Battery No",
                          controller: batteryNoCtrl,
                          disabled: isLoading,
                        ),
                      ],

                      _groupSelectorSingle(
                        isDark,
                        allGroups,
                        selectedGroup,
                        (v) => setState(() => selectedGroup = v),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              isDark: isDark,
                              label: "Vehicle Model",
                              hint: "Model",
                              controller: vehicleModelCtrl,
                              disabled: isLoading,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _textField(
                              isDark: isDark,
                              label: "Dealer Code",
                              hint: "Dealer Code",
                              controller: dealerCodeCtrl,
                              disabled: isLoading,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              isDark: isDark,
                              label: "Registration Number",
                              hint: "RTO",
                              controller: rtoCtrl,
                              disabled: isLoading,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _textField(
                              isDark: isDark,
                              label: "FG Code",
                              hint: "FG Code",
                              controller: fgCodeCtrl,
                              disabled: isLoading,
                            ),
                          ),
                        ],
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
                                      if (vehicleNoCtrl.text.trim().isEmpty ||
                                          selectedGroup.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Vehicle No and Group are mandatory",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() => isLoading = true);

                                      try {
                                        await onConfirm(
                                          imei: imeiCtrl.text.trim(),
                                          vehicleNo: vehicleNoCtrl.text.trim(),
                                          deviceType: selectedDeviceType,
                                          batteryNo: batteryNoCtrl.text.trim(),
                                          group: selectedGroup,
                                          vehicleModel:
                                              vehicleModelCtrl.text.trim(),
                                          dealerCode:
                                              dealerCodeCtrl.text.trim(),
                                          rtoNumber: rtoCtrl.text.trim(),
                                          fgCode: fgCodeCtrl.text.trim(),
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

Widget _deviceTypeChips(
  bool isDark,
  String selectedType,
  ValueChanged<String> onChanged,
) {
  final types = [
    {"key": "NON_EV", "label": "Non EV", "color": tBlue},
    {"key": "EV", "label": "EV", "color": tGreen3},
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// ---------------- LABEL ----------------
      RichText(
        text: TextSpan(
          text: 'Device Type',
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
            types.map((type) {
              final isSelected = selectedType == type["key"];
              final color = type["color"] as Color;

              return ChoiceChip(
                selected: isSelected,
                showCheckmark: true,
                checkmarkColor: isDark ? tBlack : tWhite,
                label: Text(
                  type["label"] as String,
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? (isDark ? tBlack : tWhite) : color,
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
                onSelected: (_) => onChanged(type["key"] as String),
              );
            }).toList(),
      ),
    ],
  );
}
