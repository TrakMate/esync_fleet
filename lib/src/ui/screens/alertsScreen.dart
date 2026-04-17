import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../models/alertCountModel.dart';
import '../../provider/fleetModeProvider.dart';
import '../../services/generalAPIServices.dart/alertCountAPIService.dart';
import '../../services/generalAPIServices.dart/alertsAPIService.dart';
import '../../utils/appColors.dart';

import '../../utils/appResponsive.dart';
import '../components/customTitleBar.dart';
import '../../models/alertsModel.dart';
import '../components/largeHoverCard.dart';
import '../components/smallHoverCard.dart';

// const Set<String> bmsFaultTypes = {
//   'Battery Low',
//   'Battery Disconnect',
//   'Cell Voltage High',
//   'Cell Voltage Low',
//   'Cell Temperature High',
//   'BMS Fault',
//   'Battery Over Voltage',
//   'Battery Under Voltage',
// };

// const Set<String> mcuFaultTypes = {
//   'Motor Over Temperature',
//   'Motor Controller Fault',
//   'Inverter Fault',
//   'MCU Fault',
//   'Phase Failure',
// };

// const Set<String> ecuFaultTypes = {
//   'ECU Fault',
//   'CAN Error',
//   'Sensor Fault',
//   'Communication Error',
//   'Throttle Fault',
// };
const Set<String> batteryFaulttTypes = {'Fault'};

final Map<String, Color> batteryFaulttColors = {'Fault': tGrey};

// // Update allFaultTypes to only include battery fault
final Set<String> allBatteryFaultTypes = {...batteryFaulttTypes};
final Map<String, Color> allBatteryFaultColors = {...batteryFaulttColors};
// final Map<String, Color> bmsFaultColors = {
//   'Battery Low': Colors.orange,
//   'Battery Disconnect': Colors.redAccent,
//   'Cell Voltage High': Colors.deepOrange,
//   'Cell Voltage Low': Colors.amber,
//   'Cell Temperature High': Colors.pinkAccent,
//   'BMS Fault': Colors.red,
// };

// final Map<String, Color> mcuFaultColors = {
//   'Motor Over Temperature': Colors.deepOrange,
//   'Motor Controller Fault': Colors.redAccent,
//   'Inverter Fault': Colors.purple,
//   'MCU Fault': Colors.red,
//   'Phase Failure': Colors.orange,
// };

// final Map<String, Color> ecuFaultColors = {
//   'ECU Fault': Colors.blueGrey,
//   'CAN Error': Colors.indigo,
//   'Sensor Fault': Colors.teal,
//   'Communication Error': Colors.blue,
//   'Throttle Fault': Colors.cyan,
// };

// final Set<String> allFaultTypes = {
//   ...bmsFaultTypes,
//   ...mcuFaultTypes,
//   ...ecuFaultTypes,
// };
final Set<String> batteryFaultTypes = {'Battery Fault'};

// final Map<String, Color> allFaultColors = {
//   ...bmsFaultColors,
//   ...mcuFaultColors,
//   ...ecuFaultColors,
// };

// Keep only battery fault colors
// final Map<String, Color> batteryFaulttColors = {'Battery Fault': Colors.orange};

class AlertsScreen extends StatefulWidget {
  final String type;
  const AlertsScreen({super.key, required this.type});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  String? _selectedAlertCategory;
  DateTime selectedDate = DateTime.now();

  int hoveredAlertIndex = -1;

  final AlertApiService _apiService = AlertApiService();

  AlertsModel? alertsModel;
  bool isLoading = false;
  AlertCountModel? alertCountModel;
  final AlertCountApiService _alertCountApiService = AlertCountApiService();
  int currentPage = 1;
  int rowsPerPage = 10;
  int totalPages = 1;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounceTimer;
  List<Alerts> _filteredAlerts = [];
  String selectedFilter = 'All';
  String? apiDate;
  String _getApiAlertType() {
    if (_selectedAlertCategory != null) {
      return _selectedAlertCategory!;
    }
    switch (widget.type.toLowerCase()) {
      case 'critical':
        return 'CRITICAL';
      case 'non_critical':
        return 'NON_CRITICAL';
      case 'all':
        return 'ALL';
      default:
        return 'ALL';
    }
  }

  void _onAlertCardTap(String? alertCategory) {
    setState(() {
      _selectedAlertCategory = alertCategory;
      currentPage = 1;
      selectedFilter = 'All';
    });
    fetchAlerts();
  }

