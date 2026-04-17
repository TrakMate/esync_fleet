import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../models/deviceDetailsModel.dart';
import '../../models/deviceOverviewModel.dart';
import '../../models/devicesModel.dart';
import '../../models/imeiAlertsDetailsModel.dart';
import '../../models/imeiDistSpeedSocModel.dart';
import '../../models/imeiGraphModel.dart';
import '../../models/imeiTripMappointsModel.dart';
import '../../models/imeiTripsDetailsModel.dart';
import '../../models/imeiVehicleGraphModel.dart';
import '../../models/tripMAPModel.dart';
import '../../provider/fleetModeProvider.dart';
import '../../services/generalAPIServices.dart/deviceAPIServices/deviceGeneralInfoAPIService.dart';
import '../../services/generalAPIServices.dart/deviceDetailsAPIService.dart';
import '../../services/getAddressService.dart';
import '../../utils/appColors.dart';
import '../../utils/appLogger.dart';
import '../../utils/appResponsive.dart';
import '../components/largeHoverCard.dart';
import '../components/smallHoverCard.dart';
import '../widgets/charts/deviceAlertChart.dart';
import '../widgets/charts/deviceTripChart.dart';
import '../widgets/charts/distanceSpeedchart.dart';
import '../widgets/charts/doughnutChart.dart';
import '../widgets/charts/speedDistanceChart.dart';

class DeviceGeneralInfoScreen extends StatefulWidget {
  final DeviceEntity device;
  final DateTime? selectedDate;

  const DeviceGeneralInfoScreen({
    super.key,
    required this.device,
    required this.selectedDate,
  });

  @override
  State<DeviceGeneralInfoScreen> createState() =>
      _DeviceGeneralInfoScreenState();
}

class _DeviceGeneralInfoScreenState extends State<DeviceGeneralInfoScreen> {
  final ScrollController _tripHorizontalCtrl = ScrollController();
  final ScrollController _tripVerticalCtrl = ScrollController();

  final ScrollController _alertHorizontalCtrl = ScrollController();
  final ScrollController _alertVerticalCtrl = ScrollController();

