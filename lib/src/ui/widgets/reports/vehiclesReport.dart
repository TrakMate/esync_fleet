import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:svg_flutter/svg.dart';
import '../../../models/userReportModel.dart';
import '../../../provider/fleetModeProvider.dart';
import '../../../services/generalAPIServices.dart/reportApiServices/reportsAPIService.dart';
import '../../../services/generalAPIServices.dart/reportApiServices/vehicleReportAPIService.dart';
import '../../../utils/appColors.dart';
import 'custom_Toast.dart';

class VehiclesReportView extends StatefulWidget {
  final String title;
  final String description;
  final bool isDark;
  final bool isMobile;
  const VehiclesReportView({
    super.key,
    required this.title,
    required this.description,
    required this.isDark,
    required this.isMobile,
  });

  @override
  State<VehiclesReportView> createState() => _VehiclesReportViewState();
}

class _VehiclesReportViewState extends State<VehiclesReportView> {
  DateTime? fromDate;
  DateTime? toDate;
  bool _showFilterPanel = false;
  bool isLoading = false;
  bool isDownloading = false;
  bool _isRangeSelected = false;
  int? selectedRangeDays;

  String availability = 'All';
  String vehicleStatus = 'All';

  final TextEditingController searchController = TextEditingController();
  TextEditingController? _searchFieldController;
  final List<String> availabilityOptions = ['All', 'Active', 'Inactive'];

  String format = 'XLSX';
  String range = 'All';
  String selectedFormat = 'csv';

  final List<String> formatOptions = ['Logs', 'XLSX', 'CSV', 'JSON', 'XML'];

  final List<String> rangeOptions = [
    'Last 7 Days',
    'Last 15 Days',
    'Last 30 Days',
    'Last 60 Days',
    'Last 90 Days',
  ];

  final List<String> _nonEVStatuses = [
    'Moving',
    'Stopped',
    'Idle',
    'Non Coverage',
    'Disconnected',
  ];

  final List<String> _evStatuses = [
    'Charging',
    'Discharging',
    'Idle',
    'Non Coverage',
    'Disconnected',
  ];

  final List<String> _activeNonEVStatuses = [
    'Moving',
    'Stopped',
    'Idle',
    'Non Coverage',
  ];
  final List<String> _activeEVStatuses = [
    'Charging',
    'Discharging',
    'Idle',
    'Non Coverage',
  ];
  final List<String> _inactiveStatuses = ['Disconnected'];

  final Map<String, Color> _nonEVStatusColors = {
    'Moving': tGreen,
    'Stopped': tRed,
    'Idle': tOrange1,
    'Non Coverage': const Color(0xFF9C27B0),
    'Disconnected': tGrey,
  };

  final Map<String, Color> _evStatusColors = {
    'Discharging': tGreen,
    'Charging': tBlue,
    'Idle': tOrange1,
    'Non Coverage': const Color(0xFF9C27B0),
    'Disconnected': tGrey,
  };

  Color _statusColor(String status, bool isEVFleet) {
    final map = isEVFleet ? _evStatusColors : _nonEVStatusColors;
    return map[status] ?? tGreen8;
  }

  bool _isActiveStatus(String status, bool isEVFleet) {
    if (isEVFleet) {
      return _activeEVStatuses.contains(status);
    } else {
      return _activeNonEVStatuses.contains(status);
    }
  }

  bool _isInactiveStatus(String status) {
    return _inactiveStatuses.contains(status);
  }

  List<String> _getFilteredStatuses(bool isEVFleet) {
    final allStatuses = isEVFleet ? _evStatuses : _nonEVStatuses;

    if (availability == 'All') {
      return allStatuses;
    } else if (availability == 'Active') {
      return allStatuses
          .where((status) => _isActiveStatus(status, isEVFleet))
          .toList();
    } else if (availability == 'Inactive') {
      return allStatuses.where((status) => _isInactiveStatus(status)).toList();
    }

    return allStatuses;
  }

  void _resetFilters() {
    setState(() {
      availability = 'All';
      vehicleStatus = 'All';
      format = 'XLSX'; // default format

      range = 'All';
      selectedRangeDays = null;
      _isRangeSelected = false;

      final now = DateTime.now();
      fromDate = now;
      toDate = now;

      _selectedImeis.clear();
      _selectedGroupIds.clear();

      _searchFieldController?.clear();
    });
  }

