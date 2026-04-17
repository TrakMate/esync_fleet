import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:svg_flutter/svg.dart';

import '../../../models/userReportModel.dart';
import '../../../provider/fleetModeProvider.dart';
import '../../../services/generalAPIServices.dart/reportApiServices/reportsAPIService.dart';
import '../../../services/generalAPIServices.dart/reportApiServices/vehicleSummaryReportAPIService.dart';
import '../../../utils/appColors.dart';
import 'custom_Toast.dart';

class VehicleSummaryReportView extends StatefulWidget {
  final String title;
  final String description;
  const VehicleSummaryReportView({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<VehicleSummaryReportView> createState() =>
      _VehicleSummaryReportViewState();
}

class _VehicleSummaryReportViewState extends State<VehicleSummaryReportView> {
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

  final List<String> _activeNonEVStatuses = ['Moving', 'Stopped', 'Idle'];
  final List<String> _activeEVStatuses = ['Charging', 'Discharging', 'Idle'];
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
    return map[status] ?? tBlue;
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
      case 'Last 120 Days':
        selectedRangeDays = 120;
        fromDate = now.subtract(const Duration(days: 120));
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
    setState(() {
      isDownloading = true;
      isLoading = true;
    });

    try {
      String toDateApi = _formatDateForApi(toDate!);
      int rangeDays = _calculateRangeDays();

      String? imei =
          _selectedImeis.isNotEmpty ? _selectedImeis.join(',') : null;
      String? groupId =
          _selectedGroupIds.isNotEmpty ? _selectedGroupIds.join(',') : null;

      String? availabilityParam = availability != 'All' ? availability : null;
      String? statusParam = vehicleStatus != 'All' ? vehicleStatus : null;
      String formatParam = format.isNotEmpty ? format.toLowerCase() : 'csv';

      final vehicleSummaryApi = VehicleSummaryApiService();

      if (_isRangeSelected && selectedRangeDays != null) {
        // Using range days
        await vehicleSummaryApi.downloadReport(
          context: context,
          toDate: '',
          imei: imei,
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
        await vehicleSummaryApi.downloadReport(
          context: context,
          toDate: toDateApi,
          imei: imei,
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

    final filteredStatuses = _getFilteredStatuses(isEVFleet);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: (isDark ? tWhite : tBlack).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                _filterButton(isDark),
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
                Row(
                  children: [
                    /// FROM DATE
                    // Row(
                    //   children: [
                    //     _dateLabelBox('From ', isDark),
                    //     const SizedBox(width: 5),
                    //     _dateValueBox(
                    //       _formatDate(fromDate!),
                    //       isDark,
                    //       onTap: () async {
                    //         final picked = await showDatePicker(
                    //           context: context,
                    //           initialDate: fromDate!,
                    //           firstDate: DateTime(2020),
                    //           lastDate: DateTime.now(),
                    //         );
                    //         if (picked != null) {
                    //           setState(() {
                    //             fromDate = picked;
                    //             range = 'All';
                    //             _isRangeSelected = false;
                    //             selectedRangeDays = null;
                    //           });
                    //         }
                    //       },
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(width: 30),

                    /// TO DATE
                    Row(
                      children: [
                        _dateLabelBox('Date', isDark),
                        const SizedBox(width: 5),
                        _dateValueBox(
                          _formatDate(toDate!),
                          isDark,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: toDate!,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                toDate = picked;
                                range = 'All';
                                _isRangeSelected = false;
                                selectedRangeDays = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                // const SizedBox(height: 10),
                // _chipSection(
                //   title: "Filter by Availability",
                //   options: availabilityOptions,
                //   selected: availability,
                //   onSelected: (val) {
                //     setState(() {
                //       availability = val;
                //       vehicleStatus = 'All';
                //     });
                //   },
                //   isDark: isDark,
                // ),
                // const SizedBox(height: 10),
                // _chipSection(
                //   title: "Filter by Vehicle Status",
                //   options: [...filteredStatuses],
                //   selected: vehicleStatus,
                //   onSelected: (val) => setState(() => vehicleStatus = val),
                //   isDark: isDark,
                //   isEVFleet: isEVFleet,
                //   showStatusColors: true,
                // ),
                const SizedBox(height: 15),
                Text(
                  'Search by IMEI',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                const SizedBox(height: 10),
                _searchField(isDark),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isLoading ? null : _downloadReport,
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: tWhite,
                                ),
                              ),
                            ],
                          )
                          : Text(
                            'Generate Report',
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tBlack,
                            ),
                          ),
                ),
              ],
            ),
          ],
        ),
        if (_showFilterPanel)
          Positioned(top: 50, right: 0, child: _buildFilterPanel(isDark)),
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
                  checkmarkColor: tBlack,
                  label: Text(
                    option,
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? tBlack : (isDark ? tWhite : tBlack),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: selectedColor ?? tGreen8,
                  backgroundColor:
                      isDark
                          ? tWhite.withOpacity(0.15)
                          : tBlack.withOpacity(0.1),
                  side: BorderSide(color: Colors.transparent, width: 0),
                  onSelected: (_) => onSelected(option),
                );
              }).toList(),
        ),
      ],
    );
  }

  // Widget _searchField(bool isDark) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Autocomplete<String>(
  //         optionsBuilder: (TextEditingValue textEditingValue) {
  //           if (textEditingValue.text.isEmpty) {
  //             return const Iterable<String>.empty();
  //           }

  //           return _imeis.where(
  //             (item) => item.toLowerCase().contains(
  //               textEditingValue.text.toLowerCase(),
  //             ),
  //           );
  //         },

  //         onSelected: (selection) {
  //           if (!_selectedImeis.contains(selection)) {
  //             setState(() {
  //               _selectedImeis.add(selection);
  //             });
  //           }

  //           searchController.clear();
  //           FocusScope.of(context).unfocus();
  //         },

  //         // fieldViewBuilder: (context, controller, focusNode, _) {
  //         //   return TextField(
  //         //     controller: controller,
  //         //     focusNode: focusNode,
  //         //     decoration: InputDecoration(
  //         //       hintText: "Enter IMEI",
  //         //       hintStyle: GoogleFonts.urbanist(
  //         //         fontSize: 13,
  //         //         fontWeight: FontWeight.w500,
  //         //         color:
  //         //             isDark
  //         //                 ? tWhite.withOpacity(0.6)
  //         //                 : tBlack.withOpacity(0.6),
  //         //       ),
  //         //       prefixIcon: Icon(
  //         //         Icons.search_outlined,
  //         //         size: 18,
  //         //         color: isDark ? tWhite : tBlack,
  //         //       ),
  //         //       border: OutlineInputBorder(
  //         //         borderRadius: BorderRadius.circular(0),
  //         //       ),
  //         //     ),
  //         //   );
  //         // },
  //         fieldViewBuilder: (context, controller, focusNode, _) {
  //           return TextField(
  //             controller: controller,
  //             focusNode: focusNode,
  //             cursorColor: isDark ? tWhite : tBlack, // ← Add this
  //             style: GoogleFonts.urbanist(
  //               fontSize: 13,
  //               fontWeight: FontWeight.w500,
  //               color: isDark ? tWhite : tBlack, // ← Add this
  //             ),
  //             decoration: InputDecoration(
  //               hintText: "Enter IMEI",
  //               hintStyle: GoogleFonts.urbanist(
  //                 fontSize: 13,
  //                 fontWeight: FontWeight.w500,
  //                 color:
  //                     isDark
  //                         ? tWhite.withOpacity(0.6)
  //                         : tBlack.withOpacity(0.6),
  //               ),
  //               prefixIcon: Icon(
  //                 Icons.search_outlined,
  //                 size: 18,
  //                 color: isDark ? tWhite : tBlack,
  //               ),
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(0),
  //                 borderSide: BorderSide(
  //                   // ← Add this
  //                   color: isDark ? tWhite : tBlack,
  //                   width: 1,
  //                 ),
  //               ),
  //               enabledBorder: OutlineInputBorder(
  //                 // ← Add this
  //                 borderRadius: BorderRadius.circular(0),
  //                 borderSide: BorderSide(
  //                   color: isDark ? tWhite : tBlack,
  //                   width: 1,
  //                 ),
  //               ),
  //               focusedBorder: OutlineInputBorder(
  //                 // ← Add this
  //                 borderRadius: BorderRadius.circular(0),
  //                 borderSide: BorderSide(
  //                   color: isDark ? tWhite : tBlack,
  //                   width: 1,
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       ),

  //       const SizedBox(height: 10),

  //       /// IMEI CHIPS ONLY
  //       Wrap(
  //         spacing: 6,
  //         runSpacing: 6,
  //         children:
  //             _selectedImeis.map((imei) {
  //               return Chip(
  //                 label: Text(imei),
  //                 deleteIcon: const Icon(Icons.close, size: 16),
  //                 onDeleted: () {
  //                   setState(() {
  //                     _selectedImeis.remove(imei);
  //                   });
  //                 },
  //               );
  //             }).toList(),
  //       ),
  //     ],
  //   );
  // }
  Widget _searchField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _imeis;
            }

            return _imeis.where(
              (item) => item.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
          },

          onSelected: (selection) {
            if (!_selectedImeis.contains(selection)) {
              setState(() {
                _selectedImeis.add(selection);
              });
            }

            // Clear the search field after selection
            _searchFieldController?.clear();
            FocusScope.of(context).unfocus();
          },

          fieldViewBuilder: (context, controller, focusNode, _) {
            // Store reference to the controller
            _searchFieldController = controller;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              cursorColor: isDark ? tWhite : tBlack,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? tWhite : tBlack,
              ),
              decoration: InputDecoration(
                hintText: "Enter IMEI",
                hintStyle: GoogleFonts.urbanist(
                  fontSize: 13,
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
                elevation: 4,
                color:
                    isDark
                        ? Colors.grey[900]
                        : Colors.white, // Dropdown background color
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
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
                          child: Row(
                            children: [
                              // Icon(
                              //   Icons.phone_android,
                              //   size: 16,
                              //   color: isDark ? tWhite : tBlack,
                              // ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 13,
                                    color: isDark ? tWhite : tBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        /// IMEI CHIPS ONLY
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children:
              _selectedImeis.map((imei) {
                return Chip(
                  label: Text(imei),
                  deleteIcon: SvgPicture.asset(
                    'icons/cancel.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  ),
                  onDeleted: () {
                    setState(() {
                      _selectedImeis.remove(imei);
                      // Clear the search field when deleting chip
                      _searchFieldController?.clear();
                    });
                  },
                  backgroundColor:
                      isDark
                          ? tWhite.withOpacity(0.15)
                          : tBlack.withOpacity(0.1),
                  deleteIconColor: Colors.grey,
                  labelStyle: TextStyle(
                    color: isDark ? tWhite : tBlack,
                    fontSize: 12,
                  ),
                  side: const BorderSide(color: Colors.grey),
                );
              }).toList(),
        ),
      ],
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

  Widget _buildFilterPanel(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? tBlack : tWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? tWhite : tBlack),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _chipSection(
            //   title: "Range",
            //   options: rangeOptions,
            //   selected: range,
            //   onSelected: (val) {
            //     setState(() {
            //       _applyRange(val);
            //     });
            //   },
            //   isDark: isDark,
            // ),
            // const SizedBox(height: 15),
            _chipSection(
              title: "Filter by Format",
              options: formatOptions,
              selected: format,
              onSelected: (val) => setState(() => format = val),
              isDark: isDark,
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showFilterPanel = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tGreen8,
                  foregroundColor: tBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Apply Filters",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
