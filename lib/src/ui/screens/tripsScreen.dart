import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:excel/excel.dart' as excel;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' show Lottie;
import 'package:provider/provider.dart';
import 'package:svg_flutter/svg.dart';

import '../../models/devicesModel.dart';
import '../../models/tripRoutePlayBackModel.dart';
import '../../models/tripsModel.dart';
import '../../provider/fleetModeProvider.dart';
import '../../services/generalAPIServices.dart/downloadTripApiService.dart';
import '../../services/generalAPIServices.dart/tripsAPIService.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../../utils/route/navigation_helpers.dart';
import '../components/customTitleBar.dart';
import '../widgets/reports/custom_Toast.dart';

class TripsScreen extends StatefulWidget {
  final String initialFilter;
  final String? initialImei;

  const TripsScreen({
    super.key,
    this.initialFilter = "All Trips",
    this.initialImei,
  });

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<Trip> allTrips = [];
  List<Trip> filteredByImeiTrips = [];

  bool isTripsLoading = false;
  int totalCount = 0;
  int completedCount = 0;
  int ongoingCount = 0;
  int totalPages = 0;

  String _mapFilterToPath() {
    switch (selectedFilter) {
      case "Ongoing":
        return "ongoing";
      case "Completed":
        return "completed";
      default:
        return "all";
    }
  }

  // String selectedFilter = "All Trips";
  String searchImei = ''; // Add IMEI search text

  late String selectedFilter;
  Trip? selectedTrip;

  bool _isMapReady = false;
  DateTime selectedDate = DateTime.now();
  String? apiDate;

  // flutter_map controller
  final MapController _mapController = MapController();

  List<LatLng> _routePoints = [];
  List<Data> _playbackData = [];
  Data? _currentPlaybackData;

  double _currentZoom = 17.0;

  Timer? _playTimer;
  bool _isPlaying = false;
  int _playIndex = 0;
  LatLng? _movingMarker;

  final int _tickMs = 750;

  // List<Entities> get filteredTrips {
  //   if (selectedFilter == "Ongoing") {
  //     return allTrips.where((t) => t.tripStatus == 'Ongoing').toList();
  //   } else if (selectedFilter == "Completed") {
  //     return allTrips.where((t) => t.tripStatus == 'Completed').toList();
  //   } else {
  //     return allTrips;
  //   }
  // }
  // Modified getter to apply IMEI filter on top of status filter
  // List<Entities> get filteredTrips {
  //   // First filter by status
  //   List<Entities> statusFiltered;
  //   if (selectedFilter == "Ongoing") {
  //     statusFiltered =
  //         allTrips.where((t) => t.tripStatus == 'Ongoing').toList();
  //   } else if (selectedFilter == "Completed") {
  //     statusFiltered =
  //         allTrips.where((t) => t.tripStatus == 'Completed').toList();
  //   } else {
  //     statusFiltered = allTrips;
  //   }

  //   // Then filter by IMEI if search text is not empty
  //   if (searchImei.trim().isEmpty) {
  //     return statusFiltered;
  //   } else {
  //     return statusFiltered
  //         .where(
  //           (t) =>
  //               t.imei?.toLowerCase().contains(searchImei.toLowerCase()) ??
  //               false,
  //         )
  //         .toList();
  //   }
  // }
  List<Trip> get filteredTrips {
    List<Trip> statusFiltered;

    if (selectedFilter == "Ongoing") {
      statusFiltered = allTrips.where((t) => t.tripStatus == 0).toList();
    } else if (selectedFilter == "Completed") {
      statusFiltered = allTrips.where((t) => t.tripStatus == 1).toList();
    } else {
      statusFiltered = allTrips;
    }

    if (searchImei.trim().isEmpty) {
      return statusFiltered;
    } else {
      return statusFiltered
          .where(
            (t) =>
                t.imei?.toLowerCase().contains(searchImei.toLowerCase()) ??
                false,
          )
          .toList();
    }
  }

  int currentPage = 1;
  int itemsPerPage = 12; // you can tweak this

  List<LatLng> completedPath = [];
  List<LatLng> remainingPath = [];

  final TripsApiService _api = TripsApiService();
  final Downloadtripapiservice _downloadApi = Downloadtripapiservice();

  RoutePlayBackPerTripModel? _routePlayback;
  bool _isRouteLoading = false;

  Future<void> fetchTrips() async {
    if (!mounted) return;

    setState(() => isTripsLoading = true);

    DateTime? dateTimeFilter;
    if (apiDate != null) {
      dateTimeFilter = DateTime.tryParse(apiDate!);
    }

    final imeiToSearch =
        searchImei.isNotEmpty ? searchImei : widget.initialImei;

    final result = await _api.fetchTrips(
      page: currentPage - 1,
      size: itemsPerPage,
      status: _mapFilterToPath(),
      inputDate: dateTimeFilter,
      inputImei: imeiToSearch,
    );

    if (!mounted) return;

    setState(() {
      isTripsLoading = false;

      allTrips = result?.trips ?? [];
      totalCount = result?.totalTripsCount ?? 0;
      completedCount = result?.completedCount ?? 0;
      ongoingCount = result?.ongoingCount ?? 0;

      if (selectedFilter == "Ongoing") {
        totalPages = (ongoingCount / itemsPerPage).ceil();
      } else if (selectedFilter == "Completed") {
        totalPages = (completedCount / itemsPerPage).ceil();
      } else {
        totalPages = (totalCount / itemsPerPage).ceil();
      }

      print("selectedFilter = $selectedFilter");
      print("totalCount = $totalCount");
      print("ongoingCount = $ongoingCount");
      print("completedCount = $completedCount");
      print("totalPages = $totalPages");
    });
  }

  Future<void> _downloadTrip(String tripId) async {
    try {
      final mode = context.read<FleetModeProvider>().mode;
      final isEV = mode == 'EV Fleet';
      CustomToast.show(
        context: context,
        message: "Fetching detailed trip data...",
        type: ToastType.loading,
      );

      final result = await _downloadApi.fetchDetatledTripData(tripId);

      if (!mounted) return;

      if (result == null) {
        CustomToast.show(
          context: context,
          message: "No detailed trip data found",
          type: ToastType.error,
        );
        return;
      }

      if (result.tripStatus == null || result.tripStatus!.isEmpty) {
        CustomToast.show(
          context: context,
          message: "No trip status data available for this trip",
          type: ToastType.error,
        );
        return;
      }

      var excelFile = excel.Excel.createExcel();
      excelFile.delete('Sheet1');

      excel.Sheet sheet = excelFile['Detailed Trip Data'];
      excelFile.setDefaultSheet('Detailed Trip Data');

      // ================= HEADERS =================

      List<excel.CellValue> headers = [
        excel.TextCellValue("Trip ID"),
        excel.TextCellValue("Vehicle Number"),
        excel.TextCellValue("IMEI"),
        excel.TextCellValue("Time"),
        excel.TextCellValue("Latitude"),
        excel.TextCellValue("Longitude"),
        excel.TextCellValue("Speed (km/h)"),
        excel.TextCellValue("Odometer"),
      ];

      if (mode == 'EV Fleet') {
        headers.addAll([
          excel.TextCellValue("SOC"),
          excel.TextCellValue("Location Voltage"),
          excel.TextCellValue("Battery Voltage"),
        ]);
      }

      if (mode != 'EV Fleet') {
        headers.add(excel.TextCellValue("Fuel"));
      }

      sheet.appendRow(headers);

      // ================= DATA ROWS =================

      for (var status in result.tripStatus!) {
        List<excel.CellValue> row = [
          excel.TextCellValue(result.tripId ?? ""),
          excel.TextCellValue(result.vehicleNumber ?? ""),
          excel.TextCellValue(result.imei ?? ""),
          excel.TextCellValue(status.time ?? ""),
          excel.TextCellValue(status.lat ?? ""),
          excel.TextCellValue(status.lng ?? ""),
          excel.TextCellValue(status.speed ?? ""),
          excel.TextCellValue(status.odo ?? ""),
        ];

        // EV -> Battery Details
        if (mode == 'EV Fleet') {
          row.addAll([
            excel.TextCellValue(status.soc ?? ""),
            excel.TextCellValue(status.locVol ?? ""),
            excel.TextCellValue(status.battVol ?? ""),
          ]);
        }

        // Non-EV -> Fuel
        if (mode != 'EV Fleet') {
          row.add(excel.TextCellValue(status.fuel ?? ""));
        }

        sheet.appendRow(row);
      }

      final fileBytes = excelFile.encode();

      if (fileBytes != null) {
        final uint8List = Uint8List.fromList(fileBytes);

        await FileSaver.instance.saveFile(
          name: "Detailed_Trip_Report_${result.tripId}",
          bytes: uint8List,
          ext: "xlsx",
          mimeType: MimeType.microsoftExcel,
        );

        CustomToast.show(
          context: context,
          message: "Trip data downloaded successfully",
          type: ToastType.success,
        );
      } else {
        throw Exception("Failed to encode Excel file");
      }
    } catch (e) {
      print("Trip Download Error: $e");

      CustomToast.show(
        context: context,
        message: "Download failed: ${e.toString()}",
        type: ToastType.error,
      );
    }
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

  List<LatLng> _convertPlaybackDataToLatLng(List<Data> data) {
    return data
        .where(
          (e) =>
              double.tryParse(e.lat ?? '') != null &&
              double.tryParse(e.lng ?? '') != null,
        )
        .map((e) => LatLng(double.parse(e.lat!), double.parse(e.lng!)))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;

    fetchTrips();
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TripsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        selectedFilter = widget.initialFilter;
        currentPage = 1;
        selectedTrip = null;
      });

      fetchTrips();
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  final NumberFormat format = NumberFormat('#,##,###');

  void _startPlayback() {
    if (_routePoints.isEmpty) return;

    // Reset index if at end
    if (_playIndex >= _routePoints.length - 1) {
      _playIndex = 0;
      _movingMarker = _routePoints[0];

      // reset paths
      completedPath = [_routePoints[0]];
      remainingPath = List.from(_routePoints);

      _mapController.move(_movingMarker!, _currentZoom);
    }

    _playTimer?.cancel();
    setState(() => _isPlaying = true);

    _playTimer = Timer.periodic(Duration(milliseconds: _tickMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_playIndex < _routePoints.length - 1) {
        _playIndex++;

        if (_playIndex >= _routePoints.length ||
            _playIndex >= _playbackData.length) {
          timer.cancel();
          return;
        }

        _movingMarker = _routePoints[_playIndex];
        _currentPlaybackData = _playbackData[_playIndex];

        completedPath = _routePoints.sublist(0, _playIndex + 1);
        remainingPath = _routePoints.sublist(_playIndex);

        if (mounted) {
          setState(() {});
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _movingMarker != null) {
            _mapController.move(_movingMarker!, _currentZoom);
          }
        });
      } else {
        timer.cancel();

        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
  }