  void _applyRange(String range) {
    final now = DateTime.now();
    setState(() {
      this.range = range;
      _isRangeSelected = true;
    });

    switch (range) {
      case 'Last 7 Days':
        selectedRangeDays = 7;
        fromDate = now.subtract(const Duration(days: 7));
        break;
      case 'Last 15 Days':
        selectedRangeDays = 15;
        fromDate = now.subtract(const Duration(days: 15));
        break;
      case 'Last 30 Days':
        selectedRangeDays = 30;
        fromDate = now.subtract(const Duration(days: 30));
        break;
      case 'Last 60 Days':
        selectedRangeDays = 60;
        fromDate = now.subtract(const Duration(days: 60));
        break;
      case 'Last 90 Days':
        selectedRangeDays = 90;
        fromDate = now.subtract(const Duration(days: 90));
        break;

      default:
        selectedRangeDays = null;
        fromDate = now;
        _isRangeSelected = false;
    }

    toDate = now;
  }

  List<Groups> _groups = [];
  List<String> _imeis = [];
  List<String> _searchItems = [];
  List<String> _selectedGroupIds = [];
  List<String> _selectedImeis = [];

  Future<void> _loadUserReport() async {
    try {
      final reportApi = ReportsApiService();

      final res = await reportApi.fetchUserReport();

      if (mounted) {
        setState(() {
          _groups = res.groups ?? [];
          _imeis = res.imeis ?? [];

          _searchItems = [
            ..._imeis,
            ..._groups.map((g) => g.name ?? ''),
            ..._groups.map((g) => g.id ?? ''),
          ];
        });
      }
    } catch (e) {
      print('Error loading user report: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _loadUserReport();
    fromDate = now;
    toDate = now;
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return "${date.day.toString().padLeft(2, '0')} "
        "${months[date.month - 1]} "
        "${date.year}";
  }

  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  int _calculateRangeDays() {
    return selectedRangeDays ?? 0;
  }

  Future<void> _downloadReport() async {
    if (isDownloading) return;
    setState(() {
      isDownloading = true;
      isLoading = true;
    });

    try {
      // String fromDateApi = _formatDateForApi(DateTime.now());
      // String toDateApi = _formatDateForApi(DateTime.now());
      int rangeDays = _calculateRangeDays();

      String? imeiList =
          _selectedImeis.isNotEmpty ? _selectedImeis.join(',') : null;
      String? groupId =
          _selectedGroupIds.isNotEmpty ? _selectedGroupIds.join(',') : null;

      String? availabilityParam = availability != 'All' ? availability : null;
      String? statusParam = vehicleStatus != 'All' ? vehicleStatus : null;
      String formatParam = format.toLowerCase();
      final vehicleReportApi = VehicleReportApiService();

      if (_isRangeSelected && selectedRangeDays != null) {
        // Using range days
        await vehicleReportApi.downloadReport(
          context: context,
          // fromDate: '',
          // toDate: '',
          imeiList: imeiList,
          groupId: groupId,
          rangeDays: rangeDays,
          status: statusParam,
          availability: availabilityParam,
          format: formatParam,
          onSuccess: (message) {
            if (mounted) {
              setState(() {
                isDownloading = false;
                isLoading = false;
              });
            }

            CustomToast.show(
              context: context,
              message: "Report Generated  Successfully",
              type: ToastType.success,
            );

            print('Download success: $message');
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                isDownloading = false;
                isLoading = false;
              });

              CustomToast.show(
                context: context,
                message: error,
                type: ToastType.error,
              );
            }
            print('Download error: $error');
          },
        );
      } else {
        // Using individual dates
        await vehicleReportApi.downloadReport(
          context: context,
          // fromDate: fromDateApi,
          // toDate: toDateApi,
          imeiList: imeiList,
          groupId: groupId,
          rangeDays: rangeDays,
          status: statusParam,
          availability: availabilityParam,
          format: formatParam,
          onSuccess: (message) {
            if (mounted) {
              setState(() {
                isDownloading = false;
                isLoading = false;
              });
            }
            _resetFilters();

            CustomToast.show(
              context: context,
              message: "Report Generated  Successfully",
              type: ToastType.success,
            );
            print('Download success: $message');
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                isDownloading = false;
                isLoading = false;
              });

              CustomToast.show(
                context: context,
                message: error,
                type: ToastType.error,
              );
            }
            print('Download error: $error');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isDownloading = false;
          isLoading = false;
        });

        CustomToast.show(
          context: context,
          message:
              "Error: ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e.toString()}",
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;
    final bool isEVFleet = mode == 'EV Fleet';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = widget.isMobile || (screenWidth <= 600);

    final filteredStatuses = _getFilteredStatuses(isEVFleet);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.urbanist(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                          fontSize: isMobile ? 11 : 13,
                          color: (isDark ? tWhite : tBlack).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isMobile ? 15 : 0),
                _filterButton(isDark, isMobile),
              ],
            ),
            const SizedBox(height: 5),
            Divider(
              color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
              height: 1,
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row(
                // children: [
                /// FROM DATE
                //     Row(
                //       children: [
                //         _dateLabelBox('From ', isDark),
                //         const SizedBox(width: 5),
                //         _dateValueBox(
                //           _formatDate(fromDate!),
                //           isDark,
                //           onTap: () async {
                //             final picked = await showDatePicker(
                //               context: context,
                //               initialDate: fromDate!,
                //               firstDate: DateTime(2020),
                //               lastDate: DateTime.now(),
                //             );
                //             if (picked != null) {
                //               setState(() {
                //                 fromDate = picked;
                //                 range = 'All';
                //                 _isRangeSelected = false;
                //                 selectedRangeDays = null;
                //               });
                //             }
                //           },
                //         ),
                //       ],
                //     ),
                //     const SizedBox(width: 30),

                //     /// TO DATE
                //     Row(
                //       children: [
                //         _dateLabelBox('To', isDark),
                //         const SizedBox(width: 5),
                //         _dateValueBox(
                //           _formatDate(toDate!),
                //           isDark,
                //           onTap: () async {
                //             final picked = await showDatePicker(
                //               context: context,
                //               initialDate: toDate!,
                //               firstDate: DateTime(2020),
                //               lastDate: DateTime.now(),
                //             );
                //             if (picked != null) {
                //               setState(() {
                //                 toDate = picked;
                //                 range = 'All';
                //                 _isRangeSelected = false;
                //                 selectedRangeDays = null;
                //               });
                //             }
                //           },
                //         ),
                //       ],
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 10),
                _chipSection(
                  title: "Filter by Availability",
                  options: availabilityOptions,
                  selected: availability,
                  onSelected: (val) {
                    setState(() {
                      availability = val;
                      vehicleStatus = 'All';
                    });
                  },
                  isDark: isDark,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 10),
                _chipSection(
                  title: "Filter by Vehicle Status",
                  options: [...filteredStatuses],
                  selected: vehicleStatus,
                  onSelected: (val) => setState(() => vehicleStatus = val),
                  isDark: isDark,
                  isMobile: isMobile,
                  isEVFleet: isEVFleet,
                  showStatusColors: true,
                ),

                const SizedBox(height: 15),
                Text(
                  // 'Filter by  IMEI or Group Name',
                  'Filter by Group Name',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                const SizedBox(height: 10),
                _searchField(isDark, isMobile),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _downloadReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tGreen8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child:
                      isLoading
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: tWhite,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Downloading...',
                                style: GoogleFonts.urbanist(
                                  fontSize: isMobile ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: tWhite,
                                ),
                              ),
                            ],
                          )
                          : Text(
                            'Generate Report',
                            style: GoogleFonts.urbanist(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: tWhite,
                            ),
                          ),
                ),
              ],
            ),
          ],
        ),
        if (_showFilterPanel)
          Positioned(
            top: 50,
            right: 0,
            left:
                (widget.isMobile || MediaQuery.of(context).size.width < 600)
                    ? 0
                    : null,
            child: _buildFilterPanel(isDark),
          ),
      ],
    );
  }

  Widget _dateLabelBox(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tTransparent,
        border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.urbanist(
          fontSize: 13,
          color: isDark ? tWhite : tBlack,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _dateValueBox(
    String value,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tTransparent,
          border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
        ),
        child: Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _chipSection({
    required String title,
    required List<String> options,
    required String selected,
    required Function(String) onSelected,
    required bool isDark,
    required bool isMobile,
    bool? isEVFleet,
    bool showStatusColors = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children:
              options.map((option) {
                final isSelected = selected == option;

                Color? selectedColor;
                if (showStatusColors && isEVFleet != null && option != 'All') {
                  selectedColor = _statusColor(option, isEVFleet);
                } else if (!showStatusColors) {
                  selectedColor = tGreen8; // For availability chips
                }

                return ChoiceChip(
                  showCheckmark: true,
                  checkmarkColor: tWhite,
                  label: Text(
                    option,
                    style: GoogleFonts.urbanist(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? tWhite : (isDark ? tWhite : tBlack),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: selectedColor ?? tGreen8,
                  backgroundColor:
                      isDark ? tGrey.withOpacity(0.1) : tBlack.withOpacity(0.1),
                  side: BorderSide(color: Colors.transparent, width: 0),
                  // onSelected: (_) => onSelected(option),
                  onSelected: (_) {
                    if (selected == option) {
                      // Unselect → reset to default
                      onSelected('All');
                    } else {
                      onSelected(option);
                    }
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _searchField(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// SEARCH FIELD
        LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                // final allOptions = [..._imeis, ..._groups.map((g) => g.name ?? '')];
                final allOptions = _groups.map((g) => g.name ?? '');

                if (textEditingValue.text.isEmpty) {
                  return allOptions;
                }

                return allOptions.where(
                  (item) => item.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              // onSelected: (selection) {
              //   final matchedImei = _imeis.firstWhere(
              //     (imei) => imei.toLowerCase() == selection.toLowerCase(),
              //     orElse: () => '',
              //   );

              //   if (matchedImei.isNotEmpty) {
              //     if (!_selectedImeis.contains(matchedImei)) {
              //       setState(() {
              //         _selectedGroupIds.clear();
              //         _selectedImeis.add(matchedImei);
              //       });
              //     }
              //   } else {
              //     final group = _groups.firstWhere(
              //       (g) =>
              //           g.name?.toLowerCase() == selection.toLowerCase() ||
              //           g.id == selection,
              //       orElse: () => Groups(),
              //     );

              //     if (group.id != null && !_selectedGroupIds.contains(group.id)) {
              //       setState(() {
              //         /// clear imeis when group selected
              //         _selectedImeis.clear();
              //         _selectedGroupIds.add(group.id!);
              //       });
              //     }
              //   }

              //   // Clear the search field
              //   _searchFieldController?.clear();
              //   FocusScope.of(context).unfocus();
              // },
              onSelected: (selection) {
                final group = _groups.firstWhere(
                  (g) => g.name?.toLowerCase() == selection.toLowerCase(),
                  orElse: () => Groups(),
                );

                // if (group.id != null && !_selectedGroupIds.contains(group.id)) {
                //   setState(() {
                //     _selectedGroupIds.add(group.id!);
                //   });
                // }
                if (group.id != null) {
                  setState(() {
                    _selectedGroupIds.clear();

                    _selectedGroupIds.add(group.id!);
                  });
                }

                _searchFieldController?.clear();
                searchController.clear();

                FocusScope.of(context).unfocus();
              },

              fieldViewBuilder: (context, controller, focusNode, _) {
                _searchFieldController = controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  cursorColor: isDark ? tWhite : tBlack,
                  style: GoogleFonts.urbanist(
                    fontSize: isMobile ? 11 : 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? tWhite : tBlack,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search...",
                    hintStyle: GoogleFonts.urbanist(
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.6)
                              : tBlack.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search_outlined,
                      size: 18,
                      color: isDark ? tWhite : tBlack,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide: BorderSide(
                        color: isDark ? tWhite : tBlack,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide: BorderSide(
                        color: isDark ? tWhite : tBlack,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide: BorderSide(
                        color: isDark ? tWhite : tBlack,
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.transparent, // IMPORTANT
                    child: Container(
                      margin: EdgeInsets.only(top: 6),
                      width: constraints.maxWidth,
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
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 200,
                          maxWidth:
                              isMobile
                                  ? MediaQuery.of(context).size.width - 32
                                  : MediaQuery.of(context).size.width * 0.57,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);

                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color:
                                          isDark
                                              ? tWhite.withOpacity(0.1)
                                              : tBlack.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: GoogleFonts.urbanist(
                                    fontSize: isMobile ? 11 : 13,
                                    color: isDark ? tWhite : tBlack,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 10),

        /// SELECTED IMEIs and GROUPS
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            /// GROUP CHIPS
            ..._selectedGroupIds.map((groupId) {
              final group = _groups.firstWhere(
                (g) => g.id == groupId,
                orElse: () => Groups(),
              );

              return Chip(
                label: Text(group.name ?? groupId),
                deleteIcon: SvgPicture.asset(
                  'icons/cancel.svg',
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                ),
                onDeleted: () {
                  setState(() {
                    _selectedGroupIds.remove(groupId);
                    // Clear the search field when deleting group
                    _searchFieldController?.clear();
                  });
                },
                backgroundColor:
                    isDark ? tGrey.withOpacity(0.1) : tBlack.withOpacity(0.1),
                deleteIconColor: Colors.grey,
                labelStyle: TextStyle(
                  color: isDark ? tWhite : tBlack,
                  fontSize: 12,
                ),
                side: BorderSide.none,
              );
            }),

            /// IMEI CHIPS
            ..._selectedImeis.map((imei) {
              return Chip(
                label: Text(imei),
                // deleteIcon: const Icon(Icons.close, size: 16),
                deleteIcon: SvgPicture.asset(
                  'icons/cancel.svg',
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                ),
                onDeleted: () {
                  setState(() {
                    _selectedImeis.remove(imei);
                    // Clear the search field when deleting IMEI
                    _searchFieldController?.clear();
                  });
                },
                backgroundColor:
                    isDark ? tWhite.withOpacity(0.15) : tBlack.withOpacity(0.1),
                deleteIconColor: Colors.grey,
                labelStyle: TextStyle(
                  color: isDark ? tWhite : tBlack,
                  fontSize: 13,
                ),
                side: BorderSide.none,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _filterButton(bool isDark, bool isMobile) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: tTransparent,
      border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
    ),
    child: IconButton(
      onPressed: () {
        if (isMobile) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _buildFilterPanel(isDark),
          );
        } else {
          setState(() => _showFilterPanel = !_showFilterPanel);
        }
      },
      icon: SvgPicture.asset(
        'icons/filter.svg',
        width: 18,
        height: 18,
        color: isDark ? tWhite : tBlack,
      ),
    ),
  );

  Widget _buildFilterPanel(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = widget.isMobile || screenWidth < 600;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? tBlack : tWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: _buildFilterContent(isDark, true),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 350,
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? tWhite : tBlack),
          ),
          child: _buildFilterContent(isDark, false),
        ),
      ),
    );
  }

  Widget _buildFilterContent(bool isDark, bool isMobile) {
    return StatefulBuilder(
      builder: (context, modalSetState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Filter by Format",
              style: GoogleFonts.urbanist(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: isDark ? tWhite : tBlack,
              ),
            ),

            SizedBox(height: isMobile ? 8 : 10),

            Wrap(
              spacing: isMobile ? 6 : 8,
              runSpacing: isMobile ? 6 : 8,
              children:
                  formatOptions.map((option) {
                    final isSelected = format == option;

                    return FilterChip(
                      label: Text(
                        option,
                        style: GoogleFonts.urbanist(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isSelected
                                  ? Colors.white
                                  : (isDark ? tWhite : tBlack),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: tGreen8,
                      checkmarkColor: tWhite,
                      onSelected: (_) {
                        modalSetState(() {
                          format = option;
                        });

                        setState(() {
                          format = option;
                        });
                      },
                    );
                  }).toList(),
            ),

            SizedBox(height: isMobile ? 20 : 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isMobile) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      _showFilterPanel = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tGreen8,
                  foregroundColor: tWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Apply Filters",
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tWhite,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