  late Color statusColor;
  DeviceDetailsModel? deviceDetailsModel;
  final DeviceDetailsApiService _deviceDetailsApiService =
      DeviceDetailsApiService();

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'moving':
        return tGreen;
      case 'idle':
        return tOrange1;
      case 'stopped':
        return tRed;
      case 'disconnected':
        return tGrey;
      case 'discharging':
        return tGreen;
      case 'charging':
        // return Colors.teal;
        return tBlue;
      default:
        return tBlack;
    }
  }

  final Map<String, Color> statusColors = {
    'moving': tGreen.withOpacity(0.9),
    'stopped': tRed.withOpacity(0.9),
    'idle': tOrange1.withOpacity(0.9),
    'halted': tBlue.withOpacity(0.9),
  };

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

  final NumberFormat format = NumberFormat('#,##,###');

  final IMEIAlertsApiService _apiAlertService = IMEIAlertsApiService();
  final IMEITripsApiService _apiTripService = IMEITripsApiService();
  final IMEITripMapPointsApiService _apiTripMapPointsService =
      IMEITripMapPointsApiService();

  final IMEITripMapApiService _apiTripMapService = IMEITripMapApiService();
  final IMEIGraphApiService _imeiGraphApiService = IMEIGraphApiService();
  final IMEIVehicleGraphApiService _imeiVehicleGraphApiService =
      IMEIVehicleGraphApiService();
  final IMEISpeedDistanceApiService _distanceApiService =
      IMEISpeedDistanceApiService();

  final DeviceOverviewApiService _deviceOverviewApiService =
      DeviceOverviewApiService();

  DeviceOverviewModel? deviceOverviewModel;

  IMEIAlertsDetailsModel? alertsModel;
  IMEITripDetailsModel? tripsModel;
  IMEITripMapPointsModel? tripMapPointsModel;
  TripMapPerTripModel? tripMapModel;
  IMEIGraphModel? graphModel;
  IMEIDistSpeedSocModel? distSpeedSocModel;

  bool isLoading = false;
  bool isError = false;
  String? errorMessage;
  int? touchedIndex;
  double? touchedY;
  List<Map<String, dynamic>> chartData = [];
  List<WeeklyAlertsGraph> weeklyalert = [];
  List<MonthlyAlertsGraph> monthlyalert = [];

  List<WeeklyTripsGraph> weeklytrip = [];
  List<MonthlyTripsGraph> monthlytrip = [];

  IMEIVehicleGraphModel? imeivehicleModel;
  List<VehicleGraph> vehicleGraphList = [];

  int currentPage = 1;
  int rowsPerPage = 10;
  int totalPages = 1;
  int? selectedIndex;
  LatLng? selectedPoint;

  Future<void> fetchAlerts() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _apiAlertService.fetchAlerts(
        imei: widget.device.imei!,
        date: selectedDate,
        currentIndex: (currentPage - 1) * rowsPerPage,
        sizePerPage: rowsPerPage,
      );

      if (!mounted) return;

      setState(() {
        alertsModel = result;
        totalPages = ((result.totalAlerts ?? 0) / rowsPerPage).ceil();
      });
    } catch (e) {
      debugPrint("Alerts API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchTrips() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _apiTripService.fetchTrips(
        imei: widget.device.imei!, // IMEI-based
        date: selectedDate,
        currentIndex: (currentPage - 1) * rowsPerPage,
        sizePerPage: rowsPerPage,
      );

      if (!mounted) return;

      setState(() {
        tripsModel = result;
        totalPages = ((result.summary?.totalTrips ?? 0) / rowsPerPage).ceil();
      });
    } catch (e) {
      debugPrint("Trips API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchTripMapPoints() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final resultIMEIMapPoints = await _apiTripMapPointsService
          .fetchTripMapPoints(imei: widget.device.imei!);

      if (!mounted) return;

      setState(() {
        tripMapPointsModel = resultIMEIMapPoints;
      });
    } catch (e) {
      debugPrint("Trip Map Points API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchTripMap() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final resultIMEITripMap = await _apiTripMapService.fetchTripMap(
        imei: widget.device.imei!,
        date: selectedDate,
      );

      if (!mounted) return;

      setState(() {
        tripMapModel = resultIMEITripMap;
      });
    } catch (e) {
      debugPrint("Trip Map API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchImeiGraph() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _imeiGraphApiService.fetchimeiGraph(
        imei: widget.device.imei!,
        // date: DateTime.now(),
        date: selectedDate,
      );

      if (!mounted) return;

      setState(() {
        graphModel = result;

        weeklyalert = result.weeklyAlertsGraph ?? [];
        monthlyalert = result.monthlyAlertsGraph ?? [];
        weeklytrip = result.weeklyTripsGraph ?? [];
        monthlytrip = result.monthlyTripsGraph ?? [];
      });
    } catch (e) {
      debugPrint("IMEI Graph API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchImeiDistSpeedSoc() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _distanceApiService.fetchSpeedDistanceSoc(
        imei: widget.device.imei!,
        date: selectedDate,
      );

      if (!mounted) return;

      setState(() {
        distSpeedSocModel = result;
      });
    } catch (e) {
      debugPrint("IMEI Dist-Speed-SOC API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchImeiVehicleGraph() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _imeiVehicleGraphApiService.fetchVehicleGraph(
        imei: widget.device.imei!,
        // date: DateTime.now()
        date: selectedDate,
      );

      if (!mounted) return;

      setState(() {
        imeivehicleModel = result;
        vehicleGraphList = result.vehicleGraph ?? [];

        debugPrint("Graph list length: ${vehicleGraphList.length}");
      });
    } catch (e) {
      debugPrint("IMEI Graph API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchDeviceOverview() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _deviceOverviewApiService.fetchDeviceOverview(
        imei: widget.device.imei!,
        date: selectedDate,
      );

      if (!mounted) return;

      setState(() {
        deviceOverviewModel = result;
      });
    } catch (e) {
      debugPrint("Device Overview API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

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
  void didUpdateWidget(covariant DeviceGeneralInfoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedDate != widget.selectedDate) {
      selectedDate = widget.selectedDate;
      fetchImeiVehicleGraph();
      fetchAlerts();
      fetchTrips();
      fetchImeiGraph();
      fetchTripMap();
      fetchDeviceOverview();
      fetchImeiDistSpeedSoc();
    }
  }

  DateTime? selectedDate;
  Timer? _overviewTimer;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    final status = widget.device.status ?? '';
    LoggerUtil.getInstance.print(status);

    statusColor = getStatusColor(status);
    fetchAlerts();
    fetchTrips();
    fetchTripMapPoints();
    fetchTripMap();

    fetchImeiGraph();
    fetchImeiDistSpeedSoc();
    fetchImeiVehicleGraph();
    fetchDeviceOverview();
    fetchDeviceDetails();
    _overviewTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchDeviceOverview();
      fetchImeiDistSpeedSoc();
    });
  }

  @override
  void dispose() {
    _tripHorizontalCtrl.dispose();
    _tripVerticalCtrl.dispose();
    _alertHorizontalCtrl.dispose();
    _alertVerticalCtrl.dispose();
    _overviewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const Center(child: Text("Mobile / Tablet layout coming soon")),
      tablet: const Center(child: Text("Mobile / Tablet layout coming soon")),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final mode = context.watch<FleetModeProvider>().mode;

    final device = widget.device;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = tripsModel?.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          // child: buildDeviceCard(
          //   isDark: isDark,
          //   imei: device.imei ?? '12265679827872127',
          //   vehicleNumber: device.vehicleNumber ?? 'VGFDG4251271677',
          //   status: device.status ?? '',
          //   fuel: device.soc ?? '',
          //   odo: device.odometer ?? '',
          //   trips: (device.totalTrips ?? '').toString(),
          //   alerts: (device.totalAlerts ?? '').toString(),
          //   location: device.location ?? '',
          // ),
          // child: FutureBuilder<String>(
          //   future: getAddressFromLocationStringWeb(device.location ?? ''),
          //   builder: (context, snapshot) {
          //     final address =
          //         snapshot.connectionState == ConnectionState.done &&
          //                 snapshot.hasData
          //             ? snapshot.data!
          //             : 'Fetching location...';

          //     return buildDeviceCard(
          //       isDark: isDark,
          //       imei: device.imei ?? '',
          //       vehicleNumber: device.vehicleNumber ?? '',
          //       status: device.status ?? '',
          //       fuel:
          //           mode == 'EV Fleet'
          //               ? device.soc ?? ''
          //               : (device.tafe?.fuellevel?.toString() ?? ''),
          //       odo: device.odometer ?? '',
          //       trips: (device.totalTrips ?? 0).toString(),
          //       alerts: (device.totalAlerts ?? 0).toString(),
          //       location: address,
          //       lastUpdated: device.locationLogDate ?? '',
          //     );
          //   },
          // ),
          child: FutureBuilder<String>(
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
              );
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              // padding: const EdgeInsets.all(10),
              padding: EdgeInsets.only(left: 10, right: 10, top: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Left panel
                      Expanded(
                        flex: 5,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🔹 Left section (Title + Doughnut Charts)
                            Expanded(
                              flex: 4,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    mode == 'EV Fleet'
                                        ? SingleDoughnutChart(
                                          currentValue: toDouble(
                                            deviceOverviewModel?.voltage,
                                          ),
                                          avgValue:
                                              toDouble(
                                                deviceOverviewModel?.voltage,
                                              ) *
                                              0.65,
                                          title: "Voltage",
                                          unit: "V",
                                          primaryColor: tBlue,
                                          isDark: isDark,
                                        )
                                        : SingleDoughnutChart(
                                          currentValue: toDouble(
                                            deviceOverviewModel?.vehvoltage,
                                          ),
                                          avgValue:
                                              toDouble(
                                                deviceOverviewModel?.vehvoltage,
                                              ) *
                                              0.65,
                                          title: "Voltage",
                                          unit: "V",
                                          primaryColor: tBlue,
                                          isDark: isDark,
                                        ),
                                    SingleDoughnutChart(
                                      currentValue: toDouble(
                                        deviceOverviewModel?.speed,
                                      ),
                                      avgValue:
                                          toDouble(deviceOverviewModel?.speed) *
                                          0.65,
                                      title: "Speed",
                                      unit: "km/h",
                                      primaryColor: tGreen,
                                      isDark: isDark,
                                    ),

                                    mode == 'EV Fleet'
                                        ? SingleDoughnutChart(
                                          currentValue: toDouble(
                                            deviceOverviewModel?.soc,
                                          ),
                                          avgValue:
                                              toDouble(
                                                deviceOverviewModel?.soc,
                                              ) *
                                              0.65,
                                          title: "SOC",
                                          unit: "%",
                                          primaryColor: tBlueSky,
                                          isDark: isDark,
                                        )
                                        : SingleDoughnutChart(
                                          currentValue: toDouble(
                                            device.tafe?.fuellevel,
                                          ),
                                          avgValue:
                                              toDouble(device.tafe?.fuellevel) *
                                              0.65,
                                          title: "Fuel",
                                          unit: "%",
                                          primaryColor: tBlueSky,
                                          isDark: isDark,
                                        ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildInfoCard(
                                    isDark,
                                    "Odometer (km)",
                                    format.format(
                                      toDouble(deviceOverviewModel?.odometer) ??
                                          0,
                                    ),
                                    tBlueGradient2,
                                  ),
                                  const SizedBox(height: 10),

                                  _buildInfoCard(
                                    isDark,
                                    "Operation Hours (hrs)",
                                    "${summary?.totalOperationalDuration ?? 0}",
                                    tRedGradient2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Right panel (placeholder for map, chart, etc.)
                      Expanded(flex: 5, child: _buildDeviceStatus(isDark)),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 600,
                          decoration: BoxDecoration(
                            color: tTransparent,
                            // color: isDark ? tBlack : tWhite,
                            // boxShadow: [
                            //   BoxShadow(
                            //     spreadRadius: 2,
                            //     blurRadius: 10,
                            //     color:
                            //         isDark
                            //             ? tWhite.withOpacity(0.25)
                            //             : tBlack.withOpacity(0.15),
                            //   ),
                            // ],
                          ),
                          // padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alerts Overview',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                              SizedBox(height: 10),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// LEFT → FAULTS (LARGE CARD)
                                  Expanded(
                                    flex: 1,
                                    child: GestureDetector(
                                      onTap: () {
                                        context.go(
                                          '/home/faults?imei=${widget.device.imei}',
                                        );
                                      },
                                      child: LargeHoverCard(
                                        value: NumberFormat(
                                          '#,##,###',
                                        ).format(0),
                                        label: "Faults",
                                        labelColor: tRed,
                                        icon: "icons/faults.svg",
                                        iconColor: tRed,
                                        bgColor: tRed.withOpacity(0.1),
                                        isDark: isDark,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  /// RIGHT → ALERTS + (CRITICAL & NON-CRITICAL)
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        /// TOP → ALERTS
                                        GestureDetector(
                                          onTap: () {
                                            context.go(
                                              '/home/alerts?imei=${widget.device.imei}',
                                            );
                                          },
                                          child: SmallHoverCard(
                                            width: double.infinity,
                                            height: 85,
                                            value: NumberFormat(
                                              '#,##,###',
                                            ).format(
                                              alertsModel?.totalAlerts ?? 0,
                                            ),
                                            label: "Alerts",
                                            labelColor: tRed,
                                            icon: "icons/alert.svg",
                                            iconColor: tRed,
                                            bgColor: tRed.withOpacity(0.1),
                                            isDark: isDark,
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        /// BOTTOM → CRITICAL + NON-CRITICAL
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SmallHoverCard(
                                                height: 85,
                                                value: NumberFormat(
                                                  '#,##,###',
                                                ).format(
                                                  alertsModel?.criticalAlerts ??
                                                      0,
                                                ),
                                                label: "Critical",
                                                labelColor: tOrange1,
                                                icon: "icons/alert.svg",
                                                iconColor: tOrange1,
                                                bgColor: tOrange1.withOpacity(
                                                  0.1,
                                                ),
                                                isDark: isDark,
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            Expanded(
                                              child: SmallHoverCard(
                                                height: 85,
                                                value: NumberFormat(
                                                  '#,##,###',
                                                ).format(
                                                  alertsModel
                                                          ?.nonCriticalAlerts ??
                                                      0,
                                                ),
                                                label: "Non-Critical",
                                                labelColor: tBlueSky,
                                                icon: "icons/alert.svg",
                                                iconColor: tBlueSky,
                                                bgColor: tBlueSky.withOpacity(
                                                  0.1,
                                                ),
                                                isDark: isDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 10),
                              Text(
                                'Recent Alerts',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                              SizedBox(height: 10),
                              Expanded(
                                child: Container(
                                  height: 250,
                                  decoration: BoxDecoration(
                                    color: tTransparent,
                                  ),
                                  child: buildAlertsTable(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 600,
                          decoration: BoxDecoration(color: tTransparent),
                          // padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trips Overview',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      context.go(
                                        '/home/trips?inputImei=${widget.device.imei}',
                                      );
                                    },
                                    child: LargeHoverCard(
                                      value: NumberFormat(
                                        '#,##,###',
                                      ).format(summary?.totalTrips ?? 0),
                                      label: "Trips",
                                      labelColor: tGreen,
                                      icon: "icons/distance.svg",
                                      iconColor: tGreen,
                                      bgColor: tGreen.withOpacity(0.1),
                                      isDark: isDark,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        SmallHoverCard(
                                          width: double.infinity,
                                          height: 85,
                                          value: NumberFormat(
                                            '#,##,###',
                                          ).format(
                                            summary?.completedTrips ?? 0,
                                          ),
                                          label: "Completed Trips",
                                          labelColor: tBlue,
                                          icon: "icons/completed.svg",
                                          iconColor: tBlue,
                                          bgColor: tBlue.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 10),
                                        SmallHoverCard(
                                          width: double.infinity,
                                          height: 85,
                                          value:
                                              "${summary?.avgTripsPerDay ?? 0}",
                                          label: "Avg. Trips",
                                          labelColor: tOrange1,
                                          icon: "icons/distance.svg",
                                          iconColor: tOrange1,
                                          bgColor: tOrange1.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        SmallHoverCard(
                                          width: double.infinity,
                                          height: 85,
                                          value:
                                              "${summary?.avgDistancePerImeiKm ?? 0}",
                                          label: "Avg.Dist. Travelled(km)",
                                          labelColor: tBlueSky,
                                          icon: "icons/distance.svg",
                                          iconColor: tBlueSky,
                                          bgColor: tBlueSky.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 10),
                                        SmallHoverCard(
                                          width: double.infinity,
                                          height: 85,
                                          value:
                                              "${summary?.avgOperationalHoursPerImei ?? 0}",
                                          label: "Avg.Oper. Hours(hrs)",
                                          labelColor: tRed,
                                          icon: "icons/consumedhours.svg",
                                          iconColor: tRed,
                                          bgColor: tRed.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Recent Trips',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                              SizedBox(height: 10),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: tTransparent,
                                  ),
                                  child: _buildTripsTable(
                                    isDark,
                                  ), // <-- NO SingleChildScrollView here
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 600,
                          // decoration: BoxDecoration(
                          //   color: isDark ? tBlack : tWhite,
                          //   boxShadow: [
                          //     BoxShadow(
                          //       spreadRadius: 2,
                          //       blurRadius: 10,
                          //       color:
                          //           isDark
                          //               ? tWhite.withOpacity(0.25)
                          //               : tBlack.withOpacity(0.15),
                          //     ),
                          //   ],
                          // ),
                          decoration: BoxDecoration(color: tTransparent),

                          // padding: const EdgeInsets.all(2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trip Map',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                              SizedBox(height: 10),
                              Expanded(
                                child: buildVehicleMap(
                                  isDark: isDark,
                                  zoom: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 330,
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
                          padding: const EdgeInsets.all(15),
                          child: DeviceTripsChart(
                            weeklyData: weeklytrip,
                            monthlyData: monthlytrip,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 330,
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
                          padding: EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vehicle Status',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  color: isDark ? tWhite : tBlack,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildStatusBarChart(isDark),
                              const SizedBox(height: 10),
                              // Legend
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _LegendItem(
                                    color: tGreen.withOpacity(0.9),
                                    label: "Moving",
                                  ),
                                  SizedBox(width: 6),
                                  _LegendItem(
                                    color: tOrange1.withOpacity(0.9),
                                    label: "Idle",
                                  ),
                                  SizedBox(width: 6),
                                  _LegendItem(
                                    color: tRed.withOpacity(0.9),
                                    label: "Stopped",
                                  ),
                                  SizedBox(width: 6),
                                  _LegendItem(
                                    color: tBlue.withOpacity(0.9),
                                    label: "Halted",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 330,
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
                          padding: const EdgeInsets.all(15),
                          child: DeviceAlertsChart(
                            alertsGraph: weeklyalert,
                            alertGraphforMonth: monthlyalert,
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
      ],
    );
  }

  Widget _buildInfoCard(
    bool isDark,
    String title,
    String value,
    Gradient cardColor,
  ) {
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
            padding: const EdgeInsets.symmetric(vertical: 6),
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
            height: 78,
            width: double.infinity,
            decoration: BoxDecoration(gradient: cardColor),
            alignment: Alignment.center,
            child: Text(
              value,
              style: GoogleFonts.urbanist(
                fontSize: 33,
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

    return Container(
      width: double.infinity,
      height: 90,
      decoration: BoxDecoration(
        // color: tGrey.withOpacity(0.1),
        color: isDark ? tBlack : tWhite,
        // borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 10,
            color: isDark ? tWhite.withOpacity(0.25) : tBlack.withOpacity(0.15),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SvgPicture.asset('icons/truck1.svg', width: 80, height: 80),
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
                          Flexible(
                            child: Container(
                              width: 350,
                              // constraints: const BoxConstraints(
                              //   minWidth: 200,
                              //   maxWidth: 400,
                              // ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: statusColor,
                                  width: 1,
                                ),
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
                    // Row(
                    //   children: [
                    //     Text(
                    //       'LastSync :',
                    //       style: GoogleFonts.urbanist(
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.w400,
                    //         color: isDark ? tWhite : tBlack,
                    //       ),
                    //     ),
                    //     const SizedBox(width: 5),
                    //     Text(
                    //       lastUpdated,
                    //       style: GoogleFonts.urbanist(
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.w600,
                    //         color: isDark ? tWhite : tBlack,
                    //       ),
                    //     ),
                    //   ],
                    // ),
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

  // Widget _buildDeviceStatus(bool isDark) {
  //   return Container(
  //     height: 225,
  //     decoration: BoxDecoration(
  //       color: isDark ? tBlack : tWhite,
  //       boxShadow: [
  //         BoxShadow(
  //           spreadRadius: 2,
  //           blurRadius: 10,
  //           color: isDark ? tWhite.withOpacity(0.25) : tBlack.withOpacity(0.15),
  //         ),
  //       ],
  //     ),
  //     padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
  //     child: SpeedDistanceChart(),
  //   );
  // }

  Widget _buildDeviceStatus(bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;
    final data = distSpeedSocModel?.data ?? [];

    return Container(
      height: 225,
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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child:
          mode == 'EV Fleet'
              ? (data.isEmpty
                  ? const Center(child: Text("No speed / distance data"))
                  : SpeedDistanceChart(
                    key: ValueKey(selectedDate.toString()),
                    SpeedDistanceSocData: data,
                  ))
              : (data.isEmpty
                  ? const Center(child: Text("No speed / distance data"))
                  : Distancespeedchart(
                    key: ValueKey(selectedDate.toString()),
                    SpeedDistanceSocData: data,
                  )),
    );
  }

  Widget _buildStatusBarChart(bool isDark) {
    final Map<String, Color> statusColors = this.statusColors;

    final Map<String, Map<String, double>> hourlyStatusBreakdown = {
      for (final e in vehicleGraphList)
        e.time ?? '': {
          'moving': e.moving ?? 0,
          'idle': e.idle ?? 0,
          'halted': e.halted ?? 0,
          'stopped': e.stopped ?? 0,
        },
    };
    if (hourlyStatusBreakdown.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No vehicle status data")),
      );
    }
    final labels = hourlyStatusBreakdown.keys.toList();

    final label = labels[0];
    final parts = label.split(" - ");
    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceBetween,
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              parts.first,
                              style: GoogleFonts.urbanist(
                                fontSize: 8,
                                color: isDark ? tWhite : tBlack,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              parts.length > 1 ? parts.last : '',
                              style: GoogleFonts.urbanist(
                                fontSize: 8,
                                color: isDark ? tWhite : tBlack,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.spot == null) {
                    setState(() {
                      touchedIndex = null;
                      touchedY = null;
                    });
                    return;
                  }

                  setState(() {
                    touchedIndex = response.spot!.touchedBarGroupIndex;
                    touchedY = response.spot!.touchedRodData.toY;
                  });
                },
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(10),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (group) => isDark ? tWhite : tBlack,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = labels[group.x.toInt()];
                    final data = hourlyStatusBreakdown[label]!;

                    final entries =
                        data.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));

                    final spans = <TextSpan>[
                      TextSpan(
                        text: '$label\n',
                        style: GoogleFonts.urbanist(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? tBlack : tWhite,
                        ),
                      ),
                    ];

                    for (final e in entries) {
                      spans.add(
                        TextSpan(
                          text: "● ",
                          style: TextStyle(
                            color: statusColors[e.key] ?? Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      );
                      spans.add(
                        TextSpan(
                          text: "${e.key.capitalize()}: ${e.value} min\n",
                          style: GoogleFonts.urbanist(
                            fontSize: 10,
                            color: isDark ? tBlack : tWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    return BarTooltipItem(
                      '',
                      const TextStyle(),
                      children: spans,
                      textAlign: TextAlign.start,
                    );
                  },
                ),
              ),

              // barGroups: List.generate(labels.length, (index) {
              //   final label = labels[index];
              //   final data = hourlyStatusBreakdown[label]!;

              //   final totalMins = data.values.fold<double>(
              //     0,
              //     (sum, v) => sum + v,
              //   );

              //   if (totalMins == 0) {
              //     return BarChartGroupData(
              //       x: index,
              //       barRods: [BarChartRodData(toY: 0, width: 15)],
              //     );
              //   }

              //   double startY = 0.0;

              //   final rods =
              //       data.entries.map((e) {
              //         final color = statusColors[e.key]!.withOpacity(0.9);
              //         final endY = startY + (e.value / totalMins) * 60;
              //         final item = BarChartRodStackItem(startY, endY, color);
              //         startY = endY;
              //         return item;
              //       }).toList();

              //   return BarChartGroupData(
              //     x: index,
              //     barRods: [
              //       BarChartRodData(
              //         toY: 60,
              //         rodStackItems: rods,
              //         width: 15,
              //         borderRadius: BorderRadius.circular(0),
              //       ),
              //     ],
              //   );
              // }
              barGroups: List.generate(labels.length, (index) {
                final label = labels[index];
                final data = hourlyStatusBreakdown[label]!;

                return BarChartGroupData(
                  x: index,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: data['moving'] ?? 0,
                      color: statusColors['moving'],
                      width: 6,
                      borderRadius: BorderRadius.circular(0),
                    ),
                    BarChartRodData(
                      toY: data['idle'] ?? 0,
                      color: statusColors['idle'],
                      width: 6,
                      borderRadius: BorderRadius.circular(0),
                    ),
                    BarChartRodData(
                      toY: data['halted'] ?? 0,
                      color: statusColors['halted'],
                      width: 6,
                      borderRadius: BorderRadius.circular(0),
                    ),
                    BarChartRodData(
                      toY: data['stopped'] ?? 0,
                      color: statusColors['stopped'],
                      width: 6,
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ],
                );
              }),
            ),
          ),
          if (touchedIndex != null && touchedY != null)
            IgnorePointer(
              ignoring: true,
              child: CustomPaint(
                size: Size.infinite,
                painter: CrosshairPainter(
                  xIndex: touchedIndex!,
                  yValue: touchedY!,
                  chartDataLength: labels.length,
                  maxY: 60,
                  isDark: isDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime).toLocal();

    return DateFormat("d MMM ,hh mm a").format(dateTime);
  }

  Widget buildVehicleMap({bool isDark = false, double zoom = 14.0}) {
    final tripPoints = tripMapModel?.data;

    if (tripPoints == null || tripPoints.isEmpty) {
      return const Center(child: Text("No trip data available"));
    }
    final selectedData =
        (selectedIndex != null && selectedIndex! < tripPoints.length)
            ? tripPoints[selectedIndex!]
            : null;

    // Convert Data → LatLng (safe parsing)
    final List<LatLng> polylinePoints =
        tripPoints
            .where((p) => p.lat != null && p.lng != null)
            .map((p) {
              final lat = double.tryParse(p.lat!);
              final lng = double.tryParse(p.lng!);
              if (lat == null || lng == null) return null;
              return LatLng(lat, lng);
            })
            .whereType<LatLng>()
            .toList();

    if (polylinePoints.isEmpty) {
      return const Center(child: Text("No valid coordinates"));
    }

    final LatLng startPoint = polylinePoints.first;
    final LatLng endPoint = polylinePoints.last;

    final List<LatLng> middlePoints =
        polylinePoints.length > 2
            ? polylinePoints.sublist(1, polylinePoints.length - 1)
            : [];

    final tileUrl =
        isDark
            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return SizedBox(
      height: 300,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: startPoint,
          initialZoom: zoom,
          maxZoom: 18,
          minZoom: 3,
          onTap: (tapPosition, latLng) {
            _onMapTap(latLng, polylinePoints);
          },
        ),
        children: [
          // MAP TILES
          TileLayer(
            urlTemplate: tileUrl,
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),

          // TRIP POLYLINE
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                strokeWidth: 4,
                color: tBlue.withOpacity(0.6),
              ),
            ],
          ),

          // MIDDLE POINT DOTS
          CircleLayer(
            circles:
                middlePoints
                    .map(
                      (point) => CircleMarker(
                        point: point,
                        radius: 4,
                        color: Colors.pinkAccent,
                        borderStrokeWidth: 0,
                      ),
                    )
                    .toList(),
          ),

          // START & END MARKERS
          MarkerLayer(
            markers: [
              // START
              Marker(
                point: startPoint,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tWhite,
                    boxShadow: [
                      BoxShadow(
                        color: tGreen.withOpacity(0.7),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: tGreen, width: 2),
                  ),
                  child: const Icon(Icons.circle, size: 10, color: tGreen),
                ),
              ),

              // END
              Marker(
                point: endPoint,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tWhite,
                    boxShadow: [
                      BoxShadow(
                        color: tRedDark.withOpacity(0.7),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: tRedDark, width: 2),
                  ),
                  child: const Icon(Icons.circle, size: 10, color: tRedDark),
                ),
              ),
              if (selectedPoint != null && selectedData != null)
                Marker(
                  point: selectedPoint!,
                  width: 140,
                  height: 120,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? tWhite : tBlack,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Time: ${selectedData.time != null ? formatTime(selectedData.time!) : '-'}",
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? tBlack : tWhite,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "Speed: ${selectedData.speed ?? '-'}",
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? tBlack : tWhite,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "Odo: ${selectedData.odo ?? '-'}",
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? tBlack : tWhite,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _onMapTap(LatLng tappedPoint, List<LatLng> points) {
    double minDistance = double.infinity;
    LatLng? nearest;
    int? index;

    for (int i = 0; i < points.length; i++) {
      final distance = Distance().as(LengthUnit.Meter, tappedPoint, points[i]);

      if (distance < minDistance) {
        minDistance = distance;
        nearest = points[i];
        index = i;
      }
    }

    if (minDistance < 80) {
      setState(() {
        selectedPoint = nearest;
        selectedIndex = index; // ✅ store index
      });
    } else {
      setState(() {
        selectedPoint = null;
        selectedIndex = null;
      });
    }
  }

  Widget _buildTripsTable(bool isDark) {
    final trips = tripsModel?.trips?.entities ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        Color getStatusColor(String status) {
          return status == "Completed" ? tBlue : tGreen;
        }

        String formatDate(String? iso) {
          if (iso == null || iso.isEmpty) return "-";
          final dt = DateTime.parse(iso);
          return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
        }

        String resolveTripStatus(int? status) {
          // adjust based on backend enum
          if (status == 0) return "Ongoing";
          if (status == 1) return "Completed";
          return "Unknown";
        }

        return Container(
          width: maxWidth,
          height: maxHeight,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ],
          ),
          child: Column(
            children: [
              // Scrollable Area
              Expanded(
                child: Scrollbar(
                  controller: _tripHorizontalCtrl,
                  thumbVisibility: true,
                  radius: const Radius.circular(6),
                  thickness: 4,
                  child: SingleChildScrollView(
                    controller: _tripHorizontalCtrl,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: maxWidth),
                      child: Scrollbar(
                        controller: _tripVerticalCtrl,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _tripVerticalCtrl,
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              isDark
                                  ? tGreen8.withOpacity(0.15)
                                  : tGreen8.withOpacity(0.1),
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
                              DataColumn(label: Text("Start Date")),
                              DataColumn(label: Text("End Date")),
                              DataColumn(label: Text("Duration")),
                              DataColumn(label: Text("Distance")),
                              DataColumn(label: Text("Trip Status")),
                            ],
                            rows:
                                trips.map((trip) {
                                  final status = resolveTripStatus(
                                    trip.tripStatus,
                                  );
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(formatDate(trip.tripStartTime)),
                                      ),
                                      DataCell(
                                        Text(formatDate(trip.tripEndTime)),
                                      ),
                                      DataCell(Text("${trip.totalTime} mins")),
                                      DataCell(
                                        Text(
                                          "${trip.totalDistance?.toStringAsFixed(2)} kms",
                                        ),
                                      ),

                                      // Status badge
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: getStatusColor(
                                              status,
                                            ).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: GoogleFonts.urbanist(
                                              color: getStatusColor(status),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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

              // No pagination required unless you need it later
            ],
          ),
        );
      },
    );
  }

  Widget buildAlertsTable(bool isDark) {
    final alerts = alertsModel?.alerts ?? [];
    Color getAlertColor(String type) {
      if (type.contains('Disconnect') || type.contains('Lost')) return tRed;
      if (type.contains('Low') || type.contains('Fall')) return tOrange1;
      if (type.contains('Speed')) return Colors.amber;
      if (type.contains('Ignition')) return tBlue;
      if (type.contains('Geo') || type.contains('Tilt')) return Colors.purple;
      if (type.contains('SOS')) return Colors.redAccent;
      return tGrey;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        return Container(
          width: maxWidth,
          height: maxHeight,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  controller: _alertHorizontalCtrl,
                  thumbVisibility: true,
                  radius: const Radius.circular(6),
                  thickness: 4,
                  child: SingleChildScrollView(
                    controller: _alertHorizontalCtrl,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: maxWidth),
                      child: Scrollbar(
                        controller: _alertVerticalCtrl,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _alertVerticalCtrl,
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              isDark
                                  ? tGreen8.withOpacity(0.15)
                                  : tGreen8.withOpacity(0.1),
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
                            columnSpacing: 40,
                            border: TableBorder.all(
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.1)
                                      : tBlack.withOpacity(0.1),
                              width: 0.4,
                            ),
                            dividerThickness: 0.01,

                            /// TWO COLUMNS ONLY
                            columns: const [
                              DataColumn(label: Text("Date & Time")),
                              DataColumn(label: Text("Alert")),
                            ],

                            rows:
                                alerts.map((alert) {
                                  final color = getAlertColor(alert.alertType!);
                                  String formatDate(String? iso) {
                                    if (iso == null || iso.isEmpty) return "-";
                                    final dt = DateTime.parse(iso);
                                    return DateFormat(
                                      'dd MMM yyyy, hh:mm a',
                                    ).format(dt);
                                  }

                                  return DataRow(
                                    cells: [
                                      // Date/Time
                                      DataCell(Text(formatDate(alert.time))),

                                      // Alert Badge
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            alert.alertType ?? '--',
                                            style: GoogleFonts.urbanist(
                                              color: color,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
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
            ],
          ),
        );
      },
    );
  }
}

extension StringCasing on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

// Legend item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
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
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? tWhite
                    : tBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class CrosshairPainter extends CustomPainter {
  final int xIndex;
  final double yValue;
  final int chartDataLength;
  final double maxY;
  final bool isDark;

  CrosshairPainter({
    required this.xIndex,
    required this.yValue,
    required this.chartDataLength,
    required this.maxY,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isDark ? tWhite : tBlack
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;

    const double bottomTitleHeight = 45;
    const double topPadding = 10;
    final spacing = size.width / chartDataLength;
    final xPos = spacing * xIndex + spacing / 2;
    final usableHeight = size.height - bottomTitleHeight - topPadding;

    final yPos =
        topPadding + usableHeight * (1 - (yValue / maxY).clamp(0.0, 1.0));

    _drawDashedLine(
      canvas,
      Offset(xPos, topPadding),
      Offset(xPos, size.height - bottomTitleHeight),
      paint,
      dashWidth,
      dashSpace,
    );

    _drawDashedLine(
      canvas,
      Offset(0, yPos),
      Offset(size.width, yPos),
      paint,
      dashWidth,
      dashSpace,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final ui.Path path = ui.Path();

    final distance = (end - start).distance;
    final angle = (end - start).direction;

    double drawn = 0;
    while (drawn < distance) {
      final x1 = start.dx + cos(angle) * drawn;
      final y1 = start.dy + sin(angle) * drawn;

      drawn += dashWidth;

      final x2 = start.dx + cos(angle) * min(drawn, distance);
      final y2 = start.dy + sin(angle) * min(drawn, distance);

      path.moveTo(x1, y1);
      path.lineTo(x2, y2);

      drawn += dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
