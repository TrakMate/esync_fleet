import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../models/deviceDetailsModel.dart';
import '../../models/deviceDiagnosticModel.dart';
import '../../models/devicesModel.dart';
import '../../provider/fleetModeProvider.dart';
import '../../services/generalAPIServices.dart/deviceAPIServices/deviceDiagnosticAPIService.dart';
import '../../services/generalAPIServices.dart/deviceDetailsAPIService.dart';
import '../../services/getAddressService.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../widgets/charts/doughnutChart.dart';
import '../widgets/charts/evCellTemperaturesChart.dart';
import '../widgets/charts/evCellVoltagesChart.dart';
import '../widgets/charts/fuelChart.dart';
import '../widgets/charts/odometerChart.dart';
import '../widgets/charts/rpmChart.dart';
import '../widgets/charts/speedChart.dart';
import '../widgets/charts/temperatureChart.dart';
import '../widgets/charts/vehicleVoltageChart.dart';
import '../components/customBatteryCellTemperature.dart';
import '../components/customBatteryCellVoltage.dart';
import '../widgets/grafanaPanel.dart';

class CellStats {
  final double max;
  final double min;
  final double last;
  final double mean;

  CellStats(this.max, this.min, this.last, this.mean);

  static CellStats compute(List<double> values) {
    double maxV = values.reduce((a, b) => a > b ? a : b);
    double minV = values.reduce((a, b) => a < b ? a : b);
    double lastV = values.last;
    double meanV = values.reduce((a, b) => a + b) / values.length;

    return CellStats(
      double.parse(maxV.toStringAsFixed(3)),
      double.parse(minV.toStringAsFixed(3)),
      double.parse(lastV.toStringAsFixed(3)),
      double.parse(meanV.toStringAsFixed(3)),
    );
  }
}

class DeviceDiagnosticsInfoScreen extends StatefulWidget {
  final DeviceEntity device;
  const DeviceDiagnosticsInfoScreen({super.key, required this.device});

  @override
  State<DeviceDiagnosticsInfoScreen> createState() =>
      _DeviceDiagnosticsInfoScreenState();
}

