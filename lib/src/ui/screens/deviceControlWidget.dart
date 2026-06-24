import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/devicesModel.dart';
import '../../utils/appColors.dart';
import '../../utils/appLogger.dart';
import '../../utils/appResponsive.dart';
import 'deviceConfigurationInfoScreen.dart';
import 'deviceDiagnosticsInfoScreen.dart';
import 'deviceGeneralInfoScreen.dart';
import 'deviceInformationScreen.dart';

class DeviceControlWidget extends StatefulWidget {
  final DeviceEntity device;
  final int initialTab;

  const DeviceControlWidget({
    super.key,
    required this.device,
    this.initialTab = 0,
  });

  @override
  State<DeviceControlWidget> createState() => _DeviceControlWidgetState();
}

class _DeviceControlWidgetState extends State<DeviceControlWidget> {
  late int selectedIndex;
  // DateTime? selectedDate;
  DateTime selectedDate = DateTime.now();
  String? apiDate;
  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    // Always sync UI with router tab
    selectedIndex = widget.initialTab;

    return ResponsiveLayout(
      // mobile: const Center(child: Text("Mobile / Tablet layout coming soon")),
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    LoggerUtil.getInstance.print(widget.device);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ---------------------------
        /// Top Row (Tabs + Date Filter)
        /// ---------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_buildTabBar(context, isDark)],
        ),
        SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildLabelBox("Filter By Date", tGreen8, isDark),
            const SizedBox(width: 5),
            _buildDynamicDatePicker(isDark),
          ],
        ),

        const SizedBox(height: 10),

        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    LoggerUtil.getInstance.print(widget.device);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ---------------------------
        /// Top Row (Tabs + Date Filter)
        /// ---------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTabBar(context, isDark),
            Row(
              children: [
                _buildLabelBox("Filter By Date", tGreen8, isDark),
                const SizedBox(width: 5),
                _buildDynamicDatePicker(isDark),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        /// ---------------------------
        /// Dynamic Screen Content
        /// ---------------------------
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    LoggerUtil.getInstance.print(widget.device);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ---------------------------
        /// Top Row (Tabs + Date Filter)
        /// ---------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTabBar(context, isDark),
            Row(
              children: [
                _buildLabelBox("Filter By Date", tGreen8, isDark),
                const SizedBox(width: 5),
                _buildDynamicDatePicker(isDark),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        /// ---------------------------
        /// Dynamic Screen Content
        /// ---------------------------
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildTabContent(),
          ),
        ),
      ],
    );
  }

  /// ----------------------------------------------
  /// Build Tab Bar
  /// ----------------------------------------------
  // Widget _buildTabBar(BuildContext context, bool isDark) {
  //   return Container(
  //     width: 450,
  //     height: 40,
  //     decoration: BoxDecoration(
  //       border: Border.all(color: isDark ? tWhite : tBlack, width: 0.6),
  //     ),
  //     padding: const EdgeInsets.all(5),
  //     child: Row(
  //       children: [
  //         _buildTabButton("Overview", 0, () {
  //           context.go(
  //             '/home/devices/${widget.device.imei}/overview',
  //             extra: widget.device,
  //           );
  //         }, isDark),
  //         _buildTabButton("Go live", 1, () {
  //           context.go(
  //             '/home/devices/${widget.device.imei}/goLive',
  //             extra: widget.device,
  //           );
  //         }, isDark),
  //         _buildTabButton("Device Control", 2, () {
  //           context.go(
  //             '/home/devices/${widget.device.imei}/deviceControl',
  //             extra: widget.device,
  //           );
  //         }, isDark),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTabBar(BuildContext context, bool isDark) {
    final isDisconnected =
        widget.device.status?.toLowerCase() == "disconnected";

    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;

    final isTablet = screenWidth >= 600 && screenWidth < 1100;

    return Container(
      width: isMobile ? 300 : (isTablet ? 350 : 450),
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? tWhite : tBlack, width: 0.6),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton("Overview", 0, () {
            context.go(
              '/home/devices/${widget.device.imei}/overview',
              extra: widget.device,
            );
          }, isDark),

          if (!isDisconnected)
            _buildTabButton("Go live", 1, () {
              context.go(
                '/home/devices/${widget.device.imei}/goLive',
                extra: widget.device,
              );
            }, isDark),

          if (!isDisconnected)
            _buildTabButton("Information", 2, () {
              context.go(
                '/home/devices/${widget.device.imei}/information',
                extra: widget.device,
              );
            }, isDark),

          if (!isDisconnected)
            _buildTabButton("Device Control", 3, () {
              context.go(
                '/home/devices/${widget.device.imei}/deviceControl',
                extra: widget.device,
              );
            }, isDark),
        ],
      ),
    );
  }

  /// ----------------------------------------------
  /// Reusable Tab Button
  /// ----------------------------------------------
  Widget _buildTabButton(
    String label,
    int index,
    VoidCallback onTap,
    bool isDark,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;

    final isSelected = selectedIndex == index;

    return Expanded(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? tGreen8 : (isDark ? tBlack : tWhite),
          foregroundColor: isSelected ? tWhite : (isDark ? tWhite : tBlack),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: isMobile ? 10 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// ----------------------------------------------
  /// Tab content based on selectedIndex
  /// ----------------------------------------------
  // Widget _buildTabContent() {
  //   if (selectedIndex == 0) {
  //     return DeviceGeneralInfoScreen(
  //       device: widget.device,
  //       key: const ValueKey(0),
  //     );
  //   } else if (selectedIndex == 1) {
  //     return DeviceDiagnosticsInfoScreen(
  //       device: widget.device,
  //       key: const ValueKey(1),
  //     );
  //   } else {
  //     return DeviceConfigInfoScreen(
  //       device: widget.device,
  //       key: const ValueKey(2),
  //     );
  //   }
  // }
  // Widget _buildTabContent() {
  //   if (selectedIndex == 0) {
  //     return DeviceGeneralInfoScreen(
  //       device: widget.device,
  //       selectedDate: selectedDate,
  //       key: const ValueKey(0),
  //     );
  //   } else if (selectedIndex == 1) {
  //     return DeviceDiagnosticsInfoScreen(
  //       device: widget.device,
  //       key: const ValueKey(1),
  //     );
  //   } else {
  //     return DeviceConfigInfoScreen(
  //       device: widget.device,
  //       key: const ValueKey(2),
  //     );
  //   }
  // }
  Widget _buildTabContent() {
    if (selectedIndex == 0) {
      return DeviceGeneralInfoScreen(
        device: widget.device,
        selectedDate:
            apiDate != null
                ? DateTime.parse(apiDate!)
                : null, // Pass null if no date selected
        key: const ValueKey(0),
      );
    } else if (selectedIndex == 1) {
      return DeviceDiagnosticsInfoScreen(
        device: widget.device,
        key: const ValueKey(1),
      );
    } else if (selectedIndex == 2) {
      return DeviceInformationScreen(
        device: widget.device,
        key: const ValueKey(2),
      );
    } else {
      return DeviceConfigInfoScreen(
        device: widget.device,
        key: const ValueKey(3),
      );
    }
  }

  /// ----------------------------------------------
  /// Date Picker UI
  /// ----------------------------------------------
  // Widget _buildDynamicDatePicker(bool isDark) {
  //   return GestureDetector(
  //     onTap: _selectDate,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //       decoration: BoxDecoration(
  //         border: Border.all(width: 0.6, color: isDark ? tWhite : tBlack),
  //       ),
  //       child: Text(
  //         selectedDate == null
  //             ? "SELECT DATE"
  //             : DateFormat('dd MMM yyyy').format(selectedDate!).toUpperCase(),
  //         style: GoogleFonts.urbanist(
  //           fontSize: 12.5,
  //           fontWeight: FontWeight.w600,
  //           color: isDark ? tWhite : tBlack,
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _buildDynamicDatePicker(bool isDark) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(width: 0.6, color: isDark ? tWhite : tBlack),
        ),
        child: Text(
          DateFormat('dd MMM yyyy').format(selectedDate).toUpperCase(),
          style: GoogleFonts.urbanist(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? tWhite : tBlack,
          ),
        ),
      ),
    );
  }
  // Future<void> _selectDate() async {
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: selectedDate ?? DateTime.now(),
  //     firstDate: DateTime(2020),
  //     lastDate: DateTime(2030),
  //     builder: (context, child) {
  //       return Theme(
  //         data: Theme.of(context).copyWith(
  //           colorScheme: const ColorScheme.light(
  //             primary: Colors.blueAccent,
  //             onPrimary: Colors.white,
  //             onSurface: Colors.black,
  //           ),
  //         ),
  //         child: child!,
  //       );
  //     },
  //   );

  //   if (picked != null) {
  //     setState(() => selectedDate = picked);
  //   }
  // }

  // Future<void> _selectDate() async {
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: selectedDate,
  //     firstDate: DateTime(2020),
  //     lastDate: DateTime(2030),
  //   );

  //   if (picked != null && picked != selectedDate) {
  //     setState(() => selectedDate = picked);
  //   }
  // }
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        apiDate = DateFormat(
          'yyyy-MM-dd',
        ).format(picked); // Only set when user selects
      });
    }
  }

  Widget _buildLabelBox(String text, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(width: 0.5, color: isDark ? tWhite : tBlack),
      ),
      child: Text(
        text,
        style: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