  void _stopPlayback() {
    _playTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _isPlaying = false;
    });
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lon1 = from.longitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final lon2 = to.longitude * pi / 180;

    final dLon = lon2 - lon1;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double brng = atan2(y, x);
    brng = brng * 180 / pi;
    return (brng + 360) % 360;
  }

  String formatDateTime(String value) {
    if (value.isEmpty) return '--';

    final dateTime = DateTime.tryParse(value);
    if (dateTime == null) return value;

    return DateFormat('dd MMM yyyy hh:mm a').format(dateTime);
  }

  // @override
  // Widget build(BuildContext context) {
  //   return ResponsiveLayout(
  //     mobile: Container(),
  //     tablet: Container(),
  //     desktop: _buildDesktopLayout(),
  //   );
  // }

  // Widget _buildDesktopLayout() {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;

  //   return Stack(
  //     children: [
  //       Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               FleetTitleBar(isDark: isDark, title: "Trips"),
  //               Row(
  //                 children: [
  //                   _buildFilterBySearch(isDark),
  //                   SizedBox(width: 10),
  //                   _buildDynamicDatePicker(isDark),
  //                 ],
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 10),
  //           Expanded(
  //             child: Row(
  //               children: [
  //                 // LEFT PANEL (Trips Grid)
  //                 Expanded(
  //                   flex:
  //                       selectedTrip == null
  //                           ? 10
  //                           : 5, // shrink grid when trip selected
  //                   child: Padding(
  //                     padding: const EdgeInsets.symmetric(horizontal: 10.0),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         // Filter buttons
  //                         Container(
  //                           width: 600,
  //                           height: 40,
  //                           decoration: BoxDecoration(
  //                             border: Border.all(
  //                               color: isDark ? tWhite : tBlack,
  //                               width: 0.6,
  //                             ),
  //                           ),
  //                           padding: const EdgeInsets.all(5),

  //                           child: Row(
  //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                             children: [
  //                               _buildSwapButton("All Trips", isDark),
  //                               _buildSwapButton("Ongoing", isDark),
  //                               _buildSwapButton("Completed", isDark),
  //                             ],
  //                           ),
  //                         ),
  //                         const SizedBox(height: 10),

  //                         // Trips Grid
  //                         Expanded(
  //                           child: GridView.builder(
  //                             gridDelegate:
  //                                 SliverGridDelegateWithFixedCrossAxisCount(
  //                                   crossAxisCount:
  //                                       selectedTrip == null
  //                                           ? 4
  //                                           : 2, // 4 → no selection, 2 → detail open
  //                                   mainAxisSpacing: 12,
  //                                   crossAxisSpacing: 12,
  //                                   childAspectRatio: 1.3,
  //                                 ),
  //                             itemCount: allTrips.length,
  //                             itemBuilder: (context, index) {
  //                               final trip = allTrips[index];
  //                               final bool isSelected =
  //                                   selectedTrip?.id == trip.id;
  //                               return GestureDetector(
  //                                 // onTap: () {
  //                                 //   // if (trip['status'] == 'Completed') {
  //                                 //   //   setState(() {
  //                                 //   //     selectedTrip = trip;
  //                                 //   //   });
  //                                 //   // }
  //                                 //   setState(() {
  //                                 //     selectedTrip = trip;
  //                                 //   });
  //                                 // },
  //                                 onTap: () async {
  //                                   setState(() {
  //                                     selectedTrip = trip;
  //                                     _isRouteLoading = true;
  //                                     _routePlayback = null;
  //                                   });

  //                                   final result = await _api
  //                                       .fetchTripRoutePlayback(trip.id!);

  //                                   if (!mounted || result == null) return;

  //                                   // final points = _convertPlaybackDataToLatLng(
  //                                   //   result.data ?? [],
  //                                   // );
  //                                   _playbackData = result.data ?? [];

  //                                   final points = _convertPlaybackDataToLatLng(
  //                                     _playbackData,
  //                                   );

  //                                   // setState(() {
  //                                   //   _routePoints = points;

  //                                   //   _playIndex = 0;
  //                                   //   _isPlaying = false;

  //                                   //   completedPath =
  //                                   //       points.isNotEmpty
  //                                   //           ? [points.first]
  //                                   //           : [];
  //                                   //   remainingPath = List.from(points);

  //                                   //   _movingMarker =
  //                                   //       points.isNotEmpty
  //                                   //           ? points.first
  //                                   //           : null;
  //                                   //   _isRouteLoading = false;
  //                                   // });
  //                                   setState(() {
  //                                     _routePoints = points;

  //                                     _playIndex = 0;
  //                                     _isPlaying = false;

  //                                     completedPath =
  //                                         points.isNotEmpty
  //                                             ? [points.first]
  //                                             : [];
  //                                     remainingPath = List.from(points);

  //                                     _movingMarker =
  //                                         points.isNotEmpty
  //                                             ? points.first
  //                                             : null;

  //                                     _currentPlaybackData =
  //                                         _playbackData.isNotEmpty
  //                                             ? _playbackData.first
  //                                             : null;

  //                                     _isRouteLoading = false;
  //                                   });

  //                                   if (_routePoints.isNotEmpty) {
  //                                     _mapController.move(
  //                                       _routePoints.first,
  //                                       _currentZoom,
  //                                     );
  //                                   }
  //                                 },
  //                                 child: buildTripCard(
  //                                   isDark: isDark,
  //                                   isSelected: isSelected,
  //                                   tripNumber: trip.id ?? "--",
  //                                   truckNumber: trip.imei ?? "--",
  //                                   status:
  //                                       trip.tripStatus == 0
  //                                           ? "Ongoing"
  //                                           : "Completed",
  //                                   startTime: trip.tripStartTime ?? "--",
  //                                   endTime: trip.tripEndTime ?? "--",
  //                                   durationMins:
  //                                       (trip.totalTime ?? 0).toString(),
  //                                   distanceKm: (trip.totalDistance ?? 0)
  //                                       .toStringAsFixed(1),
  //                                   maxSpeed: (trip.maxSpeed ?? 0).toString(),
  //                                   avgSpeed: (trip.averageSpeed ?? 0)
  //                                       .toStringAsFixed(2),
  //                                   source: trip.startAddress ?? "--",
  //                                   destination: trip.endAddress ?? "--",
  //                                 ),
  //                               );
  //                             },
  //                           ),
  //                         ),

  //                         // Pagination controls
  //                         if (totalPages > 1) _buildPaginationControls(isDark),
  //                       ],
  //                     ),
  //                   ),
  //                 ),

  //                 // RIGHT PANEL (Trip Details)
  //                 if (selectedTrip != null)
  //                   Expanded(
  //                     flex: 5,
  //                     child: Container(
  //                       width: double.infinity,
  //                       decoration: BoxDecoration(
  //                         color:
  //                             isDark
  //                                 ? tWhite.withOpacity(0.05)
  //                                 : tGrey.withOpacity(0.05),
  //                       ),
  //                       child: _buildTripDetailsView(selectedTrip!, isDark),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),

  //       if (isTripsLoading) _buildLoadingOverlay(isDark),
  //     ],
  //   );
  // }
  // Widget _buildDesktopLayout() {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;

  //   return Stack(
  //     children: [
  //       Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               FleetTitleBar(isDark: isDark, title: "Trips"),
  //               Row(
  //                 children: [
  //                   _buildFilterBySearch(isDark),
  //                   SizedBox(width: 10),
  //                   _buildDynamicDatePicker(isDark),
  //                 ],
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 10),
  //           Expanded(
  //             child: Row(
  //               children: [
  //                 Expanded(
  //                   flex: selectedTrip == null ? 10 : 5,
  //                   child: Padding(
  //                     padding: const EdgeInsets.symmetric(horizontal: 10.0),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         // Filter buttons row with IMEI filter display
  //                         Container(
  //                           width: 600,
  //                           height: 40,
  //                           decoration: BoxDecoration(
  //                             border: Border.all(
  //                               color: isDark ? tWhite : tBlack,
  //                               width: 0.6,
  //                             ),
  //                           ),
  //                           padding: const EdgeInsets.all(5),
  //                           child: Row(
  //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                             children: [
  //                               _buildSwapButton("All Trips", isDark),
  //                               _buildSwapButton("Ongoing", isDark),
  //                               _buildSwapButton("Completed", isDark),
  //                             ],
  //                           ),
  //                         ),

  //                         // Show active IMEI filter chip if exists
  //                         if (searchImei.isNotEmpty)
  //                           // Padding(
  //                           //   padding: const EdgeInsets.only(top: 8.0),
  //                           //   child: Container(
  //                           //     padding: const EdgeInsets.symmetric(
  //                           //       horizontal: 8,
  //                           //       vertical: 4,
  //                           //     ),
  //                           //     decoration: BoxDecoration(
  //                           //       color: tBlue.withOpacity(0.1),
  //                           //       borderRadius: BorderRadius.circular(4),
  //                           //       border: Border.all(
  //                           //         color: tBlue.withOpacity(0.3),
  //                           //       ),
  //                           //     ),
  //                           //     // child: Row(
  //                           //     //   mainAxisSize: MainAxisSize.min,
  //                           //     //   children: [
  //                           //     //     Icon(
  //                           //     //       Icons.filter_alt,
  //                           //     //       size: 16,
  //                           //     //       color: tBlue,
  //                           //     //     ),
  //                           //     //     const SizedBox(width: 8),
  //                           //     //     // Text(
  //                           //     //     //   'IMEI: $searchImei',
  //                           //     //     //   style: GoogleFonts.urbanist(
  //                           //     //     //     fontSize: 12,
  //                           //     //     //     fontWeight: FontWeight.w500,
  //                           //     //     //     color: tBlue,
  //                           //     //     //   ),
  //                           //     //     // ),
  //                           //     //     const SizedBox(width: 8),
  //                           //     //     GestureDetector(
  //                           //     //       onTap: _clearImeiFilter,
  //                           //     //       child: Icon(
  //                           //     //         Icons.close,
  //                           //     //         size: 16,
  //                           //     //         color: tBlue,
  //                           //     //       ),
  //                           //     //     ),
  //                           //     //   ],
  //                           //     // ),
  //                           //   ),
  //                           // ),
  //                           const SizedBox(height: 10),

  //                         Expanded(
  //                           child:
  //                               filteredTrips.isEmpty
  //                                   ? Center(
  //                                     child: Column(
  //                                       mainAxisAlignment:
  //                                           MainAxisAlignment.center,
  //                                       children: [
  //                                         Icon(
  //                                           Icons.search_off,
  //                                           size: 48,
  //                                           color:
  //                                               isDark
  //                                                   ? tWhite.withOpacity(0.5)
  //                                                   : tBlack.withOpacity(0.5),
  //                                         ),
  //                                         const SizedBox(height: 16),
  //                                         Text(
  //                                           searchImei.isEmpty
  //                                               ? 'No trips found'
  //                                               : 'No trips found for IMEI: $searchImei',
  //                                           style: GoogleFonts.urbanist(
  //                                             fontSize: 14,
  //                                             color:
  //                                                 isDark
  //                                                     ? tWhite.withOpacity(0.7)
  //                                                     : tBlack.withOpacity(0.7),
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   )
  //                                   : GridView.builder(
  //                                     gridDelegate:
  //                                         SliverGridDelegateWithFixedCrossAxisCount(
  //                                           crossAxisCount:
  //                                               selectedTrip == null ? 4 : 2,
  //                                           mainAxisSpacing: 12,
  //                                           crossAxisSpacing: 12,
  //                                           childAspectRatio: 1.3,
  //                                         ),
  //                                     itemCount: filteredTrips.length,
  //                                     itemBuilder: (context, index) {
  //                                       final trip = filteredTrips[index];
  //                                       final bool isSelected =
  //                                           selectedTrip?.id == trip.id;

  //                                       return buildTripCard(
  //                                         isDark: isDark,
  //                                         isSelected: isSelected,
  //                                         tripNumber: trip.id ?? "--",
  //                                         truckNumber: trip.imei ?? "--",
  //                                         status:
  //                                             trip.tripStatus == 0
  //                                                 ? "Ongoing"
  //                                                 : "Completed",
  //                                         startTime: trip.tripStartTime ?? "--",
  //                                         endTime: trip.tripEndTime ?? "--",
  //                                         durationMins:
  //                                             (trip.totalTime ?? "--")
  //                                                 .toString(),
  //                                         distanceKm:
  //                                             (trip.totalDistance == null ||
  //                                                     trip.totalDistance == 0)
  //                                                 ? "--"
  //                                                 : trip.totalDistance!
  //                                                     .toStringAsFixed(1),
  //                                         maxSpeed:
  //                                             (trip.maxSpeed == null ||
  //                                                     trip.maxSpeed == 0)
  //                                                 ? "--"
  //                                                 : trip.maxSpeed.toString(),
  //                                         avgSpeed:
  //                                             (trip.averageSpeed == null ||
  //                                                     trip.averageSpeed == 0)
  //                                                 ? "--"
  //                                                 : trip.averageSpeed!
  //                                                     .toStringAsFixed(2),
  //                                         SOCConsumed: "--",
  //                                         AvgSOCConsumed: "--",

  //                                         source: trip.startAddress ?? "--",
  //                                         destination: trip.endAddress ?? "--",
  //                                         onTripCardTap: () async {
  //                                           // Original trip card tap logic
  //                                           setState(() {
  //                                             selectedTrip = trip;
  //                                             _isRouteLoading = true;
  //                                             _routePlayback = null;
  //                                           });

  //                                           final result = await _api
  //                                               .fetchTripRoutePlayback(
  //                                                 trip.id!,
  //                                               );
  //                                           if (!mounted || result == null)
  //                                             return;

  //                                           _playbackData = result.data ?? [];
  //                                           final points =
  //                                               _convertPlaybackDataToLatLng(
  //                                                 _playbackData,
  //                                               );

  //                                           setState(() {
  //                                             _routePoints = points;
  //                                             _playIndex = 0;
  //                                             _isPlaying = false;
  //                                             completedPath =
  //                                                 points.isNotEmpty
  //                                                     ? [points.first]
  //                                                     : [];
  //                                             remainingPath = List.from(points);
  //                                             _movingMarker =
  //                                                 points.isNotEmpty
  //                                                     ? points.first
  //                                                     : null;
  //                                             _currentPlaybackData =
  //                                                 _playbackData.isNotEmpty
  //                                                     ? _playbackData.first
  //                                                     : null;
  //                                             _isRouteLoading = false;
  //                                           });

  //                                           if (_routePoints.isNotEmpty) {
  //                                             _mapController.move(
  //                                               _routePoints.first,
  //                                               _currentZoom,
  //                                             );
  //                                           }
  //                                         },
  //                                         onTruckNumberTap: () {
  //                                           // Navigate to device page
  //                                           // You need to import the navigation helper
  //                                           openDeviceOverview(
  //                                             context,
  //                                             DeviceEntity(
  //                                               imei: trip.imei,
  //                                               status:
  //                                                   trip.tripStatus == 0
  //                                                       ? "Ongoing"
  //                                                       : "Completed",
  //                                               odometer:
  //                                                   (trip.totalDistance ?? 0)
  //                                                       .toString(),
  //                                               vehicleNumber:
  //                                                   trip.imei, // or whatever vehicle number field you have
  //                                             ),
  //                                           );
  //                                         },
  //                                       );
  //                                     },
  //                                   ),
  //                         ),
  //                         // Pagination controls (only show when no IMEI filter)
  //                         if (searchImei.isEmpty && totalPages > 1)
  //                           _buildPaginationControls(isDark),
  //                       ],
  //                     ),
  //                   ),
  //                 ),

  //                 // RIGHT PANEL (Trip Details) - same as before
  //                 if (selectedTrip != null)
  //                   Expanded(
  //                     flex: 5,
  //                     child: Container(
  //                       width: double.infinity,
  //                       decoration: BoxDecoration(
  //                         color:
  //                             isDark
  //                                 ? tWhite.withOpacity(0.05)
  //                                 : tGrey.withOpacity(0.05),
  //                       ),
  //                       child: _buildTripDetailsView(selectedTrip!, isDark),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),

  //       if (isTripsLoading) _buildLoadingOverlay(isDark),
  //     ],
  //   );
  // }

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<BreadcrumbItem>? breadcrumbs;
    if (widget.initialImei != null && widget.initialImei!.isNotEmpty) {
      breadcrumbs = [
        BreadcrumbItem(
          label: "Trips",

          onTap: () {
            context.go('/home/trips');
          },
        ),
        BreadcrumbItem(
          label: widget.initialImei!,
          onTap: null, // Current page, not clickable
        ),
      ];
    }

    final List<String> filters = ["All Trips", "Ongoing", "Completed"];

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FleetTitleBar(
                  isDark: isDark,
                  title: "Trips",
                  breadcrumbs: breadcrumbs,
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// SEARCH + DATE
            Row(
              children: [
                Expanded(child: _buildFilterBySearch(isDark)),
                const SizedBox(width: 10),
                _buildDynamicDatePicker(isDark),
              ],
            ),

            const SizedBox(height: 14),

            /// SINGLE CHIP SELECTOR
            Container(
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? tWhite : tBlack, width: 0.6),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children:
                    filters.map((label) {
                      final bool isSelected = selectedFilter == label;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (!mounted) return;

                            setState(() {
                              selectedFilter = label;
                              currentPage = 1;
                            });

                            await fetchTrips();
                          },

                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? tGreen8 : Colors.transparent,
                            ),

                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected
                                        ? tWhite
                                        : (isDark ? tWhite : tBlack),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            /// TRIPS LIST
            Expanded(
              child:
                  filteredTrips.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'icons/nodata1.svg',
                              width: 140,
                              height: 140,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No trips found',
                              style: GoogleFonts.urbanist(
                                fontSize: 14,
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.7)
                                        : tBlack.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: filteredTrips.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final trip = filteredTrips[index];

                          final bool isSelected = selectedTrip?.id == trip.id;

                          return buildTripCard(
                            isDark: isDark,
                            isSelected: isSelected,
                            tripNumber: trip.id ?? "--",
                            truckNumber: trip.imei ?? "--",
                            status:
                                trip.tripStatus == 0 ? "Ongoing" : "Completed",
                            startTime: trip.tripStartTime ?? "--",
                            endTime: trip.tripEndTime ?? "--",
                            durationMins: (trip.totalTime ?? "--").toString(),
                            distanceKm:
                                (trip.totalDistance == null ||
                                        trip.totalDistance == 0)
                                    ? "--"
                                    : trip.totalDistance!.toStringAsFixed(1),
                            maxSpeed:
                                (trip.maxSpeed == null || trip.maxSpeed == 0)
                                    ? "--"
                                    : trip.maxSpeed.toString(),
                            avgSpeed:
                                (trip.averageSpeed == null ||
                                        trip.averageSpeed == 0)
                                    ? "--"
                                    : trip.averageSpeed!.toStringAsFixed(2),
                            StartSOCReading:
                                trip.tripStatus == 0
                                    ? "--"
                                    : (trip.startSOCReading?.toString() ??
                                        "--"),
                            EndSOCReading:
                                trip.tripStatus == 0
                                    ? "--"
                                    : (trip.endSOCReading?.toString() ?? "--"),
                            source: trip.startAddress ?? "--",
                            destination: trip.endAddress ?? "--",

                            /// CARD TAP
                            onTripCardTap: () async {
                              setState(() {
                                selectedTrip = trip;
                                _isRouteLoading = true;
                                _routePlayback = null;
                              });

                              final result = await _api.fetchTripRoutePlayback(
                                trip.id!,
                              );

                              if (!mounted || result == null) {
                                setState(() => _isRouteLoading = false);
                                return;
                              }

                              final playbackData = result.data ?? [];

                              setState(() {
                                _isRouteLoading = false;
                              });

                              if (!mounted) return;

                              // Navigate with raw data - the new page will handle playback internally
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => MobileTripDetailsPage(
                                        trip: trip,
                                        playbackData:
                                            playbackData, // Pass only the raw data
                                      ),
                                ),
                              );
                            },

                            onTruckNumberTap: () {
                              openDeviceOverview(
                                context,
                                DeviceEntity(
                                  imei: trip.imei,
                                  status:
                                      trip.tripStatus == 0
                                          ? "Ongoing"
                                          : "Completed",
                                  odometer:
                                      (trip.totalDistance ?? 0).toString(),
                                  vehicleNumber: trip.imei,
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),

            if (totalPages > 1) _buildPaginationControls(isDark),
          ],
        ),

        if (isTripsLoading) _buildLoadingOverlay(isDark),
      ],
    );
  }

  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<BreadcrumbItem>? breadcrumbs;
    if (widget.initialImei != null && widget.initialImei!.isNotEmpty) {
      breadcrumbs = [
        BreadcrumbItem(
          label: "Trips",

          onTap: () {
            context.go('/home/trips');
          },
        ),
        BreadcrumbItem(
          label: widget.initialImei!,
          onTap: null, // Current page, not clickable
        ),
      ];
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FleetTitleBar(
                  isDark: isDark,
                  title: "Trips",
                  breadcrumbs: breadcrumbs,
                ),
                Row(
                  children: [
                    _buildFilterBySearch(isDark),
                    SizedBox(width: 10),
                    _buildDynamicDatePicker(isDark),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: selectedTrip == null ? 10 : 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter buttons row with IMEI filter display
                          Container(
                            width: 600,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark ? tWhite : tBlack,
                                width: 0.6,
                              ),
                            ),
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSwapButton(
                                  "All Trips",
                                  format.format(totalCount),
                                  isDark,
                                ),
                                _buildSwapButton(
                                  "Ongoing",
                                  format.format(ongoingCount),
                                  isDark,
                                ),
                                _buildSwapButton(
                                  "Completed",
                                  format.format(completedCount),
                                  isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Show active IMEI filter chip if exists
                          if (searchImei.isNotEmpty) const SizedBox(height: 10),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final availableWidth = constraints.maxWidth;

                                final columns = selectedTrip == null ? 2 : 1;
                                final spacing = 12.0;

                                final itemWidth =
                                    (availableWidth - (columns - 1) * spacing) /
                                    columns;

                                return filteredTrips.isEmpty
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Icon(
                                          //   Icons.search_off,
                                          //   size: 48,
                                          //   color:
                                          //       isDark
                                          //           ? tWhite.withOpacity(0.5)
                                          //           : tBlack.withOpacity(0.5),
                                          // ),
                                          SvgPicture.asset(
                                            'icons/nodata1.svg', // your icon
                                            width: 150,
                                            height: 150,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            searchImei.isEmpty
                                                ? 'No trips found'
                                                : 'No trips found',
                                            style: GoogleFonts.urbanist(
                                              fontSize: 14,
                                              color:
                                                  isDark
                                                      ? tWhite.withOpacity(0.7)
                                                      : tBlack.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: spacing,
                                            runSpacing: spacing,
                                            children: List.generate(filteredTrips.length, (
                                              index,
                                            ) {
                                              final trip = filteredTrips[index];
                                              final bool isSelected =
                                                  selectedTrip?.id == trip.id;

                                              return SizedBox(
                                                width: itemWidth,
                                                child: buildTripCard(
                                                  isDark: isDark,
                                                  isSelected: isSelected,
                                                  tripNumber: trip.id ?? "--",
                                                  truckNumber:
                                                      trip.imei ?? "--",
                                                  status:
                                                      trip.tripStatus == 0
                                                          ? "Ongoing"
                                                          : "Completed",
                                                  startTime:
                                                      trip.tripStartTime ??
                                                      "--",
                                                  endTime:
                                                      trip.tripEndTime ?? "--",
                                                  durationMins:
                                                      (trip.totalTime ?? "--")
                                                          .toString(),
                                                  distanceKm:
                                                      (trip.totalDistance ==
                                                                  null ||
                                                              trip.totalDistance ==
                                                                  0)
                                                          ? "--"
                                                          : trip.totalDistance!
                                                              .toStringAsFixed(
                                                                1,
                                                              ),
                                                  maxSpeed:
                                                      (trip.maxSpeed == null ||
                                                              trip.maxSpeed ==
                                                                  0)
                                                          ? "--"
                                                          : trip.maxSpeed
                                                              .toString(),
                                                  avgSpeed:
                                                      (trip.averageSpeed ==
                                                                  null ||
                                                              trip.averageSpeed ==
                                                                  0)
                                                          ? "--"
                                                          : trip.averageSpeed!
                                                              .toStringAsFixed(
                                                                2,
                                                              ),
                                                  StartSOCReading:
                                                      trip.tripStatus == 0
                                                          ? "--"
                                                          : (trip.startSOCReading
                                                                  ?.toString() ??
                                                              "--"),
                                                  EndSOCReading:
                                                      trip.tripStatus == 0
                                                          ? "--"
                                                          : (trip.endSOCReading
                                                                  ?.toString() ??
                                                              "--"),
                                                  source:
                                                      trip.startAddress ?? "--",
                                                  destination:
                                                      trip.endAddress ?? "--",
                                                  onTripCardTap: () async {
                                                    // Original trip card tap logic
                                                    setState(() {
                                                      selectedTrip = trip;
                                                      _isRouteLoading = true;
                                                      _routePlayback = null;
                                                    });

                                                    final result = await _api
                                                        .fetchTripRoutePlayback(
                                                          trip.id!,
                                                        );
                                                    if (!mounted ||
                                                        result == null)
                                                      return;

                                                    _playbackData =
                                                        result.data ?? [];
                                                    final points =
                                                        _convertPlaybackDataToLatLng(
                                                          _playbackData,
                                                        );

                                                    setState(() {
                                                      _routePoints = points;
                                                      _playIndex = 0;
                                                      _isPlaying = false;
                                                      completedPath =
                                                          points.isNotEmpty
                                                              ? [points.first]
                                                              : [];
                                                      remainingPath = List.from(
                                                        points,
                                                      );
                                                      _movingMarker =
                                                          points.isNotEmpty
                                                              ? points.first
                                                              : null;
                                                      _currentPlaybackData =
                                                          _playbackData
                                                                  .isNotEmpty
                                                              ? _playbackData
                                                                  .first
                                                              : null;
                                                      _isRouteLoading = false;
                                                    });

                                                    if (_routePoints
                                                        .isNotEmpty) {
                                                      _mapController.move(
                                                        _routePoints.first,
                                                        _currentZoom,
                                                      );
                                                    }
                                                  },
                                                  onTruckNumberTap: () {
                                                    // Navigate to device page
                                                    openDeviceOverview(
                                                      context,
                                                      DeviceEntity(
                                                        imei: trip.imei,
                                                        status:
                                                            trip.tripStatus == 0
                                                                ? "Ongoing"
                                                                : "Completed",
                                                        odometer:
                                                            (trip.totalDistance ??
                                                                    0)
                                                                .toString(),
                                                        vehicleNumber:
                                                            trip.imei,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    );
                              },
                            ),
                          ),
                          if (totalPages > 1) _buildPaginationControls(isDark),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT PANEL (Trip Details) - same as before
                  if (selectedTrip != null)
                    Expanded(
                      flex: 5,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? tWhite.withOpacity(0.05)
                                  : tGrey.withOpacity(0.05),
                        ),
                        child: _buildTripDetailsView(selectedTrip!, isDark),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (isTripsLoading) _buildLoadingOverlay(isDark),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<BreadcrumbItem>? breadcrumbs;
    if (widget.initialImei != null && widget.initialImei!.isNotEmpty) {
      breadcrumbs = [
        BreadcrumbItem(
          label: "Trips",

          onTap: () {
            context.go('/home/trips');
          },
        ),
        BreadcrumbItem(label: widget.initialImei!, onTap: null),
      ];
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FleetTitleBar(
                  isDark: isDark,
                  title: "Trips",
                  breadcrumbs: breadcrumbs,
                ),
                Row(
                  children: [
                    _buildFilterBySearch(isDark),
                    SizedBox(width: 10),
                    _buildDynamicDatePicker(isDark),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: selectedTrip == null ? 10 : 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter buttons row with IMEI filter display
                          // Container(
                          //   // width: 600,
                          //   width: double.infinity,
                          //   constraints: const BoxConstraints(maxWidth: 600),
                          //   height: 50,
                          //   decoration: BoxDecoration(
                          //     border: Border.all(
                          //       color: isDark ? tWhite : tBlack,
                          //       width: 0.6,
                          //     ),
                          //     borderRadius: BorderRadius.circular(10),
                          //   ),
                          //   padding: const EdgeInsets.all(5),
                          //   child: Row(
                          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //     children: [
                          //       _buildSwapButton(
                          //         "All Trips",
                          //         format.format(totalCount),
                          //         isDark,
                          //       ),
                          //       _buildSwapButton(
                          //         "Ongoing",
                          //         format.format(ongoingCount),
                          //         isDark,
                          //       ),
                          //       _buildSwapButton(
                          //         "Completed",
                          //         format.format(completedCount),
                          //         isDark,
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          Row(
                            children: [
                              _buildTripRibbon(
                                isDark,
                                totalCount: totalCount,
                                ongoingCount: ongoingCount,
                                completedCount: completedCount,
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          // Show active IMEI filter chip if exists
                          if (searchImei.isNotEmpty) const SizedBox(height: 10),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final availableWidth = constraints.maxWidth;

                                final columns = selectedTrip == null ? 4 : 2;
                                final spacing = 12.0;

                                final itemWidth =
                                    (availableWidth - (columns - 1) * spacing) /
                                    columns;

                                return filteredTrips.isEmpty
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Icon(
                                          //   Icons.search_off,
                                          //   size: 48,
                                          //   color:
                                          //       isDark
                                          //           ? tWhite.withOpacity(0.5)
                                          //           : tBlack.withOpacity(0.5),
                                          // ),
                                          SvgPicture.asset(
                                            'icons/nodata1.svg', // your icon
                                            width: 150,
                                            height: 150,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            searchImei.isEmpty
                                                ? 'No trips found'
                                                : 'No trips found',
                                            style: GoogleFonts.urbanist(
                                              fontSize: 14,
                                              color:
                                                  isDark
                                                      ? tWhite.withOpacity(0.7)
                                                      : tBlack.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: spacing,
                                            runSpacing: spacing,
                                            children: List.generate(filteredTrips.length, (
                                              index,
                                            ) {
                                              final trip = filteredTrips[index];
                                              final bool isSelected =
                                                  selectedTrip?.id == trip.id;

                                              return SizedBox(
                                                width: itemWidth,
                                                child: buildTripCard(
                                                  isDark: isDark,
                                                  isSelected: isSelected,
                                                  tripNumber: trip.id ?? "--",
                                                  truckNumber:
                                                      trip.imei ?? "--",
                                                  status:
                                                      trip.tripStatus == 0
                                                          ? "Ongoing"
                                                          : "Completed",
                                                  startTime:
                                                      trip.tripStartTime ??
                                                      "--",
                                                  endTime:
                                                      trip.tripEndTime ?? "--",
                                                  durationMins:
                                                      (trip.totalTime ?? "--")
                                                          .toString(),
                                                  distanceKm:
                                                      (trip.totalDistance ==
                                                                  null ||
                                                              trip.totalDistance ==
                                                                  0)
                                                          ? "--"
                                                          : trip.totalDistance!
                                                              .toStringAsFixed(
                                                                1,
                                                              ),
                                                  maxSpeed:
                                                      (trip.maxSpeed == null ||
                                                              trip.maxSpeed ==
                                                                  0)
                                                          ? "--"
                                                          : trip.maxSpeed
                                                              .toString(),
                                                  avgSpeed:
                                                      (trip.averageSpeed ==
                                                                  null ||
                                                              trip.averageSpeed ==
                                                                  0)
                                                          ? "--"
                                                          : trip.averageSpeed!
                                                              .toStringAsFixed(
                                                                2,
                                                              ),
                                                  StartSOCReading:
                                                      trip.tripStatus == 0
                                                          ? "--"
                                                          : (trip.startSOCReading
                                                                  ?.toString() ??
                                                              "--"),
                                                  EndSOCReading:
                                                      trip.tripStatus == 0
                                                          ? "--"
                                                          : (trip.endSOCReading
                                                                  ?.toString() ??
                                                              "--"),
                                                  source:
                                                      trip.startAddress ?? "--",
                                                  destination:
                                                      trip.endAddress ?? "--",
                                                  onTripCardTap: () async {
                                                    // Original trip card tap logic
                                                    setState(() {
                                                      selectedTrip = trip;
                                                      _isRouteLoading = true;
                                                      _routePlayback = null;
                                                    });

                                                    final result = await _api
                                                        .fetchTripRoutePlayback(
                                                          trip.id!,
                                                        );
                                                    if (!mounted ||
                                                        result == null)
                                                      return;

                                                    _playbackData =
                                                        result.data ?? [];
                                                    final points =
                                                        _convertPlaybackDataToLatLng(
                                                          _playbackData,
                                                        );

                                                    setState(() {
                                                      _routePoints = points;
                                                      _playIndex = 0;
                                                      _isPlaying = false;
                                                      completedPath =
                                                          points.isNotEmpty
                                                              ? [points.first]
                                                              : [];
                                                      remainingPath = List.from(
                                                        points,
                                                      );
                                                      _movingMarker =
                                                          points.isNotEmpty
                                                              ? points.first
                                                              : null;
                                                      _currentPlaybackData =
                                                          _playbackData
                                                                  .isNotEmpty
                                                              ? _playbackData
                                                                  .first
                                                              : null;
                                                      _isRouteLoading = false;
                                                    });

                                                    if (_routePoints
                                                        .isNotEmpty) {
                                                      _mapController.move(
                                                        _routePoints.first,
                                                        _currentZoom,
                                                      );
                                                    }
                                                  },
                                                  onTruckNumberTap: () {
                                                    // Navigate to device page
                                                    openDeviceOverview(
                                                      context,
                                                      DeviceEntity(
                                                        imei: trip.imei,
                                                        status:
                                                            trip.tripStatus == 0
                                                                ? "Ongoing"
                                                                : "Completed",
                                                        odometer:
                                                            (trip.totalDistance ??
                                                                    0)
                                                                .toString(),
                                                        vehicleNumber:
                                                            trip.imei,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    );
                              },
                            ),
                          ),
                          if (totalPages > 1) _buildPaginationControls(isDark),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT PANEL (Trip Details) - same as before
                  if (selectedTrip != null)
                    Expanded(
                      flex: 5,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? tWhite.withOpacity(0.05)
                                  : tGrey.withOpacity(0.05),
                        ),
                        child: _buildTripDetailsView(selectedTrip!, isDark),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        if (isTripsLoading) _buildLoadingOverlay(isDark),
      ],
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
                    'Loading Trips...',
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

    // Determine start and end of visible window
    int startPage =
        ((currentPage - 1) ~/ visiblePageCount) * visiblePageCount + 1;
    int endPage = (startPage + visiblePageCount - 1).clamp(1, totalPages);

    final pageButtons = <Widget>[];
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 1100;

    for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
      final isSelected = pageNum == currentPage;

      pageButtons.add(
        GestureDetector(
          onTap: () {
            if (!mounted) return;
            setState(() => currentPage = pageNum);
            fetchTrips();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? tGreen8 : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    isSelected
                        ? tGreen8
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
                fontSize: isMobile ? 11 : (isTablet ? 12 : 13),
              ),
            ),
          ),
        ),
      );
    }

    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 4),
      child:
          isMobile
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.chevron_left,
                          color: isDark ? tWhite : tBlack,
                          size: 18,
                        ),
                        onPressed: () {
                          if (currentPage > 1) {
                            setState(() => currentPage--);
                            fetchTrips();
                          }
                        },
                      ),

                      Row(children: pageButtons),

                      IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          color: isDark ? tWhite : tBlack,
                          size: 18,
                        ),
                        onPressed: () {
                          if (currentPage < totalPages) {
                            setState(() => currentPage++);
                            fetchTrips();
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 28,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.urbanist(
                            fontSize: 10,
                            color: isDark ? tWhite : tBlack,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Page',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: isDark ? tWhite : tBlack,
                                width: 1,
                              ),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: isDark ? tBlack : tWhite,
                                width: 1.5,
                              ),
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onSubmitted: (value) {
                            final page = int.tryParse(value);

                            if (page != null &&
                                page >= 1 &&
                                page <= totalPages &&
                                mounted) {
                              setState(() => currentPage = page);

                              fetchTrips();
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        '$startPage–$endPage of $totalPages',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,

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
                          if (currentPage > 1) {
                            setState(() => currentPage--);
                            fetchTrips();
                          }
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
                          if (currentPage < totalPages) {
                            setState(() => currentPage++);
                            fetchTrips();
                          }
                        },
                      ),

                      const SizedBox(width: 16),

                      SizedBox(
                        width: 65,
                        height: 32,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,

                          cursorColor: isDark ? tWhite : tBlack,

                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            color: isDark ? tWhite : tBlack,
                            fontWeight: FontWeight.w500,
                          ),

                          decoration: InputDecoration(
                            hintText: 'Page',

                            hintStyle: GoogleFonts.urbanist(
                              fontSize: 12,
                              color: isDark ? tWhite : tBlack,
                            ),

                            filled: true,
                            fillColor: isDark ? tBlack : tWhite,

                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: isDark ? tWhite : tBlack,
                                width: 1,
                              ),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: isDark ? tWhite : tBlack,
                                width: 1.5,
                              ),
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),

                          onSubmitted: (value) {
                            final page = int.tryParse(value);

                            if (page != null &&
                                page >= 1 &&
                                page <= totalPages &&
                                mounted) {
                              setState(() => currentPage = page);

                              fetchTrips();
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
                ),
              ),
    );

    // return Padding(
    //   padding: const EdgeInsets.symmetric(vertical: 10),
    //   child: Row(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: [
    //       /// Previous Button
    //       IconButton(
    //         icon: Icon(
    //           Icons.chevron_left,
    //           color: isDark ? tWhite : tBlack,
    //           size: 22,
    //         ),
    //         onPressed: () {
    //           if (currentPage > 1) {
    //             setState(() => currentPage--);
    //             fetchTrips();
    //           }
    //         },
    //       ),

    //       /// Page Buttons (windowed 5)
    //       Row(children: pageButtons),

    //       /// Next Button
    //       IconButton(
    //         icon: Icon(
    //           Icons.chevron_right,
    //           color: isDark ? tWhite : tBlack,
    //           size: 22,
    //         ),
    //         onPressed: () {
    //           if (currentPage < totalPages) {
    //             setState(() => currentPage++);
    //             fetchTrips();
    //           }
    //         },
    //       ),

    //       const SizedBox(width: 16),

    //       /// Page Input Box
    //       SizedBox(
    //         width: 70,
    //         height: 32,
    //         child: TextField(
    //           controller: controller,
    //           style: GoogleFonts.urbanist(
    //             fontSize: 13,
    //             color: isDark ? tWhite : tBlack,
    //           ),
    //           keyboardType: TextInputType.number,
    //           decoration: InputDecoration(
    //             hintText: 'Page',
    //             hintStyle: GoogleFonts.urbanist(
    //               fontSize: 12,
    //               color: isDark ? Colors.white54 : Colors.black54,
    //             ),
    //             contentPadding: const EdgeInsets.symmetric(
    //               horizontal: 8,
    //               vertical: 4,
    //             ),
    //             enabledBorder: OutlineInputBorder(
    //               borderRadius: BorderRadius.circular(6),
    //               borderSide: BorderSide(
    //                 color: isDark ? Colors.white : Colors.black,
    //                 width: 1,
    //               ),
    //             ),

    //             focusedBorder: OutlineInputBorder(
    //               borderRadius: BorderRadius.circular(6),
    //               borderSide: BorderSide(
    //                 color: isDark ? Colors.white : Colors.black,
    //                 width: 1.5,
    //               ),
    //             ),

    //             border: OutlineInputBorder(
    //               borderRadius: BorderRadius.circular(6),
    //             ),
    //           ),
    //           onSubmitted: (value) {
    //             final page = int.tryParse(value);
    //             if (page != null &&
    //                 page >= 1 &&
    //                 page <= totalPages &&
    //                 mounted) {
    //               setState(() => currentPage = page);
    //               fetchTrips();
    //             }
    //           },
    //         ),
    //       ),

    //       const SizedBox(width: 10),

    //       Text(
    //         '$startPage–$endPage of $totalPages',
    //         style: GoogleFonts.urbanist(
    //           fontSize: 13,
    //           color: isDark ? tWhite : tBlack,
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  // Widget _buildFilterBySearch(bool isDark) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Container(
  //         width: 250,
  //         height: 40,
  //         decoration: BoxDecoration(
  //           color: tTransparent,
  //           border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
  //         ),
  //         child: TextField(
  //           style: GoogleFonts.urbanist(
  //             fontSize: 13,
  //             fontWeight: FontWeight.w500,
  //             color: isDark ? tWhite : tBlack,
  //           ),
  //           decoration: InputDecoration(
  //             hintText: 'Search',
  //             hintStyle: GoogleFonts.urbanist(
  //               fontSize: 13,
  //               fontWeight: FontWeight.w500,
  //               color: isDark ? tWhite : tBlack,
  //             ),
  //             border: InputBorder.none,
  //             prefixIcon: Icon(
  //               CupertinoIcons.search,
  //               color: isDark ? tWhite : tBlack,
  //               size: 18,
  //             ),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(height: 5),
  //       Text(
  //         '(Note: Filter by Search)',
  //         style: GoogleFonts.urbanist(
  //           fontSize: 10,
  //           color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildFilterBySearch(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width:
              isMobile
                  ? 200
                  : (isTablet ? 200 : 250), // Full width on mobile, else fixed
          height: 40,
          decoration: BoxDecoration(
            color: tTransparent,
            border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
          ),
          child: TextField(
            style: GoogleFonts.urbanist(
              fontSize: isMobile ? 12 : (isTablet ? 12 : 13),
              fontWeight: FontWeight.w500,
              color: isDark ? tWhite : tBlack,
            ),
            onChanged: (value) {
              setState(() {
                searchImei = value;
                currentPage = 1;
              });
              fetchTrips();
            },
            cursorColor: isDark ? tWhite : tBlack,
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: GoogleFonts.urbanist(
                fontSize: isMobile ? 12 : (isTablet ? 12 : 13),
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
                  searchImei.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            searchImei = '';
                          });
                        },
                      )
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '(Note:Filter by Search)',
          style: GoogleFonts.urbanist(
            fontSize: 10,
            color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSwapButton(String label, String count, bool isDark) {
    final bool isSelected = selectedFilter == label;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = label;
            currentPage = 1;
          });
          fetchTrips();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? tGreen8 : tTransparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? tWhite : (isDark ? tWhite : tBlack),
                ),
              ),

              const SizedBox(height: 2),

              Text(
                count.toString(),
                style: GoogleFonts.urbanist(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      isSelected
                          ? tWhite.withOpacity(0.9)
                          : (isDark
                              ? tWhite.withOpacity(0.7)
                              : tBlack.withOpacity(0.7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripRibbon(
    bool isDark, {
    required int totalCount,
    required int ongoingCount,
    required int completedCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? tBlack : tWhite,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (isDark ? tWhite : tBlack).withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: (isDark ? tWhite : tBlack).withOpacity(.08)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _tripStatusChip(
            isDark: isDark,
            label: "All Trips",
            count: totalCount,
            color: tBlueSky,
          ),
          _tripStatusChip(
            isDark: isDark,
            label: "Ongoing",
            count: ongoingCount,
            color: tGreen,
          ),
          _tripStatusChip(
            isDark: isDark,
            label: "Completed",
            count: completedCount,
            color: tBlue,
          ),
        ],
      ),
    );
  }

  Widget _tripStatusChip({
    required bool isDark,
    required String label,
    required int count,
    required Color color,
  }) {
    final bool isSelected = selectedFilter == label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            selectedFilter = label;
            currentPage = 1;
          });

          fetchTrips();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(.18) : color.withOpacity(.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(.35),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$label : ",
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                TextSpan(
                  text: "$count",
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget buildTripCard({
  //   required bool isDark,
  //   required bool isSelected,
  //   required String tripNumber,
  //   required String truckNumber,
  //   required String status,
  //   required String startTime,
  //   required String endTime,
  //   required String durationMins,
  //   required String distanceKm,
  //   required String maxSpeed,
  //   required String avgSpeed,
  //   required String source,
  //   required String destination,
  //   required VoidCallback onTruckNumberTap, // Add this parameter

  // }) {
  //   final displayEndTime =
  //       status.toLowerCase() == "ongoing" ? DateTime.now().toUtc() : endTime;
  //   Color statusColor;

  //   switch (status.toLowerCase()) {
  //     case 'ongoing':
  //       statusColor = tGreen;
  //       break;
  //     case 'completed':
  //       statusColor = tBlue;
  //       break;
  //     default:
  //       statusColor = tGrey;
  //   }

  //   return Container(
  //     width: double.infinity,
  //     decoration: BoxDecoration(
  //       color: isDark ? tBlack : tWhite,
  //       // borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: isSelected ? tBlue : tTransparent, width: 2),
  //       boxShadow: [
  //         BoxShadow(
  //           spreadRadius: 2,
  //           blurRadius: 10,
  //           color: isDark ? tWhite.withOpacity(0.1) : tBlack.withOpacity(0.1),
  //         ),
  //       ],
  //     ),
  //     padding: const EdgeInsets.all(10),
  //     child: Column(
  //       children: [
  //         // Header row
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Expanded(
  //               child: Container(
  //                 decoration: BoxDecoration(
  //                   border: Border.all(color: statusColor, width: 1),
  //                   borderRadius: BorderRadius.circular(6),
  //                 ),
  //                 child: Column(
  //                   children: [
  //                     Container(
  //                       width: double.infinity,
  //                       padding: const EdgeInsets.symmetric(vertical: 4),
  //                       decoration: BoxDecoration(
  //                         // color: statusColor,
  //                         gradient: SweepGradient(
  //                           colors: [statusColor, statusColor.withOpacity(0.6)],
  //                         ),
  //                         borderRadius: const BorderRadius.only(
  //                           topLeft: Radius.circular(5),
  //                           topRight: Radius.circular(5),
  //                         ),
  //                       ),
  //                       child: Text(
  //                         truckNumber,
  //                         style: GoogleFonts.urbanist(
  //                           fontSize: 13,
  //                           fontWeight: FontWeight.w700,
  //                           color: tWhite,
  //                         ),
  //                         textAlign: TextAlign.center,
  //                       ),
  //                     ),
  //                     Padding(
  //                       padding: const EdgeInsets.all(4.0),
  //                       child: Text(
  //                         tripNumber,
  //                         overflow: TextOverflow.ellipsis,
  //                         maxLines: 1,
  //                         style: GoogleFonts.urbanist(
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.w600,
  //                           color: isDark ? tWhite : tBlack,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             SizedBox(width: 15),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.end,
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 14,
  //                     vertical: 6,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     // color: statusColor,
  //                     gradient: SweepGradient(
  //                       colors: [statusColor, statusColor.withOpacity(0.6)],
  //                     ),
  //                     borderRadius: BorderRadius.circular(6),
  //                   ),
  //                   child: Text(
  //                     status,
  //                     style: GoogleFonts.urbanist(
  //                       fontSize: 13,
  //                       fontWeight: FontWeight.w600,
  //                       color: tWhite,
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 5),
  //                 // Text(
  //                 //   '$startTime\n$endTime',
  //                 //   style: GoogleFonts.urbanist(
  //                 //     fontSize: 11,
  //                 //     color: isDark ? tWhite : tBlack,
  //                 //     fontWeight: FontWeight.w600,
  //                 //   ),
  //                 // ),
  //                 Text(
  //                   'Start: ${formatDateTime(startTime)}',
  //                   style: GoogleFonts.urbanist(
  //                     fontSize: 11,
  //                     color: isDark ? tWhite : tBlack,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),

  //                 // if (status.toLowerCase() != 'ongoing')
  //                 // Text(
  //                 //   'End: ${formatDateTime(endTime)}',
  //                 //   style: GoogleFonts.urbanist(
  //                 //     fontSize: 11,
  //                 //     color: isDark ? tWhite : tBlack,
  //                 //     fontWeight: FontWeight.w600,
  //                 //   ),
  //                 // ),
  //                 Text(
  //                   'End: ${formatDateTime(displayEndTime.toString())}',
  //                   style: GoogleFonts.urbanist(
  //                     fontSize: 11,
  //                     color: isDark ? tWhite : tBlack,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 10),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             _buildStatColumn(
  //               isDark,
  //               title: 'Trip Duration (min)',
  //               value: durationMins,
  //             ),
  //             _buildStatColumn(
  //               isDark,
  //               title: 'Trip Distance (km)',
  //               value: distanceKm,
  //               alignEnd: true,
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 5),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             _buildStatColumn(
  //               isDark,
  //               title: 'Trip MAX Speed (km/h)',
  //               value: maxSpeed,
  //             ),
  //             _buildStatColumn(
  //               isDark,
  //               title: 'Trip AVG Speed (km/h)',
  //               value: avgSpeed,
  //               alignEnd: true,
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 6),
  //         Divider(
  //           color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
  //           thickness: 0.3,
  //         ),
  //         const SizedBox(height: 6),
  //         Row(
  //           children: [
  //             SvgPicture.asset(
  //               'icons/geofence.svg',
  //               width: 16,
  //               height: 16,
  //               color: tGreen,
  //             ),
  //             const SizedBox(width: 5),
  //             Expanded(
  //               child: Text(
  //                 source,
  //                 style: GoogleFonts.urbanist(
  //                   fontSize: 13,
  //                   color: isDark ? tWhite : tBlack,
  //                 ),
  //                 overflow: TextOverflow.ellipsis,
  //                 maxLines: 1,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 5),
  //         if (status.toLowerCase() != 'ongoing') ...[
  //           Row(
  //             children: [
  //               SvgPicture.asset(
  //                 'icons/geofence.svg',
  //                 width: 16,
  //                 height: 16,
  //                 color: tRedDark,
  //               ),
  //               const SizedBox(width: 5),
  //               Expanded(
  //                 child: Text(
  //                   destination,
  //                   style: GoogleFonts.urbanist(
  //                     fontSize: 13,
  //                     color: isDark ? tWhite : tBlack,
  //                   ),
  //                   overflow: TextOverflow.ellipsis,
  //                   maxLines: 1,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }
  Widget buildTripCard({
    required bool isDark,
    required bool isSelected,
    required String tripNumber,
    required String truckNumber,
    required String status,
    required String startTime,
    required String endTime,
    required String durationMins,
    required String distanceKm,
    required String maxSpeed,
    required String avgSpeed,
    required String source,
    required String destination,
    required VoidCallback onTripCardTap,
    required VoidCallback onTruckNumberTap,
    required String StartSOCReading,
    required String EndSOCReading,
  }) {
    final displayEndTime =
        status.toLowerCase() == "ongoing"
            ? DateTime.now().toIso8601String()
            : endTime;
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'ongoing':
        statusColor = tGreen;
        break;
      case 'completed':
        statusColor = tBlue;
        break;
      default:
        statusColor = tGrey;
    }

    final mode = context.read<FleetModeProvider>().mode;
    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;

    final isTablet = screenWidth >= 600 && screenWidth < 1100;
    return GestureDetector(
      onTap: onTripCardTap, // This handles the entire card tap
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? tBlack : tWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? tGreen8 : tTransparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              spreadRadius: 2,
              blurRadius: 10,
              color: isDark ? tWhite.withOpacity(0.1) : tBlack.withOpacity(0.1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: GestureDetector(
                    onTap: onTruckNumberTap,

                    child: Container(
                      // width: isMobile ? 160 : (isTablet ? 180 : 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: statusColor, width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                              truckNumber,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: tWhite,
                                //   decoration:
                                //       TextDecoration.none, // Indicates clickability
                                // ),
                                // textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              tripNumber,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? tWhite : tBlack,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
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
                              color: tWhite,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Text(
                        //   'Start: ${formatDateTime(startTime)}',
                        //   style: GoogleFonts.urbanist(
                        //     fontSize: 11,
                        //     color: isDark ? tWhite : tBlack,
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                        SizedBox(
                          width:
                              isMobile
                                  ? 90
                                  : isTablet
                                  ? 95
                                  : 130,

                          child: Text(
                            // lastUpdated,
                            'Start: ${formatDateTime(startTime)}',

                            maxLines: 2,
                            softWrap: true,

                            overflow: TextOverflow.visible,

                            textAlign: TextAlign.right,

                            style: GoogleFonts.urbanist(
                              fontSize:
                                  isMobile
                                      ? 11
                                      : isTablet
                                      ? 11
                                      : 12,

                              fontWeight: FontWeight.w500,

                              color: isDark ? tWhite : tBlack,

                              height: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(
                          width:
                              isMobile
                                  ? 90
                                  : isTablet
                                  ? 95
                                  : 130,

                          child: Text(
                            // lastUpdated,
                            'End: ${formatDateTime(displayEndTime.toString())}',

                            maxLines: 2,
                            softWrap: true,

                            overflow: TextOverflow.visible,

                            textAlign: TextAlign.right,

                            style: GoogleFonts.urbanist(
                              fontSize:
                                  isMobile
                                      ? 11
                                      : isTablet
                                      ? 11
                                      : 12,

                              fontWeight: FontWeight.w500,

                              color: isDark ? tWhite : tBlack,

                              height: 1.2,
                            ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn(
                  isDark,
                  title: 'Duration (min)',
                  value: durationMins,
                ),
                _buildStatColumn(
                  isDark,
                  title: 'Distance (km)',
                  value: distanceKm,
                  alignEnd: true,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn(
                  isDark,
                  title: 'MAX Speed (km/h)',
                  value: maxSpeed,
                ),
                _buildStatColumn(
                  isDark,
                  title: 'AVG Speed (km/h)',
                  value: avgSpeed,
                  alignEnd: true,
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (mode == 'EV Fleet')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn(
                    isDark,
                    title: 'SOC Consumed',
                    value:
                        (StartSOCReading == "--" || EndSOCReading == "--")
                            ? "--"
                            : ((double.tryParse(StartSOCReading) ?? 0) -
                                    (double.tryParse(EndSOCReading) ?? 0))
                                .toStringAsFixed(2),
                  ),
                  _buildStatColumn(
                    isDark,
                    title: 'SOC Consumed per km',
                    value:
                        (StartSOCReading == "--" ||
                                EndSOCReading == "--" ||
                                distanceKm == "--")
                            ? "--"
                            : (((double.tryParse(StartSOCReading) ?? 0) -
                                        (double.tryParse(EndSOCReading) ?? 0)) /
                                    (double.tryParse(distanceKm) ?? 1))
                                .toStringAsFixed(1),
                    alignEnd: true,
                  ),
                ],
              ),

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     _buildStatColumn(
            //       isDark,
            //       title: 'SOC Consumed',
            //       value:
            //           (StartSOCReading == "--" || EndSOCReading == "--")
            //               ? "--"
            //               : (() {
            //                 final start = double.tryParse(StartSOCReading) ?? 0;
            //                 final end = double.tryParse(EndSOCReading) ?? 0;
            //                 final result = start - end;

            //                 return result == 0
            //                     ? "--"
            //                     : result.toStringAsFixed(2);
            //               })(),
            //     ),

            //     _buildStatColumn(
            //       isDark,
            //       title: 'SOC Consumed (/km)',
            //       value:
            //           (StartSOCReading == "--" ||
            //                   EndSOCReading == "--" ||
            //                   distanceKm == "--")
            //               ? "--"
            //               : (() {
            //                 final start = double.tryParse(StartSOCReading) ?? 0;
            //                 final end = double.tryParse(EndSOCReading) ?? 0;
            //                 final distance = double.tryParse(distanceKm) ?? 0;

            //                 if (distance == 0) return "--"; // avoid divide by 0

            //                 final result = (start - end) / distance;

            //                 return result == 0
            //                     ? "--"
            //                     : result.toStringAsFixed(1);
            //               })(),
            //       alignEnd: true,
            //     ),
            //   ],
            // ),
            const SizedBox(height: 5),
            Divider(
              color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
              thickness: 0.3,
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                SvgPicture.asset(
                  'icons/geofence.svg',
                  width: 16,
                  height: 16,
                  color: tGreen,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    source,
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      color: isDark ? tWhite : tBlack,
                    ),
                    overflow: TextOverflow.visible,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (status.toLowerCase() != 'ongoing') ...[
              Row(
                children: [
                  SvgPicture.asset(
                    'icons/geofence.svg',
                    width: 16,
                    height: 16,
                    color: tRedDark,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      destination,
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    bool isDark, {
    required String title,
    required String value,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetailsView(Trip trip, bool isDark) {
    return Container(
      height: double.infinity,
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? tWhite.withOpacity(0.05) : tWhite,
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Title + Close)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "#${trip.id ?? '--'}",
                //"#${trip['tripNumber']}",
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),
              IconButton(
                // onPressed: () {
                //   if (Navigator.canPop(context)) {
                //     Navigator.pop(context);
                //   } else {
                //     setState(() {
                //       selectedTrip = null;
                //     });
                //   }
                // },
                onPressed: () {
                  setState(() {
                    selectedTrip = null;

                    _routePoints.clear();
                    completedPath.clear();
                    remainingPath.clear();

                    _movingMarker = null;
                    _currentPlaybackData = null;

                    _playIndex = 0;
                    _isPlaying = false;
                  });

                  _playTimer?.cancel();

                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                icon: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: isDark ? tRed : Colors.redAccent,
                  size: 16,
                ),
                tooltip: "Close",
              ),
            ],
          ),

          Divider(
            color: isDark ? tWhite.withOpacity(0.2) : tBlack.withOpacity(0.1),
            thickness: 0.5,
          ),

          // const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildStyledDetailButton(
                  // () {},1
                  () => _downloadTrip(selectedTrip!.id!),
                  "Download Trip",
                  // CupertinoIcons.download_circle_fill,
                  "icons/download.svg",
                  isDark,
                ),
                const SizedBox(width: 10),
                _buildStyledDetailButton(
                  () => _togglePlayback(),
                  // _isPlaying ? "Pause Playback" : "Route Playback",
                  "Route Playback",
                  CupertinoIcons.map_fill,

                  isDark,
                ),
                const SizedBox(width: 10),
                _buildStyledDetailButton(
                  () => _togglePlayback(),
                  _isPlaying ? "Pause " : "Resume ",
                  _isPlaying
                      ? CupertinoIcons.pause_circle_fill
                      : CupertinoIcons.play_arrow_solid,

                  isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          // Map placeholder
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    isDark ? tWhite.withOpacity(0.1) : tBlack.withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(2),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      onMapReady: () {
                        _isMapReady = true;
                      },
                      initialCenter:
                          _routePoints.isNotEmpty
                              ? _routePoints.first
                              : LatLng(12.9716, 77.5946),
                      initialZoom: _currentZoom,
                      onPositionChanged: (position, _) {
                        _currentZoom = position.zoom ?? _currentZoom;
                      },
                    ),

                    children: [
                      TileLayer(
                        urlTemplate:
                            isDark
                                ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.app',
                      ),

                      // Route polyline
                      PolylineLayer(
                        polylines: [
                          if (completedPath.length > 1)
                            Polyline(
                              points: completedPath,
                              strokeWidth: 6,
                              color: Colors.lightBlueAccent.withOpacity(0.6),
                            ),

                          if (remainingPath.length > 1)
                            Polyline(
                              points: remainingPath,
                              strokeWidth: 6,
                              color: tGreen8,
                            ),
                        ],
                      ),

                      // Marker layer: start, end, and moving marker
                      MarkerLayer(
                        markers: [
                          if (_routePoints.isNotEmpty)
                            Marker(
                              point: _routePoints.first,
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tWhite, // inner dot
                                  boxShadow: [
                                    BoxShadow(
                                      color: tGreen.withOpacity(0.7),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                  border: Border.all(color: tGreen, width: 4),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.circle,
                                    size: 16,
                                    color: tGreen,
                                  ),
                                ),
                              ),
                            ),

                          if (_routePoints.length > 1)
                            Marker(
                              point: _routePoints.last,
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tWhite,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tRedDark.withOpacity(0.7),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                  border: Border.all(color: tRedDark, width: 4),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.circle,
                                    size: 14,
                                    color: tRedDark,
                                  ),
                                ),
                              ),
                            ),

                          // moving marker (only when there is a position)
                          if (_movingMarker != null)
                            Marker(
                              point: _movingMarker!,
                              width: 40,
                              height: 40,
                              child: Transform.rotate(
                                angle:
                                    (_playIndex < _routePoints.length - 1)
                                        ? _calculateBearing(
                                              _routePoints[_playIndex],
                                              _routePoints[_playIndex + 1],
                                            ) *
                                            pi /
                                            180
                                        : 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: tGreen8.withOpacity(0.8),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.navigation_rounded,
                                    size: 25,
                                    color: tWhite,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  // SPEED & ODOMETER OVERLAY
                  if (_currentPlaybackData != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? tBlack.withOpacity(0.7)
                                  : tWhite.withOpacity(0.9),
                          // borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: tBlack.withOpacity(0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _mapInfoRow(
                              "Speed",
                              _currentPlaybackData!.speed ?? '0',
                              isDark,
                            ),
                            const SizedBox(height: 4),
                            _mapInfoRow(
                              "Odo",
                              _currentPlaybackData!.odo ?? '0',
                              isDark,
                            ),
                            // _mapInfoRow(
                            //   "Lat",
                            //   _currentPlaybackData!.lat ?? '0',
                            //   isDark,
                            // ),
                            _mapInfoRow(
                              "Location",
                              _currentPlaybackData!.address ?? '0',
                              isDark,
                            ),
                            // _mapInfoRow(
                            //   "Lng",
                            //   _currentPlaybackData!.lng ?? '0',
                            //   isDark,
                            // ),
                            _mapInfoRow(
                              "Time",
                              formatDateTime(_currentPlaybackData!.time ?? '0'),
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Playback progress / info
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text(
          //       'Playback: ${_playIndex + 1}/${_routePoints.length}',
          //       style: GoogleFonts.urbanist(fontSize: 13),
          //     ),
          //     Text(
          //       trip.startAddress ?? '', // trip['source'] ?? '',
          //       style: GoogleFonts.urbanist(
          //         fontSize: 13,
          //         color: Colors.grey[600],
          //       ),
          //     ),
          //   ],
          // ),
          Row(
            children: [
              Text(
                'Playback: ${_playIndex + 1}/${_routePoints.length}',
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  trip.startAddress ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Future<void> _selectDate() async {
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: selectedDate,
  //     firstDate: DateTime(2023),
  //     lastDate: DateTime.now(),
  //     builder:
  //         (context, child) => Theme(
  //           data: Theme.of(context).copyWith(
  //             colorScheme: const ColorScheme.light(
  //               primary: Colors.blueAccent,
  //               onPrimary: Colors.white,
  //               onSurface: Colors.black,
  //             ),
  //           ),
  //           child: child!,
  //         ),
  //   );

  //   if (picked != null && picked != selectedDate) {
  //     setState(() {
  //       selectedDate = picked;
  //       apiDate = DateFormat('yyyy-MM-dd').format(picked);
  //       currentPage = 1;
  //     });

  //     fetchTrips();
  //   }
  // }
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
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
        apiDate = DateFormat('yyyy-MM-dd').format(picked); // Keep as string
        currentPage = 1;
      });

      fetchTrips();
    }
  }

  // Widget _buildDynamicDatePicker(bool isDark) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       GestureDetector(
  //         onTap: _selectDate,
  //         child: Container(
  //           height: 40,
  //           padding: const EdgeInsets.symmetric(horizontal: 10),
  //           decoration: BoxDecoration(
  //             color: tTransparent,
  //             border: Border.all(width: 0.6, color: isDark ? tWhite : tBlack),
  //           ),
  //           child: Center(
  //             child: Text(
  //               selectedDate == null
  //                   ? 'SELECT DATE'
  //                   : DateFormat(
  //                     'dd MMM yyyy',
  //                   ).format(selectedDate!).toUpperCase(),
  //               style: GoogleFonts.urbanist(
  //                 fontSize: 12.5,
  //                 color: isDark ? tWhite : tBlack,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(height: 5),
  //       Text(
  //         '(Note: Filter by Date)',
  //         style: GoogleFonts.urbanist(
  //           fontSize: 10,
  //           color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //     ],
  //   );
  // }
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

  // Modern elevated action buttons
  Widget _buildStyledDetailButton(
    VoidCallback onPressed,
    String text,
    dynamic icon,
    bool isDark,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1100;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon:
          icon is String
              ? SvgPicture.asset(
                icon,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  isDark ? tWhite : tGreen8,
                  BlendMode.srcIn,
                ),
              )
              : Icon(
                icon as IconData,
                size: 18,
                color: isDark ? tWhite : tGreen8,
              ),
      label: Text(
        text,
        style: GoogleFonts.urbanist(
          fontSize: isMobile || isTablet ? 12 : 13,
          fontWeight: FontWeight.w600,
          color: tGreen8,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? tBlack : tWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tGreen8, width: 1),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _mapInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: GoogleFonts.urbanist(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.urbanist(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- INLINE DETAIL SCREEN (MOBILE/TABLET) ----------------
class TripDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('Trip ${trip['tripNumber']} Details')),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(CupertinoIcons.cloud_download, size: 16),
                  label: const Text("Download Trip"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(CupertinoIcons.play_arrow_solid, size: 16),
                  label: const Text("Route Playback"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                color:
                    isDark ? tWhite.withOpacity(0.08) : tGrey.withOpacity(0.08),
                alignment: Alignment.center,
                child: Text(
                  "Map View Here",
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileTripDetailsPage extends StatefulWidget {
  final Trip trip;
  final List<Data> playbackData;

  const MobileTripDetailsPage({
    super.key,
    required this.trip,
    required this.playbackData,
  });

  @override
  State<MobileTripDetailsPage> createState() => _MobileTripDetailsPageState();
}

class _MobileTripDetailsPageState extends State<MobileTripDetailsPage> {
  late MapController _mapController;
  List<LatLng> _routePoints = [];
  List<LatLng> _completedPath = [];
  List<LatLng> _remainingPath = [];
  LatLng? _movingMarker;
  Data? _currentPlaybackData;
  int _playIndex = 0;
  bool _isPlaying = false;
  Timer? _playTimer;
  double _currentZoom = 17.0;
  final int _tickMs = 750;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeRoute();
  }

  void _initializeRoute() {
    _routePoints =
        widget.playbackData
            .where((e) => e.lat != null && e.lng != null)
            .map((e) => LatLng(double.parse(e.lat!), double.parse(e.lng!)))
            .toList();

    if (_routePoints.isNotEmpty) {
      _movingMarker = _routePoints.first;
      _completedPath = [_routePoints.first];
      _remainingPath = List.from(_routePoints);
      _currentPlaybackData =
          widget.playbackData.isNotEmpty ? widget.playbackData.first : null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isMapReady && _routePoints.isNotEmpty) {
          _mapController.move(_routePoints.first, _currentZoom);
        }
      });
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_routePoints.isEmpty) return;

    // Reset if at end
    if (_playIndex >= _routePoints.length - 1) {
      _playIndex = 0;
      _movingMarker = _routePoints[0];
      _completedPath = [_routePoints[0]];
      _remainingPath = List.from(_routePoints);
      _currentPlaybackData =
          widget.playbackData.isNotEmpty ? widget.playbackData.first : null;
      if (_isMapReady) {
        _mapController.move(_movingMarker!, _currentZoom);
      }
    }

    _playTimer?.cancel();
    setState(() => _isPlaying = true);

    _playTimer = Timer.periodic(Duration(milliseconds: _tickMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_playIndex < _routePoints.length - 1) {
        setState(() {
          _playIndex++;
          _movingMarker = _routePoints[_playIndex];
          _currentPlaybackData = widget.playbackData[_playIndex];
          _completedPath = _routePoints.sublist(0, _playIndex + 1);
          _remainingPath = _routePoints.sublist(_playIndex);
        });

        if (_isMapReady && _movingMarker != null) {
          _mapController.move(_movingMarker!, _currentZoom);
        }
      } else {
        timer.cancel();
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _stopPlayback() {
    _playTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lon1 = from.longitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final lon2 = to.longitude * pi / 180;
    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double brng = atan2(y, x);
    brng = brng * 180 / pi;
    return (brng + 360) % 360;
  }

  String formatDateTime(String value) {
    if (value.isEmpty) return '--';
    final dateTime = DateTime.tryParse(value);
    if (dateTime == null) return value;
    return DateFormat('dd MMM yyyy hh:mm a').format(dateTime);
  }

  Future<void> _downloadTrip(String tripId) async {
    try {
      final downloadApi = Downloadtripapiservice();
      final mode = context.read<FleetModeProvider>().mode;
      CustomToast.show(
        context: context,
        message: "Fetching detailed trip data...",
        type: ToastType.loading,
      );

      final result = await downloadApi.fetchDetatledTripData(tripId);

      if (!mounted) return;

      if (result == null) {
        CustomToast.show(
          context: context,
          message: "No detailed trip data found",
          type: ToastType.error,
        );
        return;
      }

      // ... rest of download logic (same as your existing _downloadTrip method)
      var excelFile = excel.Excel.createExcel();
      excelFile.delete('Sheet1');

      excel.Sheet sheet = excelFile['Detailed Trip Data'];
      excelFile.setDefaultSheet('Detailed Trip Data');

      List<excel.CellValue> headers = [
        excel.TextCellValue("Trip ID"),
        excel.TextCellValue("Vehicle Number"),
        excel.TextCellValue("IMEI"),
        excel.TextCellValue("Time"),
        excel.TextCellValue("Latitude"),
        excel.TextCellValue("Longitude"),
        excel.TextCellValue("Speed (km/h)"),
        excel.TextCellValue("Odometer"),
      ];

      if (mode == 'EV Fleet') {
        headers.addAll([
          excel.TextCellValue("SOC"),
          excel.TextCellValue("Location Voltage"),
          excel.TextCellValue("Battery Voltage"),
        ]);
      }

      if (mode != 'EV Fleet') {
        headers.add(excel.TextCellValue("Fuel"));
      }

      sheet.appendRow(headers);

      for (var status in result.tripStatus!) {
        List<excel.CellValue> row = [
          excel.TextCellValue(result.tripId ?? ""),
          excel.TextCellValue(result.vehicleNumber ?? ""),
          excel.TextCellValue(result.imei ?? ""),
          excel.TextCellValue(status.time ?? ""),
          excel.TextCellValue(status.lat ?? ""),
          excel.TextCellValue(status.lng ?? ""),
          excel.TextCellValue(status.speed ?? ""),
          excel.TextCellValue(status.odo ?? ""),
        ];

        if (mode == 'EV Fleet') {
          row.addAll([
            excel.TextCellValue(status.soc ?? ""),
            excel.TextCellValue(status.locVol ?? ""),
            excel.TextCellValue(status.battVol ?? ""),
          ]);
        }

        if (mode != 'EV Fleet') {
          row.add(excel.TextCellValue(status.fuel ?? ""));
        }

        sheet.appendRow(row);
      }

      final fileBytes = excelFile.encode();

      if (fileBytes != null) {
        final uint8List = Uint8List.fromList(fileBytes);

        await FileSaver.instance.saveFile(
          name: "Detailed_Trip_Report_${result.tripId}",
          bytes: uint8List,
          ext: "xlsx",
          mimeType: MimeType.microsoftExcel,
        );

        CustomToast.show(
          context: context,
          message: "Trip data downloaded successfully",
          type: ToastType.success,
        );
      } else {
        throw Exception("Failed to encode Excel file");
      }
    } catch (e) {
      print("Trip Download Error: $e");
      CustomToast.show(
        context: context,
        message: "Download failed: ${e.toString()}",
        type: ToastType.error,
      );
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111111) : tWhite,
      appBar: AppBar(
        title: Text(
          "Trip #${widget.trip.id ?? '--'}",
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? tWhite : tBlack),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : tWhite,
        elevation: 0,
      ),
      body: _buildTripDetailsView(),
    );
  }

  Widget _buildTripDetailsView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStyledDetailButton(
                  () => _downloadTrip(widget.trip.id!),
                  "Download Trip",
                  // CupertinoIcons.download_circle,
                  "icons/download.svg",
                  isDark,
                ),
                const SizedBox(width: 10),
                _buildStyledDetailButton(
                  _togglePlayback,
                  "Route Playback",
                  CupertinoIcons.map_fill,
                  isDark,
                ),
                const SizedBox(width: 10),
                _buildStyledDetailButton(
                  _togglePlayback,
                  _isPlaying ? "Pause" : "Resume",
                  _isPlaying
                      ? CupertinoIcons.pause_circle_fill
                      : CupertinoIcons.play_arrow_solid,
                  isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Map
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    isDark ? tWhite.withOpacity(0.1) : tBlack.withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(2),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      onMapReady: () {
                        _isMapReady = true;
                        if (_routePoints.isNotEmpty) {
                          _mapController.move(_routePoints.first, _currentZoom);
                        }
                      },
                      initialCenter:
                          _routePoints.isNotEmpty
                              ? _routePoints.first
                              : LatLng(12.9716, 77.5946),
                      initialZoom: _currentZoom,
                      onPositionChanged: (position, _) {
                        _currentZoom = position.zoom ?? _currentZoom;
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            isDark
                                ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.app',
                      ),
                      PolylineLayer(
                        polylines: [
                          if (_completedPath.length > 1)
                            Polyline(
                              points: _completedPath,
                              strokeWidth: 6,
                              color: Colors.lightBlueAccent.withOpacity(0.6),
                            ),
                          if (_remainingPath.length > 1)
                            Polyline(
                              points: _remainingPath,
                              strokeWidth: 6,
                              color: tGreen8,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          if (_routePoints.isNotEmpty)
                            Marker(
                              point: _routePoints.first,
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tWhite,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tGreen.withOpacity(0.7),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                  border: Border.all(color: tGreen, width: 4),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.circle,
                                    size: 16,
                                    color: tGreen,
                                  ),
                                ),
                              ),
                            ),
                          if (_routePoints.length > 1)
                            Marker(
                              point: _routePoints.last,
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tWhite,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tRedDark.withOpacity(0.7),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                  border: Border.all(color: tRedDark, width: 4),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.circle,
                                    size: 14,
                                    color: tRedDark,
                                  ),
                                ),
                              ),
                            ),
                          if (_movingMarker != null)
                            Marker(
                              point: _movingMarker!,
                              width: 40,
                              height: 40,
                              child: Transform.rotate(
                                angle:
                                    (_playIndex < _routePoints.length - 1)
                                        ? _calculateBearing(
                                              _routePoints[_playIndex],
                                              _routePoints[_playIndex + 1],
                                            ) *
                                            pi /
                                            180
                                        : 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: tGreen8.withOpacity(0.8),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.navigation_rounded,
                                    size: 25,
                                    color: tWhite,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (_currentPlaybackData != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? tBlack.withOpacity(0.7)
                                  : tWhite.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: tBlack.withOpacity(0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _mapInfoRow(
                              "Speed",
                              _currentPlaybackData!.speed ?? '0',
                              isDark,
                            ),
                            const SizedBox(height: 4),
                            _mapInfoRow(
                              "Odo",
                              _currentPlaybackData!.odo ?? '0',
                              isDark,
                            ),
                            // _mapInfoRow(
                            //   "Lat",
                            //   _currentPlaybackData!.lat ?? '0',
                            // ),
                            // _mapInfoRow(
                            //   "Lng",
                            //   _currentPlaybackData!.lng ?? '0',
                            // ),
                            _mapInfoRow(
                              "Location",
                              _currentPlaybackData!.address ?? '0',
                              isDark,
                            ),
                            _mapInfoRow(
                              "Time",
                              formatDateTime(_currentPlaybackData!.time ?? '0'),
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Playback progress
          Row(
            children: [
              Text(
                'Playback: ${_playIndex + 1}/${_routePoints.length}',
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.trip.startAddress ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyledDetailButton(
    VoidCallback onPressed,
    String text,
    dynamic icon,
    bool isDark,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon:
          icon is String
              ? SvgPicture.asset(
                icon,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  isDark ? tWhite : tGreen8,
                  BlendMode.srcIn,
                ),
              )
              : Icon(
                icon as IconData,
                size: 18,
                color: isDark ? tWhite : tGreen8,
              ),
      label: Text(
        text,
        style: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tGreen8,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? tBlack : tWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tGreen8, width: 1),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _mapInfoRow(String label, String value, bool isDark) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          "$label: ",
          style: GoogleFonts.urbanist(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.urbanist(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ),
      ],
    );
  }
}
