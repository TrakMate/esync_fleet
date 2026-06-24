import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../models/deviceDetailsModel.dart';
import '../../models/deviceOverviewModel.dart';
import '../../models/devicesModel.dart';
import '../../provider/fleetModeProvider.dart';
import '../../services/generalAPIServices.dart/deviceAPIServices/deviceGeneralInfoAPIService.dart';
import '../../services/generalAPIServices.dart/deviceDetailsAPIService.dart';
import '../../services/getAddressService.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../widgets/charts/odometerChart.dart';
import '../widgets/grafanaPanel.dart';

class DeviceInformationScreen extends StatefulWidget {
  final DeviceEntity device;

  const DeviceInformationScreen({super.key, required this.device});

  @override
  State<DeviceInformationScreen> createState() =>
      _DeviceInformationScreenState();
}

class _DeviceInformationScreenState extends State<DeviceInformationScreen> {
  DeviceDetailsModel? deviceDetailsModel;
  DeviceOverviewModel? deviceOverviewModel;
  bool isLoading = false;
  final DeviceDetailsApiService _deviceDetailsApiService =
      DeviceDetailsApiService();

  DateTime? selectedDate;

  Future<void> fetchDeviceDetails() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _deviceDetailsApiService.fetchDeviceDetails(
        deviceId: widget.device.imei!,
      );

      if (!mounted) return;