class _DeviceDiagnosticsInfoScreenState
    extends State<DeviceDiagnosticsInfoScreen> {
  String selectedTab = "Statistics";

  List<List<double>> generateCellVoltages(int cells) {
    final random = Random();
    const int points = 24; // last 24 hours
    final NumberFormat format = NumberFormat('#,##,###');

    List<List<double>> data = [];

    for (int c = 0; c < cells; c++) {
      double base = 3.15 + random.nextDouble() * 0.10;
      List<double> values = [];

      for (int i = 0; i < points; i++) {
        double variation = (random.nextDouble() - 0.5) * 0.01;
        base = (base + variation).clamp(3.25, 3.80);
        values.add(double.parse(base.toStringAsFixed(4)));
      }

      data.add(values);
    }

    return data;
  }

  final NumberFormat format = NumberFormat('#,##,###');

  List<String> generateLast24HourLabels() {
    List<String> labels = [];
    DateTime now = DateTime.now();
    DateTime currentHour = DateTime(now.year, now.month, now.day, now.hour);

    for (int i = 23; i >= 0; i--) {
      DateTime t = currentHour.subtract(Duration(hours: i));
      labels.add("${t.hour.toString().padLeft(2, '0')}:00");
    }

    return labels;
  }

  // String _formatLastUpdated(String lastUpdated) {
  //   if (lastUpdated.isEmpty) return '-';

  //   try {
  //     final dateTime = DateTime.parse(lastUpdated);
  //     return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime.toLocal());
  //   } catch (e) {
  //     return lastUpdated;
  //   }
  // }

  int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();

    // remove non-numeric characters
    final cleaned = value.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  DeviceDetailsModel? deviceDetailsModel;
  final DeviceDetailsApiService _deviceDetailsApiService =
      DeviceDetailsApiService();
  final List<Color> cellColors24 = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.lightGreen,
    Colors.teal,
    Colors.cyan,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.lime,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.blueGrey,
    Colors.amber,
    Colors.lightBlue,
    Colors.deepOrangeAccent,
    Colors.greenAccent,
    Colors.redAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
  ];

  List<List<double>> generateTemperatureListOf10Sensors({
    int sensors = 10,
    int points = 50,
    double minTemp = 20.0,
    double maxTemp = 45.0,
  }) {
    final random = Random();
    List<List<double>> sensorData = [];

    for (int i = 0; i < sensors; i++) {
      List<double> readings = List.generate(points, (_) {
        double v = minTemp + random.nextDouble() * (maxTemp - minTemp);
        return double.parse(v.toStringAsFixed(2));
      });

      sensorData.add(readings);
    }

    return sensorData;
  }

  bool isLoading = false;
  final DeviceDiagnosticAPIService _deviceDiagnosticAPIService =
      DeviceDiagnosticAPIService();
  DeviceDiagnosticModel? deviceDiagnosticModel;
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

  Future<void> fetchDeviceDiagnostic() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _deviceDiagnosticAPIService.fetchdevicediagnostic(
        imei: widget.device.imei!,
      );

      if (!mounted) return;

      setState(() {
        deviceDiagnosticModel = result;
      });
    } catch (e) {
      debugPrint("Device Diagnostic API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Timer? _overviewTimer;

  // List<double?> getCellVoltages(Battery? battery) {
  //   if (battery == null) return List.filled(30, null);

  //   return [
  //     battery.cell1,
  //     battery.cell2,
  //     battery.cell3,
  //     battery.cell4,
  //     battery.cell5,
  //     battery.cell6,
  //     battery.cell7,
  //     battery.cell8,
  //     battery.cell9,
  //     battery.cell10,
  //     battery.cell11,
  //     battery.cell12,
  //     battery.cell13,
  //     battery.cell14,
  //     battery.cell15,
  //     battery.cell16,
  //     battery.cell17,
  //     battery.cell18,
  //     battery.cell19,
  //     battery.cell20,
  //     battery.cell21,
  //     battery.cell22?.toDouble(),
  //     battery.cell23?.toDouble(),
  //     battery.cell24?.toDouble(),
  //     battery.cell25?.toDouble(),
  //     battery.cell26?.toDouble(),
  //     battery.cell27?.toDouble(),
  //     battery.cell28?.toDouble(),
  //     battery.cell29?.toDouble(),
  //     battery.cell30?.toDouble(),
  //   ].map((v) {
  //     if (v == null) return null;
  //     return v;
  //   }).toList();
  // }

  // List<double> getTemperatureSensors(Battery? battery) {
  //   if (battery == null) return [];

  //   return [
  //     toDouble(battery.tempSensor1),
  //     toDouble(battery.tempSensor2),
  //     toDouble(battery.tempSensor3),
  //     toDouble(battery.tempSensor4),
  //     toDouble(battery.tempSensor5),
  //     toDouble(battery.tempSensor6),
  //     toDouble(battery.tempSensor7),
  //   ].map((t) {
  //     return t;
  //   }).toList();
  // }
  List<double?> getCellVoltages(Battery? battery) {
    if (battery == null) return [];

    // Get all cell voltages
    List<double?> allCells = [
      battery.cell1,
      battery.cell2,
      battery.cell3,
      battery.cell4,
      battery.cell5,
      battery.cell6,
      battery.cell7,
      battery.cell8,
      battery.cell9,
      battery.cell10,
      battery.cell11,
      battery.cell12,
      battery.cell13,
      battery.cell14,
      battery.cell15,
      battery.cell16,
      battery.cell17,
      battery.cell18,
      battery.cell19,
      battery.cell20,
      battery.cell21,
      battery.cell22?.toDouble(),
      battery.cell23?.toDouble(),
      battery.cell24?.toDouble(),
      battery.cell25?.toDouble(),
      battery.cell26?.toDouble(),
      battery.cell27?.toDouble(),
      battery.cell28?.toDouble(),
      battery.cell29?.toDouble(),
      battery.cell30?.toDouble(),
    ];

    // Only return up to actualCellCount cells
    return allCells.map((v) {
      if (v == null || v <= 0 || v > 5) return null;
      return v;
    }).toList();
  }

  List<double> getTemperatureSensors(Battery? battery) {
    if (battery == null) return [];

    List<double?> allTemps = [
      toDouble(battery.tempSensor1),
      toDouble(battery.tempSensor2),
      toDouble(battery.tempSensor3),
      toDouble(battery.tempSensor4),
      toDouble(battery.tempSensor5),
      toDouble(battery.tempSensor6),
      toDouble(battery.tempSensor7),
    ];

    // Only return up to actualTempCount sensors, filtering out invalid values
    return allTemps
        .where((t) {
          return t != null && t > 0 && t <= 100;
        })
        .cast<double>()
        .toList();
  }

  int? parseChargingStatus(String? value) {
    if (value == null) return null;
    return double.tryParse(value)?.toInt();
  }

  String getChargingStatus(String? value) {
    final status = parseChargingStatus(value);

    switch (status) {
      case 0:
        return "Disconnected";
      case 1:
        return "Idle";
      case 2:
        return "Discharging";
      case 3:
        return "Charging";
      default:
        return "Disconnected";
    }
  }

  LinearGradient getChargingColor(String? value) {
    final status = parseChargingStatus(value);

    switch (status) {
      case 0:
        return tGreyGradient;
      case 1:
        return tOrangeGradient;
      case 2:
        return tGreenGradient2;
      case 3:
        return tBlueGradient1;
      default:
        return tGreyGradient;
    }
  }

  @override
  void initState() {
    super.initState();
    final status = widget.device.status ?? '';
    fetchDeviceDetails();

    fetchDeviceDiagnostic();
    _overviewTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchDeviceDiagnostic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ResponsiveLayout(
      mobile: const Center(child: Text("Mobile / Tablet layout coming soon")),
      tablet: const Center(child: Text("Mobile / Tablet layout coming soon")),
      desktop: _buildDesktopLayout(context, isDark),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;
    final device = widget.device;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: FutureBuilder<String>(
            // future: getAddressFromLocationStringWeb(device.location ?? ''),
            future: getAddressFromLocationStringWeb(
              deviceDetailsModel?.lat != null &&
                      deviceDetailsModel?.long != null
                  ? '${deviceDetailsModel!.lat},${deviceDetailsModel!.long}'
                  : "",
            ),
            builder: (context, snapshot) {
              final address =
                  snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData
                      ? snapshot.data!
                      : 'Fetching location...';

              // return buildDeviceCard(
              //   isDark: isDark,
              //   imei: device.imei ?? '12265679827872127',
              //   vehicleNumber: device.vehicleNumber ?? 'VGFDG4251271677',
              //   status: device.status ?? '',
              //   fuel: device.soc?.toString() ?? '0',
              //   odo: device.odometer?.toString() ?? '0',
              //   trips: (device.totalTrips ?? 0).toString(),
              //   alerts: (device.totalAlerts ?? 0).toString(),
              //   location: address,
              //   lastUpdated: device.locationLogDate ?? '',
              //   onTabChanged: (tab) {
              //     setState(() => selectedTab = tab);
              //   },
              //   selectedTab: selectedTab,
              // );
              return buildDeviceCard(
                isDark: isDark,
                imei: deviceDetailsModel?.imei ?? '',
                vehicleNumber: deviceDetailsModel?.vehicleNumber ?? '',
                status: deviceDetailsModel?.status ?? '',
                fuel:
                    mode == 'EV Fleet'
                        ? device.soc ?? ''
                        : (device.tafe?.fuellevel?.toString() ?? ''),
                odo: device.odometer ?? '',
                trips: (device.totalTrips ?? 0).toString(),
                alerts: (device.totalAlerts ?? 0).toString(),
                location: address,
                lastUpdated: deviceDetailsModel?.batteryTime ?? '',
                onTabChanged: (tab) {
                  setState(() => selectedTab = tab);
                },
                selectedTab: selectedTab,
              );
            },
          ),
        ),
        // ===== Dynamic Body Section =====
        if (selectedTab == "Statistics")
          _buildDiagnosticsCards(isDark)
        else
          _buildCanDataTables(isDark),
      ],
    );
  }

  Widget _buildDiagnosticsCards(bool isDark) {
    final device = widget.device;
    final mode = context.watch<FleetModeProvider>().mode;

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: 225,
                      decoration: BoxDecoration(
                        color: isDark ? tBlack : tWhite,
                        boxShadow: [
                          BoxShadow(
                            spreadRadius: 2,
                            blurRadius: 10,
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.25)
                                    : tBlack.withOpacity(0.15),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          mode == 'EV Fleet'
                              ? SingleDoughnutChart(
                                currentValue: toDouble(
                                  deviceDiagnosticModel?.battery?.voltage,
                                ),
                                avgValue:
                                    toDouble(
                                      deviceDiagnosticModel?.battery?.voltage,
                                    ) *
                                    0.65,
                                title: "Voltage",
                                unit: "V",
                                primaryColor: tBlue,
                                isDark: isDark,
                              )
                              : SingleDoughnutChart(
                                currentValue: toDouble(
                                  deviceDiagnosticModel?.location?.vehvoltage,
                                ),
                                avgValue:
                                    toDouble(
                                      deviceDiagnosticModel
                                          ?.location
                                          ?.vehvoltage,
                                    ) *
                                    0.65,
                                title: "Voltage",
                                unit: "V",
                                primaryColor: tBlue,
                                isDark: isDark,
                              ),
                          mode == 'EV Fleet'
                              ? SingleDoughnutChart(
                                currentValue: toDouble(
                                  deviceDiagnosticModel?.battery?.current,
                                ),
                                avgValue:
                                    toDouble(
                                      deviceDiagnosticModel?.battery?.current,
                                    ) *
                                    0.65,
                                title: "Current",
                                unit: "A",
                                primaryColor: tPink,
                                isDark: isDark,
                              )
                              : SingleDoughnutChart(
                                currentValue: toDouble(
                                  deviceDiagnosticModel?.location?.fuelLevel,
                                ),
                                avgValue:
                                    toDouble(
                                      deviceDiagnosticModel
                                          ?.location
                                          ?.fuelLevel,
                                    ) *
                                    0.65,
                                title: "Fuel",
                                unit: "%",
                                primaryColor: tGreen,
                                isDark: isDark,
                              ),
                          mode == 'EV Fleet'
                              ? SingleDoughnutChart(
                                currentValue: toDouble(
                                  deviceDiagnosticModel?.battery?.soh,
                                ),
                                avgValue:
                                    toDouble(
                                      deviceDiagnosticModel?.battery?.soh,
                                    ) *
                                    0.65,
                                title: "SOH",
                                unit: "%",
                                primaryColor: tBlueSky,
                                isDark: isDark,
                              )
                              : SingleDoughnutChart(
                                currentValue: toDouble(
                                  deviceDiagnosticModel?.location?.rpm,
                                ),
                                avgValue:
                                    toDouble(
                                      deviceDiagnosticModel?.location?.rpm,
                                    ) *
                                    0.65,
                                title: "RPM",
                                unit: "rpm",
                                primaryColor: tBlueSky,
                                isDark: isDark,
                              ),
                          mode == 'EV Fleet'
                              ? SingleDoughnutChart(
                                currentValue: toDouble(
                                  deviceDiagnosticModel?.battery?.soc,
                                ),
                                avgValue:
                                    toDouble(
                                      deviceDiagnosticModel?.battery?.soc,
                                    ) *
                                    0.65,
                                title: "SOC",
                                unit: "%",
                                primaryColor: tGreen,
                                isDark: isDark,
                              )
                              : SingleDoughnutChart(
                                currentValue: toDouble(
                                  deviceDiagnosticModel?.location?.rpm,
                                ),
                                avgValue:
                                    toDouble(
                                      deviceDiagnosticModel?.location?.rpm,
                                    ) *
                                    0.65,
                                title: 'Torque',
                                unit: 'Nm',
                                primaryColor: tPink2,
                                isDark: true,
                              ),
                          SingleDoughnutChart(
                            currentValue: toDouble(
                              deviceDiagnosticModel?.battery?.temperature,
                            ),
                            avgValue:
                                toDouble(
                                  deviceDiagnosticModel?.battery?.temperature,
                                ) *
                                0.65,
                            title: "Temperature",
                            unit: "°C",
                            primaryColor: tOrange1,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 20),

                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildInfoCard(
                                isDark,
                                'Speed (km/h)',
                                (toDouble(
                                  deviceDiagnosticModel?.location?.speed,
                                )).toString(),
                                tGreenGradient,
                              ),
                              const SizedBox(height: 20),

                              _buildInfoCard(
                                isDark,
                                "Odometer (km)",
                                format.format(
                                  toDouble(
                                        deviceDiagnosticModel
                                            ?.location
                                            ?.odometer,
                                      ) ??
                                      0,
                                ),
                                tBlueGradient1,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      isDark,
                                      "SOS",
                                      (deviceDiagnosticModel?.location?.sos ==
                                              "1")
                                          ? "ON"
                                          : "OFF",
                                      (deviceDiagnosticModel?.location?.sos ==
                                              "1")
                                          ? tGreenGradient1
                                          : tRedGradient3,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child:
                                        mode == 'EV Fleet'
                                            ? _buildInfoCard(
                                              isDark,
                                              "Cycle Count",
                                              deviceDiagnosticModel
                                                      ?.battery
                                                      ?.cycleCount
                                                      ?.toString() ??
                                                  "--",
                                              tBlueGradient5,
                                            )
                                            : _buildInfoCard(
                                              isDark,
                                              "PTO",
                                              (deviceDiagnosticModel
                                                          ?.location
                                                          ?.pto ==
                                                      "1")
                                                  ? "ON"
                                                  : "OFF",
                                              (deviceDiagnosticModel
                                                          ?.location
                                                          ?.pto ==
                                                      "1")
                                                  ? tGreenGradient1
                                                  : tRedGradient3,
                                            ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child:
                                        mode == 'EV Fleet'
                                            ? _buildInfoCard(
                                              isDark,
                                              "DTE (km)",
                                              deviceDiagnosticModel
                                                      ?.battery
                                                      ?.distanceEmpty
                                                      ?.toString() ??
                                                  "--",
                                              tBlueGradient2,
                                            )
                                            : _buildInfoCard(
                                              isDark,
                                              "AdBlue (L)",
                                              '45',
                                              tBlueGradient2,
                                            ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      isDark,
                                      "Ignition",
                                      (deviceDiagnosticModel
                                                  ?.location
                                                  ?.ignition ==
                                              "1")
                                          ? "ON"
                                          : "OFF",
                                      tGreenGradient2,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child:
                                        mode == 'EV Fleet'
                                            // ? _buildInfoCard(
                                            //   isDark,
                                            //   "Sports Mode",
                                            //   (device.tafe?.w4d == "1")
                                            //       ? "--"
                                            //       : "--",
                                            //   (device.tafe?.w4d == "1")
                                            //       ? tRedGradient4
                                            //       : tGreyGradient,
                                            // )
                                            ? _buildInfoCard(
                                              isDark,
                                              "Charging Status",
                                              getChargingStatus(
                                                deviceDiagnosticModel
                                                    ?.battery
                                                    ?.chargingStatus,
                                              ),
                                              getChargingColor(
                                                deviceDiagnosticModel
                                                    ?.battery
                                                    ?.chargingStatus,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            )
                                            : _buildInfoCard(
                                              isDark,
                                              "4 Wheel Drive",
                                              (deviceDiagnosticModel
                                                          ?.location
                                                          ?.fourWd ==
                                                      "1")
                                                  ? "ON"
                                                  : "OFF",
                                              (deviceDiagnosticModel
                                                          ?.location
                                                          ?.fourWd ==
                                                      "1")
                                                  ? tGreenGradient1
                                                  : tRedGradient3,
                                            ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildInfoCard(
                                      isDark,
                                      "Immobilize",
                                      (deviceDiagnosticModel?.location?.pto ==
                                              "1")
                                          ? "ON"
                                          : "OFF",
                                      (deviceDiagnosticModel?.location?.pto ==
                                              "1")
                                          ? tGreenGradient1
                                          : tRedGradient3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // _buildStatsGraphsAndBars(isDark),
              // mode == 'EV Fleet' ? _buildgraphbar(isDark) : Container(),
              mode == 'EV Fleet'
                  ? Column(
                    children: [
                      _buildgraphbar(isDark),

                      if (showStatsGraphs) _buildStatsGraphsAndBars(isDark),
                    ],
                  )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    bool isDark,
    String title,
    String value,
    Gradient cardGradient, {
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return Container(
      width: double.infinity, // fits 2 per row
      decoration: BoxDecoration(
        color: tTransparent,
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 10,
            color: isDark ? tWhite.withOpacity(0.25) : tBlack.withOpacity(0.15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? tBlack : tWhite,
              // border: Border.all(width: 0.5, color: isDark ? tWhite : tBlack),
            ),
            child: Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 12,
                color: isDark ? tWhite : tBlack,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          /// Gradient Value Box
          Container(
            height: 75,
            width: double.infinity,
            decoration: BoxDecoration(gradient: cardGradient),
            alignment: Alignment.center,
            // child: Text(
            //   double.tryParse(value) != null
            //       ? double.parse(value).floor().toString()
            //       : value,
            //   overflow: overflow,
            //   maxLines: 1,
            //   style: GoogleFonts.urbanist(
            //     fontSize: 30,
            //     color: tWhite,
            //     fontWeight: FontWeight.bold,
            //   ),
            //   textAlign: TextAlign.center,
            // ),
            child: AutoSizeText(
              double.tryParse(value) != null
                  ? double.parse(value).floor().toString()
                  : value,
              overflow: overflow,
              maxLines: 1,
              style: GoogleFonts.urbanist(
                fontSize: 30,
                color: tWhite,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
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
    required Function(String) onTabChanged,
    required String selectedTab,
  }) {
    Color statusColor;
    final safeStatus = status.isEmpty ? 'unknown' : status.toLowerCase();
    switch (safeStatus) {
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

    return Container(
      width: double.infinity,
      height: 90,
      decoration: BoxDecoration(
        color: isDark ? tBlack : tWhite,
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 10,
            color: isDark ? tWhite.withOpacity(0.25) : tBlack.withOpacity(0.15),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SvgPicture.asset('icons/struck1.svg', width: 80, height: 80),
          Image.asset(
            'images/Hero_Lectro_Bike.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ===== Top Row =====
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
                          Container(
                            width: 350,
                            // constraints: const BoxConstraints(
                            //   minWidth: 200,
                            //   maxWidth: 400,
                            // ),
                            decoration: BoxDecoration(
                              border: Border.all(color: statusColor, width: 1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(5),
                                      bottomLeft: Radius.circular(5),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        vehicleNumber,
                                        style: GoogleFonts.urbanist(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? tWhite : tBlack,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

                    // ==== Right Side (Tabs) ====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildTabButton("Statistics", selectedTab, isDark, () {
                          onTabChanged("Statistics");
                        }),
                        const SizedBox(width: 5),
                        _buildTabButton("CAN Data", selectedTab, isDark, () {
                          onTabChanged("CAN Data");
                        }),
                      ],
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
                // ===== Bottom Row (Location) =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: SvgPicture.asset(
                              'icons/geofence.svg',
                              color: statusColor,
                              fit: BoxFit.contain,
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

  Widget _buildStatsGraphsAndBars(bool isDark) {
    final imei = widget.device.imei;
    final mode = context.watch<FleetModeProvider>().mode;
    return Column(
      children: [
        // Row(
        //   children: [
        //     Expanded(
        //       child: GrafanaPanel(
        //         url: grafanaUrl(panelId: 7, imei: imei ?? '', isDark: isDark),
        //         height: 175,
        //       ),
        //     ),
        //     const SizedBox(width: 20),
        //     Expanded(
        //       child: GrafanaPanel(
        //         url: grafanaUrl(panelId: 9, imei: imei ?? '', isDark: isDark),
        //         height: 175,
        //       ),
        //     ),
        //     const SizedBox(width: 20),
        //     mode == 'EV Fleet'
        //         ? Expanded(
        //           child: GrafanaPanel(
        //             url: grafanaUrl(
        //               panelId: 25,
        //               imei: imei ?? '',
        //               isDark: isDark,
        //             ),
        //             height: 175,
        //           ),
        //         )
        //         : Expanded(
        //           child: GrafanaPanel(
        //             url: grafanaUrl(
        //               panelId: 40,
        //               imei: imei ?? '',
        //               isDark: isDark,
        //             ),
        //             height: 175,
        //           ),
        //         ),
        //     const SizedBox(width: 20),
        //     mode == 'EV Fleet'
        //         ? Expanded(
        //           child: GrafanaPanel(
        //             url: grafanaUrl(
        //               panelId: 31,
        //               imei: imei ?? '',
        //               isDark: isDark,
        //             ),
        //             height: 175,
        //           ),
        //         )
        //         : Expanded(
        //           child: GrafanaPanel(
        //             url: grafanaUrl(
        //               panelId: 41,
        //               imei: imei ?? '',
        //               isDark: isDark,
        //             ),
        //             height: 175,
        //           ),
        //         ),
        //     if (mode == 'EV Fleet') ...[
        //       const SizedBox(width: 20),
        //       Expanded(
        //         child: GrafanaPanel(
        //           url: grafanaUrl(
        //             panelId: 39,
        //             imei: imei ?? '',
        //             isDark: isDark,
        //           ),
        //           height: 175,
        //         ),
        //       ),
        //       const SizedBox(width: 20),
        //       Expanded(
        //         child: GrafanaPanel(
        //           url: grafanaUrl(
        //             panelId: 19,
        //             imei: imei ?? '',
        //             isDark: isDark,
        //           ),
        //           height: 175,
        //         ),
        //       ),
        //     ],
        //   ],
        // ),
        // const SizedBox(height: 20),
        // Row(
        //   children: [
        //     Expanded(
        //       child: GrafanaPanel(
        //         url: grafanaUrl(panelId: 26, imei: imei ?? '', isDark: isDark),
        //         height: 175,
        //       ),
        //     ),
        //     const SizedBox(width: 20),
        //     Expanded(
        //       child: GrafanaPanel(
        //         url: grafanaUrl(panelId: 42, imei: imei ?? '', isDark: isDark),
        //         height: 175,
        //       ),
        //     ),
        //     const SizedBox(width: 20),
        //     Expanded(
        //       child: GrafanaPanel(
        //         url: grafanaUrl(panelId: 44, imei: imei ?? '', isDark: isDark),
        //         height: 175,
        //       ),
        //     ),
        //     if (mode == 'EV Fleet') ...[
        //       const SizedBox(width: 20),
        //       Expanded(
        //         child: GrafanaPanel(
        //           url: grafanaUrl(
        //             panelId: 57,
        //             imei: imei ?? '',
        //             isDark: isDark,
        //           ),
        //           height: 175,
        //         ),
        //       ),
        //       const SizedBox(width: 20),
        //       Expanded(
        //         child: GrafanaPanel(
        //           url: grafanaUrl(
        //             panelId: 38,
        //             imei: imei ?? '',
        //             isDark: isDark,
        //           ),
        //           height: 175,
        //         ),
        //       ),
        //     ],

        //     const SizedBox(width: 20),
        //     Expanded(
        //       child: GrafanaPanel(
        //         url: grafanaUrl(panelId: 28, imei: imei ?? '', isDark: isDark),
        //         height: 175,
        //       ),
        //     ),
        //   ],
        // ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GrafanaPanel(
                url: grafanaUrl(panelId: 30, imei: imei ?? '', isDark: isDark),
                height: 250,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: GrafanaPanel(
                url: grafanaUrl(panelId: 53, imei: imei ?? '', isDark: isDark),
                height: 250,
              ),
            ),
            const SizedBox(width: 20),
            mode == 'EV Fleet'
                ? Expanded(
                  child: GrafanaPanel(
                    url: grafanaUrl(
                      panelId: 35,
                      imei: imei ?? '',
                      isDark: isDark,
                    ),
                    height: 250,
                  ),
                )
                : Expanded(
                  child: GrafanaPanel(
                    url: grafanaUrl(
                      panelId: 52,
                      imei: imei ?? '',
                      isDark: isDark,
                    ),
                    height: 250,
                  ),
                ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GrafanaPanel(
                url: grafanaUrl(panelId: 16, imei: imei ?? '', isDark: isDark),
                height: 250,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: GrafanaPanel(
                url: grafanaUrl(panelId: 50, imei: imei ?? '', isDark: isDark),
                height: 250,
              ),
            ),
            const SizedBox(width: 20),
            mode == 'EV Fleet'
                ? Expanded(
                  child: GrafanaPanel(
                    url: grafanaUrl(
                      panelId: 22,
                      imei: imei ?? '',
                      isDark: isDark,
                    ),
                    height: 250,
                  ),
                )
                : Expanded(
                  child: GrafanaPanel(
                    url: grafanaUrl(
                      panelId: 51,
                      imei: imei ?? '',
                      isDark: isDark,
                    ),
                    height: 250,
                  ),
                ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: GrafanaPanel(
                url: grafanaUrl(panelId: 46, imei: imei ?? '', isDark: isDark),
                height: 125,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              flex: 5,
              child: GrafanaPanel(
                url: grafanaUrl(panelId: 48, imei: imei ?? '', isDark: isDark),
                height: 125,
              ),
            ),
          ],
        ),

        SizedBox(height: 20),

        if (mode != 'EV Fleet') ...[
          Row(
            children: [
              Expanded(
                flex: 5,
                child: GrafanaPanel(
                  url: grafanaUrl(
                    panelId: 47,
                    imei: imei ?? '',
                    isDark: isDark,
                  ),
                  height: 125,
                ),
              ),
              SizedBox(width: 5),
              Expanded(
                flex: 5,
                child: GrafanaPanel(
                  url: grafanaUrl(
                    panelId: 49,
                    imei: imei ?? '',
                    isDark: isDark,
                  ),
                  height: 125,
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ],

        if (mode == 'EV Fleet') ...[
          GrafanaPanel(
            url: grafanaUrl(panelId: 34, imei: imei ?? '', isDark: isDark),
            height: 125,
          ),
          SizedBox(height: 20),

          Row(
            children: [
              // Expanded(
              //   flex: 6,
              //   child: GrafanaPanel(
              //     url: grafanaUrl(
              //       panelId: 11,
              //       imei: imei ?? '',
              //       isDark: isDark,
              //     ),
              //     height: 400,
              //   ),
              // ),
              // SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: GrafanaPanel(
                  url: grafanaUrl(
                    panelId: 14,
                    imei: imei ?? '',
                    isDark: isDark,
                  ),
                  height: 400,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          GrafanaPanel(
            url: grafanaUrl(panelId: 29, imei: imei ?? '', isDark: isDark),
            height: 250,
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 10),
          //   child: _buildgraphbar(isDark),
          // ),
        ],
      ],
    );
  }

  // Widget _buildgraphbar(bool isDark) {
  //   final cellVoltages = getCellVoltages(deviceDiagnosticModel?.battery);

  //   final temps = getTemperatureSensors(deviceDiagnosticModel?.battery);
  //   final totalCells = temps.isEmpty ? 7 : temps.length;
  //   final mode = context.watch<FleetModeProvider>().mode;

  //   return Column(
  //     children: [
  //       Row(
  //         children: [
  //           Expanded(
  //             flex: 8,
  //             child: Container(
  //               height: 400,
  //               decoration: BoxDecoration(
  //                 color: isDark ? tBlack : tWhite,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     spreadRadius: 2,
  //                     blurRadius: 10,
  //                     color:
  //                         isDark
  //                             ? tWhite.withOpacity(0.25)
  //                             : tBlack.withOpacity(0.15),
  //                   ),
  //                 ],
  //               ),
  //               padding: EdgeInsets.all(10),
  //               // child: Column(
  //               //   children: [
  //               //     Text(
  //               //       'Live Cell Voltages (V)',
  //               //       style: GoogleFonts.urbanist(
  //               //         fontSize: 13,
  //               //         fontWeight: FontWeight.bold,
  //               //         color: isDark ? tWhite : tBlack,
  //               //       ),
  //               //     ),
  //               //     SizedBox(height: 20),

  //               //     Row(
  //               //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //               //       children: List.generate(10, (index) {
  //               //         double randomVoltage =
  //               //             3.0 + Random().nextDouble() * 1.5; // 3.0 - 4.5V
  //               //         return Real3DBatteryVertical(
  //               //           voltage: randomVoltage,
  //               //           height: 150,
  //               //           width: 75,
  //               //           isDark: isDark,
  //               //           label:
  //               //               "Cell ${index + 1}", // optional label for each cell
  //               //         );
  //               //       }),
  //               //     ),

  //               //     SizedBox(height: 20),

  //               //     // Second row: remaining 12 cells
  //               //     Row(
  //               //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //               //       children: List.generate(10, (index) {
  //               //         double randomVoltage =
  //               //             3.0 + Random().nextDouble() * 1.5; // 3.0 - 4.5V
  //               //         return Real3DBatteryVertical(
  //               //           voltage: randomVoltage,
  //               //           height: 150,
  //               //           width: 75,
  //               //           isDark: isDark,
  //               //           label:
  //               //               "Cell ${index + 11}", // optional label for each cell
  //               //         );
  //               //       }),
  //               //     ),

  //               //     SizedBox(height: 20),

  //               //     // Second row: remaining 12 cells
  //               //     Row(
  //               //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //               //       children: List.generate(10, (index) {
  //               //         double randomVoltage =
  //               //             3.0 + Random().nextDouble() * 1.5; // 3.0 - 4.5V
  //               //         return Real3DBatteryVertical(
  //               //           voltage: randomVoltage,
  //               //           height: 150,
  //               //           width: 75,
  //               //           isDark: isDark,
  //               //           label:
  //               //               "Cell ${index + 11}", // optional label for each cell
  //               //         );
  //               //       }),
  //               //     ),
  //               //   ],
  //               // ),
  //               child: Column(
  //                 children: [
  //                   Text(
  //                     'Live Cell Voltages (V)',
  //                     style: GoogleFonts.urbanist(
  //                       fontSize: 13,
  //                       fontWeight: FontWeight.bold,
  //                       color: isDark ? tWhite : tBlack,
  //                     ),
  //                   ),
  //                   SizedBox(height: 20),

  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                     children: List.generate(12, (index) {
  //                       final voltage =
  //                           index < cellVoltages.length
  //                               ? cellVoltages[index]
  //                               : null;

  //                       if (voltage == null) {
  //                         return SizedBox(width: 75);
  //                       }
  //                       if (voltage <= 0 || voltage > 5) {
  //                         return SizedBox(width: 75);
  //                       }
  //                       return Real3DBatteryVertical(
  //                         voltage: voltage,
  //                         height: 150,
  //                         width: 75,
  //                         isDark: isDark,
  //                         label: "Cell ${index + 1}",
  //                       );
  //                     }),
  //                   ),

  //                   SizedBox(height: 20),

  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                     children: List.generate(12, (index) {
  //                       int actualIndex = index + 12;

  //                       final voltage =
  //                           index < cellVoltages.length
  //                               ? cellVoltages[actualIndex]
  //                               : null;

  //                       if (voltage == null) {
  //                         return SizedBox(width: 75);
  //                       }
  //                       if (voltage <= 1 || voltage > 5) {
  //                         return SizedBox(width: 75);
  //                       }

  //                       return Real3DBatteryVertical(
  //                         voltage: voltage,
  //                         height: 150,
  //                         width: 75,
  //                         isDark: isDark,
  //                         label: "Cell ${actualIndex + 1}",
  //                       );
  //                     }),
  //                   ),

  //                   SizedBox(height: 20),

  //                   // Row(
  //                   //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                   //   children: List.generate(12, (index) {
  //                   //     int actualIndex = index + 20;

  //                   //     final voltage =
  //                   //         index < cellVoltages.length
  //                   //             ? cellVoltages[actualIndex]
  //                   //             : null;

  //                   //     if (voltage == null) {
  //                   //       return SizedBox(width: 75);
  //                   //     }

  //                   //     return Real3DBatteryVertical(
  //                   //       voltage: voltage,
  //                   //       height: 150,
  //                   //       width: 75,
  //                   //       isDark: isDark,
  //                   //       label: "Cell ${actualIndex + 1}",
  //                   //     );
  //                   //   }),
  //                   // ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //           SizedBox(width: 20),
  //           Expanded(
  //             flex: 3,
  //             child: Container(
  //               height: 400,
  //               decoration: BoxDecoration(
  //                 color: isDark ? tBlack : tWhite,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     spreadRadius: 2,
  //                     blurRadius: 10,
  //                     color:
  //                         isDark
  //                             ? tWhite.withOpacity(0.25)
  //                             : tBlack.withOpacity(0.15),
  //                   ),
  //                 ],
  //               ),
  //               padding: EdgeInsets.all(10),
  //               // child: Column(
  //               //   children: [
  //               //     Text(
  //               //       'Live Cell Temperatures (°C)',
  //               //       style: GoogleFonts.urbanist(
  //               //         fontSize: 13,
  //               //         fontWeight: FontWeight.bold,
  //               //         color: isDark ? tWhite : tBlack,
  //               //       ),
  //               //     ),
  //               //     SizedBox(height: 20),

  //               //     // Split the cells into rows (5 per row)
  //               //     for (int row = 0; row < (totalCells / 5).ceil(); row++)
  //               //       Padding(
  //               //         padding: const EdgeInsets.only(bottom: 20),
  //               //         child: Row(
  //               //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //               //           children: List.generate(5, (index) {
  //               //             int cellNumber = row * 5 + index + 1;
  //               //             if (cellNumber > totalCells)
  //               //               return SizedBox(width: 75); // empty space

  //               //             double randomTemp =
  //               //                 25 + Random().nextDouble() * 10; // 25°C to 35°C

  //               //             return Thermometer3D(
  //               //               temperature: randomTemp,
  //               //               height: 150,
  //               //               width: 75,
  //               //               label: 'Cell Temp. $cellNumber',
  //               //             );
  //               //           }),
  //               //         ),
  //               //       ),
  //               //   ],
  //               // ),
  //               child: Column(
  //                 children: [
  //                   Text(
  //                     'Live Cell Temperatures (°C)',
  //                     style: GoogleFonts.urbanist(
  //                       fontSize: 13,
  //                       fontWeight: FontWeight.bold,
  //                       color: isDark ? tWhite : tBlack,
  //                     ),
  //                   ),
  //                   SizedBox(height: 20),
  //                   for (int row = 0; row < (totalCells / 4).ceil(); row++)
  //                     Padding(
  //                       padding: const EdgeInsets.only(bottom: 20),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                         children: List.generate(4, (index) {
  //                           int cellNumber = row * 4 + index;

  //                           if (cellNumber >= temps.length) {
  //                             return SizedBox(width: 75);
  //                           }
  //                           double temp = temps[cellNumber];

  //                           if (temp <= 0 || temp > 100) {
  //                             return SizedBox(width: 75);
  //                           }

  //                           return Thermometer3D(
  //                             temperature:
  //                                 cellNumber < temps.length
  //                                     ? temps[cellNumber]
  //                                     : 0.0,
  //                             height: 150,
  //                             width: 75,
  //                             label: 'Cell Temp. ${cellNumber + 1}',
  //                           );
  //                         }),
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }
  //   -----------------------------

  //  -------------------------------

  bool showStatsGraphs = false;
  Widget _buildgraphbar(bool isDark) {
    final cellVoltages = getCellVoltages(deviceDiagnosticModel?.battery);
    final temps = getTemperatureSensors(deviceDiagnosticModel?.battery);

    final hasValidVoltages = cellVoltages.any(
      (v) => v != null && v > 0 && v <= 5,
    );
    final hasValidTemps = temps.any((t) => t != null && t > 0 && t <= 100);

    final hasNoData = !hasValidVoltages && !hasValidTemps;
    final totalCells = temps.isEmpty ? 7 : temps.length;

    // 🔹 Common Button Widget
    Widget buildButton(String text, VoidCallback onTap) {
      return Align(
        alignment: Alignment.bottomRight,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tGreen8,
              borderRadius: BorderRadius.circular(4),
              gradient: SweepGradient(
                colors: [tGreen8, tGreen8.withOpacity(0.6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: tGreen8.withOpacity(0.4),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: tBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    if (hasNoData) {
      if (!showStatsGraphs) {
        return buildButton("View More", () {
          setState(() {
            showStatsGraphs = true;
          });
        });
      } else {
        // 👇 When expanded (Grafana links or anything)
        return Column(
          children: [
            buildButton("View Less", () {
              setState(() {
                showStatsGraphs = false;
              });
            }),
          ],
        );
      }
    }
    return Column(
      children: [
        Row(
          children: [
            /// 🔹 Voltage Section
            Expanded(
              flex: 8,
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: 2,
                      blurRadius: 10,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.25)
                              : tBlack.withOpacity(0.15),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      'Live Cell Voltages (V)',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                    SizedBox(height: 20),

                    /// Row 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(12, (index) {
                        final voltage =
                            index < cellVoltages.length
                                ? cellVoltages[index]
                                : null;

                        if (voltage == null || voltage <= 0 || voltage > 5) {
                          return SizedBox(width: 75);
                        }

                        return Real3DBatteryVertical(
                          voltage: voltage,
                          height: 150,
                          width: 75,
                          isDark: isDark,
                          label: "Cell ${index + 1}",
                        );
                      }),
                    ),

                    SizedBox(height: 20),

                    /// Row 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(12, (index) {
                        int actualIndex = index + 12;

                        final voltage =
                            actualIndex < cellVoltages.length
                                ? cellVoltages[actualIndex]
                                : null;

                        if (voltage == null || voltage <= 1 || voltage > 5) {
                          return SizedBox(width: 75);
                        }

                        return Real3DBatteryVertical(
                          voltage: voltage,
                          height: 150,
                          width: 75,
                          isDark: isDark,
                          label: "Cell ${actualIndex + 1}",
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 20),

            /// 🔹 Temperature Section
            Expanded(
              flex: 3,
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: 2,
                      blurRadius: 10,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.25)
                              : tBlack.withOpacity(0.15),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      'Live Cell Temperatures (°C)',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                    SizedBox(height: 20),

                    for (int row = 0; row < (totalCells / 4).ceil(); row++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) {
                            int cellNumber = row * 4 + index;

                            if (cellNumber >= temps.length) {
                              return SizedBox(width: 75);
                            }

                            double temp = temps[cellNumber];

                            if (temp <= 0 || temp > 100) {
                              return SizedBox(width: 75);
                            }

                            return Thermometer3D(
                              temperature: temp,
                              height: 150,
                              width: 75,
                              label: 'Cell Temp. ${cellNumber + 1}',
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 10),

        /// 🔹 View Less Button
        buildButton(showStatsGraphs ? "View Less" : "View More", () {
          setState(() {
            showStatsGraphs = !showStatsGraphs;
          });
        }),
      ],
    );
  }

  // Widget _buildStatsGraphsAndBars(bool isDark) {
  //   final int totalCells = 15;
  //   final mode = context.watch<FleetModeProvider>().mode;

  //   // --- USE IT HERE ---
  //   final List<List<double>> cellVoltageListOf24Cells = generateCellVoltages(
  //     24,
  //   );
  //   final temperatureListOf10Sensors = generateTemperatureListOf10Sensors(
  //     points: 100, // number of values per sensor
  //   );

  //   final List<String> timeStampsList = generateLast24HourLabels();
  //   return Column(
  //     children: [
  //       Row(
  //         children: [
  //           Expanded(
  //             flex: 5,
  //             child: Container(
  //               height: 250,
  //               decoration: BoxDecoration(
  //                 color: isDark ? tBlack : tWhite,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     spreadRadius: 2,
  //                     blurRadius: 10,
  //                     color:
  //                         isDark
  //                             ? tWhite.withOpacity(0.25)
  //                             : tBlack.withOpacity(0.15),
  //                   ),
  //                 ],
  //               ),
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 10,
  //                 vertical: 5,
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         "Vehicle Voltage (V)",
  //                         style: GoogleFonts.urbanist(
  //                           fontSize: 13,
  //                           fontWeight: FontWeight.bold,
  //                           color: isDark ? tWhite : tBlack,
  //                         ),
  //                       ),
  //                       _buildLegendItem(tBlue, "Vehicle Voltage", isDark),
  //                     ],
  //                   ),

  //                   const SizedBox(height: 10),
  //                   VehicleVoltageChart(
  //                     isDark: isDark,
  //                     voltageData: [12.5, 12.7, 13.2, 13.8, 14.0, 13.5, 13.1],
  //                     timeLabels: [
  //                       '10:00',
  //                       '10:05',
  //                       '10:10',
  //                       '10:15',
  //                       '10:20',
  //                       '10:25',
  //                       '10:30',
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),

  //           const SizedBox(width: 20),
  //           Expanded(
  //             flex: 5,
  //             child: Container(
  //               height: 250,
  //               decoration: BoxDecoration(
  //                 color: isDark ? tBlack : tWhite,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     spreadRadius: 2,
  //                     blurRadius: 10,
  //                     color:
  //                         isDark
  //                             ? tWhite.withOpacity(0.25)
  //                             : tBlack.withOpacity(0.15),
  //                   ),
  //                 ],
  //               ),
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 10,
  //                 vertical: 5,
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         "Speed (Km/h)",
  //                         style: GoogleFonts.urbanist(
  //                           fontSize: 13,
  //                           fontWeight: FontWeight.bold,
  //                           color: isDark ? tWhite : tBlack,
  //                         ),
  //                       ),
  //                       _buildLegendItem(tGreen, "Speed", isDark),
  //                     ],
  //                   ),

  //                   const SizedBox(height: 10),
  //                   VehicleSpeedChart(
  //                     isDark: isDark,
  //                     speedData: [40, 45, 60, 72, 68, 70, 65],
  //                     timeLabels: [
  //                       '10:00',
  //                       '10:05',
  //                       '10:10',
  //                       '10:15',
  //                       '10:20',
  //                       '10:25',
  //                       '10:30',
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //           const SizedBox(width: 20),
  //           Expanded(
  //             flex: 5,
  //             child: Container(
  //               height: 250,
  //               decoration: BoxDecoration(
  //                 color: isDark ? tBlack : tWhite,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     spreadRadius: 2,
  //                     blurRadius: 10,
  //                     color:
  //                         isDark
  //                             ? tWhite.withOpacity(0.25)
  //                             : tBlack.withOpacity(0.15),
  //                   ),
  //                 ],
  //               ),
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 10,
  //                 vertical: 5,
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         "Odometer (km)",
  //                         style: GoogleFonts.urbanist(
  //                           fontSize: 13,
  //                           fontWeight: FontWeight.bold,
  //                           color: isDark ? tWhite : tBlack,
  //                         ),
  //                       ),
  //                       _buildLegendItem(tBlueSky, "Odometer", isDark),
  //                     ],
  //                   ),

  //                   const SizedBox(height: 10),
  //                   OdometerChart(
  //                     odometerData: [10200, 10205, 10215, 10225, 10240, 10255],
  //                     timeLabels: [
  //                       '10:00',
  //                       '10:10',
  //                       '10:20',
  //                       '10:30',
  //                       '10:40',
  //                       '10:50',
  //                     ],
  //                     isDark: false,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 20),
  //       Row(
  //         children: [
  //           Expanded(
  //             flex: 5,
  //             child: Container(
  //               height: 250,
  //               decoration: BoxDecoration(
  //                 color: isDark ? tBlack : tWhite,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     spreadRadius: 2,
  //                     blurRadius: 10,
  //                     color:
  //                         isDark
  //                             ? tWhite.withOpacity(0.25)
  //                             : tBlack.withOpacity(0.15),
  //                   ),
  //                 ],
  //               ),
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 10,
  //                 vertical: 5,
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         "RPM",
  //                         style: GoogleFonts.urbanist(
  //                           fontSize: 13,
  //                           fontWeight: FontWeight.bold,
  //                           color: isDark ? tWhite : tBlack,
  //                         ),
  //                       ),
  //                       _buildLegendItem(tOrange1, "RPM", isDark),
  //                     ],
  //                   ),

  //                   const SizedBox(height: 10),
  //                   RpmChart(
  //                     rpmData: [800, 1500, 2500, 3000, 2800, 3200, 4000, 3500],
  //                     timeLabels: [
  //                       '10:00',
  //                       '10:01',
  //                       '10:02',
  //                       '10:03',
  //                       '10:04',
  //                       '10:05',
  //                       '10:06',
  //                       '10:07',
  //                     ],
  //                     isDark: false,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //           const SizedBox(width: 20),
  //           Expanded(
  //             flex: 5,
  //             child: Container(
  //               height: 250,
  //               decoration: BoxDecoration(
  //                 color: isDark ? tBlack : tWhite,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     spreadRadius: 2,
  //                     blurRadius: 10,
  //                     color:
  //                         isDark
  //                             ? tWhite.withOpacity(0.25)
  //                             : tBlack.withOpacity(0.15),
  //                   ),
  //                 ],
  //               ),
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 10,
  //                 vertical: 5,
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         "Fuel (%)",
  //                         style: GoogleFonts.urbanist(
  //                           fontSize: 13,
  //                           fontWeight: FontWeight.bold,
  //                           color: isDark ? tWhite : tBlack,
  //                         ),
  //                       ),
  //                       _buildLegendItem(tGreenDark, "Fuel", isDark),
  //                     ],
  //                   ),

  //                   const SizedBox(height: 10),
  //                   FuelChart(
  //                     fuelData: [100, 95, 90, 85, 80, 75, 70, 65],
  //                     timeLabels: [
  //                       '10:00',
  //                       '10:01',
  //                       '10:02',
  //                       '10:03',
  //                       '10:04',
  //                       '10:05',
  //                       '10:06',
  //                       '10:07',
  //                     ],
  //                     isDark: false,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //           const SizedBox(width: 20),
  //           Expanded(
  //             flex: 5,
  //             child: Container(
  //               height: 250,
  //               decoration: BoxDecoration(
  //                 color: isDark ? tBlack : tWhite,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     spreadRadius: 2,
  //                     blurRadius: 10,
  //                     color:
  //                         isDark
  //                             ? tWhite.withOpacity(0.25)
  //                             : tBlack.withOpacity(0.15),
  //                   ),
  //                 ],
  //               ),
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 10,
  //                 vertical: 5,
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         "Temperature (°C)",
  //                         style: GoogleFonts.urbanist(
  //                           fontSize: 13,
  //                           fontWeight: FontWeight.bold,
  //                           color: isDark ? tWhite : tBlack,
  //                         ),
  //                       ),
  //                       _buildLegendItem(tRed, "Temperature", isDark),
  //                     ],
  //                   ),

  //                   const SizedBox(height: 10),
  //                   VehicleTemperatureChart(
  //                     temperatureData: [72, 75, 78, 82, 85, 88, 90, 93],
  //                     timeLabels: [
  //                       '10:00',
  //                       '10:01',
  //                       '10:02',
  //                       '10:03',
  //                       '10:04',
  //                       '10:05',
  //                       '10:06',
  //                       '10:07',
  //                     ],
  //                     isDark: false,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 20),

  //       buildStatusBars(isDark),
  //       const SizedBox(height: 20),
  //       if (mode == 'EV Fleet') ...[
  //         Row(
  //           children: [
  //             Expanded(
  //               flex: 7,
  //               child: Container(
  //                 height: 600,
  //                 decoration: BoxDecoration(
  //                   color: isDark ? tBlack : tWhite,
  //                   boxShadow: [
  //                     BoxShadow(
  //                       spreadRadius: 2,
  //                       blurRadius: 10,
  //                       color:
  //                           isDark
  //                               ? tWhite.withOpacity(0.25)
  //                               : tBlack.withOpacity(0.15),
  //                     ),
  //                   ],
  //                 ),
  //                 padding: EdgeInsets.all(10),
  //                 child: Column(
  //                   children: [
  //                     Text(
  //                       'Live Cell Voltages (V)',
  //                       style: GoogleFonts.urbanist(
  //                         fontSize: 13,
  //                         fontWeight: FontWeight.bold,
  //                         color: isDark ? tWhite : tBlack,
  //                       ),
  //                     ),
  //                     SizedBox(height: 20),

  //                     // First row: 12 cells
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                       children: List.generate(10, (index) {
  //                         double randomVoltage =
  //                             3.0 + Random().nextDouble() * 1.5; // 3.0 - 4.5V
  //                         return Real3DBatteryVertical(
  //                           voltage: randomVoltage,
  //                           height: 150,
  //                           width: 75,
  //                           isDark: isDark,
  //                           label:
  //                               "Cell ${index + 1}", // optional label for each cell
  //                         );
  //                       }),
  //                     ),

  //                     SizedBox(height: 20),

  //                     // Second row: remaining 12 cells
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                       children: List.generate(10, (index) {
  //                         double randomVoltage =
  //                             3.0 + Random().nextDouble() * 1.5; // 3.0 - 4.5V
  //                         return Real3DBatteryVertical(
  //                           voltage: randomVoltage,
  //                           height: 150,
  //                           width: 75,
  //                           isDark: isDark,
  //                           label:
  //                               "Cell ${index + 11}", // optional label for each cell
  //                         );
  //                       }),
  //                     ),

  //                     SizedBox(height: 20),

  //                     // Second row: remaining 12 cells
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                       children: List.generate(10, (index) {
  //                         double randomVoltage =
  //                             3.0 + Random().nextDouble() * 1.5; // 3.0 - 4.5V
  //                         return Real3DBatteryVertical(
  //                           voltage: randomVoltage,
  //                           height: 150,
  //                           width: 75,
  //                           isDark: isDark,
  //                           label:
  //                               "Cell ${index + 11}", // optional label for each cell
  //                         );
  //                       }),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             SizedBox(width: 20),
  //             Expanded(
  //               flex: 3,
  //               child: Container(
  //                 height: 600,
  //                 decoration: BoxDecoration(
  //                   color: isDark ? tBlack : tWhite,
  //                   boxShadow: [
  //                     BoxShadow(
  //                       spreadRadius: 2,
  //                       blurRadius: 10,
  //                       color:
  //                           isDark
  //                               ? tWhite.withOpacity(0.25)
  //                               : tBlack.withOpacity(0.15),
  //                     ),
  //                   ],
  //                 ),
  //                 padding: EdgeInsets.all(10),
  //                 child: Column(
  //                   children: [
  //                     Text(
  //                       'Live Cell Temperatures (°C)',
  //                       style: GoogleFonts.urbanist(
  //                         fontSize: 13,
  //                         fontWeight: FontWeight.bold,
  //                         color: isDark ? tWhite : tBlack,
  //                       ),
  //                     ),
  //                     SizedBox(height: 20),

  //                     // Split the cells into rows (5 per row)
  //                     for (int row = 0; row < (totalCells / 5).ceil(); row++)
  //                       Padding(
  //                         padding: const EdgeInsets.only(bottom: 20),
  //                         child: Row(
  //                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                           children: List.generate(5, (index) {
  //                             int cellNumber = row * 5 + index + 1;
  //                             if (cellNumber > totalCells)
  //                               return SizedBox(width: 75); // empty space

  //                             double randomTemp =
  //                                 25 +
  //                                 Random().nextDouble() * 10; // 25°C to 35°C

  //                             return Thermometer3D(
  //                               temperature: randomTemp,
  //                               height: 150,
  //                               width: 75,
  //                               label: 'Cell Temp. $cellNumber',
  //                             );
  //                           }),
  //                         ),
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),

  //         const SizedBox(height: 20),

  //         Container(
  //           height: 450,
  //           decoration: BoxDecoration(
  //             color: isDark ? tBlack : tWhite,
  //             boxShadow: [
  //               BoxShadow(
  //                 spreadRadius: 2,
  //                 blurRadius: 10,
  //                 color:
  //                     isDark
  //                         ? tWhite.withOpacity(0.25)
  //                         : tBlack.withOpacity(0.15),
  //               ),
  //             ],
  //           ),
  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //           child: Row(
  //             children: [
  //               /// LEFT — CHART
  //               Expanded(
  //                 flex: 5,
  //                 child: Column(
  //                   children: [
  //                     Text(
  //                       "Cell Voltages (Last 24 Hours)",
  //                       style: GoogleFonts.urbanist(
  //                         fontSize: 13,
  //                         fontWeight: FontWeight.bold,
  //                         color: isDark ? tWhite : tBlack,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 10),

  //                     Expanded(
  //                       child: MultiCellVoltageChart(
  //                         cellVoltages: cellVoltageListOf24Cells,
  //                         timeLabels: timeStampsList,
  //                         isDark: isDark,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),

  //               const SizedBox(width: 10),

  //               /// RIGHT — LEGEND TABLE
  //               Expanded(
  //                 flex: 1,
  //                 child: buildCellLegendTable(
  //                   cellVoltages: cellVoltageListOf24Cells,
  //                   colors: cellColors24,
  //                   isDark: isDark,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         SizedBox(height: 20),
  //         Container(
  //           height: 400,
  //           width: double.infinity,
  //           decoration: BoxDecoration(
  //             color: isDark ? tBlack : tWhite,
  //             boxShadow: [
  //               BoxShadow(
  //                 spreadRadius: 2,
  //                 blurRadius: 10,
  //                 color:
  //                     isDark
  //                         ? tWhite.withOpacity(0.25)
  //                         : tBlack.withOpacity(0.15),
  //               ),
  //             ],
  //           ),
  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.center,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     "Cell Temperatures",
  //                     style: GoogleFonts.urbanist(
  //                       fontSize: 13,
  //                       fontWeight: FontWeight.bold,
  //                       color: isDark ? tWhite : tBlack,
  //                     ),
  //                   ),
  //                   _buildLegendItem(tOrange1, "RPM", isDark),
  //                 ],
  //               ),

  //               const SizedBox(height: 10),
  //               MultiSensorTemperatureChart(
  //                 tempValues: temperatureListOf10Sensors, // List<List<double>>
  //                 timeLabels: timeStampsList, // List<String>
  //                 isDark: false,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ],
  //   );
  // }

  Widget _buildCanDataTables(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? tWhite.withOpacity(0.3) : tBlack.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CAN Data Tables",
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? tWhite : tBlack,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "This section will show detailed CAN Bus data (RPM, Fuel Level, Engine Temp, etc.)",
            style: GoogleFonts.urbanist(
              fontSize: 11,
              color: isDark ? tWhite.withOpacity(0.8) : tBlack.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    String selectedTab,
    bool isDark,
    VoidCallback onTap,
  ) {
    final bool isSelected = selectedTab == label;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // color: isSelected ? tBlue.withOpacity(0.15) : Colors.transparent,
          gradient:
              isSelected
                  ? SweepGradient(colors: [tGreen8, tGreen8.withOpacity(0.6)])
                  : SweepGradient(colors: [tTransparent, tTransparent]),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color:
                isSelected
                    ? tTransparent
                    : (isDark
                        ? tWhite.withOpacity(0.3)
                        : tBlack.withOpacity(0.3)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color:
                isDark
                    ? (isSelected ? tBlack : tWhite.withOpacity(0.8))
                    : (isSelected ? tBlack : tBlack.withOpacity(0.7)),
          ),
        ),
      ),
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

  Widget buildStatusBars(bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusBar(
          title: "Ignition Status (Last 24 Hours)",
          history: [
            1,
            1,
            0,
            0,
            1,
            1,
            1,
            0,
            0,
            1,
            1,
            1,
            0,
            0,
            0,
            1,
            1,
            1,
            0,
            0,
            1,
            0,
            0,
            1,
          ],
          onColor: tGreen,
          offColor: tRed,
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        _buildStatusBar(
          title: "SOS Status (Last 24 Hours)",
          history: [
            0, 0, 1, 1, 0, 0, 1, 0, 0, 1, // last 10
            1, 0, 0, 0, 1, 0, 0, 1, 1, 0, // 10 older
            1, 0, 0, 1, // oldest 4
          ],
          onColor: tGreen,
          offColor: tRed,
          isDark: isDark,
        ),
        if (mode == 'ICE Fleet') ...[
          const SizedBox(height: 20),
          _buildStatusBar(
            title: "PTO Status (Last 24 Hours)",
            history: [
              1,
              1,
              1,
              0,
              0,
              0,
              1,
              0,
              1,
              1,
              0,
              0,
              1,
              1,
              1,
              0,
              0,
              1,
              0,
              0,
              1,
              1,
              0,
              0,
            ],
            onColor: tGreen,
            offColor: tRed,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildStatusBar(
            title: "4 Wheel Drive (Last 24 Hours)",
            history: [
              0,
              0,
              0,
              0,
              1,
              1,
              1,
              1,
              0,
              0,
              0,
              0,
              1,
              1,
              1,
              0,
              0,
              0,
              1,
              1,
              0,
              0,
              0,
              0,
            ],
            onColor: tGreen,
            offColor: tRed,
            isDark: isDark,
          ),
        ],

        if (mode == 'EV Fleet') ...[
          const SizedBox(height: 20),

          _buildChargingStatusBar(
            title: "Charging Status (Last 24 Hours)",
            history: [
              0,
              0,
              1,
              1,
              0,
              0,
              2,
              0,
              0,
              1,
              2,
              0,
              0,
              0,
              1,
              0,
              2,
              1,
              1,
              0,
              1,
              0,
              2,
              1,
            ],
            chargingColor: tGreen,
            dischargingColor: tBlue, // <-- pick your discharging color
            idleColor: tOrange1, // <-- idle color
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBar({
    required String title,
    required List<int> history,
    required Color onColor,
    required Color offColor,
    required bool isDark,
  }) {
    // Count totals
    final Map<String, double> data = {
      "ON": history.where((v) => v == 1).length.toDouble(),
      "OFF": history.where((v) => v == 0).length.toDouble(),
    };

    final Map<String, Color> borderColors = {"ON": onColor, "OFF": offColor};

    final Map<String, Color> fillColors = {
      "ON": onColor.withOpacity(0.2),
      "OFF": offColor.withOpacity(0.2),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 6),

        _buildAnimatedAlertsBar(data, borderColors, fillColors, isDark),

        const SizedBox(height: 6),

        // Hour labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(24, (i) {
            final now = DateTime.now();
            final hour = now.subtract(Duration(hours: 23 - i));
            return Text(
              "${hour.hour.toString().padLeft(2, '0')}:00",
              style: GoogleFonts.urbanist(
                fontSize: 8,
                color:
                    isDark ? tWhite.withOpacity(0.7) : tBlack.withOpacity(0.7),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildChargingStatusBar({
    required String title,
    required List<int> history, // 0=idle, 1=charging, 2=discharging
    required Color chargingColor,
    required Color dischargingColor,
    required Color idleColor,
    required bool isDark,
  }) {
    // Count totals
    final Map<String, double> data = {
      "CHARGING": history.where((v) => v == 1).length.toDouble(),
      "DISCHARGING": history.where((v) => v == 2).length.toDouble(),
      "IDLE": history.where((v) => v == 0).length.toDouble(),
    };

    final Map<String, Color> borderColors = {
      "CHARGING": chargingColor,
      "DISCHARGING": dischargingColor,
      "IDLE": idleColor,
    };

    final Map<String, Color> fillColors = {
      "CHARGING": chargingColor.withOpacity(0.20),
      "DISCHARGING": dischargingColor.withOpacity(0.20),
      "IDLE": idleColor.withOpacity(0.20),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),

        const SizedBox(height: 6),

        _buildAnimatedAlertsBar(data, borderColors, fillColors, isDark),

        const SizedBox(height: 6),

        // Hour labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(24, (i) {
            final now = DateTime.now();
            final hour = now.subtract(Duration(hours: 23 - i));
            return Text(
              "${hour.hour.toString().padLeft(2, '0')}:00",
              style: GoogleFonts.urbanist(
                fontSize: 8,
                color:
                    isDark ? tWhite.withOpacity(0.7) : tBlack.withOpacity(0.7),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAnimatedAlertsBar(
    Map<String, double> data,
    Map<String, Color> borderColors,
    Map<String, Color> fillColors,
    bool isDark,
  ) {
    double total = data.values.fold(0, (a, b) => a + b);

    return Container(
      width: double.infinity,
      height: 40,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            data.entries.map((entry) {
              double percentage = total == 0 ? 0 : entry.value / total;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: percentage),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Expanded(
                    flex: (value * 1000).toInt().clamp(1, 1000),
                    child: Container(
                      decoration: BoxDecoration(
                        color: fillColors[entry.key] ?? tGrey.withOpacity(0.2),
                        border: Border.all(
                          color: borderColors[entry.key] ?? tGrey,
                          width: 1.5,
                        ),
                      ),
                      child: Tooltip(
                        message:
                            "${entry.key}: ${(entry.value).toStringAsFixed(1)} hrs",
                        child: const SizedBox.expand(),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }

  Widget buildCellLegendTable({
    required List<List<double>> cellVoltages,
    required List<Color> colors,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tTransparent,
        border: Border.all(
          width: 0.5,
          color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
        ),
        // borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER ROW
          Row(
            children: [
              SizedBox(
                width: 30,
                child: Text("Cell", style: _legendHeader(isDark)),
              ),
              sizedW(8),
              SizedBox(
                width: 40,
                child: Text("Last", style: _legendHeader(isDark)),
              ),
              SizedBox(
                width: 40,
                child: Text("Max", style: _legendHeader(isDark)),
              ),
              SizedBox(
                width: 40,
                child: Text("Min", style: _legendHeader(isDark)),
              ),
              SizedBox(
                width: 45,
                child: Text("Mean", style: _legendHeader(isDark)),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// TABLE BODY SCROLL
          Expanded(
            child: ListView.builder(
              itemCount: cellVoltages.length,
              itemBuilder: (context, i) {
                final stats = CellStats.compute(cellVoltages[i]);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      /// Cell color + number
                      SizedBox(
                        width: 30,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors[i],
                                // shape: BoxShape.circle,
                              ),
                            ),
                            sizedW(4),
                            Text("${i + 1}", style: _legendText(isDark)),
                          ],
                        ),
                      ),
                      sizedW(8),

                      SizedBox(
                        width: 40,
                        child: Text(
                          "${stats.last}",
                          style: _legendText(isDark),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text("${stats.max}", style: _legendText(isDark)),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text("${stats.min}", style: _legendText(isDark)),
                      ),
                      SizedBox(
                        width: 45,
                        child: Text(
                          "${stats.mean}",
                          style: _legendText(isDark),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Text styles
  TextStyle _legendHeader(bool isDark) => GoogleFonts.urbanist(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: isDark ? Colors.white : Colors.black,
  );

  TextStyle _legendText(bool isDark) => GoogleFonts.urbanist(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: isDark ? Colors.white70 : Colors.black87,
  );

  Widget sizedW(double w) => SizedBox(width: w);
}
