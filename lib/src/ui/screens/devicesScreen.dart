import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' show Lottie;
import 'package:provider/provider.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../models/devicesMapModel.dart';
import '../../models/devicesModel.dart';
import '../../provider/fleetModeProvider.dart';
import '../../services/generalAPIServices.dart/deviceAPIServices/deviceAPIService.dart';
import '../../services/getAddressService.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../../utils/route/navigation_helpers.dart';
import '../components/customTitleBar.dart';

class DevicesScreen extends StatefulWidget {
  final String? filterStatus;
  final String? soc;
  const DevicesScreen({super.key, this.soc, this.filterStatus});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  OverlayEntry? _devicePopup;
  int _totalCountFromAPI = 0;
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

  final MapController _mapController = MapController();

  final ValueNotifier<LatLng> _centerNotifier = ValueNotifier(
    LatLng(13.0827, 80.2707),
  );
  final ValueNotifier<double> _zoomNotifier = ValueNotifier<double>(4.5);

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
    'icons/indicationIcons/moving.svg',
    'icons/indicationIcons/stopped.svg',
    'icons/indicationIcons/idle.svg',
    'icons/indicationIcons/disconnected.svg',
    'icons/indicationIcons/noncoverage.svg',
    'icons/indicationIcons/charging.svg',
  ];

  final Map<String, String> _addressCache = {};

  @override
  void initState() {
    super.initState();
    _initializeSelectedStatuses();
    _tempSelectedStatuses = List.from(_selectedStatuses);
    _tempSelectedFilterValues = List.from(_selectedFilterValues);
    _loadDevices(); // Load paginated list
    _loadDevicesForMap(); // Load ALL devices for map
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

  // void _initializeSelectedStatuses() {
  //   if (widget.filterStatus != null && widget.filterStatus!.isNotEmpty) {
  //     final displayStatus = _convertApiStatusToDisplay(widget.filterStatus!);

  //     _selectedStatuses.clear();
  //     if (displayStatus != null) {
  //       _selectedStatuses.add(displayStatus);
  //     }
  //   }
  // }
  void _initializeSelectedStatuses() {
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

  String? _convertApiStatusToDisplay(String apiStatus) {
    for (var entry in statusApiMap.entries) {
      if (entry.value.toLowerCase() == apiStatus.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }
  // Future<void> _loadDevicesForMap() async {
  //   // try {
  //   //   final devicesMapApi = DevicesMapApiService();
  //   //   final res = await devicesMapApi.fetchDevicesMap(
  //   //     status: widget.filterStatus,
  //   //   );
  //   try {
  //     final devicesMapApi = DevicesMapApiService();

  //     String? statusToUse;

  //     if (widget.filterStatus != null && widget.filterStatus!.isNotEmpty) {
  //       // statusToUse = widget.filterStatus;
  //       statusToUse = normalizeStatus(widget.filterStatus!);
  //     } else if (_selectedStatuses.isNotEmpty) {
  //       statusToUse = _selectedStatuses.first.toLowerCase();
  //     }

  //     final res = await devicesMapApi.fetchDevicesMap(status: statusToUse);

  //     if (mounted) {
  //       setState(() {
  //         _allMapDevices = res.entities ?? [];
  //         _applyMapFilters();
  //       });
  //     }
  //   } catch (e) {
  //     print('Error loading devices for map: $e');
  //   }
  // }

  Future<void> _loadDevicesForMap() async {
    try {
      final devicesMapApi = DevicesMapApiService();

      String? statusToUse;

      final mode = context.read<FleetModeProvider>().mode;

      final currentMap =
          mode == 'EV Fleet' ? EvstatusApiMap : NonEvstatusApiMap;

      if (_selectedStatuses.isNotEmpty) {
        statusToUse = _selectedStatuses
            .map((s) {
              final mapped = currentMap[s];

              if (mapped != null) {
                // ✅ Convert API format → MAP format
                return mapped.replaceAll('_', ' ');
              }

              // ✅ fallback
              return s.toLowerCase();
            })
            .join(',');
      } else if (widget.filterStatus != null &&
          widget.filterStatus!.isNotEmpty) {
        statusToUse = widget.filterStatus!.toLowerCase().replaceAll('_', ' ');
      }

      final res = await devicesMapApi.fetchDevicesMap(
        status: statusToUse, // ✅ NOW sends: "non coverage"
      );

      if (mounted) {
        setState(() {
          _allMapDevices = res.entities ?? [];
          _applyMapFilters();
        });
      }
    } catch (e) {
      print('❌ Error loading devices for map: $e');
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

    try {
      String? statusForAPI;

      final mode = context.read<FleetModeProvider>().mode;

      // ✅ Pick correct map based on mode
      final currentMap =
          mode == 'EV Fleet' ? EvstatusApiMap : NonEvstatusApiMap;

      if (_selectedStatuses.isNotEmpty) {
        statusForAPI = _selectedStatuses
            .map(
              (e) => currentMap[e] ?? e.toLowerCase().replaceAll(' ', '_'),
            ) // ✅ fallback
            .join(',');
      } else if (widget.filterStatus != null &&
          widget.filterStatus!.isNotEmpty) {
        statusForAPI = widget.filterStatus;
      }

      final res = await _api.fetchDevices(
        currentIndex: currentPage - 1,
        sizePerPage: itemsPerPage,
        status: statusForAPI, // ✅ correct value passed
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        selectedStatuses: null, // ✅ not needed anymore
        SOC: widget.soc,
      );

      if (mounted) {
        setState(() {
          _allDevices = res.entities ?? [];
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

  // Future<void> _loadDevices({int? page}) async {
  //   if (_loading) return;

  //   setState(() {
  //     _loading = true;
  //     if (page != null) {
  //       currentPage = page;
  //     }
  //   });

  //   try {
  //     String? statusForAPI;

  //     if (_selectedStatuses.isNotEmpty) {
  //       statusForAPI = _selectedStatuses
  //           .map((e) => statusApiMap[e] ?? e)
  //           .join(',');
  //     } else if (widget.filterStatus != null &&
  //         widget.filterStatus!.isNotEmpty) {
  //       statusForAPI = widget.filterStatus;
  //     }

  //     final res = await _api.fetchDevices(
  //       currentIndex: currentPage - 1,
  //       sizePerPage: itemsPerPage,
  //       status: statusForAPI, // Use the determined status
  //       search: _searchQuery.isNotEmpty ? _searchQuery : null,
  //       selectedStatuses:
  //           null, // Don't use this parameter anymore since we're using status param
  //       SOC: widget.soc,
  //     );

  //     if (mounted) {
  //       setState(() {
  //         _allDevices = res.entities ?? [];
  //         _totalCountFromAPI = res.totalCount ?? 0;
  //         _applyFilters();
  //       });
  //     }
  //   } catch (e) {
  //     print('Error loading devices: $e');
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _loading = false;
  //       });
  //     }
  //   }
  // }

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
        width: 25,
        height: 25,
        child: GestureDetector(
          onTapDown: (d) {
            _showMapDeviceTooltip(
              device,
              pos,
              Theme.of(context).brightness == Brightness.dark,
              globalPosition: d.globalPosition,
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
    String placement = 'top',
  }) {
    _removeDeviceTooltip();

    const double popupWidth = 220;
    const double popupHeight = 160;
    const double gap = 8;

    double left = globalPosition.dx - popupWidth / 2;
    double top = globalPosition.dy - popupHeight - gap;

    final Size screen = MediaQuery.of(context).size;
    left = left.clamp(6.0, screen.width - popupWidth - 6.0);
    top = top.clamp(6.0, screen.height - popupHeight - 6.0);

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
                      color: isDark ? tBlack : tWhite,
                      borderRadius: BorderRadius.circular(10),
                      elevation: 8,
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
                                      : Colors.grey.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            /// Header
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

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// IMEI Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
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

                                      const SizedBox(width: 8),

                                      Flexible(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 5,
                                            horizontal: 6,
                                          ),
                                          child:
                                              device.imei != null &&
                                                      device.imei!.isNotEmpty
                                                  ? GestureDetector(
                                                    onTap: () {
                                                      _removeDeviceTooltip();
                                                      openDeviceOverview(
                                                        context,
                                                        DeviceEntity(
                                                          imei: device.imei,
                                                          status: device.status,
                                                          odometer:
                                                              device.odometer,
                                                          lat: device.lat,
                                                          lng: device.lng,
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isDark
                                                                ? Colors.blue
                                                                    .withOpacity(
                                                                      0.2,
                                                                    )
                                                                : Colors.blue
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        device.imei!,
                                                        style: GoogleFonts.urbanist(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              isDark
                                                                  ? Colors
                                                                      .lightBlue
                                                                  : Colors.blue,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  : const Text('--'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                /// Status
                                _deviceInfoRow(
                                  'Status',
                                  device.status ?? '--',
                                  isDark,
                                ),

                                /// ODO
                                _deviceInfoRow(
                                  'ODO',
                                  device.odometer ?? '--',
                                  isDark,
                                ),

                                /// Location
                                FutureBuilder<String>(
                                  future:
                                      (device.lat != null && device.lng != null)
                                          ? getAddressFromLocationStringWeb(
                                            '${device.lat},${device.lng}',
                                          )
                                          : Future.value('--'),
                                  builder: (context, snapshot) {
                                    final address =
                                        snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData
                                            ? snapshot.data!
                                            : 'Fetching location...';

                                    return _deviceInfoRow(
                                      'Location',
                                      address,
                                      isDark,
                                    );
                                  },
                                ),
                              ],
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

    Overlay.of(context)?.insert(_devicePopup!);
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

    return FlutterMap(
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
        TileLayer(
          urlTemplate:
              isDark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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

        // Zoom controls
        Positioned(
          right: 12,
          top: 12,
          child: Column(
            children: [
              _mapControlButton(iconPath: 'icons/zoomout.svg', onTap: _zoomIn),
              const SizedBox(height: 6),
              _mapControlButton(iconPath: 'icons/zoomin.svg', onTap: _zoomOut),
            ],
          ),
        ),

        // Legends
        _buildLegends(),
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
            currentPage = 1; // Reset to first page when searching
          });
          _loadDevices(); // This will trigger API call with search query
        });
      },
    ),
  );
  Widget _buildFilterPanel(bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;

    return Positioned(
      top: 55,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 350,
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
                    return _evStatusColors[item] ?? tBlue;
                  }
                  return _nonEVStatusColors[item] ?? tBlue;
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
                colorResolver: (_) => tBlue,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    if (!mounted) return;
                    setState(() {
                      // Apply the temp selections to actual selections
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
                    backgroundColor: tBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.urbanist(
                      color: tWhite,
                      fontWeight: FontWeight.w600,
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
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.urbanist(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? tWhite : tBlack,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children:
            items.map((item) {
              final selected = selectedItems.contains(item);
              return FilterChip(
                label: Text(item),
                selected: selected,
                onSelected: (_) => onTap(item),
                // backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                backgroundColor:
                    isDark ? tWhite.withOpacity(0.15) : tBlack.withOpacity(0.1),
                selectedColor: colorResolver(item),
                checkmarkColor: tWhite,
                labelStyle: GoogleFonts.urbanist(
                  color: selected ? tWhite : (isDark ? tWhite : tBlack),
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
      ),
    ],
  );
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

    // Determine start and end of visible window
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

    final pageButtons = <Widget>[];

    for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
      final isSelected = pageNum == currentPage;

      pageButtons.add(
        GestureDetector(
          onTap: () {
            if (pageNum == currentPage || _loading) return;
            if (!mounted) return;

            _removeDeviceTooltip(); // Clear any open tooltips
            _loadDevices(page: pageNum);
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
          /// Previous Button
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

          /// Page Buttons (windowed 5)
          Row(children: pageButtons),

          /// Next Button
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

          /// Page Input Box
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

          /// Show visible range (e.g., "1–5 of 20")
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

  // Widget buildDeviceCard({
  //   required bool isDark,
  //   required String vehicleNumber,
  //   required String status,
  //   required String imei,
  //   required String fuel,
  //   required String odo,
  //   required String trips,
  //   required String alerts,
  //   required String location,
  //   required String lastUpdated,
  // }) {
  //   final mode = context.watch<FleetModeProvider>().mode;

  //   Color statusColor;
  //   switch (status.toLowerCase()) {
  //     case 'moving':
  //       statusColor = tGreen;
  //       break;
  //     case 'idle':
  //       statusColor = tOrange1;
  //       break;
  //     case 'stopped':
  //       statusColor = tRed;
  //       break;
  //     case 'disconnected':
  //       statusColor = tGrey;
  //       break;
  //     case 'discharging':
  //       statusColor = tGreen;
  //       break;
  //     case 'charging':
  //       statusColor = Colors.teal;
  //       break;
  //     case 'non coverage':
  //     case 'non_coverage':
  //       statusColor = Colors.purple;
  //       break;
  //     default:
  //       statusColor = tBlack;
  //   }

  //   return Container(
  //     width: double.infinity,
  //     decoration: BoxDecoration(
  //       color: isDark ? tBlack : tWhite,
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
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         /// IMEI + Vehicle + Status Row
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Container(
  //               width: 250,
  //               decoration: BoxDecoration(
  //                 border: Border.all(color: statusColor, width: 1),
  //                 borderRadius: BorderRadius.circular(6),
  //               ),
  //               child: Column(
  //                 children: [
  //                   Container(
  //                     width: double.infinity,
  //                     padding: const EdgeInsets.symmetric(vertical: 4),
  //                     decoration: BoxDecoration(
  //                       // color: statusColor,
  //                       gradient: SweepGradient(
  //                         colors: [statusColor, statusColor.withOpacity(0.6)],
  //                       ),
  //                       borderRadius: const BorderRadius.only(
  //                         topLeft: Radius.circular(5),
  //                         topRight: Radius.circular(5),
  //                       ),
  //                     ),
  //                     child: Text(
  //                       imei,
  //                       style: GoogleFonts.urbanist(
  //                         fontSize: 13,
  //                         fontWeight: FontWeight.w700,
  //                         // color: isDark ? tBlack : tWhite,
  //                         color: tWhite,
  //                       ),
  //                       textAlign: TextAlign.center,
  //                     ),
  //                   ),
  //                   Padding(
  //                     padding: const EdgeInsets.all(4.0),
  //                     child: Text(
  //                       vehicleNumber,
  //                       style: GoogleFonts.urbanist(
  //                         fontSize: 12,
  //                         fontWeight: FontWeight.w600,
  //                         color: isDark ? tWhite : tBlack,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),

  //             const SizedBox(width: 15),

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
  //                       // color: isDark ? tBlack : tWhite,
  //                       color: tWhite,
  //                     ),
  //                   ),
  //                 ),
  //                 SizedBox(height: 5),
  //                 Text(
  //                   lastUpdated,
  //                   style: GoogleFonts.urbanist(
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.w500,
  //                     color: isDark ? tWhite : tBlack,
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
  //             _buildStatColumn(isDark, title: 'ODO', value: odo),
  //             _buildStatColumn(
  //               isDark,
  //               title: mode == 'EV Fleet' ? 'SOC' : 'Fuel',
  //               value: fuel,
  //               alignEnd: true,
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 5),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             _buildStatColumn(isDark, title: 'Trips', value: trips),
  //             _buildStatColumn(
  //               isDark,
  //               title: 'ALERTS',
  //               value: alerts,
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
  //                 location,
  //                 style: GoogleFonts.urbanist(
  //                   fontSize: 13,
  //                   color: isDark ? tWhite : tBlack,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
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
      case 'non_coverage':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = tBlack;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? tBlack : tWhite,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMEI + Vehicle + Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 250,
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
                          colors: [statusColor, statusColor.withOpacity(0.6)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _removeDeviceTooltip();

                              openDeviceOverview(context, device);
                            },

                            onDoubleTap: () {
                              Clipboard.setData(
                                ClipboardData(text: device.imei ?? ''),
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('IMEI copied')),
                              );
                            },

                            child: Text(
                              device.imei ?? '--',
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: tWhite,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),

                          // const SizedBox(width: 8),
                          // GestureDetector(
                          //   onTap: () {
                          //     // Copy IMEI to clipboard
                          //     Clipboard.setData(ClipboardData(text: imei));
                          //     // Optional: Show a snackbar or toast notification
                          //     ScaffoldMessenger.of(context).showSnackBar(
                          //       SnackBar(
                          //         content: Text(
                          //           'IMEI copied to clipboard',
                          //           style: GoogleFonts.urbanist(),
                          //         ),
                          //         duration: const Duration(seconds: 2),
                          //         behavior: SnackBarBehavior.floating,
                          //       ),
                          //     );
                          //   },
                          //   child: Container(
                          //     padding: const EdgeInsets.all(4),
                          //     decoration: BoxDecoration(
                          //       color: tWhite.withOpacity(0.2),
                          //       borderRadius: BorderRadius.circular(4),
                          //     ),
                          //     child: Icon(Icons.copy, size: 14, color: tWhite),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        vehicleNumber,
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

              const SizedBox(width: 15),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: SweepGradient(
                        colors: [statusColor, statusColor.withOpacity(0.6)],
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
                  SizedBox(height: 5),
                  Text(
                    lastUpdated,
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
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
            color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
            thickness: 0.3,
          ),
          const SizedBox(height: 6),
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
                  location,
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
              ),
            ],
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const Center(child: Text("Mobile / Tablet layout coming soon")),
      tablet: const Center(child: Text("Mobile / Tablet layout coming soon")),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;

    return Stack(
      children: [
        Column(
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
                                child: Text(
                                  'No devices found',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 16,
                                    color: isDark ? tWhite : tBlack,
                                  ),
                                ),
                              );
                            }

                            return SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 50),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  children:
                                      paginatedDevices
                                          .map(
                                            (device) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 5,
                                                    horizontal: 6,
                                                  ),
                                              child: GestureDetector(
                                                // onTap:
                                                //     () => openDeviceOverview(
                                                //       context,
                                                //       device,
                                                //     ),
                                                onTap: () {
                                                  final status = device.status
                                                      ?.toLowerCase()
                                                      .replaceAll("_", " ");

                                                  if (status ==
                                                      "disconnected") {
                                                    _showDisconnectedMessage(
                                                      context,
                                                      isDark,
                                                      device,
                                                    );
                                                  } else {
                                                    openDeviceOverview(
                                                      context,
                                                      device,
                                                    );
                                                  }
                                                },
                                                child: FutureBuilder<String>(
                                                  future:
                                                      getAddressFromLocationStringWeb(
                                                        device.location ?? '',
                                                      ),
                                                  builder: (context, snapshot) {
                                                    final address =
                                                        snapshot.connectionState ==
                                                                    ConnectionState
                                                                        .done &&
                                                                snapshot.hasData
                                                            ? snapshot.data!
                                                            : 'Fetching location...';

                                                    return buildDeviceCard(
                                                      isDark: isDark,
                                                      imei: device.imei ?? '',
                                                      vehicleNumber:
                                                          device
                                                              .vehicleNumber ??
                                                          '',
                                                      status:
                                                          device.status ?? '',
                                                      fuel:
                                                          mode == 'EV Fleet'
                                                              ? device.soc ?? ''
                                                              : (device
                                                                      .tafe
                                                                      ?.fuellevel
                                                                      ?.toString() ??
                                                                  ''),
                                                      odo:
                                                          device.odometer ?? '',
                                                      trips:
                                                          (device.totalTrips ??
                                                                  0)
                                                              .toString(),
                                                      alerts:
                                                          (device.totalAlerts ??
                                                                  0)
                                                              .toString(),
                                                      location: address,
                                                      device: device,
                                                      lastUpdated:
                                                          device
                                                              .locationLogDate ??
                                                          '',
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            );
                          },
                        ),
                        if (totalPages > 0 && paginatedDevices.isNotEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              alignment: Alignment.center,
                              color: isDark ? tBlack : tWhite,
                              child: _buildPaginationControls(isDark),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(flex: 9, child: _buildClusterMap()),
                ],
              ),
            ),
          ],
        ),
        if (_showFilterPanel) _buildFilterPanel(isDark),
        if (_loading) _buildLoadingOverlay(isDark),
      ],
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
        final bgColor = isDark ? tWhite : tBlack;
        final textColor = isDark ? tBlack : tWhite;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: bgColor,
          shadowColor: textColor.withOpacity(0.2),

          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.redAccent),
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
            "Overview, Diagnostics, and Control data are not available.",
            style: GoogleFonts.urbanist(fontSize: 16, color: textColor),
          ),

          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: tBlue1,
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
}
