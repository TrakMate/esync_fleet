import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:svg_flutter/svg_flutter.dart';
import '../../../models/CRUDModels/devicesCRUDModel.dart';
import '../../../models/CRUDModels/groupsCRUDModel.dart';
import '../../../services/CRUDServices/devicesCRUDService.dart';
import '../../../services/CRUDServices/groupsCRUDService.dart';
import '../../../utils/appColors.dart';
import '../../forms/devices/deviceCreateUpdateForm.dart';

class DevicesCRUDScreen extends StatefulWidget {
  const DevicesCRUDScreen({super.key});

  @override
  State<DevicesCRUDScreen> createState() => _DevicesCRUDScreenState();
}

class _DevicesCRUDScreenState extends State<DevicesCRUDScreen> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  int page = 1;
  int sizePerPage = 10;

  bool isLoading = false;
  bool isError = false;
  String? errorMessage;

  int totalCount = 0;
  int currentPage = 1;
  int totalPages = 1;

  List<Entities> filteredallDevices = [];
  List<GroupEntity> groups = [];
  final DevicesCRUDApiService _devicesApiService = DevicesCRUDApiService();
  final _apiService = GroupsApiService();

  final List<int> pageSizeOptions = [10, 25, 50, 100];
  String orgType = '';
  int currentIndex = 0;
  String? selectedGroup;

  bool isGroupsLoading = false;

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _loadGroups();
  }

  Future<void> _initialLoad() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      filteredallDevices.clear();
      currentPage = 1;
      currentIndex = 0;
    });

    await _reloadDevices();
  }

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "--";
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat("yyyy-MM-dd HH:mm").format(parsed);
    } catch (_) {
      return "--";
    }
  }

  /// ---------- FIXED RELOAD DEVICES LOGIC ----------
  Future<void> _reloadDevices() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isError = false;
      errorMessage = null;
    });

    try {
      final result = await _devicesApiService.fetchDevices(
        page: currentPage,
        sizePerPage: sizePerPage,
      );

      if (!mounted) return;

      setState(() {
        filteredallDevices = result.entities ?? [];
        totalCount = result.totalCount ?? 0;
        totalPages = totalCount == 0 ? 1 : (totalCount / sizePerPage).ceil();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = e.toString();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;

    setState(() => isGroupsLoading = true);

    try {
      final result = await _apiService.fetchGroups(
        page: 1,
        sizePerPage: 100, // load all groups
      );

      if (!mounted) return;

      setState(() {
        groups = result.entities ?? [];
        isGroupsLoading = false;
      });
    } catch (e) {
      debugPrint("Group fetch error: $e");
      if (mounted) setState(() => isGroupsLoading = false);
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             "Devices",
  //             style: GoogleFonts.urbanist(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //               color: isDark ? tWhite : tBlack,
  //             ),
  //           ),
  //           Row(
  //             children: [
  //               _addNewDeviceButton(isDark),
  //               const SizedBox(width: 10),
  //               Container(
  //                 height: 42,
  //                 padding: const EdgeInsets.symmetric(horizontal: 12),
  //                 decoration: BoxDecoration(
  //                   color: isDark ? Colors.white10 : Colors.grey.shade100,
  //                   border: Border.all(
  //                     color: isDark ? Colors.white24 : Colors.black12,
  //                   ),
  //                 ),
  //                 child: DropdownButtonHideUnderline(
  //                   child: DropdownButton<int>(
  //                     value: sizePerPage,
  //                     icon: Icon(
  //                       Icons.expand_more_rounded,
  //                       size: 20,
  //                       color:
  //                           isDark
  //                               ? tWhite.withOpacity(0.8)
  //                               : Colors.grey.shade700,
  //                     ),
  //                     dropdownColor:
  //                         isDark ? tBlack.withOpacity(0.95) : Colors.white,
  //                     borderRadius: BorderRadius.circular(10),
  //                     style: GoogleFonts.urbanist(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                       color: isDark ? tWhite : Colors.black87,
  //                     ),
  //                     items:
  //                         pageSizeOptions
  //                             .map(
  //                               (s) => DropdownMenuItem(
  //                                 value: s,
  //                                 child: Text(
  //                                   "$s / page",
  //                                   style: GoogleFonts.urbanist(
  //                                     fontSize: 14,
  //                                     fontWeight: FontWeight.w600,
  //                                     color: isDark ? tWhite : Colors.black87,
  //                                   ),
  //                                 ),
  //                               ),
  //                             )
  //                             .toList(),
  //                     onChanged: (v) async {
  //                       if (v == null) return;
  //                       if (!mounted) return;

  //                       setState(() {
  //                         sizePerPage = v;
  //                         currentPage = 1;
  //                         currentIndex = 0;
  //                         isLoading = true;
  //                       });

  //                       await _reloadDevices();
  //                     },
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),

  //       const SizedBox(height: 16),

  //       Expanded(
  //         child: Stack(
  //           children: [
  //             _buildTableArea(isDark),
  //             if (isLoading)
  //               Positioned.fill(
  //                 child: Container(
  //                   color:
  //                       isDark ? Colors.black26 : Colors.white.withOpacity(0.6),
  //                   child: const Center(child: CircularProgressIndicator()),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),

  //       const SizedBox(height: 12),
  //       _buildPaginationControls(isDark),
  //     ],
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Devices",
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                Row(
                  children: [
                    _addNewDeviceButton(isDark),
                    const SizedBox(width: 10),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: sizePerPage,
                          icon: Icon(
                            Icons.expand_more_rounded,
                            size: 20,
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.8)
                                    : Colors.grey.shade700,
                          ),
                          dropdownColor:
                              isDark ? tBlack.withOpacity(0.95) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? tWhite : Colors.black87,
                          ),
                          items:
                              pageSizeOptions
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        "$s / page",
                                        style: GoogleFonts.urbanist(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDark ? tWhite : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) async {
                            if (v == null) return;
                            if (!mounted) return;

                            setState(() {
                              sizePerPage = v;
                              currentPage = 1;
                              currentIndex = 0;
                              isLoading = true;
                            });

                            await _reloadDevices();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _buildTableArea(isDark), // Always build the table
            ),

            const SizedBox(height: 12),

            // Pagination Footer - Dimmed during loading
            Opacity(
              opacity: isLoading ? 0.5 : 1.0,
              child: IgnorePointer(
                ignoring: isLoading,
                child: _buildPaginationControls(isDark),
              ),
            ),
          ],
        ),
        // Loading Overlay
        if (isLoading) _buildLoadingOverlay(isDark),
      ],
    );
  }

  // Widget _buildTableArea(bool isDark) {
  //   if (!isLoading && filteredallDevices.isEmpty) {
  //     return Center(
  //       child: Text(
  //         isError
  //             ? (errorMessage ?? "Failed to load devices")
  //             : "No devices found.",
  //         style: GoogleFonts.urbanist(
  //           fontSize: 14,
  //           color: isDark ? tWhite : tBlack,
  //         ),
  //       ),
  //     );
  //   }
  //   Color? getGroupColor(String? group) {
  //     if (group == null || group.trim().isEmpty || group == '--') return null;

  //     final List<Color> colors = [
  //       Colors.green,
  //       Colors.blue,
  //       Colors.orange,
  //       Colors.purple,
  //       Colors.teal,
  //       Colors.indigo,
  //       Colors.red,
  //       Colors.brown,
  //     ];

  //     int index = group.hashCode.abs() % colors.length;
  //     return colors[index];
  //   }

  //   return Scrollbar(
  //     controller: _horizontalController,
  //     thumbVisibility: true,
  //     child: SingleChildScrollView(
  //       controller: _horizontalController,
  //       scrollDirection: Axis.horizontal,
  //       child: ConstrainedBox(
  //         constraints: BoxConstraints(
  //           minWidth: MediaQuery.of(context).size.width,
  //         ),
  //         child: Scrollbar(
  //           controller: _verticalController,
  //           thumbVisibility: true,
  //           child: SingleChildScrollView(
  //             controller: _verticalController,
  //             scrollDirection: Axis.vertical,
  //             child: DataTable(
  //               headingRowColor: WidgetStateProperty.all(
  //                 isDark ? tBlue.withOpacity(0.15) : tBlue.withOpacity(0.05),
  //               ),
  //               headingTextStyle: GoogleFonts.urbanist(
  //                 fontWeight: FontWeight.w700,
  //                 color: isDark ? tWhite : tBlack,
  //                 fontSize: 13,
  //               ),
  //               dataTextStyle: GoogleFonts.urbanist(
  //                 color: isDark ? tWhite : tBlack,
  //                 fontWeight: FontWeight.w400,
  //                 fontSize: 12,
  //               ),
  //               columnSpacing: 30,
  //               border: TableBorder.all(
  //                 color:
  //                     isDark
  //                         ? tWhite.withOpacity(0.1)
  //                         : tBlack.withOpacity(0.1),
  //                 width: 0.4,
  //               ),
  //               dividerThickness: 0.01,
  //               columns: const [
  //                 DataColumn(label: Text("S.No")),
  //                 DataColumn(label: Text("IMEI")),
  //                 DataColumn(label: Text("SIM No.")),
  //                 DataColumn(label: Text("Vehicle No.")),
  //                 DataColumn(label: Text("FG Code")),
  //                 DataColumn(label: Text("Registration No.")),
  //                 DataColumn(label: Text("Battery No.")),
  //                 DataColumn(label: Text("Group")),
  //                 DataColumn(label: Text("Created Date")),
  //                 DataColumn(label: Text("Firmware Ver.")),
  //                 DataColumn(label: Text("Hardware Ver.")),
  //                 DataColumn(label: Text("Product")),
  //                 DataColumn(label: Text("Vehicle Model")),
  //                 DataColumn(label: Text("Dealer Code")),
  //                 DataColumn(label: Text("Actions")),
  //               ],
  //               rows:
  //                   filteredallDevices.asMap().entries.map((entry) {
  //                     final idx = entry.key;
  //                     final d = entry.value;

  //                     final sNo = ((currentPage - 1) * sizePerPage) + idx + 1;
  //                     final group = d.groupDetails?.name ?? '--';
  //                     final groupColor = getGroupColor(group);
  //                     return DataRow(
  //                       cells: [
  //                         DataCell(Text(sNo.toString())),
  //                         DataCell(Text(d.imei ?? '--')),
  //                         DataCell(Text(d.simno ?? '--')),
  //                         DataCell(Text(d.vehicleNo ?? '--')),
  //                         DataCell(Text(d.fgCode ?? '--')),
  //                         DataCell(Text(d.rtoNumber ?? '--')),
  //                         DataCell(Text(d.batteryNo ?? '--')),
  //                         DataCell(
  //                           groupColor == null
  //                               ? const SizedBox() // show nothing if no group
  //                               : Container(
  //                                 padding: const EdgeInsets.symmetric(
  //                                   horizontal: 8,
  //                                   vertical: 4,
  //                                 ),
  //                                 decoration: BoxDecoration(
  //                                   color: groupColor,
  //                                   borderRadius: BorderRadius.circular(6),
  //                                 ),
  //                                 child: Text(
  //                                   group,
  //                                   style: const TextStyle(
  //                                     color: tWhite,
  //                                     fontSize: 11,
  //                                   ),
  //                                 ),
  //                               ),
  //                         ),

  //                         DataCell(Text(d.createdDate ?? '--')),
  //                         DataCell(Text(d.fwver ?? '--')),
  //                         DataCell(Text(d.hwver ?? '--')),
  //                         DataCell(Text(d.product ?? '--')),
  //                         DataCell(Text(d.vehicleModel ?? '--')),
  //                         DataCell(Text(d.dealerCode ?? '--')),

  //                         // ACTION BUTTONS
  //                         DataCell(
  //                           Row(
  //                             children: [
  //                               IconButton(
  //                                 icon: SvgPicture.asset(
  //                                   'icons/edit.svg',
  //                                   height: 20,
  //                                   width: 20,
  //                                   color: tBlue,
  //                                 ),
  //                                 onPressed: () {
  //                                   // TODO: open edit dialog
  //                                   showDeviceCreateUpdateDialog(
  //                                     context: context,
  //                                     title: "Update Device",
  //                                     confirmText: "Update",

  //                                     /// UPDATE → populate values
  //                                     initialImei: d.imei ?? "",
  //                                     initialVehicleNo: d.vehicleNo,
  //                                     initialDeviceType:
  //                                         d.deviceType ?? "NON_EV",
  //                                     initialBatteryNo: d.batteryNo,
  //                                     initialGroupId: d.groupDetails?.id,
  //                                     initialVehicleModel: d.vehicleModel,
  //                                     initialDealerCode: d.dealerCode,
  //                                     initialRtoNumber: d.rtoNumber,
  //                                     initialFgCode: d.fgCode,

  //                                     allGroups: groups,

  //                                     onConfirm: ({
  //                                       required String imei,
  //                                       required String vehicleNo,
  //                                       required String deviceType,
  //                                       required String batteryNo,
  //                                       required String group,
  //                                       required String vehicleModel,
  //                                       required String dealerCode,
  //                                       required String rtoNumber,
  //                                       required String fgCode,
  //                                     }) async {
  //                                       await _devicesApiService
  //                                           .updateDevice(imei, {
  //                                             "imei": imei,
  //                                             "vehicleNo": vehicleNo,
  //                                             "deviceType": deviceType,
  //                                             if (deviceType != "NON_EV")
  //                                               "batteryNo": batteryNo,
  //                                             "group": group,
  //                                             "vehicleModel": vehicleModel,
  //                                             "dealerCode": dealerCode,
  //                                             "rtoNumber": rtoNumber,
  //                                             "fgCode": fgCode,
  //                                             "org": d.org,
  //                                             "product": d.product,
  //                                             "hwver": d.hwver,
  //                                             "fwver": d.fwver,
  //                                             "simno": d.simno,
  //                                             "createdDate": d.createdDate,
  //                                           });

  //                                       await _reloadDevices();
  //                                     },
  //                                   );
  //                                 },
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     );
  //                   }).toList(),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _buildTableArea(bool isDark) {
    if (!isLoading && filteredallDevices.isEmpty) {
      return Center(
        child: Text(
          isError
              ? (errorMessage ?? "Failed to load devices")
              : "No devices found.",
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: isDark ? tWhite : tBlack,
          ),
        ),
      );
    }

    Color? getGroupColor(String? group) {
      if (group == null || group.trim().isEmpty || group == '--') return null;

      final List<Color> colors = [
        Colors.green,
        Colors.blue,
        Colors.orange,
        Colors.purple,
        Colors.teal,
        Colors.indigo,
        Colors.red,
        Colors.brown,
      ];

      int index = group.hashCode.abs() % colors.length;
      return colors[index];
    }

    return Opacity(
      opacity: isLoading ? 0.3 : 1.0,
      child: IgnorePointer(
        ignoring: isLoading,
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      isDark
                          ? tBlue.withOpacity(0.15)
                          : tBlue.withOpacity(0.05),
                    ),
                    headingTextStyle: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w700,
                      color: isDark ? tWhite : tBlack,
                      fontSize: 13,
                    ),
                    dataTextStyle: GoogleFonts.urbanist(
                      color: isDark ? tWhite : tBlack,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                    columnSpacing: 30,
                    border: TableBorder.all(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.1)
                              : tBlack.withOpacity(0.1),
                      width: 0.4,
                    ),
                    dividerThickness: 0.01,
                    columns: const [
                      DataColumn(label: Text("S.No")),
                      DataColumn(label: Text("IMEI")),
                      DataColumn(label: Text("SIM No.")),
                      DataColumn(label: Text("Vehicle No.")),
                      DataColumn(label: Text("FG Code")),
                      DataColumn(label: Text("Registration No.")),
                      DataColumn(label: Text("Battery No.")),
                      DataColumn(label: Text("Group")),
                      DataColumn(label: Text("Created Date")),
                      DataColumn(label: Text("Firmware Ver.")),
                      DataColumn(label: Text("Hardware Ver.")),
                      DataColumn(label: Text("Product")),
                      DataColumn(label: Text("Vehicle Model")),
                      DataColumn(label: Text("Dealer Code")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows:
                        filteredallDevices.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final d = entry.value;

                          final sNo =
                              ((currentPage - 1) * sizePerPage) + idx + 1;
                          final group = d.groupDetails?.name ?? '--';
                          final groupColor = getGroupColor(group);
                          return DataRow(
                            cells: [
                              DataCell(Text(sNo.toString())),
                              DataCell(Text(d.imei ?? '--')),
                              DataCell(Text(d.simno ?? '--')),
                              DataCell(Text(d.vehicleNo ?? '--')),
                              DataCell(Text(d.fgCode ?? '--')),
                              DataCell(Text(d.rtoNumber ?? '--')),
                              DataCell(Text(d.batteryNo ?? '--')),
                              DataCell(
                                groupColor == null
                                    ? const SizedBox()
                                    : Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: groupColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        group,
                                        style: const TextStyle(
                                          color: tWhite,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                              ),
                              DataCell(Text(d.createdDate ?? '--')),
                              DataCell(Text(d.fwver ?? '--')),
                              DataCell(Text(d.hwver ?? '--')),
                              DataCell(Text(d.product ?? '--')),
                              DataCell(Text(d.vehicleModel ?? '--')),
                              DataCell(Text(d.dealerCode ?? '--')),
                              // ACTION BUTTONS
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: SvgPicture.asset(
                                        'icons/edit.svg',
                                        height: 20,
                                        width: 20,
                                        color: tBlue,
                                      ),
                                      onPressed:
                                          isLoading
                                              ? null
                                              : () {
                                                showDeviceCreateUpdateDialog(
                                                  context: context,
                                                  title: "Update Device",
                                                  confirmText: "Update",
                                                  initialImei: d.imei ?? "",
                                                  initialVehicleNo: d.vehicleNo,
                                                  initialDeviceType:
                                                      d.deviceType ?? "NON_EV",
                                                  initialBatteryNo: d.batteryNo,
                                                  initialGroupId:
                                                      d.groupDetails?.id,
                                                  initialVehicleModel:
                                                      d.vehicleModel,
                                                  initialDealerCode:
                                                      d.dealerCode,
                                                  initialRtoNumber: d.rtoNumber,
                                                  initialFgCode: d.fgCode,
                                                  allGroups: groups,
                                                  onConfirm: ({
                                                    required String imei,
                                                    required String vehicleNo,
                                                    required String deviceType,
                                                    required String batteryNo,
                                                    required String group,
                                                    required String
                                                    vehicleModel,
                                                    required String dealerCode,
                                                    required String rtoNumber,
                                                    required String fgCode,
                                                  }) async {
                                                    await _devicesApiService
                                                        .updateDevice(imei, {
                                                          "imei": imei,
                                                          "vehicleNo":
                                                              vehicleNo,
                                                          "deviceType":
                                                              deviceType,
                                                          if (deviceType !=
                                                              "NON_EV")
                                                            "batteryNo":
                                                                batteryNo,
                                                          "group": group,
                                                          "vehicleModel":
                                                              vehicleModel,
                                                          "dealerCode":
                                                              dealerCode,
                                                          "rtoNumber":
                                                              rtoNumber,
                                                          "fgCode": fgCode,
                                                          "org": d.org,
                                                          "product": d.product,
                                                          "hwver": d.hwver,
                                                          "fwver": d.fwver,
                                                          "simno": d.simno,
                                                          "createdDate":
                                                              d.createdDate,
                                                        });

                                                    await _reloadDevices();
                                                  },
                                                );
                                              },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: tBlack.withOpacity(isDark ? 0.35 : 0.15),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'gifs/loading1.json',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                  Text(
                    'Loading Devices...',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(bool isDark) {
    const int visiblePageCount = 5;
    final computedTotalPages = totalPages < 1 ? 1 : totalPages;

    int startPage =
        ((currentPage - 1) ~/ visiblePageCount) * visiblePageCount + 1;
    int endPage = (startPage + visiblePageCount - 1).clamp(1, totalPages);

    final pageButtons = <Widget>[];

    for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
      final isSelected = pageNum == currentPage;

      pageButtons.add(
        GestureDetector(
          onTap: () async {
            if (pageNum == currentPage) return;

            if (!mounted) return; // FIX
            setState(() {
              currentPage = pageNum;
              page = currentPage;
              currentIndex = (currentPage - 1) * sizePerPage;
              isLoading = true;
            });

            await _reloadDevices();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? tBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    isSelected
                        ? tBlue
                        : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
            child: Text(
              '$pageNum',
              style: GoogleFonts.urbanist(
                color:
                    isSelected
                        ? tWhite
                        : (isDark
                            ? tWhite.withOpacity(0.8)
                            : tBlack.withOpacity(0.8)),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: isDark ? tWhite : tBlack,
              size: 22,
            ),
            onPressed:
                currentPage > 1
                    ? () async {
                      if (!mounted) return; // FIX
                      setState(() {
                        currentPage--;
                        page = currentPage;
                        currentIndex = (currentPage - 1) * sizePerPage;
                        isLoading = true;
                      });
                      await _reloadDevices();
                    }
                    : null,
          ),

          Row(children: pageButtons),

          // Next
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isDark ? tWhite : tBlack,
              size: 22,
            ),
            onPressed:
                currentPage < totalPages
                    ? () async {
                      if (!mounted) return; // FIX
                      setState(() {
                        currentPage++;
                        page = currentPage;
                        currentIndex = (currentPage - 1) * sizePerPage;
                        isLoading = true;
                      });
                      await _reloadDevices();
                    }
                    : null,
          ),

          const SizedBox(width: 16),

          // Jump to page
          SizedBox(
            width: 70,
            height: 32,
            child: TextField(
              controller: controller,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                color: isDark ? tWhite : tBlack,
              ),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Page',
                hintStyle: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? tWhite : tBlack,
                    width: 0.8,
                  ),
                ),
              ),
              onSubmitted: (value) async {
                final p = int.tryParse(value);
                if (p != null && p >= 1 && p <= totalPages) {
                  if (!mounted) return; // FIX
                  setState(() {
                    currentPage = p;
                    page = currentPage;
                    currentIndex = (currentPage - 1) * sizePerPage;
                    isLoading = true;
                  });
                  await _reloadDevices();
                }
              },
            ),
          ),

          const SizedBox(width: 10),

          Text(
            'Page $currentPage of $computedTotalPages · $totalCount items',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addNewDeviceButton(bool isDark) => Container(
    height: 40,
    padding: EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: isDark ? tWhite : tBlack),
    child: TextButton(
      onPressed: () {
        showDeviceCreateUpdateDialog(
          context: context,
          title: "Create Device",
          confirmText: "Create",
          initialImei: "",
          initialVehicleNo: "",
          initialDeviceType: "NON_EV",
          initialBatteryNo: "",
          initialGroupId: "",
          initialVehicleModel: "",
          initialDealerCode: "",
          initialRtoNumber: "",
          initialFgCode: "",

          allGroups: groups,

          onConfirm: ({
            required String imei,
            required String vehicleNo,
            required String deviceType,
            required String batteryNo,
            required String group,
            required String vehicleModel,
            required String dealerCode,
            required String rtoNumber,
            required String fgCode,
          }) async {
            await _devicesApiService.createDevice({
              "imei": imei,
              "vehicleNo": vehicleNo,
              "deviceType": deviceType,
              "batteryNo": batteryNo,
              "group": group,
              "vehicleModel": vehicleModel,
              "dealerCode": dealerCode,
              "rtoNumber": rtoNumber,
              "fgCode": fgCode,
            });

            await _reloadDevices();
          },
        );
      },
      child: Row(
        children: [
          SvgPicture.asset(
            'icons/device.svg',
            width: 18,
            height: 18,
            color: isDark ? tBlack : tWhite,
          ),
          SizedBox(width: 5),
          Text(
            'New Device',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: isDark ? tBlack : tWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