  //
  void _updateFilteredAlerts() {
    if (alertsModel == null) {
      _filteredAlerts = [];
      return;
    }

    List<Alerts> combinedAlerts = [];

    switch (selectedFilter) {
      case 'Devices':
        // Get unique devices from alerts
        final Map<String, Alerts> uniqueDevices = {};

        // Add from main alerts
        for (var alert in (alertsModel?.alerts ?? [])) {
          final key = alert.imei ?? alert.vehicleNumber ?? '';
          if (key.isNotEmpty && !uniqueDevices.containsKey(key)) {
            uniqueDevices[key] = alert;
          }
        }

        // Add from speed alerts
        for (var speedAlert in (alertsModel?.speedAlerts ?? [])) {
          final key = speedAlert.imei ?? speedAlert.vehicleNumber ?? '';
          if (key.isNotEmpty && !uniqueDevices.containsKey(key)) {
            uniqueDevices[key] = Alerts(
              imei: speedAlert.imei,
              vehicleNumber: speedAlert.vehicleNumber,
              alertType: speedAlert.alertType,
              data: speedAlert.data,
              time: speedAlert.time,
              alertCategory: speedAlert.alertCategory,
            );
          }
        }

        // Add from geo-fence alerts
        for (var geoAlert in (alertsModel?.geoFenceAlerts ?? [])) {
          final key = geoAlert.imei ?? geoAlert.vehicleNumber ?? '';
          if (key.isNotEmpty && !uniqueDevices.containsKey(key)) {
            uniqueDevices[key] = Alerts(
              imei: geoAlert.imei,
              vehicleNumber: geoAlert.vehicleNumber,
              alertType: geoAlert.alertType ?? 'GeoFence',
              data: geoAlert.data,
              time: geoAlert.time,
              alertCategory: geoAlert.alertCategory,
            );
          }
        }

        combinedAlerts = uniqueDevices.values.toList();
        break;

      case 'Speed':
        // Convert SpeedAlerts to Alerts format
        combinedAlerts =
            (alertsModel?.speedAlerts ?? []).map((speedAlert) {
              return Alerts(
                imei: speedAlert.imei,
                vehicleNumber: speedAlert.vehicleNumber,
                alertType: speedAlert.alertType,
                data: speedAlert.data,
                time: speedAlert.time,
                alertCategory: speedAlert.alertCategory,
              );
            }).toList();
        break;

      case 'Geo-Fence':
        // Convert GeoFenceAlerts to Alerts format
        combinedAlerts =
            (alertsModel?.geoFenceAlerts ?? []).map((geoAlert) {
              return Alerts(
                imei: geoAlert.imei,
                vehicleNumber: geoAlert.vehicleNumber,
                alertType: geoAlert.alertType ?? 'GeoFence',
                data: geoAlert.data,
                time: geoAlert.time,
                alertCategory: geoAlert.alertCategory,
              );
            }).toList();
        break;

      case 'All':
      default:
        final allAlerts = <Alerts>[];

        // Add from main alerts
        allAlerts.addAll(alertsModel?.alerts ?? []);

        // Add from speed alerts
        allAlerts.addAll(
          (alertsModel?.speedAlerts ?? []).map((speedAlert) {
            return Alerts(
              imei: speedAlert.imei,
              vehicleNumber: speedAlert.vehicleNumber,
              alertType: speedAlert.alertType,
              data: speedAlert.data,
              time: speedAlert.time,
              alertCategory: speedAlert.alertCategory,
            );
          }),
        );

        // Add from geo-fence alerts
        allAlerts.addAll(
          (alertsModel?.geoFenceAlerts ?? []).map((geoAlert) {
            return Alerts(
              imei: geoAlert.imei,
              vehicleNumber: geoAlert.vehicleNumber,
              alertType: geoAlert.alertType ?? 'GeoFence',
              data: geoAlert.data,
              time: geoAlert.time,
              alertCategory: geoAlert.alertCategory,
            );
          }),
        );

        combinedAlerts = allAlerts;
        break;
    }

    // Apply search filter if needed
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _filteredAlerts =
          combinedAlerts.where((alert) {
            return (alert.imei?.toLowerCase().contains(query) ?? false) ||
                (alert.vehicleNumber?.toLowerCase().contains(query) ?? false);
          }).toList();
    } else {
      _filteredAlerts = combinedAlerts;
    }

