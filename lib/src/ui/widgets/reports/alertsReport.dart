import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg.dart';

import '../../../models/userReportModel.dart';
import '../../../services/generalAPIServices.dart/reportApiServices/alertReportAPIService.dart';
import '../../../services/generalAPIServices.dart/reportApiServices/reportsAPIService.dart';
import '../../../utils/appColors.dart';
import 'custom_Toast.dart';

class AlertsReportView extends StatefulWidget {
  final String title;
  final String description;
  final bool isDark;
  final bool isMobile;
  const AlertsReportView({
    super.key,
    required this.title,
    required this.description,
    required this.isDark,
    required this.isMobile,
  });

  @override
  State<AlertsReportView> createState() => _AlertsReportViewState();
}

class _AlertsReportViewState extends State<AlertsReportView> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool isDownloading = false;
  bool _showFilterPanel = false;

  final TextEditingController searchController = TextEditingController();
  TextEditingController? _searchFieldController;

  String alertStatus = 'All';
  int? selectedRangeDays;
  String format = 'XLSX';
  String range = 'All';
  final List<String> formatOptions = ['Logs', 'XLSX', 'CSV', 'JSON', 'XML'];
  String selectedFormat = 'csv';

  final List<String> rangeOptions = [
    'Last 7 Days',
    'Last 15 Days',
    'Last 30 Days',
    'Last 60 Days',
    'Last 90 Days',
  ];
  bool _isRangeSelected = false;
  final List<String> alertStatusOptions = ['All', 'Critical', 'Non-critical'];
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

  // void _resetFilters() {
  //   final now = DateTime.now();

  //   setState(() {
  //     // Reset dates
  //     fromDate = now;
  //     toDate = now;

  //     // Reset filters
  //     alertStatus = 'All';
  //     format = 'XLSX';
  //     range = 'All';

  //     selectedRangeDays = null;
  //     _isRangeSelected = false;

  //     // Clear selections
  //     _selectedImeis.clear();
  //     _selectedGroupIds.clear();

  //     // Clear search
  //     _searchFieldController?.clear();
  //     searchController.clear();

  //     // Close filter panel
  //     _showFilterPanel = false;
  //   });
  // }

  void _applyRange(String range) {
    final now = DateTime.now();

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
    }

    _isRangeSelected = true;
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
      String fromDateApi = _formatDateForApi(fromDate!);
      String toDateApi = _formatDateForApi(toDate!);
      int rangeDays = _calculateRangeDays();

      String? imeiList =
          _selectedImeis.isNotEmpty ? _selectedImeis.join(',') : null;

      String? groupId =
          _selectedGroupIds.isNotEmpty ? _selectedGroupIds.join(',') : null;

      String? statusParam = alertStatus != 'All' ? alertStatus : null;
      // String formatParam = selectedFormat;
      String formatParam = format.isNotEmpty ? format.toLowerCase() : 'csv';

      final alertReportApi = AlertReportApiService();

      await alertReportApi.downloadReport(
        context: context,
        fromDate: fromDateApi,
        toDate: toDateApi,
        imeiList: imeiList,
        groupId: groupId,
        rangeDays: rangeDays,
        status: statusParam,
        format: formatParam,
        onSuccess: (message) {
          if (mounted) {
            setState(() {
              isDownloading = false;
              isLoading = false;
            });
            // _resetFilters();
          }
          CustomToast.show(
            context: context,
            message: "Report Generated  Successfully",
            type: ToastType.success,
          );
          print('Alerts download success: $message');
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              isDownloading = false;
              isLoading = false;
            });
          }
          CustomToast.show(
            context: context,
            message: error,
            type: ToastType.error,
          );
          print('Alerts download error: $error');
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isDownloading = false;
          isLoading = false;
        });
      }
      CustomToast.show(
        context: context,
        message:
            "Error: ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e.toString()}",
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = widget.isMobile || (screenWidth <= 600);

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
              mainAxisAlignment:
                  isMobile
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.start,
              children: [
                /// FROM DATE
                Row(
                  children: [
                    _dateLabelBox('From', isDark, isMobile),
                    const SizedBox(width: 5),
                    _dateValueBox(
                      _formatDate(fromDate!),
                      isDark,
                      isMobile,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fromDate!,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.blue,
                                  onPrimary: tWhite,
                                  onSurface: tBlack,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => fromDate = picked);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(width: isMobile ? 10 : 30),

                /// TO DATE
                Row(
                  children: [
                    _dateLabelBox('To', isDark, isMobile),
                    const SizedBox(width: 5),
                    _dateValueBox(
                      _formatDate(toDate!),
                      isDark,
                      isMobile,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: toDate!,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.blue,
                                  onPrimary: tWhite,
                                  onSurface: tBlack,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => toDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _chipSection(
              title: "Filter by Alert Status",
              options: alertStatusOptions,
              selected: alertStatus,
              onSelected: (val) => setState(() => alertStatus = val),
              isDark: isDark,
              isMobile: isMobile,
            ),
            const SizedBox(height: 15),
            Text(
              'Filter by IMEI or Group Name',
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? tWhite : tBlack,
              ),
            ),
            SizedBox(height: 10),
            _searchField(isDark, isMobile),
            SizedBox(height: 25),
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

  Widget _dateLabelBox(String text, bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tTransparent,
        border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.urbanist(
          fontSize: isMobile ? 11 : 13,
          color: isDark ? tWhite : tBlack,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _dateValueBox(
    String value,
    bool isDark,
    bool isMobile, {
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
            fontSize: isMobile ? 11 : 13,
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

                return ChoiceChip(
                  showCheckmark: true,
                  checkmarkColor: tWhite,
                  label: Text(
                    option,
                    style: GoogleFonts.urbanist(
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: FontWeight.w600,

                      color: isSelected ? tWhite : (isDark ? tWhite : tBlack),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: tGreen8,
                  backgroundColor:
                      isDark ? tGrey.withOpacity(0.1) : tBlack.withOpacity(0.1),
                  side: BorderSide(color: Colors.transparent, width: 0),
                  // onSelected: (_) => onSelected(option),
                  onSelected: (_) {
                    if (selected == option) {
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
                final allOptions = [
                  ..._imeis,
                  ..._groups.map((g) => g.name ?? ''),
                ];

                final uniqueOptions =
                    allOptions
                        .where((item) => item.isNotEmpty)
                        .toSet()
                        .toList();

                if (textEditingValue.text.isEmpty) {
                  return uniqueOptions;
                }

                return uniqueOptions.where(
                  (item) => item.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (selection) {
                bool isImeiMatch(String imei) {
                  return imei.trim().toLowerCase() ==
                      selection.trim().toLowerCase();
                }

                bool isGroupMatch(String groupName) {
                  return groupName.trim().toLowerCase() ==
                      selection.trim().toLowerCase();
                }

                final matchedImei = _imeis.firstWhere(
                  (imei) => isImeiMatch(imei),
                  orElse: () => '',
                );

                if (matchedImei.isNotEmpty) {
                  if (!_selectedImeis.contains(matchedImei)) {
                    setState(() {
                      _selectedGroupIds.clear();
                      _selectedImeis.add(matchedImei);
                    });
                  }
                } else {
                  final group = _groups.firstWhere(
                    (g) => isGroupMatch(g.name ?? '') || g.id == selection,
                    orElse: () => Groups(),
                  );

                  if (group.id != null &&
                      !_selectedGroupIds.contains(group.id)) {
                    setState(() {
                      /// clear imeis when group selected
                      _selectedImeis.clear();

                      _selectedGroupIds.add(group.id!);
                    });
                  }
                }

                // Clear the search field after selection
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

  Widget _filterButton(bool isDark) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: tTransparent,
      border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
    ),
    child: IconButton(
      onPressed: () {
        final isMobile =
            widget.isMobile || MediaQuery.of(context).size.width < 600;

        if (isMobile) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _buildMobileFilterPanel(isDark),
          );
        } else {
          setState(() {
            _showFilterPanel = !_showFilterPanel;
          });
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

    final double panelWidth = isMobile ? screenWidth - 32 : 350.0;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          width: panelWidth,
          margin: EdgeInsets.only(
            right: isMobile ? 16 : 0,
            left: isMobile ? 16 : 0,
          ),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
            border: Border.all(color: isDark ? tWhite : tBlack),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isMobile ? 0.2 : 0.3),
                blurRadius: isMobile ? 8 : 10,
              ),
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
                    range = val;
                    _applyRange(val);
                  });
                },
                isDark: isDark,
                isMobile: isMobile,
              ),

              SizedBox(height: isMobile ? 12 : 15),

              _chipSection(
                title: "Filter by Format",
                options: formatOptions,
                selected: format,
                onSelected: (val) {
                  setState(() {
                    format = val;
                  });
                },
                isDark: isDark,
                isMobile: isMobile,
              ),

              SizedBox(height: isMobile ? 20 : 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showFilterPanel = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tGreen8,
                      foregroundColor: tWhite,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                      ),
                    ),
                    child: Text(
                      "Apply Filters",
                      style: GoogleFonts.urbanist(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: tWhite,
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

  Widget _buildMobileFilterPanel(bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: StatefulBuilder(
            builder: (context, modalSetState) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    _chipSection(
                      title: "Range",
                      options: rangeOptions,
                      selected: range,
                      onSelected: (val) {
                        modalSetState(() {
                          range = val;
                          _applyRange(val);
                        });

                        setState(() {
                          range = val;
                          _applyRange(val);
                        });
                      },
                      isDark: isDark,
                      isMobile: true,
                    ),

                    const SizedBox(height: 20),

                    _chipSection(
                      title: "Filter by Format",
                      options: formatOptions,
                      selected: format,
                      onSelected: (val) {
                        modalSetState(() {
                          format = val;
                        });

                        setState(() {
                          format = val;
                        });
                      },
                      isDark: isDark,
                      isMobile: true,
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tGreen8,
                          foregroundColor: tWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                ),
              );
            },
          ),
        );
      },
    );
  }
}
