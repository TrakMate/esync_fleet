import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:esync_fleet/src/models/devicesMapModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart' show Lottie;
import 'package:provider/provider.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../models/devicesModel.dart';
import '../../provider/fleetModeProvider.dart';
import '../../services/generalAPIServices.dart/dashboardAPIService.dart';
import '../../services/generalAPIServices.dart/deviceAPIServices/deviceAPIService.dart';
import '../../services/getAddressService.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../../utils/route/navigation_helpers.dart';
import '../components/customTitleBar.dart';
import '../widgets/reports/custom_Toast.dart';

class DevicesScreen extends StatefulWidget {
  final String? filterStatus;
  final String? vehicleFilter;
  final String? soc;
  const DevicesScreen({
    super.key,
    this.soc,
    this.vehicleFilter,
    this.filterStatus,
  });

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  OverlayEntry? _devicePopup;
  final GlobalKey _mapKey = GlobalKey();
  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();

  bool imeiCopied = false;
  bool vehicleCopied = false;

  Set<String> hoveredDevices = {}; //hover for devices
  bool isSatelliteView = false;
  bool isMapFullscreen = false;

  int _totalCountFromAPI = 0;

  final DashboardApiService _dashboardApi = DashboardApiService();

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

  String? get dateParam => apiDate;
  DateTime selectedDate = DateTime.now();
  String? apiDate;

  String? selectedGroup;

  final List<String> _nonEVStatuses = [
    'Moving',
    'Stopped',
    'Idle',
    'Non Coverage',
    'Disconnected',
  ];
  final List<String> _evStatuses = [
    'Charging',
    'DisCharging',
    'Idle',
    'Non Coverage',
    'Disconnected',
  ];
  final Map<String, String> statusApiMap = {
    'Moving': 'moving',
    'Stopped': 'stopped',
    'Idle': 'idle',
    'Non Coverage': 'non_coverage',
    'Disconnected': 'disconnected',
    'Charging': 'charging',
    'DisCharging': 'discharging',
  };

  final Map<String, String> NonEvstatusApiMap = {
    'Moving': 'moving',
    'Stopped': 'stopped',
    'Idle': 'idle',
    'Non Coverage': 'non_coverage',
    'Disconnected': 'disconnected',
  };

  final Map<String, String> EvstatusApiMap = {
    'Charging': 'charging',
    'DisCharging': 'discharging',
    'Idle': 'idle',
    'Non Coverage': 'non_coverage',
    'Disconnected': 'disconnected',
  };

  final List<String> _filterValues = [
    'Max Odo',
    'Max Trips Count',
    'Max Alerts',
    'Max SOC',
    "Min SOC",
  ];

  final List<String> _selectedStatuses = [];
  final List<String> _selectedFilterValues = [];

  bool _showFilterPanel = false;

  final Map<String, Color> _nonEVStatusColors = {
    'Moving': tGreen,
    'Stopped': tRed,
    'Idle': tOrange1,
    'Non Coverage': const Color(0xFF9C27B0),
    'Disconnected': tGrey,
  };

  final Map<String, Color> _evStatusColors = {
    'DisCharging': tGreen,
    'Charging': tBlue,
    'Idle': tOrange1,
    'Non Coverage': const Color(0xFF9C27B0),
    'Disconnected': tGrey,
  };

  final ValueNotifier<LatLng> _centerNotifier = ValueNotifier(
    LatLng(13.0827, 80.2707),
  );
  final ValueNotifier<double> _zoomNotifier = ValueNotifier<double>(4.25);

  bool _isZooming = false;
  Timer? _zoomDebounceTimer;
  Timer? _positionDebounceTimer;
  Timer? _searchDebounceTimer;
  bool _routeWasActive = false;

  int currentPage = 1;
  int itemsPerPage = 10;
  List<String> _tempSelectedStatuses = [];
  List<String> _tempSelectedFilterValues = [];
  final DevicesApiService _api = DevicesApiService();

  List<DeviceEntity> _allDevices = [];
  List<DeviceEntity> _filteredDevices = [];
  // Add this near your other lists
  List<Entities> _allMapDevices = [];
  List<Entities> _filteredMapDevices = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _loading = false;

  late final List<Marker> _cachedMarkers;

  final List<String> _truckIconPaths = [
    'icons/indicationIcons/cycmoving.svg',
    'icons/indicationIcons/cycstopped.svg',
    'icons/indicationIcons/cycidle.svg',
    'icons/indicationIcons/cycdisconnected.svg',
    'icons/indicationIcons/cycnoncoverage.svg',
    'icons/indicationIcons/cycdischarging.svg',
  ];

