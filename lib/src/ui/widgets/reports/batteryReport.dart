import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg.dart';
import '../../../models/alertDashboardModel.dart';
import '../../../services/generalAPIServices.dart/reportApiServices/batteryReportAPIService.dart';
import '../../../services/generalAPIServices.dart/reportApiServices/reportsAPIService.dart';
import '../../../utils/appColors.dart';
import 'custom_Toast.dart';

class Batteryreport extends StatefulWidget {
  final String title;
  final String description;
  const Batteryreport({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<Batteryreport> createState() => _BatteryreportState();
}

class _BatteryreportState extends State<Batteryreport> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool isDownloading = false;
  bool _showFilterPanel = false;
  String format = 'XLSX';
  String range = 'All';
  String? selectedBatteryStatus;
  String? selectedVehicleType;
  int? selectedRangeDays;
  final List<String> formatOptions = ['Logs', 'XLSX', 'CSV', 'JSON', 'XML'];
  String selectedFormat = 'csv';
  bool _isRangeSelected = false;
  final TextEditingController searchController = TextEditingController();
  TextEditingController? _searchFieldController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _loadUserReport();
    fromDate = now;
    toDate = now;
    selectedBatteryStatus = 'All';
    selectedVehicleType = 'All';
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
          _groups = [];
          _imeis = [];

          if (res.groups != null && res.groups is List) {
            try {
              _groups =
                  (res.groups as List)
                      .map((item) {
                        if (item is Groups) {
                          return item;
                        } else if (item is Map) {
                          return Groups.fromJson(item as Map<String, dynamic>);
                        }
                        return null;
                      })
                      .whereType<Groups>()
                      .toList();
            } catch (e) {
              print('Error parsing groups: $e');
              _groups = [];
            }
          }

          if (res.imeis != null && res.imeis is List) {
            try {
              _imeis =
                  (res.imeis as List)
                      .map((item) => item.toString())
                      .where((item) => item.isNotEmpty)
                      .toList();
            } catch (e) {
              print('Error parsing imeis: $e');
              _imeis = [];
            }
          }

          _searchItems =
              [
                ..._imeis,
                ..._groups.map((g) => g.name ?? ''),
                ..._groups.map((g) => g.id ?? ''),
              ].where((item) => item.isNotEmpty).toList();

          print('Loaded ${_imeis.length} IMEIs and ${_groups.length} groups');
        });
      }
    } catch (e) {
      print('Error loading user report: $e');
      print('Error details: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user data: ${e.toString()}'),
            backgroundColor: tRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  final List<String> rangeOptions = [
    'Last 7 Days',
    'Last 15 Days',
    'Last 30 Days',
    'Last 60 Days',
    'Last 90 Days',
  ];

  void _downloadReport() async {
    setState(() {
      isLoading = true;
      isDownloading = true;
    });

    try {
      if (fromDate == null || toDate == null) {
        throw Exception("Please select both From and To dates");
      }

      String fromDateApi = _formatDateForApi(fromDate!);
      String toDateApi = _formatDateForApi(toDate!);

      print("FROM DATE 👉 $fromDateApi");
      print("TO DATE 👉 $toDateApi");

      String? imeiParam =
          _selectedImeis.isNotEmpty ? _selectedImeis.join(',') : null;

      String? groupIdParam =
          _selectedGroupIds.isNotEmpty ? _selectedGroupIds.join(',') : null;

      String? batteryStatusParam =
          selectedBatteryStatus != null && selectedBatteryStatus != 'All'
              ? selectedBatteryStatus
              : null;

      String? vehicleTypeParam =
          selectedVehicleType != null && selectedVehicleType != 'All'
              ? selectedVehicleType
              : null;

      // String formatParam = (format.isNotEmpty ? format : 'csv').toLowerCase();
      String formatParam = format.isNotEmpty ? format.toLowerCase() : 'csv';

      final batteryReportApi = BatteryReportApiService();

      await batteryReportApi.downloadReport(
        context: context,
        fromDate: fromDateApi,
        toDate: toDateApi,
        imei: imeiParam,
        groupId: groupIdParam,
        batteryStatus: batteryStatusParam,
        vehicleType: vehicleTypeParam,
        format: formatParam,
        onSuccess: (message) {
          if (!mounted) return;

          setState(() {
            isDownloading = false;
            isLoading = false;
          });

          CustomToast.show(
            context: context,
            message: "Report Generated  Successfully",
            type: ToastType.success,
          );
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            isDownloading = false;
            isLoading = false;
          });

          CustomToast.show(
            context: context,
            message: error,
            type: ToastType.error,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

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

  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
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

            Row(
              children: [
                Row(
                  children: [
                    _dateLabelBox('from', isDark),
                    const SizedBox(width: 5),
                    _dateValueBox(
                      _formatDate(fromDate!),
                      isDark,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fromDate!,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => fromDate = picked);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 30),

                /// TO DATE
                Row(
                  children: [
                    _dateLabelBox('To', isDark),
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

            const SizedBox(height: 15),

            // Search Section
            Text(
              'Search by IMEI ',
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? tWhite : tBlack,
              ),
            ),
            const SizedBox(height: 10),
            _searchField(isDark),

            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _downloadReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: tBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Generate Report',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tWhite,
                ),
              ),
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
          color: tBlue,
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

  // Widget _searchField(bool isDark) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       /// SEARCH FIELD
  //       Autocomplete<String>(
  //         optionsBuilder: (TextEditingValue textEditingValue) {
  //           if (textEditingValue.text.isEmpty) {
  //             return const Iterable<String>.empty();
  //           }

  //           return [..._imeis, ..._groups.map((g) => g.name ?? '')].where(
  //             (item) => item.toLowerCase().contains(
  //               textEditingValue.text.toLowerCase(),
  //             ),
  //           );
  //         },
  //         onSelected: (selection) {
  //           /// If IMEI selected
  //           if (_imeis.contains(selection)) {
  //             if (!_selectedImeis.contains(selection)) {
  //               setState(() {
  //                 _selectedGroupIds.clear();
  //                 _selectedImeis.add(selection);
  //               });
  //             }
  //           } else {
  //             /// If Group selected
  //             final group = _groups.firstWhere(
  //               (g) => g.name == selection || g.id == selection,
  //               orElse: () => Groups(),
  //             );

  //             if (group.id != null &&
  //                 group.id!.isNotEmpty &&
  //                 !_selectedGroupIds.contains(group.id)) {
  //               setState(() {
  //                 /// clear imeis when group selected
  //                 _selectedImeis.clear();
  //                 _selectedGroupIds.add(group.id!);
  //               });
  //             }
  //           }

  //           searchController.clear();
  //           FocusScope.of(context).unfocus();
  //         },
  //         // fieldViewBuilder: (context, controller, focusNode, _) {
  //         //   return TextField(
  //         //     controller: controller,
  //         //     focusNode: focusNode,
  //         //     decoration: InputDecoration(
  //         //       hintText: "Enter  IMEI",
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

  //       /// SELECTED ITEMS DISPLAY
  //       if (_selectedGroupIds.isNotEmpty || _selectedImeis.isNotEmpty)
  //         Wrap(
  //           spacing: 6,
  //           runSpacing: 6,
  //           children: [
  //             /// GROUP CHIPS
  //             ..._selectedGroupIds.map((groupId) {
  //               final group = _groups.firstWhere(
  //                 (g) => g.id == groupId,
  //                 orElse: () => Groups(),
  //               );

  //               return Chip(
  //                 label: Text(group.name ?? groupId),
  //                 deleteIcon: const Icon(Icons.close, size: 16),
  //                 onDeleted: () {
  //                   setState(() {
  //                     _selectedGroupIds.remove(groupId);
  //                   });
  //                 },
  //               );
  //             }),

  //             /// IMEI CHIPS
  //             ..._selectedImeis.map((imei) {
  //               return Chip(
  //                 label: Text(imei),
  //                 deleteIcon: const Icon(Icons.close, size: 16),
  //                 onDeleted: () {
  //                   setState(() {
  //                     _selectedImeis.remove(imei);
  //                   });
  //                 },
  //               );
  //             }),
  //           ],
  //         ),
  //     ],
  //   );
  // }
  Widget _searchField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// SEARCH FIELD
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            final allOptions = [..._imeis, ..._groups.map((g) => g.name ?? '')];

            if (textEditingValue.text.isEmpty) {
              return allOptions;
            }

            return allOptions.where(
              (item) => item.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
          },
          onSelected: (selection) {
            if (_imeis.contains(selection)) {
              if (!_selectedImeis.contains(selection)) {
                setState(() {
                  _selectedGroupIds.clear();
                  _selectedImeis.add(selection);
                });
              }
            } else {
              final group = _groups.firstWhere(
                (g) => g.name == selection || g.id == selection,
                orElse: () => Groups(),
              );

              if (group.id != null && !_selectedGroupIds.contains(group.id)) {
                setState(() {
                  _selectedImeis.clear();
                  _selectedGroupIds.add(group.id!);
                });
              }
            }

            _searchFieldController?.clear();
            searchController.clear();
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
                color: isDark ? Colors.grey[900] : Colors.white,
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

                      final bool isImei = _imeis.contains(option);

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
                              //   isImei ? Icons.phone_android : Icons.group,
                              //   size: 16,
                              //   color: isDark ? tWhite : tBlack,
                              // ),
                              const SizedBox(width: 8),
                              // Option text
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 13,
                                    color: isDark ? tWhite : tBlack,
                                  ),
                                ),
                              ),
                              //
                              if (!isImei) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? Colors.grey[800]
                                            : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Group",
                                    style: GoogleFonts.urbanist(
                                      fontSize: 10,
                                      color: isDark ? tWhite : tBlack,
                                    ),
                                  ),
                                ),
                              ],
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
                    _searchFieldController?.clear();
                  });
                },
                backgroundColor:
                    isDark ? tWhite.withOpacity(0.15) : tBlack.withOpacity(0.1),
                deleteIconColor: Colors.grey,
                labelStyle: TextStyle(
                  color: isDark ? tWhite : tBlack,
                  fontSize: 12,
                ),
                side: const BorderSide(color: Colors.grey),
                avatar: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  radius: 12,
                  child: Icon(Icons.group, size: 12, color: Colors.grey[700]),
                ),
              );
            }),

            /// IMEI CHIPS
            ..._selectedImeis.map((imei) {
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
                    // Clear the search field when deleting IMEI
                    _searchFieldController?.clear();
                  });
                },
                backgroundColor:
                    isDark ? tWhite.withOpacity(0.15) : tBlack.withOpacity(0.1),
                deleteIconColor: Colors.grey,
                labelStyle: TextStyle(
                  color: isDark ? tWhite : tBlack,
                  fontSize: 12,
                ),
                side: const BorderSide(color: Colors.grey),
              );
            }),
          ],
        ),
      ],
    );
  }
  // Widget _chipSection({
  //   required String title,
  //   required List<String> options,
  //   required String selected,
  //   required Function(String) onSelected,
  //   required bool isDark,
  //   bool? isEVFleet,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         title,
  //         style: GoogleFonts.urbanist(
  //           fontSize: 13,
  //           fontWeight: FontWeight.w600,
  //           color: isDark ? tWhite : tBlack,
  //         ),
  //       ),
  //       const SizedBox(height: 10),
  //       Wrap(
  //         spacing: 6,
  //         runSpacing: 6,
  //         children:
  //             options.map((option) {
  //               final isSelected = selected == option;

  //               return ChoiceChip(
  //                 showCheckmark: true,
  //                 checkmarkColor: tWhite,
  //                 label: Text(
  //                   option,
  //                   style: GoogleFonts.urbanist(
  //                     fontSize: 13,
  //                     fontWeight: FontWeight.w600,

  //                     color: isSelected ? tWhite : (isDark ? tWhite : tBlack),
  //                   ),
  //                 ),
  //                 selected: isSelected,
  //                 selectedColor: tBlue,
  //                 backgroundColor:
  //                     isDark
  //                         ? tWhite.withOpacity(0.15)
  //                         : tBlack.withOpacity(0.1),
  //                 side: BorderSide(color: Colors.transparent, width: 0),
  //                 onSelected: (_) => onSelected(option),
  //               );
  //             }).toList(),
  //       ),
  //     ],
  //   );
  // }
  Widget _chipSection({
    required String title,
    required List<String> options,
    required String selected,
    required Function(String) onSelected,
    required bool isDark,
    bool? isEVFleet,
  }) {
    // Add this debug print
    print('=== CHIP SECTION: $title ===');
    print('Selected value: "$selected"');
    print('Available options: ${options.map((o) => '"$o"').toList()}');
    print('Is "CSV" in options? ${options.contains("CSV")}');
    print('Does selected == "CSV"? ${selected == "CSV"}');

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

                // Add debug print for each option
                print('Option: "$option", isSelected: $isSelected');

                return ChoiceChip(
                  showCheckmark: true,
                  checkmarkColor: tWhite,
                  label: Text(
                    option,
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? tWhite : (isDark ? tWhite : tBlack),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: tBlue,
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

  // void _generateReport() {

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Generating battery report...'),
  //       backgroundColor: tBlue,
  //     ),
  //   );
  // }

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
          mainAxisSize: MainAxisSize.min,
          children: [
            _chipSection(
              title: "Range",
              options: rangeOptions,
              selected: range,
              onSelected: (val) {
                setState(() {
                  _applyRange(val);
                });
              },
              isDark: isDark,
            ),
            const SizedBox(height: 15),
            // Format Filter
            _chipSection(
              title: "Format",
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
                  backgroundColor: tBlue,
                  foregroundColor: tWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Apply Filters",
                  style: TextStyle(color: tWhite),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