    setState(() {});
  }

  void _applySearchFilter() {
    if (alertsModel == null) {
      _filteredAlerts = [];
      return;
    }

    if (_searchQuery.isEmpty) {
      _updateFilteredAlerts(); // Refresh with current filter
    } else {
      final query = _searchQuery.toLowerCase();
      List<Alerts> sourceAlerts = [];

      switch (selectedFilter) {
        case 'Devices':
          // Get unique devices
          final Map<String, Alerts> uniqueDevices = {};
          for (var alert in (alertsModel?.alerts ?? [])) {
            final key = alert.imei ?? alert.vehicleNumber ?? '';
            if (key.isNotEmpty && !uniqueDevices.containsKey(key)) {
              uniqueDevices[key] = alert;
            }
          }
          for (var speedAlert in (alertsModel?.speedAlerts ?? [])) {
            final key = speedAlert.imei ?? speedAlert.vehicleNumber ?? '';
            if (key.isNotEmpty && !uniqueDevices.containsKey(key)) {
              uniqueDevices[key] = Alerts(
                imei: speedAlert.imei,
                vehicleNumber: speedAlert.vehicleNumber,
                alertType: speedAlert.alertType,
                data: speedAlert.data,
                time: speedAlert.time,
                alertCategory: speedAlert.alertCategory,
              );
            }
          }
          for (var geoAlert in (alertsModel?.geoFenceAlerts ?? [])) {
            final key = geoAlert.imei ?? geoAlert.vehicleNumber ?? '';
            if (key.isNotEmpty && !uniqueDevices.containsKey(key)) {
              uniqueDevices[key] = Alerts(
                imei: geoAlert.imei,
                vehicleNumber: geoAlert.vehicleNumber,
                alertType: geoAlert.alertType ?? 'GeoFence',
                data: geoAlert.data,
                time: geoAlert.time,
                alertCategory: geoAlert.alertCategory,
              );
            }
          }
          sourceAlerts = uniqueDevices.values.toList();
          break;

        case 'Speed':
          sourceAlerts =
              (alertsModel?.speedAlerts ?? []).map((speedAlert) {
                return Alerts(
                  imei: speedAlert.imei,
                  vehicleNumber: speedAlert.vehicleNumber,
                  alertType: speedAlert.alertType,
                  data: speedAlert.data,
                  time: speedAlert.time,
                  alertCategory: speedAlert.alertCategory,
                );
              }).toList();
          break;

        case 'Geo-Fence':
          sourceAlerts =
              (alertsModel?.geoFenceAlerts ?? []).map((geoAlert) {
                return Alerts(
                  imei: geoAlert.imei,
                  vehicleNumber: geoAlert.vehicleNumber,
                  alertType: geoAlert.alertType ?? 'GeoFence',
                  data: geoAlert.data,
                  time: geoAlert.time,
                  alertCategory: geoAlert.alertCategory,
                );
              }).toList();
          break;

        case 'All':
        default:
          final allAlerts = <Alerts>[];
          allAlerts.addAll(
            (alertsModel?.alerts ?? []).map(
              (alert) => Alerts(
                imei: alert.imei,
                vehicleNumber: alert.vehicleNumber,
                alertType: alert.alertType,
                data: alert.data,
                time: alert.time,
                alertCategory: alert.alertCategory,
              ),
            ),
          );
          allAlerts.addAll(
            (alertsModel?.speedAlerts ?? []).map(
              (speedAlert) => Alerts(
                imei: speedAlert.imei,
                vehicleNumber: speedAlert.vehicleNumber,
                alertType: speedAlert.alertType,
                data: speedAlert.data,
                time: speedAlert.time,
                alertCategory: speedAlert.alertCategory,
              ),
            ),
          );
          allAlerts.addAll(
            (alertsModel?.geoFenceAlerts ?? []).map(
              (geoAlert) => Alerts(
                imei: geoAlert.imei,
                vehicleNumber: geoAlert.vehicleNumber,
                alertType: geoAlert.alertType ?? 'GeoFence',
                data: geoAlert.data,
                time: geoAlert.time,
                alertCategory: geoAlert.alertCategory,
              ),
            ),
          );
          sourceAlerts = allAlerts;
          break;
      }

      _filteredAlerts =
          sourceAlerts.where((alert) {
            return (alert.imei?.toLowerCase().contains(query) ?? false) ||
                (alert.vehicleNumber?.toLowerCase().contains(query) ?? false);
          }).toList();
      setState(() {});
    }
  }
  // Future<void> fetchAlerts() async {
  //   if (!mounted) return;

  //   setState(() => isLoading = true);

  //   try {
  //     final result = await _apiService.fetchAlerts(
  //       type: widget.type,
  //       searchText: _searchQuery.isNotEmpty ? _searchQuery : null,
  //       date: apiDate,
  //       currentIndex: (currentPage - 1) * rowsPerPage,
  //       sizePerPage: rowsPerPage,
  //     );

  //     if (!mounted) return;

  //     setState(() {
  //       alertsModel = result;
  //       _filteredAlerts = result.alerts ?? [];
  //       totalPages = ((result.totalAlerts ?? 0) / rowsPerPage).ceil();
  //     });
  //   } catch (e) {
  //     debugPrint("Alerts API Error: $e");
  //   } finally {
  //     if (!mounted) return;
  //     setState(() => isLoading = false);
  //   }
  // }
  Future<void> fetchAlerts() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _apiService.fetchAlerts(
        imei: null,
        alertType: _getApiAlertType(),
        searchText: _searchQuery.isNotEmpty ? _searchQuery : null,
        date: apiDate,
        currentIndex: (currentPage - 1) * rowsPerPage,
        sizePerPage: rowsPerPage,
      );

      if (!mounted) return;

      setState(() {
        alertsModel = result;
        totalPages = ((result.totalAlerts ?? 0) / rowsPerPage).ceil();
        if (_searchQuery.isNotEmpty) {
          final allAlerts = <Alerts>[];
          allAlerts.addAll(result.alerts ?? []);
          allAlerts.addAll(
            (result.speedAlerts ?? []).map(
              (s) => Alerts(
                imei: s.imei,
                vehicleNumber: s.vehicleNumber,
                alertType: s.alertType,
                data: s.data,
                time: s.time,
                alertCategory: s.alertCategory,
              ),
            ),
          );
          allAlerts.addAll(
            (result.geoFenceAlerts ?? []).map(
              (g) => Alerts(
                imei: g.imei,
                vehicleNumber: g.vehicleNumber,
                alertType: g.alertType ?? 'GeoFence',
                data: g.data,
                time: g.time,
                alertCategory: g.alertCategory,
              ),
            ),
          );
          _filteredAlerts = allAlerts;
        } else {
          _updateFilteredAlerts();
        }
      });
    } catch (e) {
      debugPrint("Alerts API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) fetchAlerts();
      fetchAlertCounts();
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, double> _buildFaultData(Set<String> faultTypes) {
    final rand = Random();

    final selected = faultTypes.take(4).toList();
    final Map<String, double> result = {};

    double remaining = 100;

    for (int i = 0; i < selected.length; i++) {
      final value =
          i == selected.length - 1 ? remaining : rand.nextInt(30) + 10;

      result[selected[i]] = value.toDouble();
      remaining -= value;
    }

    return result;
  }

  // @override
  // Widget build(BuildContext context) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;

  //   return ResponsiveLayout(
  //     mobile: _buildMobileLayout(),
  //     tablet: _buildTabletLayout(),
  //     desktop: _buildDesktopLayout(isDark),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              // Main content
              Expanded(
                child: ResponsiveLayout(
                  mobile: _buildMobileLayout(),
                  tablet: _buildTabletLayout(),
                  desktop: _buildDesktopLayout(isDark),
                ),
              ),

              if (totalPages > 1) _buildPaginationControls(isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container();
  }

  Widget _buildTabletLayout() {
    return Container();
  }

  Widget _buildCombinedAlertsBar(bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;
    final isEV = mode == 'EV Fleet';

    final lowBatteryCount = alertCountModel?.lowBattery ?? 0;
    final lowFuelCount = alertCountModel?.lowFuel ?? 0;
    final highTempCount = alertCountModel?.highTemperature ?? 0;
    final fallCount = alertCountModel?.fall ?? 0;
    final sosCount = alertCountModel?.soS ?? 0;
    final batterycount = alertCountModel?.batteryFault ?? 0;

    final Map<String, int> criticalAlertCounts = {};
    final Map<String, Color> criticalAlertColors = {};

    if (isEV) {
      criticalAlertCounts['Battery Low'] = lowBatteryCount;
      criticalAlertCounts['High Temperature'] = highTempCount;
      criticalAlertCounts['Fall Detected'] = fallCount;
      criticalAlertCounts['SOS Triggered'] = sosCount;
      criticalAlertCounts['Battery Fault'] = batterycount;

      criticalAlertColors['Battery Low'] = tOrange1;
      criticalAlertColors['High Temperature'] = tOrange;
      criticalAlertColors['Fall Detected'] = tPink1;
      criticalAlertColors['SOS Triggered'] = tRed;
      criticalAlertColors['Battery Fault'] = tBlueDark;
    } else {
      criticalAlertCounts['Low Fuel'] = lowFuelCount;
      criticalAlertCounts['High Temperature'] = highTempCount;
      criticalAlertCounts['Fall Detected'] = fallCount;
      criticalAlertCounts['SOS Triggered'] = sosCount;

      criticalAlertColors['Low Fuel'] = tOrange1;
      criticalAlertColors['High Temperature'] = tOrange;
      criticalAlertColors['Fall Detected'] = tPink1;
      criticalAlertColors['SOS Triggered'] = const Color(0xFFFA0E0E);
    }

    // final totalPositiveCount = criticalAlertCounts.values
    //     .where((count) => count > 0)
    //     .fold(0, (a, b) => a + b);

    final total = criticalAlertCounts.values.fold(0, (a, b) => a + b);

    // Show loading state
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Critical Alerts Overview',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: 0.5,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: tOrange1,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Loading...',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              left: 14.0,
                            ),
                            child: Text(
                              '-- [--%]',
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? tWhite : tBlack,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 100,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: tGrey.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Critical Alerts Overview',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? tWhite : tBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Labels and counts in a row
        Row(
          children:
              criticalAlertCounts.entries.map((entry) {
                final label = entry.key;
                final count = entry.value;
                final color = criticalAlertColors[label]!;

                final total = criticalAlertCounts.values.fold(
                  0,
                  (a, b) => a + b,
                );
                final percentage = total > 0 ? (count / total) * 100 : 0.0;

                return Expanded(
                  // ✅ THIS FIXES EVEN SPACING
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// 🔹 Color + Label
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center, // center inside each block
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? tWhite : tBlack,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      /// 🔹 Value + %
                      Text(
                        '$count [${percentage.toStringAsFixed(0)}%]',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),

        const SizedBox(height: 20),

        // Bar chart
        total == 0
            ? Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: isDark ? tGrey.withOpacity(0.3) : tGrey.withOpacity(0.2),
                borderRadius: BorderRadius.zero,
              ),
            )
            : Row(
              children:
                  criticalAlertCounts.entries.map((entry) {
                    final label = entry.key;
                    final count = entry.value;
                    final color = criticalAlertColors[label]!;

                    final total = criticalAlertCounts.values.fold(
                      0,
                      (a, b) => a + b,
                    );

                    final flex =
                        total > 0
                            ? ((count / total) * 100).toInt()
                            : 1; // 👈 keep minimal width

                    return Expanded(
                      flex: flex == 0 ? 1 : flex, // 👈 prevents invisible bars
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color:
                              count > 0
                                  ? color
                                  : Colors.transparent, // 👈 empty if 0
                          border: Border.all(
                            color: color.withOpacity(
                              0.3,
                            ), // 👈 outline for 0 values
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    );
                  }).toList(),
            ),
      ],
    );
  }

  Widget _buildEnhancedLegendItem(
    String label,
    Color color,
    int count,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 12, bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label [$count]',
            style: GoogleFonts.urbanist(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FleetTitleBar(isDark: isDark, title: "Alerts"),
                Row(
                  children: [
                    _buildFilterBySearch(isDark),
                    const SizedBox(width: 10),
                    _buildDynamicDatePicker(isDark),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// 🔹 MAIN CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ================= LEFT SIDE =================
                    Expanded(
                      flex: 4,
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: _cardDecoration(isDark),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      /// TOTAL (FULL HEIGHT)
                                      Expanded(
                                        child: LargeHoverCard(
                                          value: NumberFormat(
                                            '#,##,###',
                                          ).format(
                                            int.tryParse(
                                                  alertsModel?.totalAlerts
                                                          ?.toString() ??
                                                      "0",
                                                ) ??
                                                0,
                                          ),
                                          label: "Total Alerts",
                                          labelColor: tBlue,
                                          icon: "icons/alert.svg",
                                          iconColor: tBlue,
                                          bgColor: tBlue.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      /// MIDDLE (CRITICAL + NON-CRITICAL)
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: SmallHoverCard(
                                                value: NumberFormat(
                                                  '#,##,###',
                                                ).format(
                                                  int.tryParse(
                                                        alertsModel
                                                                ?.criticalAlerts
                                                                ?.toString() ??
                                                            "0",
                                                      ) ??
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

                                            const SizedBox(height: 8),

                                            Expanded(
                                              child: SmallHoverCard(
                                                value: NumberFormat(
                                                  '#,##,###',
                                                ).format(
                                                  int.tryParse(
                                                        alertsModel
                                                                ?.nonCriticalAlerts
                                                                ?.toString() ??
                                                            "0",
                                                      ) ??
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
                                      ),

                                      const SizedBox(width: 10),

                                      /// FAULTS (SAME HEIGHT AS TOTAL ✅)
                                      Expanded(
                                        child: LargeHoverCard(
                                          value:
                                              alertsModel
                                                  ?.attentionNeededVehicles
                                                  ?.toString() ??
                                              "0",
                                          label: "Faults",
                                          labelColor: tRed,
                                          icon: "icons/faults.svg",
                                          iconColor: tRed,
                                          bgColor: tRed.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              /// 🔸 VEHICLE FAULT OVERVIEW
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: _cardDecoration(isDark),
                                child: _buildFaultSection(
                                  title: ' Fault Overview',
                                  faultTypes: allBatteryFaultTypes,
                                  colors: allBatteryFaultColors,
                                  isDark: isDark,
                                ),
                              ),

                              const SizedBox(height: 12),

                              /// 🔸 CRITICAL OVERVIEW (FALL / ALERT BAR)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: _cardDecoration(isDark),
                                child: _buildCombinedAlertsBar(isDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// ================= RIGHT SIDE =================
                    Expanded(
                      flex: 6,
                      child: Container(
                        height: double.infinity,
                        child: _buildAlertsTable(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        /// 🔹 LOADING
        if (isLoading) _buildLoadingOverlay(isDark),
      ],
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color:
          isDark
              ? tBlack.withOpacity(0.8) // 👈 transparent
              : tWhite.withOpacity(0.9),

      border: Border.all(color: tWhite.withOpacity(0.08)),

      boxShadow: [
        BoxShadow(
          blurRadius: 5,
          spreadRadius: 2,
          color:
              isDark
                  ? tTransparent.withOpacity(0.08)
                  : tTransparent.withOpacity(0.1),
        ),
      ],
    );
  }
  // Widget _buildDesktopLayout(bool isDark) {
  //   return Stack(
  //     children: [
  //       Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           /// HEADER
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               FleetTitleBar(isDark: isDark, title: "Alerts"),
  //               Row(
  //                 children: [
  //                   _buildFilterBySearch(isDark),
  //                   const SizedBox(width: 10),
  //                   _buildDynamicDatePicker(isDark),
  //                 ],
  //               ),
  //             ],
  //           ),

  //           const SizedBox(height: 10),

  //           Expanded(
  //             child: SingleChildScrollView(
  //               child: Padding(
  //                 padding: const EdgeInsets.all(10.0),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     /// Top Cards Row
  //                     IntrinsicHeight(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.stretch,
  //                         children: [
  //                           Expanded(
  //                             flex: 4,
  //                             child: Row(
  //                               children: [
  //                                 /// TOTAL ALERTS CARD - Click to show ALL
  //                                 Expanded(
  //                                   child: GestureDetector(
  //                                     onTap: () {
  //                                       setState(() {
  //                                         _selectedAlertCategory =
  //                                             null; // null means ALL
  //                                         currentPage = 1;
  //                                         selectedFilter = 'All';
  //                                       });
  //                                       fetchAlerts();
  //                                     },
  //                                     child: LargeHoverCard(
  //                                       value: NumberFormat('#,##,###').format(
  //                                         int.tryParse(
  //                                               alertsModel?.totalAlerts
  //                                                       ?.toString() ??
  //                                                   "0",
  //                                             ) ??
  //                                             .0,
  //                                       ),
  //                                       label: "Total Alerts",
  //                                       labelColor: tBlue,
  //                                       icon: "icons/alert.svg",
  //                                       iconColor: tBlue,
  //                                       bgColor: tBlue.withOpacity(0.1),
  //                                       isDark: isDark,
  //                                     ),
  //                                   ),
  //                                 ),
  //                                 const SizedBox(width: 10),
  //                                 Expanded(
  //                                   flex: 2,
  //                                   child: Column(
  //                                     children: [
  //                                       /// CRITICAL ALERTS CARD - Click to show CRITICAL
  //                                       Expanded(
  //                                         child: GestureDetector(
  //                                           onTap: () {
  //                                             setState(() {
  //                                               _selectedAlertCategory =
  //                                                   'CRITICAL';
  //                                               currentPage = 1;
  //                                               selectedFilter = 'All';
  //                                             });
  //                                             fetchAlerts();
  //                                           },
  //                                           child: SmallHoverCard(
  //                                             width: double.infinity,
  //                                             height: 70,
  //                                             value: NumberFormat(
  //                                               '#,##,###',
  //                                             ).format(
  //                                               int.tryParse(
  //                                                     alertsModel
  //                                                             ?.criticalAlerts
  //                                                             ?.toString() ??
  //                                                         "0",
  //                                                   ) ??
  //                                                   .0,
  //                                             ),
  //                                             label: "Critical Alerts",
  //                                             labelColor: tOrange1,
  //                                             icon: "icons/alert.svg",
  //                                             iconColor: tOrange1,
  //                                             bgColor: tOrange1.withOpacity(
  //                                               0.1,
  //                                             ),
  //                                             isDark: isDark,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       const SizedBox(height: 11),

  //                                       /// NON-CRITICAL ALERTS CARD - Click to show NON_CRITICAL
  //                                       Expanded(
  //                                         child: GestureDetector(
  //                                           onTap: () {
  //                                             setState(() {
  //                                               _selectedAlertCategory =
  //                                                   'NON_CRITICAL';
  //                                               currentPage = 1;
  //                                               selectedFilter = 'All';
  //                                             });
  //                                             fetchAlerts();
  //                                           },
  //                                           child: SmallHoverCard(
  //                                             width: double.infinity,
  //                                             height: 70,
  //                                             value: NumberFormat(
  //                                               '#,##,###',
  //                                             ).format(
  //                                               int.tryParse(
  //                                                     alertsModel
  //                                                             ?.nonCriticalAlerts
  //                                                             ?.toString() ??
  //                                                         "0",
  //                                                   ) ??
  //                                                   .0,
  //                                             ),
  //                                             label: "Non-Critical Alerts",
  //                                             labelColor: tBlueSky,
  //                                             icon: "icons/alert.svg",
  //                                             iconColor: tBlueSky,
  //                                             bgColor: tBlueSky.withOpacity(
  //                                               0.1,
  //                                             ),
  //                                             isDark: isDark,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ),
  //                                 const SizedBox(width: 10),

  //                                 /// VEHICLE FAULTS CARD
  //                                 Expanded(
  //                                   child: LargeHoverCard(
  //                                     value:
  //                                         alertCountModel?.batteryFault
  //                                             ?.toString() ??
  //                                         "0",
  //                                     label: "Vehicle Faults",
  //                                     labelColor: tRed,
  //                                     icon: "icons/vehicleFaults.svg",
  //                                     iconColor: tRed,
  //                                     bgColor: tRed.withOpacity(0.1),
  //                                     isDark: isDark,
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                           const SizedBox(width: 10),
  //                           Expanded(
  //                             flex: 7,
  //                             child: Container(
  //                               decoration: BoxDecoration(
  //                                 color: isDark ? tBlack : tWhite,
  //                                 boxShadow: [
  //                                   BoxShadow(
  //                                     spreadRadius: 2,
  //                                     blurRadius: 10,
  //                                     color:
  //                                         isDark
  //                                             ? tWhite.withOpacity(0.25)
  //                                             : tBlack.withOpacity(0.15),
  //                                   ),
  //                                 ],
  //                               ),
  //                               padding: const EdgeInsets.only(
  //                                 left: 15,
  //                                 right: 15,
  //                                 top: 10,
  //                               ),
  //                               child: _buildFaultSection(
  //                                 title: 'Vehicle Faults Overview',
  //                                 faultTypes: allBatteryFaultTypes,
  //                                 colors: allBatteryFaultColors,
  //                                 isDark: isDark,
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),

  //                     const SizedBox(height: 20),

  //                     Container(
  //                       padding: const EdgeInsets.all(15),
  //                       decoration: BoxDecoration(
  //                         color: isDark ? tBlack : tWhite,
  //                         boxShadow: [
  //                           BoxShadow(
  //                             spreadRadius: 2,
  //                             blurRadius: 10,
  //                             color:
  //                                 isDark
  //                                     ? tWhite.withOpacity(0.25)
  //                                     : tBlack.withOpacity(0.15),
  //                           ),
  //                         ],
  //                       ),
  //                       child: _buildCombinedAlertsBar(isDark),
  //                     ),

  //                     const SizedBox(height: 20),

  //                     Container(
  //                       height: 600,
  //                       decoration: BoxDecoration(
  //                         // color: isDark ? tBlack : tWhite,
  //                         // boxShadow: [
  //                         //   BoxShadow(
  //                         //     spreadRadius: 2,
  //                         //     blurRadius: 10,
  //                         //     color:
  //                         //         isDark
  //                         //             ? tWhite.withOpacity(0.25)
  //                         //             : tBlack.withOpacity(0.15),
  //                         //   ),
  //                         // ],
  //                       ),
  //                       child: _buildAlertsTable(isDark),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       // if (totalPages > 1)
  //       // Positioned(
  //       //   bottom: 20,
  //       //   left: 0,
  //       //   right: 0,
  //       //   child: Center(child: _buildPaginationControls(isDark)),
  //       // ),
  //       // Positioned(
  //       //   bottom: -5,
  //       //   left: 0,
  //       //   right: 0,
  //       //   child: Center(
  //       //     child: Container(
  //       //       padding: const EdgeInsets.symmetric(
  //       //         horizontal: 16,
  //       //         vertical: 10,
  //       //       ),
  //       //       decoration: BoxDecoration(
  //       //         color: isDark ? tBlack : tWhite, // ✅ background
  //       //         borderRadius: BorderRadius.circular(0),
  //       //         boxShadow: [
  //       //           BoxShadow(
  //       //             blurRadius: 10,
  //       //             spreadRadius: 2,
  //       //             color:
  //       //                 isDark
  //       //                     ? tWhite.withOpacity(0.1)
  //       //                     : tBlack.withOpacity(0.2),
  //       //           ),
  //       //         ],
  //       //       ),
  //       //       child: _buildPaginationControls(isDark),
  //       //     ),
  //       //   ),
  //       // ),
  //       if (isLoading) _buildLoadingOverlay(isDark),
  //     ],
  //   );
  // }

  Widget _buildFilterBySearch(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 250,
          height: 40,
          decoration: BoxDecoration(
            color: tTransparent,
            border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
          ),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? tWhite : tBlack,
            ),
            decoration: InputDecoration(
              hintText: 'Search ',
              hintStyle: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? tWhite : tBlack,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(
                CupertinoIcons.search,
                color: isDark ? tWhite : tBlack,
                size: 18,
              ),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 18,
                          color: isDark ? tWhite : tBlack,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            currentPage = 1;
                          });
                          fetchAlerts();
                        },
                      )
                      : null,
            ),
            onChanged: (query) {
              _searchDebounceTimer?.cancel();
              _searchDebounceTimer = Timer(
                const Duration(milliseconds: 500),
                () {
                  if (!mounted) return;
                  setState(() {
                    _searchQuery = query.trim();
                    currentPage = 1;
                  });
                  fetchAlerts();
                },
              );
            },
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '(Note: Filter by Search)',
          style: GoogleFonts.urbanist(
            fontSize: 10,
            color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicDatePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: tTransparent,
              border: Border.all(width: 0.6, color: isDark ? tWhite : tBlack),
            ),
            child: Center(
              child: Text(
                DateFormat('dd MMM yyyy').format(selectedDate).toUpperCase(),
                style: GoogleFonts.urbanist(
                  fontSize: 12.5,
                  color: isDark ? tWhite : tBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.blueAccent,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        apiDate = DateFormat('yyyy-MM-dd').format(picked);
        currentPage = 1;
      });
      fetchAlerts();
    }
  }

  // Widget _buildFilterTabs(bool isDark) {
  //   final List<String> filters = ['All', 'Devices', 'Geo-Fence', 'Speed'];

  //   return Container(
  //     width: 550,
  //     height: 40,
  //     margin: const EdgeInsets.only(bottom: 10),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: isDark ? tWhite : tBlack, width: 0.6),
  //     ),
  //     padding: const EdgeInsets.all(5),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children:
  //           filters.map((label) {
  //             return Expanded(
  //               child: GestureDetector(
  //                 onTap: () {
  //                   setState(() {
  //                     selectedFilter = label;
  //                     currentPage = 1;
  //                   });
  //                   fetchAlerts();
  //                 },
  //                 child: Container(
  //                   decoration: BoxDecoration(
  //                     color: selectedFilter == label ? tBlue : tTransparent,
  //                   ),
  //                   alignment: Alignment.center,
  //                   child: Text(
  //                     label,
  //                     style: GoogleFonts.urbanist(
  //                       fontSize: 13,
  //                       fontWeight: FontWeight.w600,
  //                       color:
  //                           selectedFilter == label
  //                               ? tWhite
  //                               : (isDark ? tWhite : tBlack),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             );
  //           }).toList(),
  //     ),
  //   );
  // }
  Widget _buildFilterTabs(bool isDark) {
    final List<String> filters = ['All', 'Devices', 'Speed', 'Geo-Fence'];

    return Container(
      width: 550,
      height: 40,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? tWhite : tBlack, width: 0.6),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            filters.map((label) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFilter = label;
                      currentPage = 1;
                    });
                    _updateFilteredAlerts();
                    // Update based on selected filter
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedFilter == label ? tGreen8 : tTransparent,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            selectedFilter == label
                                ? tBlack
                                : (isDark ? tWhite : tBlack),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildAlertsTable(bool isDark) {
    final Map<String, Color> alertColors = {
      'PowerDisconnect': Colors.redAccent,
      'BatteryDisconnect': Colors.orangeAccent,
      'Speed': Colors.deepOrange,
      'OverSpeed': Colors.deepOrange,
      'Ignition On': Colors.green,
      'Ignition Off': Colors.grey,
      'GeoFence': Colors.purpleAccent,
      'Geo Fence Alert': Colors.purpleAccent,
      'Device': Colors.teal,
      'Battery Low': Colors.amber,
      'Tilt': Colors.blueAccent,
      'Fall': Colors.pinkAccent,
      'SOSTriggered': Colors.red,
      'Ignition': Colors.lightGreen,
      'HighTemperature': Colors.orangeAccent.shade100,
      'LowFuel': Colors.amber.shade300,
      'HighRpm': Colors.deepOrangeAccent.shade100,
    };

    final alerts = _filteredAlerts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        return Container(
          width: maxWidth,
          height: maxHeight,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            // color: isDark ? tBlack : tWhite,
            // boxShadow: [
            //   BoxShadow(
            //     blurRadius: 12,
            //     spreadRadius: 2,
            //     color:
            //         isDark ? tWhite.withOpacity(0.12) : tBlack.withOpacity(0.1),
            //   ),
            // ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterTabs(isDark),
              const SizedBox(height: 15),

              // Show message when no data
              if (alerts.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'No ${selectedFilter.toLowerCase()} data available',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: maxWidth - 30),
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
                            columnSpacing: 20,
                            horizontalMargin: 10,
                            border: TableBorder.all(
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.1)
                                      : tBlack.withOpacity(0.1),
                              width: 0.4,
                            ),
                            dividerThickness: 0.01,
                            columns: const [
                              DataColumn(label: Text('IMEI Number')),
                              DataColumn(label: Text('Vehicle ID')),
                              DataColumn(label: Text('Alert Time')),
                              DataColumn(label: Text('Alert Type')),
                              DataColumn(label: Text('Alert Data')),
                            ],
                            rows:
                                alerts.map((alert) {
                                  final isCritical =
                                      alert.alertCategory == "CRITICAL";
                                  final color =
                                      alertColors[alert.alertType] ??
                                      (isDark ? tBlue : Colors.blueGrey);

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          alert.imei ?? "--",
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          alert.vehicleNumber == null ||
                                                  alert.vehicleNumber!.isEmpty
                                              ? "--"
                                              : alert.vehicleNumber!,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          alert.time != null
                                              ? DateFormat(
                                                'dd MMM yyyy, hh:mm a',
                                              ).format(
                                                DateTime.parse(
                                                  alert.time!,
                                                ).toLocal(),
                                              )
                                              : "--",
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(
                                                right: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isCritical
                                                        ? tOrange1
                                                        : tBlueSky,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        isCritical
                                                            ? tOrange1
                                                                .withOpacity(
                                                                  0.4,
                                                                )
                                                            : tBlueSky
                                                                .withOpacity(
                                                                  0.4,
                                                                ),
                                                    blurRadius: 2,
                                                    spreadRadius: 0.5,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2,
                                                    horizontal: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                border: Border.all(
                                                  color: color.withOpacity(0.6),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                alert.alertType ?? "--",
                                                style: GoogleFonts.urbanist(
                                                  color: color,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // DataCell(Text(alert.data ?? "--")),
                                      DataCell(
                                        _buildFormattedAlertData(
                                          alert.data,
                                          isDark,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormattedAlertData(String? data, bool isDark) {
    if (data == null || data == "--" || data.isEmpty) {
      return Text("--");
    }

    if (data.contains("\n")) {
      final parts = data.split("\n");

      if (parts.length >= 2 && parts[0].contains("Status:")) {
        final statusPart = parts[0]; // "Status: on" or "Status: off"
        final valuePart = parts[1]; // numeric value

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusPart,
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? tWhite : tBlack,
              ),
            ),
            Text(
              "Data: $valuePart",
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? tWhite : tBlack,
              ),
            ),
          ],
        );
      }

      // Case 2: Just two lines without "Status:" label
      if (parts.length >= 2) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children:
              parts
                  .map(
                    (part) => Text(
                      part,
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                  )
                  .toList(),
        );
      }
    }

    // Check if data is just a number (without "Status:")
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(data)) {
      return Text("Data: $data");
    }

    // Default display for other data formats
    return Text(data);
  }

  // Widget _buildFaultSection({
  //   required String title,
  //   required Set<String> faultTypes,
  //   required Map<String, Color> colors,
  //   required bool isDark,
  // }) {
  //   // Use real battery fault count from API
  //   final batteryFaultCount = alertCountModel?.batteryFault ?? 0;

  //   // Create data map with real count
  //   final Map<String, double> data = {};
  //   if (batteryFaultCount > 0) {
  //     // For now, just show Battery Fault with 100%
  //     data['Battery Fault'] = 100.0;
  //   }

  //   final total = data.values.fold(0.0, (a, b) => a + b);

  //   final filtered =
  //       data.entries
  //           .where((e) => e.value > 0)
  //           .map(
  //             (e) => {
  //               'label': e.key,
  //               'count': batteryFaultCount, // Use actual count
  //               'color': colors[e.key] ?? tOrange,
  //             },
  //           )
  //           .toList();

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.stretch,
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             title,
  //             style: GoogleFonts.urbanist(
  //               fontSize: 14,
  //               fontWeight: FontWeight.bold,
  //               color: isDark ? tWhite : tBlack,
  //             ),
  //           ),
  //           // Optional: Add total count
  //           Text(
  //             'Total: ${NumberFormat('#,##,###').format(batteryFaultCount)}',
  //             style: GoogleFonts.urbanist(
  //               fontSize: 12,
  //               fontWeight: FontWeight.w500,
  //               color:
  //                   isDark ? tWhite.withOpacity(0.7) : tBlack.withOpacity(0.7),
  //             ),
  //           ),
  //         ],
  //       ),

  //       const SizedBox(height: 12),

  //       if (batteryFaultCount == 0)
  //         SizedBox(
  //           height: 60,
  //           child: Center(
  //             child: Text(
  //               'No battery faults detected',
  //               style: GoogleFonts.urbanist(
  //                 fontSize: 13,
  //                 color:
  //                     isDark
  //                         ? tWhite.withOpacity(0.6)
  //                         : tBlack.withOpacity(0.6),
  //               ),
  //             ),
  //           ),
  //         )
  //       else ...[
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: List.generate(filtered.length, (i) {
  //             final item = filtered[i];
  //             final label = item['label'] as String;
  //             final count = item['count'] as int;
  //             final color = item['color'] as Color;

  //             return Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   // TYPE (label + color box)
  //                   Row(
  //                     children: [
  //                       Container(
  //                         width: 10,
  //                         height: 10,
  //                         decoration: BoxDecoration(
  //                           color: color,
  //                           borderRadius: BorderRadius.circular(2),
  //                         ),
  //                       ),
  //                       const SizedBox(width: 6),
  //                       Flexible(
  //                         child: Text(
  //                           label,
  //                           style: GoogleFonts.urbanist(
  //                             fontSize: 13,
  //                             fontWeight: FontWeight.w600,
  //                             color: isDark ? tWhite : tBlack,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 6),
  //                   // COUNT
  //                   Padding(
  //                     padding: const EdgeInsets.only(top: 10.0, left: 14.0),
  //                     child: Text(
  //                       NumberFormat('#,##,###').format(count),
  //                       style: GoogleFonts.urbanist(
  //                         fontSize: 13,
  //                         fontWeight: FontWeight.w500,
  //                         color: isDark ? tWhite : tBlack,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }),
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: List.generate(filtered.length, (i) {
  //             final item = filtered[i];
  //             final color = item['color'] as Color;

  //             return Expanded(
  //               flex: 100, // Full width since only one fault type
  //               child: Container(
  //                 height: 20,
  //                 decoration: BoxDecoration(
  //                   color: color,
  //                   boxShadow: [
  //                     BoxShadow(
  //                       blurRadius: 6,
  //                       spreadRadius: 2,
  //                       color: color.withOpacity(0.3),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }),
  //         ),
  //       ],
  //     ],
  //   );
  // }
  // Widget _buildFaultSection({
  //   required String title,
  //   required Set<String> faultTypes,
  //   required Map<String, Color> colors,
  //   required bool isDark,
  // }) {
  //   final mode = context.watch<FleetModeProvider>().mode;
  //   final isEV = mode == 'EV Fleet';
  //   // Use real battery fault count from API
  //   final batteryFaultCount = alertCountModel?.batteryFault ?? 0;

  //   final totalAlerts = alertsModel?.totalAlerts ?? 0;

  //   double percentage = 0.0;
  //   if (totalAlerts > 0 && batteryFaultCount > 0) {
  //     percentage = (batteryFaultCount / totalAlerts) * 100;
  //     percentage = percentage.clamp(0.0, 100.0);
  //   }

  //   final faultColor = const Color(0xFFFF9800);

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.stretch,
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             title,
  //             style: GoogleFonts.urbanist(
  //               fontSize: 14,
  //               fontWeight: FontWeight.bold,
  //               color: isDark ? tWhite : tBlack,
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 12),

  //       if (batteryFaultCount == 0)
  //         SizedBox(
  //           height: 80,
  //           child: Center(
  //             child: Text(
  //               isEV
  //                   ? 'No Vehicle  faults detected'
  //                   : 'No  Vehicle  faults detected',
  //               style: GoogleFonts.urbanist(
  //                 fontSize: 13,
  //                 color:
  //                     isDark
  //                         ? tWhite.withOpacity(0.6)
  //                         : tBlack.withOpacity(0.6),
  //               ),
  //             ),
  //           ),
  //         )
  //       else ...[
  //         // Label and percentage
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   // TYPE (label + color box)
  //                   Row(
  //                     children: [
  //                       Container(
  //                         width: 10,
  //                         height: 10,
  //                         decoration: BoxDecoration(
  //                           color: faultColor,
  //                           borderRadius: BorderRadius.circular(2),
  //                         ),
  //                       ),
  //                       const SizedBox(width: 6),
  //                       Flexible(
  //                         child: Text(
  //                           'Battery Fault',
  //                           style: GoogleFonts.urbanist(
  //                             fontSize: 13,
  //                             fontWeight: FontWeight.w600,
  //                             color: isDark ? tWhite : tBlack,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 6),
  //                   // COUNT
  //                   Padding(
  //                     padding: const EdgeInsets.only(top: 10.0, left: 14.0),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           '${NumberFormat('#,##,###').format(batteryFaultCount)} [${percentage.toStringAsFixed(1)}%]',
  //                           style: GoogleFonts.urbanist(
  //                             fontSize: 13,
  //                             fontWeight: FontWeight.w500,
  //                             color: isDark ? tWhite : tBlack,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 20),

  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Container(
  //               width: double.infinity,
  //               height: 20,
  //               decoration: BoxDecoration(
  //                 color:
  //                     isDark ? tGrey.withOpacity(0.3) : tGrey.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(4),
  //               ),
  //               child: Container(
  //                 width: double.infinity,
  //                 height: 20,
  //                 decoration: BoxDecoration(
  //                   color: faultColor,
  //                   borderRadius: BorderRadius.circular(4),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       blurRadius: 6,
  //                       spreadRadius: 2,
  //                       color: faultColor.withOpacity(0.3),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ],
  //   );
  // }
  Widget _buildFaultSection({
    required String title,
    required Set<String> faultTypes,
    required Map<String, Color> colors,
    required bool isDark,
  }) {
    final batteryFaultCount = alertCountModel?.batteryFault ?? 0;

    final hasValue = batteryFaultCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// 🔹 HEADING (STATIC)
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),

        const SizedBox(height: 10),

        /// 🔹 LABEL (STATIC)
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: tGrey,
                borderRadius: BorderRadius.zero,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Fault',
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? tWhite : tBlack,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$batteryFaultCount',
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? tWhite : tBlack,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        /// 🔹 BAR (STATIC LOGIC)
        Container(
          width: double.infinity,
          height: 20,
          decoration: BoxDecoration(
            color: isDark ? tGrey.withOpacity(0.3) : tGrey.withOpacity(0.2),
            borderRadius: BorderRadius.zero,
          ),
          child:
              hasValue
                  ? Container(
                    width: double.infinity,
                    height: 20,
                    decoration: BoxDecoration(
                      color: tGrey, // or use specific fault color if needed
                      borderRadius: BorderRadius.zero,
                    ),
                  )
                  : null, // 👈 empty → grey bar only
        ),
      ],
    );
  }

  Widget _buildAnimatedAlertsBar(
    Map<String, double> data,
    Map<String, Color> colors,
    bool isDark,
  ) {
    double total = data.values.fold(0, (a, b) => a + b);

    return Container(
      width: double.infinity,
      height: 26,
      decoration: BoxDecoration(color: tTransparent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            data.entries.map((entry) {
              double percentage = entry.value / total;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: percentage),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Expanded(
                    flex: (value * 1000).toInt().clamp(1, 1000),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors[entry.key] ?? tGrey,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (colors[entry.key]?.withOpacity(0.4)) ??
                                tGrey.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Tooltip(
                        message:
                            "${entry.key}: ${(entry.value).toStringAsFixed(1)}%",
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

  Widget _buildPaginationControls(bool isDark) {
    const int visiblePageCount = 5;

    int startPage =
        ((currentPage - 1) ~/ visiblePageCount) * visiblePageCount + 1;
    int endPage = (startPage + visiblePageCount - 1).clamp(1, totalPages);

    final pageButtons = <Widget>[];

    for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
      final isSelected = pageNum == currentPage;

      pageButtons.add(
        GestureDetector(
          onTap: () {
            if (!mounted) return;
            setState(() => currentPage = pageNum);
            fetchAlerts();
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
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: isDark ? tWhite : tBlack,
              size: 22,
            ),
            onPressed: () {
              if (!mounted || currentPage <= 1) return;
              setState(() => currentPage--);
              fetchAlerts();
            },
          ),

          Row(children: pageButtons),

          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isDark ? tWhite : tBlack,
              size: 22,
            ),
            onPressed: () {
              if (!mounted || currentPage >= totalPages) return;
              setState(() => currentPage++);
              fetchAlerts();
            },
          ),

          const SizedBox(width: 16),

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
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null &&
                    page >= 1 &&
                    page <= totalPages &&
                    mounted) {
                  setState(() => currentPage = page);
                  fetchAlerts();
                }
              },
            ),
          ),

          const SizedBox(width: 10),

          Text(
            '$startPage–$endPage of $totalPages',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ],
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
                    'Loading alerts...',
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
