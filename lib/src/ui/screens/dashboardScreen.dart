import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:svg_flutter/svg_flutter.dart';

// import '../../models/dashboardDetailsModel.dart';
import '../../models/alertCountModel.dart';
import '../../models/groupsModel.dart';
// import '../../models/alertGraphModel.dart';
// import '../../models/tripGraphModel.dart';
// import '../../models/vehicleDashboardModel.dart';
import '../../models/alertGraphModel.dart' as alertModel;
import '../../models/tripGraphModel.dart' as tripModel;
import '../../models/vehicleDashboardModel.dart' as vehicleModel;

import '../../provider/fleetModeProvider.dart';
import '../../services/generalAPIServices.dart/alertCountAPIService.dart';
import '../../services/generalAPIServices.dart/dashboardAPIService.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../components/customTitleBar.dart';
import '../components/largeHoverCard.dart';
import '../components/smallHoverCard.dart';
import '../widgets/charts/alertDoughnutChart.dart';
import '../widgets/charts/alertsChart.dart';
import '../widgets/charts/evBatteriesDistributionProgressBar.dart';
import '../widgets/charts/tripsChart.dart';
import '../widgets/charts/vehicleStatusProgressBar.dart';
import '../widgets/charts/vehicleUtilizationChart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  String? get dateParam => apiDate;
  DateTime selectedDate = DateTime.now();
  String? apiDate;

  String? selectedGroup;
  // String get dateParam => selectedDate.toUtc().toIso8601String();
  final DashboardApiService _dashboardApi = DashboardApiService();

  bool isLoadingGroups = false;
  bool isHovered = false;

  OverlayEntry? _groupOverlayEntry;
  final LayerLink _groupLayerLink = LayerLink();

  void _hideGroupDropdown() {
    if (_groupOverlayEntry != null) {
      try {
        _groupOverlayEntry!.remove();
      } catch (_) {}
      _groupOverlayEntry = null;
    }
  }

  String formatDateTime(String? value) {
    if (value == null || value.isEmpty) return '--';

    try {
      final dt = DateTime.parse(value).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm a').format(dt);
    } catch (e) {
      return value; // fallback
    }
  }

  AlertCountModel? alertCountModel;
  final AlertCountApiService _alertCountApiService = AlertCountApiService();
  Future<void> fetchAlertCounts() async {
    try {
      final result = await _alertCountApiService.fetchAlertCounts();
      if (mounted) {
        setState(() {
          alertCountModel = result;
        });
      }
    } catch (e) {
      debugPrint("Alert Counts API Error: $e");
    }
  }

  Future<void> fetchAlertDetails({bool showLoading = true}) async {
    if (showLoading) setState(() => isDashboardLoading = true);

    try {
      final response = await _dashboardApi.fetchAlertDetails(
        date: dateParam,
        groupId: selectedGroup,
      );

      updateGroups(response.groups);

      setState(() {
        // groupsList = response.groups ?? [];
        if (selectedGroup != null &&
            !groupsList.any((g) => g.id == selectedGroup)) {
          selectedGroup = null;
        }
        if (!mounted) return;
        // ALERTS
        totalAlerts = response.totalAlerts ?? 0;
        criticalAlerts = response.criticalAlerts ?? 0;
        nonCriticalAlerts = response.nonCriticalAlerts ?? 0;
        attentionNeededVehicles = response.attentionNeededVehicles ?? 0;

        recentAlerts = response.alerts?.map((e) => e.toJson()).toList() ?? [];
      });
    } catch (e) {
      debugPrint("Dashboard API error: $e");
    } finally {
      if (showLoading && mounted) setState(() => isDashboardLoading = false);
    }
  }

  Future<void> fetchTripDetails({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => isDashboardLoading = true);

    try {
      final response = await _dashboardApi.fetchTripsDetails(
        date: dateParam,
        groupId: selectedGroup,
      );
      updateGroups(response.groups);
      if (!mounted) return;
      setState(() {
        // groupsList = response.groups ?? [];
        if (selectedGroup != null &&
            !groupsList.any((g) => g.id == selectedGroup)) {
          selectedGroup = null;
        }

        // VEHICLES

        // TRIPS
        tripsTotal = response.totalTrips ?? 0;
        completedTrips = response.completedTrips ?? 0;
        ongoingTrips = response.ongoingTrips ?? 0;
        // totalDistance = response.totalDistanceKm ?? 0;
        // totalOperHours = response.totalOperationalDuration ?? 0;
        avgTripsDay = response.avgTripsPerDay ?? 0;
        totalConsumedEnergy = (response.totalEnergyConsumed) ?? 0;
        todayTotalDistance = (response.todayDistanceKm) ?? 0;
        todayTotalOperHr = response.todayOperationalHours ?? 0;
        yesterdayTotalDistanceKm =
            parseDouble(response.yesterdayDistanceKm) ?? 0;
        yesterdayTotalOperHr =
            parseDouble(response.yesterdayOperationalHours) ?? 0;

        // tripsWeeklyGraph = response.weeklyTripsGraph ?? [];
        // tripsMonthlyGraph = response.monthlyTripsGraph ?? [];
      });
    } catch (e) {
      debugPrint("Dashboard API error: $e");
    } finally {
      if (showLoading && mounted) setState(() => isDashboardLoading = false);
    }
  }

  Future<void> fetchVehicleDetails({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => isDashboardLoading = true);

    try {
      final response = await _dashboardApi.fetchVehicleDetails(
        date: dateParam,
        groupId: selectedGroup,
      );
      updateGroups(response.groups);
      if (!mounted) return;
      setState(() {
        // groupsList = response.groups ?? [];
        if (selectedGroup != null &&
            !groupsList.any((g) => g.id == selectedGroup)) {
          selectedGroup = null;
        }

        // VEHICLES
        totalVehicles = response.totalVehicles ?? 0;
        activeVehicles = response.activeVehicles ?? 0;
        inactiveVehicles = response.inactiveVehicles ?? 0;

        // STATUS
        moving = response.vehicleStatusMap!.moving ?? 0;
        idle = response.vehicleStatusMap!.idle ?? 0;
        stopped = response.vehicleStatusMap!.stopped ?? 0;
        disconnected = response.vehicleStatusMap!.disconnected ?? 0;
        nonCoverage = response.vehicleStatusMap!.noncoverage ?? 0;
        charging = response.vehicleStatusMap!.charging ?? 0;
        discharging = response.vehicleStatusMap!.discharging ?? 0;
        batteryIdle = response.vehicleStatusMap?.idle ?? 0;
        batteryDisconnected = response.vehicleStatusMap?.disconnected ?? 0;
        // nonCoverage = response.vehicleStatusMap!.noncoverage ?? 0;

        //BMS Stats
        bmsStatsExcellent = response.socSummary!.excellent ?? 0;
        bmsStatsGood = response.socSummary!.good ?? 0;
        bmsStatsModerate = response.socSummary!.moderate ?? 0;
        bmsStatsPoor = response.socSummary!.poor ?? 0;

        vehicleUtilizationWeeklyGraph = response.weeklyVehicleUtilization ?? [];
        vehicleUtilizationMonthlyGraph =
            response.monthlyVehicleUtilization ?? [];
      });
    } catch (e) {
      debugPrint("Dashboard API error: $e");
    } finally {
      if (showLoading && mounted) setState(() => isDashboardLoading = false);
    }
  }

  bool isGraphLoading = false;
  Future<void> fetchAllGraphs() async {
    if (!mounted) return;

    setState(() => isGraphLoading = true);

    try {
      final alertResponse = await _dashboardApi.fetchAlertGraph(
        date: dateParam,
        groupId: selectedGroup,
      );

      final tripResponse = await _dashboardApi.fetchTripsGraph(
        date: dateParam,
        groupId: selectedGroup,
      );

      if (!mounted) return;

      setState(() {
        alertsWeeklyGraph = alertResponse.weeklyAlertsGraph ?? [];
        alertsMonthlyGraph = alertResponse.monthlyAlertsGraph ?? [];

        tripsWeeklyGraph = tripResponse.weeklyTripsGraph ?? [];
        tripsMonthlyGraph = tripResponse.monthlyTripsGraph ?? [];
      });
    } catch (e) {
      debugPrint('Graphs API error: $e');
    } finally {
      if (mounted) {
        setState(() => isGraphLoading = false);
      }
    }
  }

  Future<void> fetchAllDashboardData() async {
    if (mounted) setState(() => isDashboardLoading = true);
    try {
      await Future.wait([
        fetchAlertDetails(showLoading: false),
        fetchTripDetails(showLoading: false),
        fetchVehicleDetails(showLoading: false),
        // fetchAlertCounts(),
        fetchAllGraphs(),
      ]);
    } catch (e) {
      debugPrint('Dashboard API error: $e');
    } finally {
      if (mounted) setState(() => isDashboardLoading = false);
    }
    // fetchAllGraphs();
  }

  void updateGroups(List<dynamic>? groupsFromApi) {
    if (groupsFromApi == null || groupsFromApi.isEmpty) return;

    setState(() {
      groupsList =
          groupsFromApi.map((g) => Group.fromJson(g.toJson())).toList();

      if (selectedGroup != null &&
          !groupsList.any((g) => g.id == selectedGroup)) {
        selectedGroup = null;
      }
    });
  }

  Map<String, dynamic>? dashboardData;
  bool isDashboardLoading = false;
  int totalVehicles = 0;
  int evtotalvehicles = 0;

  int moving = 0;
  int idle = 0;
  int stopped = 0;
  int nonCoverage = 0;
  int disconnected = 0;
  int charging = 0;
  int discharging = 0;
  int batteryIdle = 0;
  int batteryDisconnected = 0;

  int activeVehicles = 0;
  int inactiveVehicles = 0;
  int evActive = 0;
  int evInactive = 0;

  Map<String, dynamic>? tripFullDetails;

  int tripsTotal = 0;
  int completedTrips = 0;
  int ongoingTrips = 0;
  double totalDistance = 0;
  double totalOperHours = 0;
  double totalConsumedEnergy = 0;
  double avgTripsDay = 0;
  double avgOdoPerVehicle = 0;
  double avgConEngPerVehicle = 0;
  double todayTotalDistance = 0;
  double todayTotalOperHr = 0;
  double yesterdayTotalDistanceKm = 0;
  double yesterdayTotalOperHr = 0;

  int totalAlerts = 0;
  int criticalAlerts = 0;
  int nonCriticalAlerts = 0;
  int attentionNeededVehicles = 0;

  int bmsStatsExcellent = 0;
  int bmsStatsGood = 0;
  int bmsStatsModerate = 0;
  int bmsStatsPoor = 0;

  List<Map<String, dynamic>> recentAlerts = [];

  // List<AlertsGraph> alertsWeeklyGraph = [];
  // List<AlertGraphforMonth> alertsMonthlyGraph = [];

  List<alertModel.WeeklyAlertsGraph> alertsWeeklyGraph = [];
  List<alertModel.MonthlyAlertsGraph> alertsMonthlyGraph = [];

  // List<TripsGraph> tripsWeeklyGraph = [];
  // List<TripsGraphforMonth> tripsMonthlyGraph = [];

  List<tripModel.WeeklyTripsGraph> tripsWeeklyGraph = [];
  List<tripModel.MonthlyTripsGraph> tripsMonthlyGraph = [];

  // List<VehicleutliGraph> vehicleUtilizationWeeklyGraph = [];
  // List<VehicleutliGraphforMonth> vehicleUtilizationMonthlyGraph = [];

  List<vehicleModel.WeeklyVehicleUtilization> vehicleUtilizationWeeklyGraph =
      [];
  List<vehicleModel.MonthlyVehicleUtilization> vehicleUtilizationMonthlyGraph =
      [];

  List<Group> groupsList = [];

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
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
        apiDate = DateFormat('yyyy-MM-dd').format(picked); // Add this line
      });
      fetchAllDashboardData();
    }
  }

  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  final NumberFormat format = NumberFormat('#,##,###');

  String formatEnergy(num valueInKw) {
    final int digits = valueInKw.toStringAsFixed(0).length;

    if (digits > 3) {
      double mw = valueInKw / 1000;
      return "${mw.toStringAsFixed(2)} ᴍᴡ";
    }

    return "${format.format(valueInKw.toInt())} kw";
  }

  List<Map<String, dynamic>> getBackendStatus() {
    final total = totalVehicles;
    if (total == 0) return [];

    double pct(int value) => (value / total) * 100;

    return [
      {
        'label': 'Moving',
        'api': 'moving',
        'color': tGreen,
        'count': moving,
        'percent': pct(moving),
      },
      {
        'label': 'Stopped',
        'api': 'stopped',
        'color': tRed,
        'count': stopped,
        'percent': pct(stopped),
      },
      {
        'label': 'Idle',
        'api': 'idle',
        'color': tOrange1,
        'count': idle,
        'percent': pct(idle),
      },
      {
        'label': 'Non Coverage',
        'api': 'non_coverage',
        'color': Colors.purple,
        'count': nonCoverage,
        'percent': pct(nonCoverage),
      },
      {
        'label': 'Disconnected',
        'api': 'disconnected',
        'color': tGrey,
        'count': disconnected,
        'percent': pct(disconnected),
      },
    ];
  }

  List<Map<String, dynamic>> getEVBackendStatus() {
    final total = totalVehicles;
    if (total == 0) return [];

    double pct(int value) => (value / total) * 100;

    return [
      {
        'label': 'Charging',
        'api': 'charging',
        // 'color': Colors.teal,
        'color': tBlue,
        'count': charging,
        'percent': pct(charging),
      },
      {
        'label': 'Discharging',
        'api': 'discharging',
        'color': tGreen,
        'count': discharging,
        'percent': pct(discharging),
      },
      {
        'label': 'Idle',
        'api': 'idle',
        'color': tOrange1,
        'count': batteryIdle,
        'percent': pct(batteryIdle),
      },
      {
        'label': 'Non Coverage',
        'api': 'non_coverage',
        'color': const Color(0xFF9C27B0),
        'count': nonCoverage,
        'percent': pct(nonCoverage),
      },
      {
        'label': 'Disconnected',
        'api': 'disconnected',
        'color': tGrey,
        'count': batteryDisconnected,
        'percent': pct(batteryDisconnected),
      },
    ];
  }

  String formatAlertDate(String? utc) {
    if (utc == null || utc.isEmpty) return '';
    final dateTime = DateTime.parse(utc).toLocal();
    return DateFormat('dd MMM yyyy, HH:mm:ss').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    // fetchDashboardDetails();
    fetchAllDashboardData();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _hideGroupDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      // tablet: Container(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_groupOverlayEntry != null) {
      _hideGroupDropdown();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _groupOverlayEntry?.markNeedsBuild();
      });
    }
  }

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              FleetTitleBar(isDark: isDark, title: "Dashboard"),

              const SizedBox(height: 12),

              /// FILTERS
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _buildGroupSelector(isDark),
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildDateSelector(isDark),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// TOTAL VEHICLES
              SizedBox(
                height: 185,
                child: Row(
                  children: [
                    /// TOTAL VEHICLES CARD
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          context.go('/home/devices');
                        },
                        child: LargeHoverCard(
                          value: "$totalVehicles",
                          label: "Total Vehicles",
                          labelColor: tBlue,
                          icon: "icons/car.svg",
                          iconColor: tBlue,
                          bgColor: tBlue.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    /// ACTIVE + INACTIVE
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.go('/home/devices?vehicleFilter=active');
                            },
                            child: SmallHoverCard(
                              height: 90,
                              value: "$activeVehicles",
                              label: "Active ",
                              labelColor: tGreen,
                              icon: "icons/car.svg",
                              iconColor: tGreen,
                              bgColor: tGreen.withOpacity(0.1),
                              isDark: isDark,
                            ),
                          ),

                          const SizedBox(height: 5),

                          GestureDetector(
                            onTap: () {
                              context.go(
                                '/home/devices?vehicleFilter=inactive',
                              );
                            },
                            child: SmallHoverCard(
                              height: 90,
                              value: "$inactiveVehicles",
                              label: "InActive ",
                              labelColor: tRed,
                              icon: "icons/car.svg",
                              iconColor: tRed,
                              bgColor: tRed.withOpacity(0.1),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// VEHICLE STATUS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      spreadRadius: 1,
                      // color: isDark ? Colors.white12 : Colors.black12,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.12)
                              : tBlack.withOpacity(0.1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode == 'EV Fleet'
                          ? 'EV Vehicle Status'
                          : 'Vehicle Status',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),

                    const SizedBox(height: 12),

                    DynamicSegmentBar(
                      statuses:
                          mode == 'EV Fleet'
                              ? getEVBackendStatus()
                              : getBackendStatus(),
                      height: 24,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              if (mode == "EV Fleet") ...[
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    'Battery Status',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: isDark ? tWhite : tBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: isDark ? tBlack : tWhite,
                    boxShadow: [
                      BoxShadow(
                        spreadRadius: 2,
                        blurRadius: 10,
                        // color:
                        //     isDark
                        //         ? tWhite.withOpacity(0.25)
                        //         : tBlack.withOpacity(0.15),
                        color:
                            isDark
                                ? tWhite.withOpacity(0.25)
                                : tBlack.withOpacity(0.15),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(15),
                  child: Opacity(
                    opacity: isDashboardLoading ? 0.5 : 1.0,
                    child: BatteryProgressBar(
                      counts: [
                        bmsStatsExcellent,
                        bmsStatsGood,
                        bmsStatsModerate,
                        bmsStatsPoor,
                      ],
                      showLabels: true,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              /// TRIPS OVERVIEW
              Text(
                'Trips Overview',
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),

              const SizedBox(height: 12),

              /// TRIPS
              SizedBox(
                height: 190,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          context.go('/home/trips');
                        },
                        child: LargeHoverCard(
                          value: format.format(tripsTotal),
                          label: "Trips",
                          labelColor: tGreen,
                          icon: "icons/distance.svg",
                          iconColor: tGreen,
                          bgColor: tGreen.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                context.go('/home/trips?filter=Completed');
                              },
                              child: SmallHoverCard(
                                value: format.format(completedTrips),
                                label: "Completed",
                                labelColor: tBlue,
                                icon: "icons/completed.svg",
                                iconColor: tBlue,
                                bgColor: tBlue.withOpacity(0.1),
                                isDark: isDark,
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                context.go('/home/trips?filter=Ongoing');
                              },
                              child: SmallHoverCard(
                                value: format.format(ongoingTrips),
                                label: "Ongoing",
                                labelColor: tOrange1,
                                icon: "icons/ongoing.svg",
                                iconColor: tOrange1,
                                bgColor: tOrange1.withOpacity(0.1),
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SmallHoverCard(
                          value: format.format(avgTripsDay),
                          label: "Avg Trips",
                          labelColor: tBlueSky,
                          icon: "icons/distance.svg",
                          iconColor: tBlueSky,
                          bgColor: tBlueSky.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child:
                            mode == 'EV Fleet'
                                ? SmallHoverCard(
                                  value: formatEnergy(totalConsumedEnergy),
                                  label: "Energy",
                                  labelColor: tBlue1,
                                  icon: "icons/battery.svg",
                                  iconColor: tBlue1,
                                  bgColor: tBlue1.withOpacity(0.1),
                                  isDark: isDark,
                                )
                                : SmallHoverCard(
                                  height: 78,
                                  value: "--",
                                  label: "Fuel(L)",
                                  labelColor: tRed,
                                  icon: "icons/fuel.svg",
                                  iconColor: tRed,
                                  bgColor: tRed.withOpacity(0.1),
                                  isDark: isDark,
                                ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: SmallHoverCard(
                          enableHover: false,
                          value: format.format(todayTotalDistance),
                          label: "Today Dist.",
                          labelColor: tGreenDark,
                          icon: "icons/distance.svg",
                          iconColor: tGreenDark,
                          bgColor: tGreenDark.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: SmallHoverCard(
                          enableHover: false,
                          value: todayTotalOperHr.toString(),
                          label: "Today Hours",
                          labelColor: tPink,
                          icon: "icons/consumedhours.svg",
                          iconColor: tPink,
                          bgColor: tPink.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: SmallHoverCard(
                          enableHover: false,
                          value: format.format(yesterdayTotalDistanceKm),
                          label: "Yest Dist.",
                          labelColor: tGreen,
                          icon: "icons/distance.svg",
                          iconColor: tGreen,
                          bgColor: tGreen.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: SmallHoverCard(
                          enableHover: false,
                          value: yesterdayTotalOperHr.toString(),
                          label: "Yest Hours",
                          labelColor: Colors.purpleAccent,
                          icon: "icons/consumedhours.svg",
                          iconColor: Colors.purpleAccent,
                          bgColor: Colors.purpleAccent.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// ALERTS SECTION
              Text(
                'Alerts Overview',
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SmallHoverCard(
                      value: format.format(totalAlerts),
                      label: "Alerts",
                      labelColor: tRed,
                      icon: "icons/alert.svg",
                      iconColor: tRed,
                      bgColor: tRed.withOpacity(0.1),
                      isDark: isDark,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: SmallHoverCard(
                      value: format.format(attentionNeededVehicles),
                      label: "Faults",
                      labelColor: tPink,
                      icon: "icons/fault.svg",
                      iconColor: tPink,
                      bgColor: tPink.withOpacity(0.1),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: SmallHoverCard(
                      value: format.format(nonCriticalAlerts),
                      label: "Non Critical",
                      labelColor: tBlueSky,
                      icon: "icons/alert.svg",
                      iconColor: tBlueSky,
                      bgColor: tBlueSky.withOpacity(0.1),
                      isDark: isDark,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: SmallHoverCard(
                      value: format.format(criticalAlerts),
                      label: "Critical",
                      labelColor: tOrange1,
                      icon: "icons/alert.svg",
                      iconColor: tOrange1,
                      bgColor: tOrange1.withOpacity(0.1),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// RECENT ALERTS
              Text(
                'Recent Alerts',
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(height: 400, child: buildAlertsTable(isDark)),

              const SizedBox(height: 16),
              Container(
                height: 270,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 2,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.12)
                              : tBlack.withOpacity(0.08),
                    ),
                  ],
                ),
                child: AlertsDonutChart(
                  critical: criticalAlerts,
                  nonCritical: nonCriticalAlerts,
                  avgCritical:
                      ((criticalAlerts * 100) /
                              (totalAlerts == 0 ? 1 : totalAlerts))
                          .toInt(),
                  avgNonCritical:
                      ((nonCriticalAlerts * 100) /
                              (totalAlerts == 0 ? 1 : totalAlerts))
                          .toInt(),
                ),
              ),
              SizedBox(height: 12),

              /// CHARTS
              Container(
                height: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 2,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.25)
                              : tBlack.withOpacity(0.15),
                    ),
                  ],
                ),
                child: ClipRect(
                  child: SizedBox.expand(
                    child: TripsChart(
                      weeklyData: tripsWeeklyGraph,
                      monthlyData: tripsMonthlyGraph,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 2,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.25)
                              : tBlack.withOpacity(0.15),
                    ),
                  ],
                ),
                child: ClipRect(
                  child: SizedBox.expand(
                    child: VehicleUtilizationChart(
                      weeklyData: vehicleUtilizationWeeklyGraph,
                      monthlyData: vehicleUtilizationMonthlyGraph,
                    ),
                  ),
                ),
              ),
              Container(
                height: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 2,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.25)
                              : tBlack.withOpacity(0.15),
                    ),
                  ],
                ),
                child: ClipRect(
                  child: SizedBox.expand(
                    child: AlertsChart(
                      weeklyData: alertsWeeklyGraph,
                      monthlyData: alertsMonthlyGraph,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        if (isDashboardLoading) _buildLoadingOverlay(isDark),
      ],
    );
  }

  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FleetTitleBar(isDark: isDark, title: "Dashboard"),
                  const Spacer(),

                  SizedBox(width: 275, child: _buildGroupSelector(isDark)),

                  const SizedBox(width: 5),

                  _buildDateSelector(isDark),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 185,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          context.go('/home/devices');
                        },
                        child: LargeHoverCard(
                          value: "$totalVehicles",
                          label: "Total Vehicles",
                          labelColor: tBlue,
                          icon: "icons/car.svg",
                          iconColor: tBlue,
                          bgColor: tBlue.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    /// ACTIVE + INACTIVE
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.go('/home/devices?vehicleFilter=active');
                            },
                            child: SmallHoverCard(
                              height: 90,
                              value: "$activeVehicles",
                              label: "Active Vehicles",
                              labelColor: tGreen,
                              icon: "icons/car.svg",
                              iconColor: tGreen,
                              bgColor: tGreen.withOpacity(0.1),
                              isDark: isDark,
                            ),
                          ),

                          const SizedBox(height: 5),

                          GestureDetector(
                            onTap: () {
                              context.go(
                                '/home/devices?vehicleFilter=inactive',
                              );
                            },
                            child: SmallHoverCard(
                              height: 90,
                              value: "$inactiveVehicles",
                              label: "InActive Vehicles ",
                              labelColor: tRed,
                              icon: "icons/car.svg",
                              iconColor: tRed,
                              bgColor: tRed.withOpacity(0.1),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: SmallHoverCard(
                                    value: format.format(
                                      attentionNeededVehicles,
                                    ),
                                    label: "Faults",
                                    labelColor: tPink,
                                    icon: "icons/fault.svg",
                                    iconColor: tPink,
                                    bgColor: tPink.withOpacity(0.1),
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                Expanded(
                                  child: SmallHoverCard(
                                    value: format.format(totalAlerts),
                                    label: "Alerts",
                                    labelColor: tRed,
                                    icon: "icons/alert.svg",
                                    iconColor: tRed,
                                    bgColor: tRed.withOpacity(0.1),
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: SmallHoverCard(
                                    value: format.format(nonCriticalAlerts),
                                    label: "Non Critical",
                                    labelColor: tBlueSky,
                                    icon: "icons/alert.svg",
                                    iconColor: tBlueSky,
                                    bgColor: tBlueSky.withOpacity(0.1),
                                    isDark: isDark,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: SmallHoverCard(
                                    value: format.format(criticalAlerts),
                                    label: "Critical",
                                    labelColor: tOrange1,
                                    icon: "icons/alert.svg",
                                    iconColor: tOrange1,
                                    bgColor: tOrange1.withOpacity(0.1),
                                    isDark: isDark,
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
              ),

              const SizedBox(height: 12),

              /// VEHICLE STATUS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      spreadRadius: 1,
                      // color: isDark ? Colors.white12 : Colors.black12,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.12)
                              : tBlack.withOpacity(0.1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode == 'EV Fleet'
                          ? 'EV Vehicle Status'
                          : 'Vehicle Status',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),

                    const SizedBox(height: 12),

                    DynamicSegmentBar(
                      statuses:
                          mode == 'EV Fleet'
                              ? getEVBackendStatus()
                              : getBackendStatus(),
                      height: 24,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              if (mode == "EV Fleet") ...[
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    // 'SOC Status',
                    'Battery Status',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: isDark ? tWhite : tBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: isDark ? tBlack : tWhite,
                    boxShadow: [
                      BoxShadow(
                        spreadRadius: 2,
                        blurRadius: 10,
                        // color:
                        //     isDark
                        //         ? tWhite.withOpacity(0.25)
                        //         : tBlack.withOpacity(0.15),
                        color:
                            isDark
                                ? tWhite.withOpacity(0.25)
                                : tBlack.withOpacity(0.15),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(15),
                  child: Opacity(
                    opacity: isDashboardLoading ? 0.5 : 1.0,
                    child: BatteryProgressBar(
                      counts: [
                        bmsStatsExcellent,
                        bmsStatsGood,
                        bmsStatsModerate,
                        bmsStatsPoor,
                      ],
                      showLabels: true,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              /// TRIPS
              Text(
                'Trips Overview',
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),

              const SizedBox(height: 12),

              Column(
                children: [
                  SizedBox(
                    height: 185,
                    child: Row(
                      children: [
                        /// LEFT SIDE - TRIPS
                        GestureDetector(
                          onTap: () {
                            context.go('/home/trips');
                          },

                          child: LargeHoverCard(
                            value: format.format(tripsTotal),
                            label: "Trips",
                            labelColor: tGreen,
                            icon: "icons/distance.svg",
                            iconColor: tGreen,
                            bgColor: tGreen.withOpacity(0.1),
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(width: 8),

                        /// RIGHT SIDE - 4 SMALL CARDS
                        Expanded(
                          child: Column(
                            children: [
                              /// TOP ROW
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          context.go(
                                            '/home/trips?filter=Completed',
                                          );
                                        },

                                        child: SmallHoverCard(
                                          value: format.format(completedTrips),
                                          label: "Completed",
                                          labelColor: tBlue,
                                          icon: "icons/completed.svg",
                                          iconColor: tBlue,
                                          bgColor: tBlue.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          context.go(
                                            '/home/trips?filter=Ongoing',
                                          );
                                        },

                                        child: SmallHoverCard(
                                          value: format.format(ongoingTrips),
                                          label: "Ongoing",
                                          labelColor: tOrange1,
                                          icon: "icons/ongoing.svg",
                                          iconColor: tOrange1,
                                          bgColor: tOrange1.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              /// BOTTOM ROW
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SmallHoverCard(
                                        width: double.infinity,
                                        value: format.format(avgTripsDay),
                                        label: "Avg. Trips",
                                        labelColor: tBlueSky,
                                        icon: "icons/distance.svg",
                                        iconColor: tBlueSky,
                                        bgColor: tBlueSky.withOpacity(0.1),
                                        isDark: isDark,
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child:
                                          mode == 'EV Fleet'
                                              ? SmallHoverCard(
                                                width: double.infinity,
                                                height: 75,
                                                value: formatEnergy(
                                                  totalConsumedEnergy,
                                                ),
                                                label: "Consumed Energy",
                                                labelColor: tBlue1,
                                                icon: "icons/battery.svg",
                                                iconColor: tBlue1,
                                                bgColor: tBlue1.withOpacity(
                                                  0.1,
                                                ),
                                                isDark: isDark,
                                              )
                                              : SmallHoverCard(
                                                width: double.infinity,
                                                height: 75,
                                                value: "--",
                                                label: "Consumed Fuel(L)",
                                                labelColor: tRed,
                                                icon: "icons/fuel.svg",
                                                iconColor: tRed,
                                                bgColor: tRed.withOpacity(0.1),
                                                isDark: isDark,
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
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: SmallHoverCard(
                          enableHover: false,
                          value: format.format(todayTotalDistance),
                          label: "Today Dist.",
                          labelColor: tGreenDark,
                          icon: "icons/distance.svg",
                          iconColor: tGreenDark,
                          bgColor: tGreenDark.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: SmallHoverCard(
                          enableHover: false,
                          value: todayTotalOperHr.toString(),
                          label: "Today Hours",
                          labelColor: tPink,
                          icon: "icons/consumedhours.svg",
                          iconColor: tPink,
                          bgColor: tPink.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: SmallHoverCard(
                          enableHover: false,
                          value: format.format(yesterdayTotalDistanceKm),
                          label: "Yest Dist.",
                          labelColor: tGreen,
                          icon: "icons/distance.svg",
                          iconColor: tGreen,
                          bgColor: tGreen.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: SmallHoverCard(
                          enableHover: false,
                          value: yesterdayTotalOperHr.toString(),
                          label: "Yest Hours",
                          labelColor: Colors.purpleAccent,
                          icon: "icons/consumedhours.svg",
                          iconColor: Colors.purpleAccent,
                          bgColor: Colors.purpleAccent.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// RECENT ALERTS
              Text(
                'Recent Alerts',
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(height: 400, child: buildAlertsTable(isDark)),

              const SizedBox(height: 16),
              Container(
                height: 270,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 2,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.12)
                              : tBlack.withOpacity(0.08),
                    ),
                  ],
                ),
                child: AlertsDonutChart(
                  critical: criticalAlerts,
                  nonCritical: nonCriticalAlerts,
                  avgCritical:
                      ((criticalAlerts * 100) /
                              (totalAlerts == 0 ? 1 : totalAlerts))
                          .toInt(),
                  avgNonCritical:
                      ((nonCriticalAlerts * 100) /
                              (totalAlerts == 0 ? 1 : totalAlerts))
                          .toInt(),
                ),
              ),
              SizedBox(height: 12),

              /// CHARTS
              Container(
                height: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 2,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.25)
                              : tBlack.withOpacity(0.15),
                    ),
                  ],
                ),
                child: TripsChart(
                  weeklyData: tripsWeeklyGraph,
                  monthlyData: tripsMonthlyGraph,
                ),
              ),

              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 2,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.25)
                              : tBlack.withOpacity(0.15),
                    ),
                  ],
                ),
                child: VehicleUtilizationChart(
                  weeklyData: vehicleUtilizationWeeklyGraph,
                  monthlyData: vehicleUtilizationMonthlyGraph,
                ),
              ),

              Container(
                height: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? tBlack : tWhite,
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 2,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.25)
                              : tBlack.withOpacity(0.15),
                    ),
                  ],
                ),
                child: AlertsChart(
                  weeklyData: alertsWeeklyGraph,
                  monthlyData: alertsMonthlyGraph,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        if (isDashboardLoading) _buildLoadingOverlay(isDark),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // _buildTitle(isDark),
                FleetTitleBar(isDark: isDark, title: "Dashboard"),

                Row(
                  children: [
                    _buildGroupSelector(isDark),
                    const SizedBox(width: 10),
                    _buildDateSelector(isDark),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          // Total Vehicles Main Card
                          GestureDetector(
                            onTap: () {
                              context.go('/home/devices');
                            },
                            child: LargeHoverCard(
                              value:
                                  mode == 'EV Fleet'
                                      ? '$totalVehicles'
                                      : "$totalVehicles", //value: "5,673",
                              label: "Total Vehicles",
                              labelColor: tBlue,
                              icon: "icons/car.svg",
                              iconColor: tBlue,
                              bgColor: tBlue.withOpacity(0.1),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                /// 🔹 Active Vehicles
                                GestureDetector(
                                  onTap: () {
                                    context.push(
                                      '/home/devices?vehicleFilter=active',
                                    );
                                  },
                                  child: SmallHoverCard(
                                    width: double.infinity,
                                    height: 87,
                                    value: "$activeVehicles",
                                    label: "Active Vehicles",
                                    labelColor: tGreen,
                                    icon: "icons/car.svg",
                                    iconColor: tGreen,
                                    bgColor: tGreen.withOpacity(0.1),
                                    isDark: isDark,
                                  ),
                                ),

                                const SizedBox(height: 11),
                                GestureDetector(
                                  onTap: () {
                                    context.push(
                                      '/home/devices?vehicleFilter=inactive',
                                    );
                                  },
                                  child: SmallHoverCard(
                                    width: double.infinity,
                                    height: 87,
                                    value: "$inactiveVehicles",
                                    label: "Inactive Vehicles",
                                    labelColor: tRed,
                                    icon: "icons/car.svg",
                                    iconColor: tRed,
                                    bgColor: tRed.withOpacity(0.1),
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),

                          /// 🔹 Middle: Vehicle Status Bars
                          Expanded(
                            flex: 8,
                            child: Container(
                              height: 185,
                              decoration: BoxDecoration(
                                color: isDark ? tBlack : tWhite,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                    color:
                                        isDark
                                            ? tWhite.withOpacity(0.12)
                                            : tBlack.withOpacity(0.1),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.only(
                                left: 15,
                                right: 15,
                                top: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'icons/progress.svg',
                                        height: 16,
                                        width: 16,
                                        color: isDark ? tWhite : tBlack,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        mode == 'EV Fleet'
                                            ? 'EV Fleet Status'
                                            : 'ICE Fleet Status',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 13,
                                          color: isDark ? tWhite : tBlack,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  mode == 'EV Fleet'
                                      ? Opacity(
                                        opacity: isDashboardLoading ? 0.5 : 1.0,
                                        child: DynamicSegmentBar(
                                          statuses: getEVBackendStatus(),
                                          height: 26,
                                        ),
                                      )
                                      : Opacity(
                                        opacity: isDashboardLoading ? 0.5 : 1.0,
                                        child: DynamicSegmentBar(
                                          statuses: getBackendStatus(),
                                          height: 26,
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          GestureDetector(
                            onTap: () {
                              context.go('/home/trips');
                            },
                            child: LargeHoverCard(
                              // value: NumberFormat('#,##,###').format(
                              //   int.tryParse(tripsTotal.toString()) ?? .0,
                              // ),
                              value: format.format(tripsTotal),
                              //value: "50,678",
                              label: "Trips",
                              labelColor: tGreen,
                              icon: "icons/distance.svg",
                              iconColor: tGreen,
                              bgColor: tGreen.withOpacity(0.1),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      if (mode == "EV Fleet") ...[
                        const SizedBox(height: 10),

                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            // 'SOC Status',
                            'Battery Status',
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: isDark ? tWhite : tBlack,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? tBlack : tWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                spreadRadius: 2,
                                blurRadius: 10,
                                // color:
                                //     isDark
                                //         ? tWhite.withOpacity(0.25)
                                //         : tBlack.withOpacity(0.15),
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.25)
                                        : tBlack.withOpacity(0.15),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(15),
                          child: Opacity(
                            opacity: isDashboardLoading ? 0.5 : 1.0,
                            child: BatteryProgressBar(
                              counts: [
                                bmsStatsExcellent,
                                bmsStatsGood,
                                bmsStatsModerate,
                                bmsStatsPoor,
                              ],
                              showLabels: true,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          // LEFT SIDE (Flex 8)
                          Expanded(
                            flex: 8,
                            child: Column(
                              children: [
                                // --------------------- ALERTS OVERVIEW ---------------------
                                Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: tTransparent,
                                    // boxShadow: [
                                    //   BoxShadow(
                                    //     blurRadius: 12,
                                    //     spreadRadius: 2,
                                    //     color:
                                    //         isDark
                                    //             ? tWhite.withOpacity(0.12)
                                    //             : tBlack.withOpacity(0.1),
                                    //   ),
                                    // ],
                                  ),
                                  // padding: EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                // ---------------- FIRST ROW (Large Cards) ----------------
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          context.go(
                                                            '/home/alerts',
                                                          );
                                                        },
                                                        child: LargeHoverCard(
                                                          value: format.format(
                                                            totalAlerts,
                                                          ),
                                                          label: "Alerts",
                                                          labelColor: tRed,
                                                          icon:
                                                              "icons/alert.svg",
                                                          iconColor: tRed,
                                                          bgColor: tRed
                                                              .withOpacity(0.1),
                                                          isDark: isDark,
                                                          height: 185,
                                                        ),
                                                      ),
                                                    ),

                                                    SizedBox(width: 10),

                                                    Expanded(
                                                      child: LargeHoverCard(
                                                        value: format.format(
                                                          attentionNeededVehicles ??
                                                              0,
                                                        ),
                                                        label: "Faults",
                                                        labelColor: tPink,
                                                        icon: "icons/fault.svg",
                                                        iconColor: tPink,
                                                        bgColor: tPink
                                                            .withOpacity(0.1),
                                                        isDark: isDark,
                                                        height: 185,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                SizedBox(height: 10),

                                                // ---------------- SECOND ROW (Small Cards) ----------------
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          context.go(
                                                            '/home/alerts/non_critical',
                                                          );
                                                        },
                                                        child: SmallHoverCard(
                                                          height: 74,
                                                          // value:
                                                          //     nonCriticalAlerts
                                                          //         .toString(),
                                                          value: format.format(
                                                            nonCriticalAlerts,
                                                          ),

                                                          label:
                                                              "Non-Critical Alerts",
                                                          labelColor: tBlueSky,
                                                          icon:
                                                              "icons/alert.svg",
                                                          iconColor: tBlueSky,
                                                          bgColor: tBlueSky
                                                              .withOpacity(0.1),
                                                          isDark: isDark,
                                                        ),
                                                      ),
                                                    ),

                                                    SizedBox(width: 10),

                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          context.go(
                                                            '/home/alerts/critical',
                                                          );
                                                        },
                                                        child: SmallHoverCard(
                                                          height: 74,
                                                          // value: NumberFormat(
                                                          //   '#,##,###',
                                                          // ).format(
                                                          //   int.tryParse(
                                                          //         criticalAlerts
                                                          //             .toString(),
                                                          //       ) ??
                                                          //       0,
                                                          // ),
                                                          value: format.format(
                                                            criticalAlerts,
                                                          ),

                                                          label:
                                                              "Critical Alerts",
                                                          labelColor: tOrange1,
                                                          icon:
                                                              "icons/alert.svg",
                                                          iconColor: tOrange1,
                                                          bgColor: tOrange1
                                                              .withOpacity(0.1),
                                                          isDark: isDark,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(width: 10),

                                          // ---------------- DONUT CHART CONTAINER ----------------
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: 270,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: isDark ? tBlack : tWhite,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    blurRadius: 12,
                                                    spreadRadius: 2,
                                                    color:
                                                        isDark
                                                            ? tWhite
                                                                .withOpacity(
                                                                  0.12,
                                                                )
                                                            : tBlack
                                                                .withOpacity(
                                                                  0.08,
                                                                ),
                                                  ),
                                                ],
                                              ),
                                              child: AlertsDonutChart(
                                                critical: criticalAlerts,
                                                nonCritical: nonCriticalAlerts,
                                                avgCritical:
                                                    ((criticalAlerts * 100) /
                                                            (totalAlerts == 0
                                                                ? 1
                                                                : totalAlerts))
                                                        .toInt(),
                                                avgNonCritical:
                                                    ((nonCriticalAlerts * 100) /
                                                            (totalAlerts == 0
                                                                ? 1
                                                                : totalAlerts))
                                                        .toInt(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 10),

                                // --------------------- TRIPS OVERVIEW ---------------------
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: tTransparent,
                                    // color: isDark ? tBlack : tWhite,
                                    // boxShadow: [
                                    //   BoxShadow(
                                    //     blurRadius: 12,
                                    //     spreadRadius: 2,
                                    //     color:
                                    //         isDark
                                    //             ? tWhite.withOpacity(0.12)
                                    //             : tBlack.withOpacity(0.1),
                                    //   ),
                                    // ],
                                  ),
                                  // padding: EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Trips Overview',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? tWhite : tBlack,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    context.go(
                                                      '/home/trips?filter=Completed',
                                                    );
                                                  },
                                                  child: SmallHoverCard(
                                                    width: double.infinity,
                                                    height: 75,
                                                    // value: NumberFormat(
                                                    //   '#,##,###',
                                                    // ).format(
                                                    //   int.tryParse(
                                                    //         completedTrips
                                                    //             .toString(),
                                                    //       ) ??
                                                    //       0,
                                                    // ),
                                                    value: format.format(
                                                      completedTrips,
                                                    ),
                                                    label: "Completed Trips",
                                                    labelColor: tBlue,
                                                    icon: "icons/completed.svg",
                                                    iconColor: tBlue,
                                                    bgColor: tBlue.withOpacity(
                                                      0.1,
                                                    ),
                                                    isDark: isDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                GestureDetector(
                                                  onTap: () {
                                                    context.go(
                                                      '/home/trips?filter=Ongoing',
                                                    );
                                                  },
                                                  child: SmallHoverCard(
                                                    width: double.infinity,
                                                    height: 75,
                                                    // value: NumberFormat(
                                                    //   '#,##,###',
                                                    // ).format(
                                                    //   int.tryParse(
                                                    //         ongoingTrips
                                                    //             .toString(),
                                                    //       ) ??
                                                    //       0,
                                                    // ),
                                                    value: format.format(
                                                      ongoingTrips,
                                                    ),

                                                    label: "Ongoing Trips",
                                                    labelColor: tOrange1,
                                                    icon: "icons/ongoing.svg",
                                                    iconColor: tOrange1,
                                                    bgColor: tOrange1
                                                        .withOpacity(0.1),
                                                    isDark: isDark,
                                                  ),
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
                                                  enableHover: false,
                                                  height: 75,
                                                  // value: NumberFormat(
                                                  //   '#,##,###',
                                                  // ).format(
                                                  //   int.tryParse(
                                                  //         avgTripsDay
                                                  //             .toString(),
                                                  //       ) ??
                                                  //       0,
                                                  // ),
                                                  value: format.format(
                                                    avgTripsDay,
                                                  ),
                                                  label: "Avg. Trips",
                                                  labelColor: tBlueSky,
                                                  icon: "icons/distance.svg",
                                                  iconColor: tBlueSky,
                                                  bgColor: tBlueSky.withOpacity(
                                                    0.1,
                                                  ),
                                                  isDark: isDark,
                                                ),
                                                const SizedBox(height: 10),

                                                mode == 'EV Fleet'
                                                    ? SmallHoverCard(
                                                      width: double.infinity,
                                                      enableHover: false,
                                                      height: 75,
                                                      value: formatEnergy(
                                                        totalConsumedEnergy,
                                                      ),
                                                      label: "Consumed Energy",
                                                      labelColor: tBlue1,
                                                      icon: "icons/battery.svg",
                                                      iconColor: tBlue1,
                                                      bgColor: tBlue1
                                                          .withOpacity(0.1),
                                                      isDark: isDark,
                                                    )
                                                    : SmallHoverCard(
                                                      width: double.infinity,
                                                      enableHover: false,
                                                      height: 75,
                                                      value: "--",
                                                      label: "Consumed Fuel(L)",
                                                      labelColor: tRed,
                                                      icon: "icons/fuel.svg",
                                                      iconColor: tRed,
                                                      bgColor: tRed.withOpacity(
                                                        0.1,
                                                      ),
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
                                                  enableHover: false,
                                                  width: double.infinity,
                                                  height: 75,
                                                  // value: NumberFormat(
                                                  //   '#,##,###.##',
                                                  // ).format(
                                                  //   double.tryParse(
                                                  //         todayTotalDistance
                                                  //             .toString(),
                                                  //       ) ??
                                                  //       0,
                                                  // ),
                                                  value: format.format(
                                                    todayTotalDistance,
                                                  ),

                                                  label: "Today's Distance(km)",
                                                  labelColor: tGreenDark,
                                                  icon: "icons/distance.svg",
                                                  iconColor: tGreenDark,
                                                  bgColor: tGreenDark
                                                      .withOpacity(0.1),
                                                  isDark: isDark,
                                                ),
                                                const SizedBox(height: 10),
                                                SmallHoverCard(
                                                  enableHover: false,
                                                  width: double.infinity,
                                                  height: 75,
                                                  value:
                                                      todayTotalOperHr
                                                          .toString(),
                                                  label:
                                                      "Today's Oper. Hours(hrs)",
                                                  labelColor: tPink,
                                                  icon:
                                                      "icons/consumedhours.svg",
                                                  iconColor: tPink,
                                                  bgColor: tPink.withOpacity(
                                                    0.1,
                                                  ),
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
                                                  enableHover: false,
                                                  width: double.infinity,
                                                  height: 75,
                                                  // value: NumberFormat(
                                                  //   '#,##,###.##',
                                                  // ).format(
                                                  //   double.tryParse(
                                                  //         yesterdayTotalDistanceKm
                                                  //             .toString(),
                                                  //       ) ??
                                                  //       0,
                                                  // ),
                                                  value: format.format(
                                                    yesterdayTotalDistanceKm,
                                                  ),

                                                  label: "Yest. Distance(km)",
                                                  labelColor: tGreen,
                                                  icon: "icons/distance.svg",
                                                  iconColor: tGreen,
                                                  bgColor: tGreen.withOpacity(
                                                    0.1,
                                                  ),
                                                  isDark: isDark,
                                                ),
                                                const SizedBox(height: 10),
                                                SmallHoverCard(
                                                  enableHover: false,
                                                  width: double.infinity,
                                                  height: 75,
                                                  value:
                                                      yesterdayTotalOperHr
                                                          .toString(),
                                                  label:
                                                      "Yest. Oper. Hours(hrs)",
                                                  labelColor:
                                                      Colors.purpleAccent,
                                                  icon:
                                                      "icons/consumedhours.svg",
                                                  iconColor:
                                                      Colors.purpleAccent,
                                                  bgColor: Colors.purpleAccent
                                                      .withOpacity(0.1),
                                                  isDark: isDark,
                                                ),
                                              ],
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

                          SizedBox(width: 10),

                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 510,
                              decoration: BoxDecoration(
                                color: tTransparent,
                                // color: isDark ? tBlack : tWhite,
                                // boxShadow: [
                                //   BoxShadow(
                                //     blurRadius: 12,
                                //     spreadRadius: 2,
                                //     color:
                                //         isDark
                                //             ? tWhite.withOpacity(0.12)
                                //             : tBlack.withOpacity(0.1),
                                //   ),
                                // ],
                              ),
                              // padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Left side
                                      Text(
                                        'Recent Alerts',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? tWhite : tBlack,
                                        ),
                                      ),

                                      // Right side group
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        onEnter:
                                            (_) => setState(
                                              () => isHovered = true,
                                            ),
                                        onExit:
                                            (_) => setState(
                                              () => isHovered = false,
                                            ),
                                        child: GestureDetector(
                                          onTap: () {
                                            context.go('/home/alerts');
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isHovered
                                                      ? tGreen8
                                                      : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.visibility_outlined,
                                                  size: 16,
                                                  color:
                                                      isHovered
                                                          ? tWhite
                                                          : (isDark
                                                              ? tWhite
                                                              : tBlack),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'View More',
                                                  style: GoogleFonts.urbanist(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        isHovered
                                                            ? tWhite
                                                            : (isDark
                                                                ? tWhite
                                                                : tBlack),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),

                                  /// Scrollable content must be wrapped in Expanded
                                  Expanded(child: buildAlertsTable(isDark)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 325,
                              decoration: BoxDecoration(
                                color: isDark ? tBlack : tWhite,
                                borderRadius: BorderRadius.circular(20),
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
                              child: ClipRect(
                                child: SizedBox.expand(
                                  child: TripsChart(
                                    weeklyData: tripsWeeklyGraph,
                                    monthlyData: tripsMonthlyGraph,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 325,
                              decoration: BoxDecoration(
                                color: isDark ? tBlack : tWhite,
                                borderRadius: BorderRadius.circular(20),
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
                              // child: ClipRect(
                              //   child: SizedBox.expand(
                              child: VehicleUtilizationChart(
                                weeklyData: vehicleUtilizationWeeklyGraph,
                                monthlyData: vehicleUtilizationMonthlyGraph,
                              ),
                            ),
                          ),
                          //   ),
                          // ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 325,
                              decoration: BoxDecoration(
                                color: isDark ? tBlack : tWhite,
                                borderRadius: BorderRadius.circular(20),
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
                              child: ClipRect(
                                child: SizedBox.expand(
                                  child: AlertsChart(
                                    weeklyData: alertsWeeklyGraph,
                                    monthlyData: alertsMonthlyGraph,
                                  ),
                                ),
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
        ),

        if (isDashboardLoading) _buildLoadingOverlay(isDark),
      ],
    );
  }

  Widget _buildGroupSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabelBox("Group Name", tBlue, isDark),
            const SizedBox(width: 5),
            _buildDynamicDropdown(isDark),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '(Note: Filter by Group Name)',
          style: GoogleFonts.urbanist(
            fontSize: 10,
            color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return _buildDynamicDatePicker(isDark);
  }

  Widget _buildLabelBox(String text, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tTransparent,
        border: Border.all(width: 0.5, color: isDark ? tWhite : tBlack),
      ),
      child: Text(
        text,
        style: GoogleFonts.urbanist(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDynamicDropdown(bool isDark) {
    void _showGroupDropdown(BuildContext context) {
      final overlay = Overlay.of(context);

      _groupOverlayEntry = OverlayEntry(
        builder: (context) {
          return Positioned(
            width: 180,
            child: CompositedTransformFollower(
              link: _groupLayerLink,
              offset: const Offset(0, 35),
              showWhenUnlinked: false,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? tBlack.withOpacity(0.95) : Colors.white,
                    border: Border.all(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.10)
                              : Colors.grey.shade300,
                      width: 1.2,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        // Group options
                        ...groupsList.map((group) {
                          return InkWell(
                            onTap: () {
                              if (!mounted) return;
                              setState(() {
                                selectedGroup = group.id;
                              });
                              _hideGroupDropdown();
                              fetchAllDashboardData();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Text(
                                group.name ?? '',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? tWhite : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      overlay.insert(_groupOverlayEntry!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _groupLayerLink,
          child: GestureDetector(
            onTap: () {
              if (_groupOverlayEntry == null) {
                _showGroupDropdown(context);
              } else {
                _hideGroupDropdown();
              }
            },
            child: Container(
              height: 30,
              width: 180,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? tWhite : tBlack, width: 0.6),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedGroup == null
                          ? "Select Group"
                          : (groupsList
                                  .firstWhere(
                                    (g) => g.id == selectedGroup,
                                    orElse: () => Group(id: '', name: ''),
                                  )
                                  .name ??
                              "Select Group"),
                      style: GoogleFonts.urbanist(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? tWhite : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedGroup != null) ...[
                        GestureDetector(
                          onTap: () {
                            _hideGroupDropdown();
                            setState(() {
                              selectedGroup = null;
                            });
                            fetchAllDashboardData();
                          },
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.8)
                                    : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color:
                            isDark
                                ? tWhite.withOpacity(0.8)
                                : Colors.grey.shade700,
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

  Widget _buildDynamicDatePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: tTransparent,
                  border: Border.all(
                    width: 0.6,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                child: Center(
                  child: Text(
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(selectedDate).toUpperCase(),
                    style: GoogleFonts.urbanist(
                      fontSize: 12.5,
                      color: isDark ? tWhite : tBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '(Note: Filter by Date)',
          style: GoogleFonts.urbanist(
            fontSize: 10,
            color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget buildAlertsTable(bool isDark) {
    final alerts = recentAlerts;

    Color getAlertColor(String type) {
      type = type.toLowerCase();
      if (type.contains('disconnect')) return tRedDark;
      if (type.contains('battery')) return Colors.red.shade400;
      if (type.contains('low') || type.contains('low_fuel')) return tOrange1;
      if (type.contains('temperature') || type.contains('temp')) {
        return Colors.deepOrange;
      }
      if (type.contains('fall')) {
        return Colors.purple;
      }
      if (type.contains('ignition')) return tBlueSky;
      if (type.contains('speed')) return Colors.teal;
      if (type.contains('tilt')) return Colors.indigo;

      return tGreen3;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        return Container(
          width: maxWidth,
          height: maxHeight,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            borderRadius: BorderRadius.circular(20),
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
                  controller: _horizontalController,
                  thumbVisibility: true,
                  radius: const Radius.circular(6),
                  thickness: 4,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: maxWidth),
                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalController,
                          scrollDirection: Axis.vertical,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                isDark
                                    ? tGreen8.withOpacity(0.15)
                                    : tGreen8.withOpacity(0.05),
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
                              columnSpacing: 35,

                              border: TableBorder.all(
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.1)
                                        : tBlack.withOpacity(0.1),
                                width: 0.4,
                              ),
                              dividerThickness: 0.01,
                              columns: [
                                DataColumn(
                                  label: Text(
                                    "Vehicle / IMEI",
                                    style: GoogleFonts.urbanist(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? tWhite : tBlack,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Date & Time",
                                    style: GoogleFonts.urbanist(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? tWhite : tBlack,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Alert Type",
                                    style: GoogleFonts.urbanist(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? tWhite : tBlack,
                                    ),
                                  ),
                                ),
                              ],
                              rows:
                                  alerts.map((alert) {
                                    final alertType =
                                        (alert['alertType'] ?? '').toString();
                                    final alertColor = getAlertColor(
                                      alert['alertType']!,
                                    );

                                    return DataRow(
                                      cells: [
                                        // Vehicle + IMEI column
                                        DataCell(
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                (alert['imei'] ?? '')
                                                    .toString(),
                                                style: GoogleFonts.urbanist(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                  color:
                                                      isDark ? tWhite : tBlack,
                                                ),
                                              ),
                                              Text(
                                                (alert['vehicleNumber'] ?? '')
                                                    .toString(),
                                                style: GoogleFonts.urbanist(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 11,
                                                  color:
                                                      isDark
                                                          ? Colors.grey[300]
                                                          : Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // DateTime
                                        DataCell(
                                          Text(
                                            formatDateTime(
                                              alert['time'] ?? '',
                                            ).toString(),
                                            style: GoogleFonts.urbanist(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                              color: isDark ? tWhite : tBlack,
                                            ),
                                          ),
                                        ),

                                        // Alert Type Badge
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                              horizontal: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: alertColor.withOpacity(
                                                0.18,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              alertType,
                                              style: GoogleFonts.urbanist(
                                                color: alertColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true, // block all touches
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
                    'Loading Dashboard...',
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
}