      setState(() {
        deviceDetailsModel = result;
      });
    } catch (e) {
      debugPrint("Device Details API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDeviceDetails();
  }

  @override
  Widget build(BuildContext context) {
    // return Container();
    return ResponsiveLayout(
      // mobile: const Center(child: Text("Mobile / Tablet layout coming soon")),
      mobile: Container(),
      tablet: Container(),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildDesktopLayout(context) {
    final mode = Provider.of<FleetModeProvider>(context).mode;
    final device = widget.device;
    final imei = widget.device.imei;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),

          child: FutureBuilder<String>(
            future: getAddressFromLocationStringWeb(
              deviceDetailsModel?.lat != null &&
                      deviceDetailsModel?.long != null
                  ? '${deviceDetailsModel!.lat},${deviceDetailsModel!.long}'
                  : "",
            ),
            builder: (context, snapshot) {
              final displayStatus =
                  mode == 'EV Fleet'
                      ? (deviceDetailsModel?.status ??
                          device.status ??
                          '') // Use regular status for EV
                      : (deviceDetailsModel?.lstatus ?? device.status ?? '');
              final displayTime =
                  mode == 'EV Fleet'
                      ? (deviceDetailsModel?.batteryTime ??
                          device.batteryLogDate ??
                          '') // Use regular status for EV
                      : (deviceDetailsModel?.locationTime ??
                          device.locationLogDate ??
                          '');

              return buildDeviceCard(
                isDark: isDark,
                imei: deviceDetailsModel?.imei ?? device.imei ?? '',
                vehicleNumber: deviceDetailsModel?.vehicleNumber ?? '',
                status: displayStatus,
                fuel:
                    mode == 'EV Fleet'
                        ? device.soc ?? ''
                        : (device.tafe?.fuellevel?.toString() ?? ''),
                odo: device.odometer ?? '',
                trips: (device.totalTrips ?? 0).toString(),
                alerts: (device.totalAlerts ?? 0).toString(),
                location: deviceDetailsModel?.address ?? '',
                lastUpdated: displayTime,
              );
            },
          ),
        ),

        const SizedBox(height: 15),

        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(5),
            child: IntrinsicHeight(
              // child: Row(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     Expanded(flex: 1, child: _buildDeviceDetailsTable(isDark)),

              //     const SizedBox(width: 15),

              //     Expanded(
              //       flex: 2,
              //       child: Container(
              //         decoration: BoxDecoration(
              //           color: isDark ? tBlack : tWhite,
              //           borderRadius: BorderRadius.circular(20),
              //           boxShadow: [
              //             BoxShadow(
              //               spreadRadius: 2,
              //               blurRadius: 10,
              //               color:
              //                   isDark
              //                       ? tWhite.withOpacity(0.12)
              //                       : tBlack.withOpacity(0.08),
              //             ),
              //           ],
              //         ),
              //         child: Center(
              //           child: Text(
              //             "Right Side Container",
              //             style: GoogleFonts.urbanist(
              //               fontSize: 34,
              //               fontWeight: FontWeight.w700,
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildBatteryInfoTable(isDark),
                        ),

                        const SizedBox(width: 15),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 425,
                            decoration: BoxDecoration(
                              color: isDark ? tBlack : tWhite,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  color:
                                      isDark
                                          ? tWhite.withOpacity(0.12)
                                          : tBlack.withOpacity(0.08),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                " Container",
                                style: GoogleFonts.urbanist(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),

                        Expanded(flex: 1, child: _buildIoTInfoTable(isDark)),
                      ],
                    ),

                    SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? tBlack : tWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            spreadRadius: 2,
                            blurRadius: 10,
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.15)
                                    : tBlack.withOpacity(0.08),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            // child: Container(
                            //   padding: const EdgeInsets.all(16),
                            //   decoration: BoxDecoration(
                            //     color: isDark ? tBlack : tWhite,
                            //     borderRadius: BorderRadius.circular(20),
                            //     boxShadow: [
                            //       BoxShadow(
                            //         spreadRadius: 2,
                            //         blurRadius: 10,
                            //         color:
                            //             isDark
                            //                 ? tWhite.withOpacity(0.12)
                            //                 : tBlack.withOpacity(0.08),
                            //       ),
                            //     ],
                            //   ),

                            // child: Column(
                            //   children: [
                            //     Row(
                            //       mainAxisAlignment:
                            //           MainAxisAlignment.spaceBetween,
                            //       children: [
                            //         Text(
                            //           "Odometer (km)",
                            //           style: GoogleFonts.urbanist(
                            //             fontSize: 13,
                            //             fontWeight: FontWeight.bold,
                            //             color: isDark ? tWhite : tBlack,
                            //           ),
                            //         ),
                            //         _buildLegendItem(
                            //           tBlueSky,
                            //           "Odometer",
                            //           isDark,
                            //         ),
                            //       ],
                            //     ),

                            //     const SizedBox(height: 10),

                            //     SizedBox(
                            //       height: 300,
                            //       child: OdometerChart(
                            //         odometerData: const [
                            //           10200,
                            //           10205,
                            //           10215,
                            //           10225,
                            //           10240,
                            //           10255,
                            //         ],
                            //         timeLabels: const [
                            //           '10:00',
                            //           '10:10',
                            //           '10:20',
                            //           '10:30',
                            //           '10:40',
                            //           '10:50',
                            //         ],
                            //         isDark: isDark,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            child: GrafanaPanel(
                              url: grafanaUrl(
                                panelId: 16,
                                imei: imei ?? '',
                                isDark: isDark,
                              ),
                              height: 350,
                            ),
                            // ),
                          ),

                          const SizedBox(width: 15),

                          mode == 'EV Fleet'
                              ? Expanded(
                                child: GrafanaPanel(
                                  url: grafanaUrl(
                                    panelId: 35,
                                    imei: imei ?? '',
                                    isDark: isDark,
                                  ),
                                  height: 350,
                                ),
                              )
                              : Expanded(
                                child: GrafanaPanel(
                                  url: grafanaUrl(
                                    panelId: 52,
                                    imei: imei ?? '',
                                    isDark: isDark,
                                  ),
                                  height: 350,
                                ),
                              ),
                          const SizedBox(width: 15),

                          Expanded(
                            child: GrafanaPanel(
                              url: grafanaUrl(
                                panelId: 36,
                                imei: imei ?? '',
                                isDark: isDark,
                              ),
                              height: 350,
                            ),
                          ),
                          const SizedBox(width: 15),

                          Expanded(
                            child: GrafanaPanel(
                              url: grafanaUrl(
                                panelId: 50,
                                imei: imei ?? '',
                                isDark: isDark,
                              ),
                              height: 350,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? tWhite : tBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryInfoTable(bool isDark) {
    final data = {
      " Serial No": "BAT-2026-001",
      "BIN Number": "BIN-458921",
      " Rated Capacity": "120 Ah",
      "Remaining Capacity": "108 Ah",
      "Voltage Range": "48V - 54.6V",
      "BMS Firmware": "v2.4.1",
      "Last Updated": "18 Jun 2026 10:30 AM",
      "Warrenty Remaining": "224 days",
    };

    return _buildInfoTable(
      title: "Battery Information",
      data: data,
      isDark: isDark,
    );
  }

  Widget _buildIoTInfoTable(bool isDark) {
    final data = {
      "IMEI": "867530912345678",
      "Product ID": "TM-PRD-1001",
      "ICCID": "8991001200003204512",
      "Hardware Version": "1.02",
      "Firmware Version": "2.8.5",
      "Last FW Update": "15 Jun 2026",
      "Model Name": "TM-EV-Tracker-X1",
      "Created Date": "01 Jan 2026",
      "Warrenty Remaining": "424 days",
    };

    return _buildInfoTable(
      title: "IoT Information",
      data: data,
      isDark: isDark,
    );
  }

  Widget _buildInfoTable({
    required String title,
    required Map<String, String> data,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? tBlack : tWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 10,
            color: isDark ? tWhite.withOpacity(0.12) : tBlack.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? tWhite : tBlack,
              ),
            ),
          ),

          const Divider(height: 1),

          Table(
            border: TableBorder.all(
              color: isDark ? tWhite.withOpacity(0.1) : tBlack.withOpacity(0.1),
            ),
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(1.8),
            },
            children:
                data.entries.map((entry) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          entry.key,
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          entry.value,
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(IconData icon, String title, String value, bool isDark) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 18, color: Colors.grey),
        ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            title,
            style: GoogleFonts.urbanist(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            value,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDeviceCard({
    required bool isDark,
    required String vehicleNumber,
    required String status,
    required String imei,
    required String fuel,
    required String odo,
    required String trips,
    required String alerts,
    required String location,
    required String lastUpdated,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'moving':
        statusColor = tGreen;
        break;
      case 'idle':
        statusColor = tOrange1;
        break;
      case 'stopped':
        statusColor = tRed;
        break;
      case 'disconnected':
        statusColor = tGrey;
        break;
      case 'discharging':
        statusColor = tGreen;
        break;
      case 'charging':
        // statusColor = Colors.teal;
        statusColor = tBlue;

        break;
      case 'non coverage':
        statusColor = const Color(0xFF9C27B0);
        break;

      default:
        statusColor = tBlack;
    }

    String getTruckIcon(String status) {
      switch (status.toLowerCase()) {
        case 'moving':
          return 'icons/indicationIcons/cycmoving.svg';

        case 'stopped':
          return 'icons/indicationIcons/cycstopped.svg';

        case 'idle':
          return 'icons/indicationIcons/cycidle.svg';

        case 'disconnected':
          return 'icons/indicationIcons/cycdisconnected.svg';

        case 'non coverage':
        case 'non_coverage':
          return 'icons/indicationIcons/cycnoncoverage.svg';

        case 'charging':
          return 'icons/indicationIcons/cyccharging.svg';

        case 'discharging':
          return 'icons/indicationIcons/cycmoving.svg';

        default:
          return 'icons/indicationIcons/cycstopped.svg';
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;

    return Container(
      width: double.infinity,
      // height: 90,
      decoration: BoxDecoration(
        // color: tGrey.withOpacity(0.1),
        color: isDark ? tBlack : tWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 10,
            color: isDark ? tWhite.withOpacity(0.25) : tBlack.withOpacity(0.15),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child:
          isMobile
              ? Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// TRUCK IMAGE
                      SvgPicture.asset(
                        getTruckIcon(status),
                        height: 65,
                        width: 65,
                      ),

                      const SizedBox(width: 10),

                      /// RIGHT CONTENT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// IMEI + VEHICLE
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: statusColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// IMEI
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: SweepGradient(
                                        colors: [
                                          statusColor,
                                          statusColor.withOpacity(0.6),
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(5),
                                        topRight: Radius.circular(5),
                                      ),
                                    ),
                                    child: Text(
                                      imei,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.urbanist(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: tWhite,
                                      ),
                                    ),
                                  ),

                                  /// VEHICLE
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      vehicleNumber,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.urbanist(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? tWhite : tBlack,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            /// STATUS
                            Row(
                              // mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: SweepGradient(
                                      colors: [
                                        statusColor,
                                        statusColor.withOpacity(0.6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.urbanist(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: tWhite,
                                    ),
                                  ),
                                ),

                                // const SizedBox(width: 8),
                                const Spacer(),

                                SvgPicture.asset(
                                  'icons/immobilize_ON.svg',
                                  width: 18,
                                  height: 18,
                                  color: isDark ? tRed : tGreen,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Divider(color: statusColor, thickness: 0.3),

                  const SizedBox(height: 2),

                  /// ===================== ROW 4 =====================
                  /// LOCATION
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: isMobile ? 30 : 36,
                        height: isMobile ? 28 : 36,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(13),
                        ),

                        child: Center(
                          child: SvgPicture.asset(
                            'icons/geofence.svg',
                            width: isMobile ? 12 : 16,
                            height: isMobile ? 12 : 16,
                            color: statusColor,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.urbanist(
                            fontSize: 11,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Text(
                        'LastSync :',
                        style: GoogleFonts.urbanist(
                          fontSize: 10,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          lastUpdated,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.urbanist(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // SvgPicture.asset('icons/truck1.svg', width: 80, height: 80),
                  // Image.asset(
                  //   'images/truck1.png',
                  //   width: isMobile ? 85 : 100,
                  //   height: isMobile ? 85 : 100,
                  //   fit: BoxFit.contain,
                  // ),
                  SvgPicture.asset(getTruckIcon(status), height: 85, width: 85),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ==== Left Side (IMEI + Vehicle + Status) ====
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // IMEI + Vehicle ID Container
                                  Flexible(
                                    child: Container(
                                      width: 350,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: statusColor,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // IMEI Box
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: SweepGradient(
                                                colors: [
                                                  statusColor,
                                                  statusColor.withOpacity(0.6),
                                                ],
                                              ),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(5),
                                                    bottomLeft: Radius.circular(
                                                      5,
                                                    ),
                                                  ),
                                            ),
                                            child: Text(
                                              imei,
                                              style: GoogleFonts.urbanist(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                // color: isDark ? tWhite : tBlack,
                                                color: tWhite,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),

                                          // Vehicle ID Text
                                          Expanded(
                                            child: Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                child: Text(
                                                  vehicleNumber,
                                                  style: GoogleFonts.urbanist(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        isDark
                                                            ? tWhite
                                                            : tBlack,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Moving Status Container
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: SweepGradient(
                                        colors: [
                                          statusColor,
                                          statusColor.withOpacity(0.6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status,
                                      style: GoogleFonts.urbanist(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        // color: isDark ? tWhite : tBlack,
                                        color: tWhite,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ==== Right Side ====
                            SvgPicture.asset(
                              'icons/immobilize_ON.svg',
                              width: 25,
                              height: 25,
                              color: isDark ? tRed : tGreen,
                            ),
                          ],
                        ),

                        const SizedBox(height: 2),
                        Divider(
                          // color:
                          //     isDark
                          //         ? tWhite.withOpacity(0.4)
                          //         : tBlack.withOpacity(0.4),
                          color: statusColor,
                          thickness: 0.3,
                        ),
                        const SizedBox(height: 2),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: isMobile ? 30 : 36,
                                    height: isMobile ? 28 : 36,
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(13),
                                    ),

                                    child: Center(
                                      child: SvgPicture.asset(
                                        'icons/geofence.svg',
                                        width: isMobile ? 12 : 16,
                                        height: isMobile ? 12 : 16,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 6),

                                  Expanded(
                                    child: Text(
                                      location,
                                      style: GoogleFonts.urbanist(
                                        fontSize: 13,
                                        color: isDark ? tWhite : tBlack,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              children: [
                                Text(
                                  'LastSync :',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: isDark ? tWhite : tBlack,
                                  ),
                                ),

                                const SizedBox(width: 5),

                                Text(
                                  lastUpdated,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? tWhite : tBlack,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