  final Map<String, Future<String>> _addressCache = {};
  bool _hasMoreData = true;
  bool _isPaginationLoading = false;

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loading &&
        !_isPaginationLoading &&
        _hasMoreData) {
      _loadMoreDevices();
    }
  }

  Future<String> getCachedAddress(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return Future.value('--');
    }

    final key = '$lat,$lng';

    return _addressCache.putIfAbsent(
      key,
      () => getAddressFromLatLngWeb(lat, lng),
    );
  }

  Future<void> _loadMoreDevices() async {
    if (_isPaginationLoading || !_hasMoreData) return;

    setState(() {
      _isPaginationLoading = true;
    });

    try {
      currentPage++;

      String? statusForAPI;

      final mode = context.read<FleetModeProvider>().mode;

      final currentMap =
          mode == 'EV Fleet' ? EvstatusApiMap : NonEvstatusApiMap;

      if (_selectedStatuses.isNotEmpty) {
        statusForAPI = _selectedStatuses
            .map((e) => currentMap[e] ?? e.toLowerCase().replaceAll(' ', '_'))
            .join(',');
      } else if (widget.filterStatus != null &&
          widget.filterStatus!.isNotEmpty) {
        statusForAPI = widget.filterStatus;
      }

      final res = await _api.fetchDevices(
        currentIndex: currentPage - 1,
        sizePerPage: itemsPerPage,
        status: statusForAPI,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        selectedStatuses: null,
        SOC: widget.soc,
        vehicleFilter: widget.vehicleFilter,
      );

      final newDevices = res.entities ?? [];

      if (mounted) {
        setState(() {
          if (newDevices.isEmpty) {
            _hasMoreData = false;
          } else {
            _allDevices.addAll(newDevices);
            _applyFilters();
          }
        });
      }
    } catch (e) {
      print("Pagination Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isPaginationLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeSelectedStatuses();
    _tempSelectedStatuses = List.from(_selectedStatuses);
    _tempSelectedFilterValues = List.from(_selectedFilterValues);
    _scrollController.addListener(_scrollListener);
    _loadDevices(); // Load paginated list
    _loadDevicesForMap(); // Load ALL devices for map

    fetchVehicleDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    final isCurrent = route?.isCurrent ?? false;

    if (_routeWasActive && !isCurrent) {
      _removeDeviceTooltip();
    }

    _routeWasActive = isCurrent;
  }

  void _initializeSelectedStatuses() {
    if (widget.vehicleFilter != null && widget.vehicleFilter!.isNotEmpty) {
      // Clear status selections when vehicle filter is active
      _selectedStatuses.clear();
      _tempSelectedStatuses.clear();
      return;
    }
    if (widget.filterStatus != null && widget.filterStatus!.isNotEmpty) {
      final displayStatus = _convertApiStatusToDisplay(widget.filterStatus!);
      _selectedStatuses.clear();
      _tempSelectedStatuses.clear();
      if (displayStatus != null) {
        _selectedStatuses.add(displayStatus);
        _tempSelectedStatuses.add(displayStatus);
      }
    }
  }

  // void _initializeSelectedStatuses() {
  //   if (widget.filterStatus != null && widget.filterStatus!.isNotEmpty) {
  //     final displayStatus = _convertApiStatusToDisplay(widget.filterStatus!);
  //     _selectedStatuses.clear();
  //     _tempSelectedStatuses.clear();
  //     if (displayStatus != null) {
  //       _selectedStatuses.add(displayStatus);
  //       _tempSelectedStatuses.add(displayStatus);
  //     }
  //   }
  // }

  String? _convertApiStatusToDisplay(String apiStatus) {
    for (var entry in statusApiMap.entries) {
      if (entry.value.toLowerCase() == apiStatus.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }

  bool _statusFilterModified = false;

  Future<void> _loadDevicesForMap() async {
    try {
      final devicesMapApi = DevicesMapApiService();

      String? statusToUse;
      String? vehicleFilterToUse;

      final mode = context.read<FleetModeProvider>().mode;
      final currentMap =
          mode == 'EV Fleet' ? EvstatusApiMap : NonEvstatusApiMap;

      if (_selectedStatuses.isEmpty &&
          widget.vehicleFilter != null &&
          widget.vehicleFilter!.isNotEmpty) {
        vehicleFilterToUse = widget.vehicleFilter;
      } else {
        vehicleFilterToUse = null;
      }

      if (_selectedStatuses.isNotEmpty) {
        statusToUse = _selectedStatuses
            .map((s) {
              final mapped = currentMap[s];
              if (mapped != null) {
                return mapped.replaceAll('_', ' ');
              }
              return s.toLowerCase();
            })
            .join(',');
      } else if (!_statusFilterModified &&
          widget.filterStatus != null &&
          widget.filterStatus!.isNotEmpty) {
        statusToUse = widget.filterStatus!.toLowerCase().replaceAll('_', ' ');
      } else {
        statusToUse = null; // All
      }
      print(
        ' Map API Call - Status: $statusToUse, VehicleFilter: $vehicleFilterToUse',
      );

      final res = await devicesMapApi.fetchDevicesMap(
        status: statusToUse,
        vehicleFilter: vehicleFilterToUse,
      );

      if (mounted) {
        setState(() {
          _allMapDevices = res.entities ?? [];
          _applyMapFilters();
        });
      }
    } catch (e) {
      print(' Error loading devices for map: $e');
    }
  }

  String? get socFilter => widget.soc;

  Future<void> _loadDevices({int? page}) async {
    if (_loading) return;

    setState(() {
      _loading = true;
      if (page != null) {
        currentPage = page;
      }
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    try {
      String? statusForAPI;

      final mode = context.read<FleetModeProvider>().mode;
      final currentMap =
          mode == 'EV Fleet' ? EvstatusApiMap : NonEvstatusApiMap;

      String? vehicleFilterToUse;

      if (_selectedStatuses.isEmpty &&
          _searchQuery.isEmpty &&
          widget.vehicleFilter != null &&
          widget.vehicleFilter!.isNotEmpty) {
        vehicleFilterToUse = widget.vehicleFilter;
      } else {
        vehicleFilterToUse = null;
      }

      // if (_selectedStatuses.isNotEmpty) {
      //   statusForAPI = _selectedStatuses
      //       .map((e) => currentMap[e] ?? e.toLowerCase().replaceAll(' ', '_'))
      //       .join(',');
      // } else if (widget.filterStatus != null &&
      //     widget.filterStatus!.isNotEmpty &&
      //     _selectedStatuses.isEmpty) {
      //   statusForAPI = widget.filterStatus;
      // }
      if (_selectedStatuses.isNotEmpty) {
        statusForAPI = _selectedStatuses
            .map((e) => currentMap[e] ?? e.toLowerCase().replaceAll(' ', '_'))
            .join(',');
      } else if (!_statusFilterModified &&
          widget.filterStatus != null &&
          widget.filterStatus!.isNotEmpty) {
        statusForAPI = widget.filterStatus;
      } else {
        statusForAPI = null; // All
      }

      print(
        ' API Call - Status: $statusForAPI, VehicleFilter: $vehicleFilterToUse',
      );

      final res = await _api.fetchDevices(
        currentIndex: currentPage - 1,
        sizePerPage: itemsPerPage,
        status: statusForAPI,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        selectedStatuses: null,
        SOC: widget.soc,
        vehicleFilter: vehicleFilterToUse, // Use conditional value
      );

      if (mounted) {
        setState(() {
          _allDevices = res.entities ?? [];
          _hasMoreData = (res.entities ?? []).length >= itemsPerPage;
          _totalCountFromAPI = res.totalCount ?? 0;
          _applyFilters();
        });
      }
    } catch (e) {
      print('❌ Error loading devices: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> fetchVehicleDetails({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);

    try {
      final response = await _dashboardApi.fetchVehicleDetails(
        date: dateParam,
        groupId: selectedGroup,
      );
      if (!mounted) return;
      setState(() {
        // VEHICLES
        totalVehicles = response.totalVehicles ?? 0;

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
      });
    } catch (e) {
      debugPrint("Dashboard API error: $e");
    } finally {
      if (showLoading && mounted) setState(() => _loading = false);
    }
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

  num safeNum(dynamic value) {
    if (value == null) return 0;

    if (value is num) return value;

    String str = value.toString().replaceAll('%', '').trim();

    return num.tryParse(str) ?? 0;
  }

  int get totalPages =>
      (_totalCountFromAPI / itemsPerPage).ceil().clamp(1, 999);

  void _applyFilters() {
    List<DeviceEntity> listResult = List.from(_allDevices);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      listResult =
          listResult.where((d) {
            return (d.imei ?? '').toLowerCase().contains(q) ||
                (d.vehicleNumber ?? '').toLowerCase().contains(q) ||
                (d.status ?? '').toLowerCase().contains(q);
          }).toList();
    }

    if (_selectedStatuses.isNotEmpty) {
      final selectedLower =
          _selectedStatuses.map((s) => s.toLowerCase()).toSet();
      listResult =
          listResult.where((d) {
            return selectedLower.contains((d.status ?? '').toLowerCase());
          }).toList();
    }

    if (_selectedFilterValues.contains('Max Odo')) {
      listResult.sort((a, b) => safeInt(b.odometer) - safeInt(a.odometer));
    } else if (_selectedFilterValues.contains('Max Trips Count')) {
      listResult.sort(
        (a, b) => (b.totalTrips ?? 0).compareTo(a.totalTrips ?? 0),
      );
    } else if (_selectedFilterValues.contains('Max SOC')) {
      listResult.sort((a, b) => safeNum(b.soc).compareTo(safeNum(a.soc)));
    } else if (_selectedFilterValues.contains('Min SOC')) {
      listResult.sort((a, b) => safeNum(a.soc).compareTo(safeNum(b.soc)));
    } else if (_selectedFilterValues.contains('Max Alerts')) {
      listResult.sort(
        (a, b) => (b.totalAlerts ?? 0).compareTo(a.totalAlerts ?? 0),
      );
    }

    _filteredDevices = listResult;

    _applyMapFilters();
  }

  String normalizeStatus(String value) {
    return value.toLowerCase().replaceAll('_', ' ').trim();
  }

  void _applyMapFilters() {
    List<Entities> result = List.from(_allMapDevices);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result =
          result.where((d) {
            return (d.imei ?? '').toLowerCase().contains(q) ||
                (d.vehicleNumber ?? '').toLowerCase().contains(q) ||
                (d.status ?? '').toLowerCase().contains(q);
          }).toList();
    }

    if (_selectedStatuses.isNotEmpty) {
      final selectedLower =
          _selectedStatuses.map((s) => s.toLowerCase()).toSet();
      result =
          result.where((d) {
            return selectedLower.contains((d.status ?? '').toLowerCase());
          }).toList();
    }

    _filteredMapDevices = result;
  }

  int safeInt(dynamic value) {
    if (value == null) return 0;

    String s = value.toString().trim();

    s = s.replaceAll(RegExp(r'[^0-9]'), '');

    if (s.isEmpty) return 0;

    return int.tryParse(s) ?? 0;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _zoomDebounceTimer?.cancel();
    _positionDebounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _removeDeviceTooltip();
    _centerNotifier.dispose();
    _zoomNotifier.dispose();
    super.dispose();
  }

  List<Marker> _buildMarkersFromDevices(List<Entities> devices) {
    return devices.where((d) => d.lat != null && d.lng != null).map((device) {
      final pos = LatLng(device.lat!, device.lng!);
      final statusLower = (device.status ?? '').toLowerCase();

      final iconPath = switch (statusLower) {
        'moving' => _truckIconPaths[0],
        'stopped' => _truckIconPaths[1],
        'idle' => _truckIconPaths[2],
        'disconnected' => _truckIconPaths[3],
        'non coverage' => _truckIconPaths[4],
        'non_coverage' => _truckIconPaths[4],
        'charging' => _truckIconPaths[5],
        _ => _truckIconPaths[0],
      };

      return Marker(
        key: ValueKey('${device.imei}|${device.status}'),
        point: pos,
        width: 35,
        height: 35,
        child: GestureDetector(
          onTap: () {
            final projected = _mapController.camera.projectAtZoom(
              pos,
              _mapController.camera.zoom,
            );

            final pixelOrigin = _mapController.camera.pixelOrigin;

            // Position inside the FlutterMap widget
            final localPosition = Offset(
              projected.dx - pixelOrigin.dx,
              projected.dy - pixelOrigin.dy,
            );

            final RenderBox mapBox =
                _mapKey.currentContext!.findRenderObject() as RenderBox;

            // Convert local map coordinate to global screen coordinate
            final globalPosition = mapBox.localToGlobal(localPosition);

            _showMapDeviceTooltip(
              device,
              pos,
              Theme.of(context).brightness == Brightness.dark,
              globalPosition: globalPosition,
            );
          },
          child: SvgPicture.asset(iconPath),
        ),
      );
    }).toList();
  }

  // Helper method to find DeviceEntity by imei
  DeviceEntity? _findDeviceEntity(String? imei) {
    if (imei == null) return null;
    return _allDevices.firstWhere(
      (d) => d.imei == imei,
      orElse: () => DeviceEntity(), // Return empty if not found
    );
  }

  // Helper method to find DeviceEntity by imei

  List<DeviceEntity> get paginatedDevices {
    return _filteredDevices;
  }

  // int get totalPages =>
  //     (_filteredDevices.length / itemsPerPage).ceil().clamp(1, 999);

  void _changeZoom(double delta) {
    _zoomDebounceTimer?.cancel();
    final tentativeZoom = (_zoomNotifier.value + delta).clamp(3.0, 18.0);
    _zoomDebounceTimer = Timer(const Duration(milliseconds: 140), () async {
      if (!mounted) return;
      if (_isZooming) return;
      _isZooming = true;
      try {
        _mapController.move(_centerNotifier.value, tentativeZoom);
        _zoomNotifier.value = tentativeZoom;
        await Future.delayed(const Duration(milliseconds: 120));
      } finally {
        _isZooming = false;
      }
    });
  }

  void _zoomIn() => _changeZoom(1.0);
  void _zoomOut() => _changeZoom(-1.0);

  void _onMapPositionChanged(dynamic position, bool hasGesture) {
    if (hasGesture) {
      _removeDeviceTooltip();
    }

    _positionDebounceTimer?.cancel();
    _positionDebounceTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      try {
        final newCenter = position.center as LatLng?;
        final newZoom = position.zoom as double?;
        if (newCenter != null) _centerNotifier.value = newCenter;
        if (newZoom != null) _zoomNotifier.value = newZoom;
      } catch (_) {}
    });
  }

  Map<String, dynamic> _getClusterInfo(List<Marker> markers) {
    int moving = 0, stopped = 0, idle = 0;

    for (final marker in markers) {
      final key = marker.key;

      if (key is ValueKey<String>) {
        final parts = key.value.split('|');
        if (parts.length < 2) continue;

        final status = parts[1].toLowerCase();

        switch (status) {
          case 'moving':
            moving++;
            break;
          case 'stopped':
            stopped++;
            break;
          case 'idle':
            idle++;
            break;
        }
      }
    }

    if (moving >= stopped && moving >= idle && moving > 0) {
      return {'color': tGreen.withOpacity(0.85), 'textColor': Colors.white};
    } else if (stopped >= moving && stopped >= idle && stopped > 0) {
      return {'color': tRed.withOpacity(0.85), 'textColor': Colors.white};
    } else if (idle > 0) {
      return {'color': tOrange1.withOpacity(0.9), 'textColor': tBlack};
    } else {
      return {
        'color': Colors.blueAccent.withOpacity(0.8),
        'textColor': Colors.white,
      };
    }
  }

  void _showMapDeviceTooltip(
    Entities device,
    LatLng position,
    bool isDark, {
    required Offset globalPosition,
  }) {
    _removeDeviceTooltip();

    const double popupWidth = 220;
    const double popupHeight = 160;
    const double gap = 8;

    final RenderBox mapBox =
        _mapKey.currentContext!.findRenderObject() as RenderBox;

    final Offset mapOffset = mapBox.localToGlobal(Offset.zero);
    final Size mapSize = mapBox.size;

    final double mapLeft = mapOffset.dx;
    final double mapTop = mapOffset.dy;
    final double mapRight = mapLeft + mapSize.width;
    final double mapBottom = mapTop + mapSize.height;

    // --------------------------------------------------
    // Vertical positioning
    // --------------------------------------------------

    final double spaceAbove = globalPosition.dy - mapTop;
    final double spaceBelow = mapBottom - globalPosition.dy;

    bool showAbove;

    if (spaceAbove > popupHeight + gap) {
      showAbove = true;
    } else if (spaceBelow > popupHeight + gap) {
      showAbove = false;
    } else {
      showAbove = spaceAbove > spaceBelow;
    }

    double top =
        showAbove
            ? globalPosition.dy - popupHeight - gap
            : globalPosition.dy + gap;

    // --------------------------------------------------
    // Horizontal positioning
    // --------------------------------------------------

    double left = globalPosition.dx - (popupWidth / 2);

    // Keep inside map horizontally
    if (left < mapLeft + 4) {
      left = mapLeft + 4;
    }

    if (left + popupWidth > mapRight - 4) {
      left = mapRight - popupWidth - 4;
    }

    // Keep inside map vertically
    if (top < mapTop + 4) {
      top = mapTop + 4;
    }

    if (top + popupHeight > mapBottom - 4) {
      top = mapBottom - popupHeight - 4;
    }

    _devicePopup = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeDeviceTooltip,
            child: Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Material(
                      color: Colors.transparent,
                      elevation: 10,
                      child: Container(
                        width: popupWidth,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? tBlack : tWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? tWhite : tBlack,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  isDark
                                      ? Colors.black.withOpacity(0.5)
                                      : Colors.grey.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Device Details',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? tWhite : tBlack,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _removeDeviceTooltip,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          isDark
                                              ? Colors.grey[800]
                                              : Colors.grey[300],
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: isDark ? tWhite : tBlack,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Divider(
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.3)
                                      : tBlack.withOpacity(0.3),
                              thickness: 0.5,
                            ),

                            const SizedBox(height: 6),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'IMEI',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isDark
                                              ? tWhite.withOpacity(0.8)
                                              : tBlack.withOpacity(0.8),
                                    ),
                                  ),
                                  Flexible(
                                    child: GestureDetector(
                                      onTap: () {
                                        _removeDeviceTooltip();

                                        openDeviceOverview(
                                          context,
                                          DeviceEntity(
                                            imei: device.imei,
                                            status: device.status,
                                            odometer: device.odometer,
                                            lat: device.lat,
                                            lng: device.lng,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isDark
                                                  ? Colors.blue.withOpacity(0.2)
                                                  : Colors.blue.withOpacity(
                                                    0.1,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          device.imei ?? '--',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.urbanist(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isDark ? tGreen8 : tGreenDark,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            _deviceInfoRow(
                              'Status',
                              device.status ?? '--',
                              isDark,
                            ),

                            _deviceInfoRow(
                              'ODO',
                              device.odometer ?? '--',
                              isDark,
                            ),

                            _deviceInfoRow(
                              "Location",
                              device.address ?? '--',
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true)?.insert(_devicePopup!);
  }

  void _removeDeviceTooltip() {
    _devicePopup?.remove();
    _devicePopup = null;
  }

  Widget _deviceInfoRow(
    String title,
    String value,
    bool isDark, {
    bool showLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.urbanist(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? tWhite.withOpacity(0.8) : tBlack.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showLoading)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? tWhite : tBlack,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? tWhite : tBlack,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegends() {
    final mode = context.watch<FleetModeProvider>().mode;
    return Positioned(
      left: 12,
      bottom: 12,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tWhite.withOpacity(0.9),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              mode == 'EV Fleet'
                  ? _evStatusColors.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: e.value),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            e.key,
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              color: tBlack,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()
                  : _nonEVStatusColors.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: e.value),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            e.key,
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              color: tBlack,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
        ),
      ),
    );
  }

  Widget _buildClusterMap() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use filtered map devices instead of filtered list devices
    final markers = _buildMarkersFromDevices(_filteredMapDevices);

    return Stack(
      children: [
        FlutterMap(
          key: _mapKey,
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centerNotifier.value,
            initialZoom: _zoomNotifier.value,
            maxZoom: 18,
            minZoom: 3,
            onPositionChanged:
                (position, hasGesture) =>
                    _onMapPositionChanged(position, hasGesture),
          ),
          children: [
            // TileLayer(
            //   urlTemplate:
            //       isDark
            //           ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
            //           : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            //   userAgentPackageName: 'com.example.app',
            //"https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png"
            // ),
            TileLayer(
              urlTemplate:
                  isSatelliteView
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : (isDark
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),

              subdomains: const ['a', 'b', 'c'],

              userAgentPackageName: 'com.example.app',
            ),

            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 60,
                size: const Size(35, 35),
                markers: markers,
                disableClusteringAtZoom: 13,
                builder: (context, clusterMarkers) {
                  final info = _getClusterInfo(clusterMarkers);
                  final color = info['color'] as Color;
                  final textColor = info['textColor'] as Color;
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: SweepGradient(
                        colors: [color, color.withOpacity(0.6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.35),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      clusterMarkers.length.toString(),
                      style: GoogleFonts.urbanist(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Legends
            _buildLegends(),
          ],
        ),

        if (isMapFullscreen)
          Positioned(top: 12, left: 12, child: _buildFleetRibbon(isDark)),
        //Map View
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            height: 42,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? tBlack.withOpacity(.85)
                      : Colors.white.withOpacity(.95),
              borderRadius: BorderRadius.circular(0),
              boxShadow: [
                BoxShadow(color: tBlack.withOpacity(.15), blurRadius: 10),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mapViewTab(
                  title: "Map",
                  selected: !isSatelliteView,
                  onTap: () {
                    setState(() {
                      isSatelliteView = false;
                    });
                  },
                ),

                _mapViewTab(
                  title: "Satellite",
                  selected: isSatelliteView,
                  onTap: () {
                    setState(() {
                      isSatelliteView = true;
                    });
                  },
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 65,
          right: 12,
          child: GestureDetector(
            onTap: () {
              setState(() {
                isMapFullscreen = true;
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? tBlack.withOpacity(.85)
                        : Colors.white.withOpacity(.95),
                borderRadius: BorderRadius.circular(0),
                border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
                boxShadow: [
                  BoxShadow(color: tBlack.withOpacity(.15), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.fullscreen, size: 18),
            ),
          ),
        ),

        // Zoom controls
        Positioned(
          right: 12,
          bottom: 20,
          child: Column(
            children: [
              _mapControlButton(iconPath: 'icons/zoomout.svg', onTap: _zoomIn),
              const SizedBox(height: 6),
              _mapControlButton(iconPath: 'icons/zoomin.svg', onTap: _zoomOut),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBySearch(bool isDark) => Container(
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
        hintText: 'Search',
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
      ),
      onChanged: (query) {
        if (!mounted) return;

        _searchDebounceTimer?.cancel();
        _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _searchQuery = query.trim();
            currentPage = 1;
            _filteredDevices.clear();
            _allDevices.clear();
          });
          _loadDevices();
          _loadDevicesForMap();
        });
      },
      cursorColor: isDark ? tWhite : tBlack,
    ),
  );
  Widget _buildFilterPanel(bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    return Positioned(
      top: isMobile ? 45 : 55,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: isMobile ? 300 : 350,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color:
                    isDark ? tWhite.withOpacity(0.2) : tBlack.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: isDark ? tWhite : tBlack, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterGroup(
                title: 'Vehicle Status',
                items:
                    mode == 'EV Fleet'
                        ? EvstatusApiMap.keys.toList()
                        : NonEvstatusApiMap.keys.toList(),
                selectedItems: _tempSelectedStatuses,
                onTap: (item) {
                  _statusFilterModified = true;

                  setState(() {
                    if (_tempSelectedStatuses.contains(item)) {
                      _tempSelectedStatuses.clear();
                    } else {
                      _tempSelectedStatuses.clear();
                      _tempSelectedStatuses.add(item);
                    }
                  });
                },
                isDark: isDark,
                colorResolver: (item) {
                  if (mode == 'EV Fleet') {
                    return _evStatusColors[item] ?? tGreen8;
                  }
                  return _nonEVStatusColors[item] ?? tGreen8;
                },
              ),
              const SizedBox(height: 14),
              Divider(
                color:
                    isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              _buildFilterGroup(
                title: 'Filter by Values',
                items: _filterValues,
                selectedItems: _tempSelectedFilterValues, // Use temp here
                onTap: (item) {
                  setState(() {
                    if (_tempSelectedFilterValues.contains(item)) {
                      _tempSelectedFilterValues.remove(item);
                    } else {
                      _tempSelectedFilterValues.clear();
                      _tempSelectedFilterValues.add(item);
                    }
                  });
                },
                isDark: isDark,
                colorResolver: (_) => tGreen8,
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: isMobile ? 80 : 120,
                  height: isMobile ? 30 : 40,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!mounted) return;

                      setState(() {
                        _selectedStatuses.clear();
                        _selectedStatuses.addAll(_tempSelectedStatuses);

                        _selectedFilterValues.clear();
                        _selectedFilterValues.addAll(_tempSelectedFilterValues);

                        _showFilterPanel = false;
                        currentPage = 1;
                      });

                      _loadDevices();
                      _loadDevicesForMap();
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: tGreen8,

                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 20,
                        vertical: isMobile ? 6 : 10,
                      ),

                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    child: Text(
                      'Apply Filters',
                      style: GoogleFonts.urbanist(
                        color: tWhite,
                        fontSize: isMobile ? 10 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterButton(bool isDark) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: tTransparent,
      border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
    ),
    child: IconButton(
      onPressed: () {
        if (!mounted) return;
        setState(() => _showFilterPanel = !_showFilterPanel);
      },
      icon: SvgPicture.asset(
        'icons/filter.svg',
        width: 18,
        height: 18,
        color: isDark ? tWhite : tBlack,
      ),
    ),
  );

  Widget _buildFilterGroup({
    required String title,
    required List<String> items,
    required List<String> selectedItems,
    required Function(String) onTap,
    required bool isDark,
    required Color Function(String) colorResolver,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: isMobile ? 11 : 13,
            fontWeight: FontWeight.w700,
            color: isDark ? tWhite : tBlack,
          ),
        ),

        SizedBox(height: isMobile ? 6 : 8),

        Wrap(
          spacing: isMobile ? 6 : 8,
          runSpacing: isMobile ? 4 : 6,
          children:
              items.map((item) {
                final selected = selectedItems.contains(item);

                return FilterChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,

                  label: Text(item),

                  selected: selected,

                  onSelected: (_) => onTap(item),

                  backgroundColor:
                      isDark ? tGrey.withOpacity(0.1) : tBlack.withOpacity(0.1),

                  selectedColor: colorResolver(item),

                  side: BorderSide.none,

                  checkmarkColor: tWhite,

                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6 : 10,
                    vertical: isMobile ? 2 : 4,
                  ),

                  labelStyle: GoogleFonts.urbanist(
                    fontSize:
                        isMobile
                            ? 10
                            : isTablet
                            ? 11
                            : 12,
                    color: selected ? tWhite : (isDark ? tWhite : tBlack),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _mapControlButton({
    required String iconPath,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? tBlack : tWhite,
        border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: SvgPicture.asset(
          iconPath,
          width: 18,
          height: 18,
          color: isDark ? tWhite : tBlack,
        ),
      ),
    );
  }

  Widget _buildPaginationControls(bool isDark) {
    const int visiblePageCount = 5;

    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;

    final isTablet = screenWidth >= 600 && screenWidth < 1100;

    // ---------------- PAGE WINDOW ----------------
    int startPage =
        ((currentPage - 1) ~/ visiblePageCount) * visiblePageCount + 1;

    int endPage = (startPage + visiblePageCount - 1).clamp(1, totalPages);

    int startItem = ((currentPage - 1) * itemsPerPage) + 1;

    int endItem = (currentPage * itemsPerPage).clamp(1, _totalCountFromAPI);

    if (currentPage == totalPages) {
      endItem = _totalCountFromAPI;

      startItem = endItem - paginatedDevices.length + 1;

      if (startItem < 1) startItem = 1;
    }

    // ---------------- PAGE BUTTONS ----------------
    final pageButtons = <Widget>[];

    for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
      final isSelected = pageNum == currentPage;

      pageButtons.add(
        GestureDetector(
          onTap: () {
            if (pageNum == currentPage || _loading) {
              return;
            }

            if (!mounted) return;

            _removeDeviceTooltip();

            _loadDevices(page: pageNum);
          },

          child: Container(
            margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),

            padding: EdgeInsets.symmetric(
              horizontal:
                  isMobile
                      ? 8
                      : isTablet
                      ? 9
                      : 10,

              vertical: isMobile ? 5 : 6,
            ),

            decoration: BoxDecoration(
              color: isSelected ? tGreen8 : Colors.transparent,

              borderRadius: BorderRadius.zero,

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

                fontSize:
                    isMobile
                        ? 11
                        : isTablet
                        ? 12
                        : 13,
              ),
            ),
          ),
        ),
      );
    }

    final controller = TextEditingController();

    // ---------------- MOBILE + TABLET ----------------
    if (isMobile || isTablet) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 4 : 6,
          horizontal: isMobile ? 4 : 6,
        ),

        child: Column(
          children: [
            Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // PREVIOUS
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.chevron_left,
                          color: isDark ? tWhite : tBlack,
                          size: isMobile ? 20 : 21,
                        ),
                        onPressed:
                            _loading
                                ? null
                                : () {
                                  if (currentPage > 1) {
                                    _removeDeviceTooltip();

                                    _loadDevices(page: currentPage - 1);
                                  }
                                },
                      ),

                      const SizedBox(width: 2),

                      Row(children: pageButtons),

                      const SizedBox(width: 2),

                      // NEXT
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.chevron_right,
                          color: isDark ? tWhite : tBlack,
                          size: isMobile ? 20 : 21,
                        ),
                        onPressed:
                            _loading
                                ? null
                                : () {
                                  if (currentPage < totalPages) {
                                    _removeDeviceTooltip();

                                    _loadDevices(page: currentPage + 1);
                                  }
                                },
                      ),

                      SizedBox(
                        width: isMobile ? 50 : 58,
                        height: 30,
                        child: TextField(
                          controller: controller,
                          style: GoogleFonts.urbanist(
                            fontSize: isMobile ? 11 : 12,
                            color: isDark ? tWhite : tBlack,
                          ),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Page',
                            hintStyle: GoogleFonts.urbanist(
                              fontSize: isMobile ? 10 : 11,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
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
                              _removeDeviceTooltip();

                              _loadDevices(page: page);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$startPage–$endPage of $totalPages',
                      style: GoogleFonts.urbanist(
                        fontSize: isMobile ? 11 : 12,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ---------------- DESKTOP ----------------
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          // PREVIOUS
          IconButton(
            icon: Icon(
              Icons.chevron_left,

              color: isDark ? tWhite : tBlack,

              size: 22,
            ),

            onPressed:
                _loading
                    ? null
                    : () {
                      if (currentPage > 1) {
                        _removeDeviceTooltip();

                        _loadDevices(page: currentPage - 1);
                      }
                    },
          ),

          Row(children: pageButtons),

          // NEXT
          IconButton(
            icon: Icon(
              Icons.chevron_right,

              color: isDark ? tWhite : tBlack,

              size: 22,
            ),

            onPressed:
                _loading
                    ? null
                    : () {
                      if (currentPage < totalPages) {
                        _removeDeviceTooltip();

                        _loadDevices(page: currentPage + 1);
                      }
                    },
          ),

          const SizedBox(width: 16),

          // PAGE INPUT
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
                  _removeDeviceTooltip();

                  _loadDevices(page: page);
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
    required DeviceEntity device,
  }) {
    final mode = context.watch<FleetModeProvider>().mode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1100;
    final hasImei = (device.imei ?? '').trim().isNotEmpty;
    final hasVehicleNumber = vehicleNumber.trim().isNotEmpty;
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
        statusColor = tBlue;
        break;
      case 'non coverage':
      case 'non_coverage':
        statusColor = Colors.purple;
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
          return 'icons/indicationIcons/cycdischarging.svg';

        case 'discharging':
          return 'icons/indicationIcons/cycmoving.svg';

        default:
          return 'icons/indicationIcons/cycstopped.svg';
      }
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          hoveredDevices.add(device.imei ?? '');
        });
      },
      onExit: (_) {
        setState(() {
          hoveredDevices.remove(device.imei ?? '');
        });
      },
      child: GestureDetector(
        onTap: () {
          _removeDeviceTooltip();
          openDeviceOverview(context, device);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform:
              hoveredDevices.contains(device.imei ?? '')
                  ? (Matrix4.identity()
                    ..translate(0.0, -5.0)
                    ..scale(1.02))
                  : Matrix4.identity(),

          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,

            // borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  hoveredDevices.contains(device.imei ?? '')
                      ? statusColor
                      : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    hoveredDevices.contains(device.imei ?? '')
                        ? statusColor.withOpacity(.25)
                        : (isDark
                            ? tWhite.withOpacity(.08)
                            : tBlack.withOpacity(.08)),
                blurRadius:
                    hoveredDevices.contains(device.imei ?? '') ? 18 : 10,
                spreadRadius:
                    hoveredDevices.contains(device.imei ?? '') ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- TOP SECTION WITH ENHANCED COPY ----------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    getTruckIcon(status),
                    height: isMobile ? 40 : 50,
                    width: isMobile ? 40 : 50,
                  ),
                  SizedBox(width: 10),

                  // Vehicle Info Container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: statusColor, width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          // IMEI Header with Copy
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      device.imei ?? '--',
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: GoogleFonts.urbanist(
                                        fontSize:
                                            isMobile
                                                ? 11
                                                : isTablet
                                                ? 12
                                                : 13,
                                        fontWeight: FontWeight.w700,
                                        color: tWhite,
                                      ),
                                    ),
                                  ),
                                  if (hasImei)
                                    SizedBox(
                                      width: 22, // fixed width
                                      child: Center(
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () {
                                              Clipboard.setData(
                                                ClipboardData(
                                                  text: device.imei ?? '',
                                                ),
                                              );

                                              setState(() {
                                                imeiCopied = true;
                                              });

                                              Future.delayed(
                                                const Duration(seconds: 2),
                                                () {
                                                  if (mounted) {
                                                    setState(() {
                                                      imeiCopied = false;
                                                    });
                                                  }
                                                },
                                              );
                                            },
                                            child: Tooltip(
                                              message:
                                                  imeiCopied
                                                      ? 'IMEI Copied'
                                                      : 'Copy IMEI',
                                              child: Icon(
                                                Icons.copy,
                                                size: isMobile ? 10 : 12,
                                                color: tWhite,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // Vehicle Number with Copy
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    vehicleNumber,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.urbanist(
                                      fontSize:
                                          isMobile
                                              ? 10
                                              : isTablet
                                              ? 11
                                              : 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? tWhite : tBlack,
                                    ),
                                  ),
                                ),
                                if (hasVehicleNumber)
                                  SizedBox(
                                    width: 22, // fixed width
                                    child: Center(
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(
                                              ClipboardData(
                                                text: vehicleNumber,
                                              ),
                                            );

                                            setState(() {
                                              vehicleCopied = true;
                                            });

                                            Future.delayed(
                                              const Duration(seconds: 2),
                                              () {
                                                if (mounted) {
                                                  setState(() {
                                                    vehicleCopied = false;
                                                  });
                                                }
                                              },
                                            );
                                          },
                                          child: Tooltip(
                                            message:
                                                vehicleCopied
                                                    ? 'Vehicle Number Copied'
                                                    : 'Copy Vehicle Number',
                                            child: Icon(
                                              Icons.copy,
                                              size: isMobile ? 10 : 12,
                                              color: tWhite,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width:
                        isMobile
                            ? 8
                            : isTablet
                            ? 10
                            : 15,
                  ),
                  // ---------------- STATUS + DATE ----------------
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                isMobile
                                    ? 8
                                    : isTablet
                                    ? 9
                                    : 11,
                            vertical: isMobile ? 4 : 6,
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
                              fontSize:
                                  isMobile
                                      ? 10
                                      : isTablet
                                      ? 11
                                      : 13,
                              fontWeight: FontWeight.w600,
                              color: tWhite,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width:
                              isMobile
                                  ? 90
                                  : isTablet
                                  ? 95
                                  : 130,
                          child: Text(
                            lastUpdated,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.urbanist(
                              fontSize:
                                  isMobile
                                      ? 10
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
                ],
              ),
              const SizedBox(height: 10),
              // ---------------- STATS ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn(isDark, title: 'ODO', value: odo),
                  _buildStatColumn(
                    isDark,
                    title: mode == 'EV Fleet' ? 'SOC' : 'Fuel',
                    value: fuel,
                    alignEnd: true,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn(isDark, title: 'Trips', value: trips),
                  _buildStatColumn(
                    isDark,
                    title: 'ALERTS',
                    value: alerts,
                    alignEnd: true,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Divider(
                color:
                    isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
                thickness: 0.3,
              ),
              const SizedBox(height: 6),
              // ---------------- LOCATION ----------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: isMobile ? 32 : 36,
                    height: isMobile ? 30 : 36,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),

                    child: Center(
                      child: SvgPicture.asset(
                        'icons/geofence.svg',
                        width: isMobile ? 14 : 16,
                        height: isMobile ? 14 : 16,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize:
                            isMobile
                                ? 11
                                : isTablet
                                ? 12
                                : 13,
                        color: isDark ? tWhite : tBlack,
                        height: 1.3,
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

  Widget _mapViewTab({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tGreen8 : Colors.transparent,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color:
                selected
                    ? Colors.white
                    : Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : tBlack,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      // mobile: const Center(child: Text("Mobile / Tablet layout coming soon")),
      mobile: _buildMobileLayout(),
      // tablet: const Center(child: Text("Mobile / Tablet layout coming soon")),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: FleetTitleBar(
                      isDark: isDark,
                      title: "Devices (${_totalCountFromAPI})",
                    ),
                  ),

                  const SizedBox(width: 8),

                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _openMobileMap(isDark);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tGreen8,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(CupertinoIcons.map_fill, color: tWhite),
                      label: Text(
                        "Map",
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tWhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(child: _buildFilterBySearch(isDark)),

                  const SizedBox(width: 8),

                  _filterButton(isDark),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // DEVICE LIST
            Expanded(
              child: RefreshIndicator(
                color: tGreen8,
                onRefresh: () async {
                  currentPage = 1;
                  _hasMoreData = true;

                  await _loadDevices();
                  await _loadDevicesForMap();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    bottom: 20,
                  ),

                  // itemCount: _filteredDevices.length + 1,
                  itemCount:
                      _filteredDevices.length + (_isPaginationLoading ? 1 : 0),

                  itemBuilder: (context, index) {
                    /// PAGINATION LOADER
                    // if (index == _filteredDevices.length) {
                    if (index >= _filteredDevices.length) {
                      return _isPaginationLoading
                          ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: LoadingAnimationWidget.staggeredDotsWave(
                                color: isDark ? tWhite : tBlack,
                                size: 42,
                              ),
                            ),
                          )
                          : const SizedBox.shrink();
                    }

                    final device = _filteredDevices[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),

                      child: FutureBuilder<String>(
                        // future: getAddressFromLocationStringWeb(
                        //   device.location ?? '',
                        // ),
                        future: getCachedAddress(device.lat, device.lng),

                        builder: (context, snapshot) {
                          // final address =
                          //     snapshot.connectionState ==
                          //                 ConnectionState.done &&
                          //             snapshot.hasData
                          //         ? snapshot.data!
                          //         : 'Fetching location...';

                          return buildDeviceCard(
                            isDark: isDark,
                            imei: device.imei ?? '',
                            vehicleNumber: device.vehicleNumber ?? '',
                            status: device.status ?? '',
                            fuel:
                                mode == 'EV Fleet'
                                    ? '${double.tryParse((device.soc ?? '').replaceAll('%', ''))?.toInt() ?? ''}%'
                                    : '${device.tafe?.fuellevel ?? ''}%',
                            odo: device.odometer ?? '',
                            trips: (device.totalTrips ?? 0).toString(),
                            alerts: (device.totalAlerts ?? 0).toString(),
                            location: (device.address ?? '').toString(),
                            device: device,
                            lastUpdated:
                                mode == 'EV Fleet'
                                    ? device.batteryLogDate ?? ''
                                    : device.locationLogDate ?? '',
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        // if (_loading)
        //   Center(
        //     child: LoadingAnimationWidget.staggeredDotsWave(
        //       color: isDark ? tWhite : tBlack,
        //       size: 42,
        //     ),
        //   ),
        if (_showFilterPanel) _buildFilterPanel(isDark),

        if (_loading) _buildLoadingOverlay(isDark),
      ],
    );
  }

  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;

    return Stack(
      children: [
        Column(
          children: [
            // ---------------- HEADER ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FleetTitleBar(
                      isDark: isDark,
                      title: "Devices (${_totalCountFromAPI})",
                    ),
                  ),

                  const SizedBox(width: 10),

                  Row(
                    children: [
                      SizedBox(width: 260, child: _buildFilterBySearch(isDark)),

                      const SizedBox(width: 6),

                      _filterButton(isDark),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- BODY ----------------
            Expanded(
              child: Row(
                children: [
                  // ---------------- DEVICE LIST ----------------
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: double.infinity,
                      margin: const EdgeInsets.only(left: 10, bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark ? tBlack : tWhite,
                        borderRadius: BorderRadius.zero,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.08)
                                    : tBlack.withOpacity(0.08),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // DEVICE LIST
                          Expanded(
                            child:
                                paginatedDevices.isEmpty && !_loading
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            'icons/nodata1.svg',
                                            height: 90,
                                            width: 90,
                                          ),

                                          const SizedBox(height: 12),

                                          Text(
                                            'No devices found',
                                            style: GoogleFonts.urbanist(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? tWhite : tBlack,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : Scrollbar(
                                      thumbVisibility: true,
                                      controller: _scrollController,
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          10,
                                          10,
                                          10,
                                          6,
                                        ),
                                        // itemCount: paginatedDevices.length,
                                        itemCount:
                                            paginatedDevices.length +
                                            (_isPaginationLoading ? 1 : 0),
                                        itemBuilder: (context, index) {
                                          if (index >=
                                              paginatedDevices.length) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 15,
                                                  ),
                                              child: Center(
                                                child:
                                                    LoadingAnimationWidget.staggeredDotsWave(
                                                      color:
                                                          isDark
                                                              ? tWhite
                                                              : tBlack,
                                                      size: 32,
                                                    ),
                                              ),
                                            );
                                          }

                                          final device =
                                              paginatedDevices[index];

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: FutureBuilder<String>(
                                              // future:
                                              //     getAddressFromLocationStringWeb(
                                              //       device.location ?? '',
                                              //     ),
                                              future: getCachedAddress(
                                                device.lat,
                                                device.lng,
                                              ),
                                              builder: (context, snapshot) {
                                                // final address =
                                                //     snapshot.connectionState ==
                                                //                 ConnectionState
                                                //                     .done &&
                                                //             snapshot.hasData
                                                //         ? snapshot.data!
                                                //         : 'Fetching location...';

                                                return buildDeviceCard(
                                                  isDark: isDark,
                                                  imei: device.imei ?? '',
                                                  vehicleNumber:
                                                      device.vehicleNumber ??
                                                      '',
                                                  status: device.status ?? '',
                                                  fuel:
                                                      mode == 'EV Fleet'
                                                          ? '${double.tryParse((device.soc ?? '').replaceAll('%', ''))?.toInt() ?? ''}%'
                                                          : '${device.tafe?.fuellevel ?? ''}%',
                                                  odo: device.odometer ?? '',
                                                  trips:
                                                      (device.totalTrips ?? 0)
                                                          .toString(),
                                                  alerts:
                                                      (device.totalAlerts ?? 0)
                                                          .toString(),
                                                  location:
                                                      (device.address ?? '')
                                                          .toString(),
                                                  device: device,
                                                  lastUpdated:
                                                      mode == 'EV Fleet'
                                                          ? device.batteryLogDate ??
                                                              ''
                                                          : device.locationLogDate ??
                                                              '',
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                          ),

                          // PAGINATION FIXED
                          // if (totalPages > 0 && paginatedDevices.isNotEmpty)
                          //   Container(
                          //     width: double.infinity,
                          //     padding: const EdgeInsets.symmetric(vertical: 6),
                          //     decoration: BoxDecoration(
                          //       color: isDark ? tBlack : tWhite,
                          //       // borderRadius: const BorderRadius.only(
                          //       //   bottomLeft: Radius.circular(14),
                          //       //   bottomRight: Radius.circular(14),
                          //       // ),
                          //       boxShadow: [
                          //         BoxShadow(
                          //           blurRadius: 6,
                          //           color:
                          //               isDark
                          //                   ? tWhite.withOpacity(0.05)
                          //                   : tBlack.withOpacity(0.05),
                          //         ),
                          //       ],
                          //     ),
                          //     // child: _buildPaginationControls(isDark),
                          //   ),
                        ],
                      ),
                    ),
                  ),

                  // ---------------- MAP ----------------
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                        bottom: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.08)
                                      : tBlack.withOpacity(0.08),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: _buildClusterMap(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ---------------- FILTER PANEL ----------------
        if (_showFilterPanel) _buildFilterPanel(isDark),

        // ---------------- LOADING ----------------
        if (_loading) _buildLoadingOverlay(isDark),
        // if (_loading)
        //   Center(
        //     child: LoadingAnimationWidget.staggeredDotsWave(
        //       color: isDark ? tWhite : tBlack,
        //       size: 42,
        //     ),
        //   ),
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
                FleetTitleBar(isDark: isDark, title: "Devices"),
                Row(
                  children: [
                    _buildFilterBySearch(isDark),
                    const SizedBox(width: 6),
                    _filterButton(isDark),
                  ],
                ),
              ],
            ),
            _buildFleetRibbon(isDark),
            const SizedBox(height: 10),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // ADD EMPTY STATE HANDLING
                            if (paginatedDevices.isEmpty && !_loading) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'icons/nodata1.svg',
                                      height: 120,
                                      width: 120,
                                    ),

                                    const SizedBox(height: 16),

                                    Text(
                                      'No devices found',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? tWhite : tBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,

                              child: ListView.builder(
                                controller: _scrollController,

                                physics: const BouncingScrollPhysics(),

                                padding: const EdgeInsets.only(
                                  bottom: 50,
                                  left: 6,
                                  right: 6,
                                  top: 5,
                                ),

                                itemCount:
                                    paginatedDevices.length +
                                    (_isPaginationLoading ? 1 : 0),

                                itemBuilder: (context, index) {
                                  /// PAGINATION LOADER
                                  if (index >= paginatedDevices.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child:
                                            LoadingAnimationWidget.staggeredDotsWave(
                                              color: isDark ? tWhite : tBlack,
                                              size: 36,
                                            ),
                                      ),
                                    );
                                  }

                                  final device = paginatedDevices[index];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                      horizontal: 6,
                                    ),

                                    child: GestureDetector(
                                      onTap:
                                          () => openDeviceOverview(
                                            context,
                                            device,
                                          ),

                                      child: FutureBuilder<String>(
                                        // future: getAddressFromLocationStringWeb(
                                        //   device.location ?? '',
                                        // ),
                                        future: getCachedAddress(
                                          device.lat,
                                          device.lng,
                                        ),

                                        builder: (context, snapshot) {
                                          // final address =
                                          //     snapshot.connectionState ==
                                          //                 ConnectionState
                                          //                     .done &&
                                          //             snapshot.hasData
                                          //         ? snapshot.data!
                                          //         : 'Fetching location...';

                                          return buildDeviceCard(
                                            isDark: isDark,
                                            imei: device.imei ?? '',
                                            vehicleNumber:
                                                device.vehicleNumber ?? '',
                                            status: device.status ?? '',

                                            fuel:
                                                mode == 'EV Fleet'
                                                    ? '${double.tryParse((device.soc ?? '').replaceAll('%', ''))?.toInt() ?? ''}%'
                                                    : '${device.tafe?.fuellevel ?? ''}%',
                                            odo: device.odometer ?? '',

                                            trips:
                                                (device.totalTrips ?? 0)
                                                    .toString(),

                                            alerts:
                                                (device.totalAlerts ?? 0)
                                                    .toString(),

                                            location:
                                                (device.address ?? '')
                                                    .toString(),

                                            device: device,

                                            lastUpdated:
                                                mode == 'EV Fleet'
                                                    ? device.batteryLogDate ??
                                                        ''
                                                    : device.locationLogDate ??
                                                        '',
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),

                        // if (totalPages > 0 && paginatedDevices.isNotEmpty)
                        //   Positioned(
                        //     left: 0,
                        //     right: 0,
                        //     bottom: 0,
                        //     child: Container(
                        //       alignment: Alignment.center,
                        //       color: isDark ? tBlack : tWhite,
                        //       child: _buildPaginationControls(isDark),
                        //     ),
                        //   ),
                      ],
                    ),
                  ),
                  if (!isMapFullscreen)
                    Expanded(flex: 9, child: _buildClusterMap()),
                ],
              ),
            ),
          ],
        ),
        if (_showFilterPanel) _buildFilterPanel(isDark),
        if (_loading) _buildLoadingOverlay(isDark),
        // if (_loading)
        //   Center(
        //     child: LoadingAnimationWidget.staggeredDotsWave(
        //       color: isDark ? tWhite : tBlack,
        //       size: 42,
        //     ),
        //   ),

        // FULLSCREEN MAP
        if (isMapFullscreen)
          Positioned.fill(
            child: Material(
              color: isDark ? tBlack : tWhite,
              child: Stack(
                children: [
                  _buildClusterMap(),

                  Positioned(
                    top: 65,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isMapFullscreen = false;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? tBlack : tWhite,
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(
                            color: isDark ? tWhite : tBlack,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.fullscreen_exit,
                          size: 18,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _openMobileMap(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? tBlack : tWhite,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.92,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? tBlack : tWhite,
                    border: Border(
                      bottom: BorderSide(
                        color:
                            isDark
                                ? tWhite.withOpacity(0.5)
                                : tBlack.withOpacity(0.5),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDark
                                ? tBlack.withOpacity(0.25)
                                : tWhite.withOpacity(0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Devices Map',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.close,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                    ],
                  ),
                ),

                // Expanded(child: _buildClusterMap()),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.76,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: _buildClusterMap(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDisconnectedMessage(
    BuildContext context,
    bool isDark,
    DeviceEntity device,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final bgColor = isDark ? tBlack : tWhite;
        final textColor = isDark ? tWhite : tBlack;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? tWhite.withOpacity(0.7) : tTransparent,
              width: 2,
            ),
          ),
          backgroundColor: bgColor,
          shadowColor: textColor.withOpacity(0.2),

          title: Row(
            children: [
              Icon(Icons.wifi_off, color: isDark ? tWhite : tBlack),
              const SizedBox(width: 10),
              Text(
                "Device Disconnected",
                style: GoogleFonts.urbanist(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),

          content: Text(
            "This device ${device.imei ?? '--'} is currently disconnected.\n\n"
            "Overview, Go Live, and Control data are not available.",
            style: GoogleFonts.urbanist(fontSize: 16, color: textColor),
          ),

          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: tGreen8,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color: tWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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
                    'Loading devices...',
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

  void _onStatusTap(String status) {
    debugPrint("Selected Status: $status");

    setState(() {
      _selectedStatuses.clear();
      _selectedStatuses.add(status);

      _tempSelectedStatuses.clear();
      _tempSelectedStatuses.add(status);

      currentPage = 1;
    });

    _loadDevices();
    _loadDevicesForMap();
  }

  Widget _buildFleetRibbon(bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;

    final statusData =
        mode == "EV Fleet" ? getEVBackendStatus() : getBackendStatus();

    final totalCount = statusData.fold<int>(
      0,
      (sum, item) => sum + (item['count'] as int),
    );

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
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _selectedStatuses.clear();
                  _tempSelectedStatuses.clear();

                  _selectedFilterValues.clear();
                  _tempSelectedFilterValues.clear();

                  currentPage = 1;
                });
                context.go('/home/devices');

                _loadDevices();
                _loadDevicesForMap();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tGreen8, tGreen8.withOpacity(.75)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "TOTAL : $totalCount",
                  style: GoogleFonts.urbanist(
                    color: tWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          if (mode == "EV Fleet") ...[
            _statusChip(
              isDark: isDark,
              label: "Charging",
              count: getStatusCount(statusData, "Charging"),
              color: tBlue,
              onTap: () {
                _onStatusTap("Charging");
              },
            ),
            _statusChip(
              isDark: isDark,
              label: "Discharging",
              count: getStatusCount(statusData, "Discharging"),
              color: tGreen,
              onTap: () {
                _onStatusTap("Discharging");
              },
            ),
            _statusChip(
              isDark: isDark,
              label: "Idle",
              count: getStatusCount(statusData, "Idle"),
              color: tOrange1,
              onTap: () {
                _onStatusTap("Idle");
              },
            ),
            _statusChip(
              isDark: isDark,
              label: "Non Coverage",
              count: getStatusCount(statusData, "Non Coverage"),
              color: Colors.purple,
              onTap: () {
                _onStatusTap("Non Coverage");
              },
            ),
            _statusChip(
              isDark: isDark,
              label: "Disconnected",
              count: getStatusCount(statusData, "Disconnected"),
              color: tGrey,
              onTap: () {
                _onStatusTap("Disconnected");
              },
            ),
          ] else ...[
            _statusChip(
              isDark: isDark,
              label: "Moving",
              count: getStatusCount(statusData, "Moving"),
              color: tGreen,
              onTap: () {
                _onStatusTap("Moving");
              },
            ),

            _statusChip(
              isDark: isDark,
              label: "Stopped",
              count: getStatusCount(statusData, "Stopped"),
              color: tRed,
              onTap: () {
                _onStatusTap("Stopped");
              },
            ),
            _statusChip(
              isDark: isDark,
              label: "Idle",
              count: getStatusCount(statusData, "Idle"),
              color: tOrange1,
              onTap: () {
                _onStatusTap("Idle");
              },
            ),
            _statusChip(
              isDark: isDark,
              label: "Non Coverage",
              count: getStatusCount(statusData, "Non Coverage"),
              color: Colors.purple,
              onTap: () {
                _onStatusTap("Non Coverage");
              },
            ),
            _statusChip(
              isDark: isDark,
              label: "Disconnected",
              count: getStatusCount(statusData, "Disconnected"),
              color: tGrey,
              onTap: () {
                _onStatusTap("Disconnected");
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip({
    required bool isDark,
    required String label,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(.35)),
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

  int getStatusCount(List<Map<String, dynamic>> statusData, String label) {
    try {
      return statusData.firstWhere((e) => e['label'] == label)['count'] as int;
    } catch (_) {
      return 0;
    }
  }
}
