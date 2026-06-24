import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../../models/CRUDModels/commandsCRUDModel.dart';
import '../../../models/CRUDModels/devicesCRUDModel.dart';
import '../../../models/CRUDModels/groupsCRUDModel.dart';
import '../../../services/CRUDServices/commandsCRUDService.dart';
import '../../../services/CRUDServices/devicesCRUDService.dart';
import '../../../services/CRUDServices/groupsCRUDService.dart';
import '../../../utils/appColors.dart';
import '../../forms/commandsAllSendDialog.dart';

class CommandsAllCRUDContent extends StatefulWidget {
  final bool isMobile;
  const CommandsAllCRUDContent({super.key, this.isMobile = false});
  @override
  State<CommandsAllCRUDContent> createState() => _CommandsAllCRUDContentState();
}

class _CommandsAllCRUDContentState extends State<CommandsAllCRUDContent> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final GlobalKey _pageSizeKey = GlobalKey();

  int page = 1;
  int sizePerPage = 25;

  bool isLoading = false;
  bool isError = false;
  String? errorMessage;

  int totalCount = 0;
  int currentPage = 1;
  int totalPages = 1;

  List<CommandEntities> allcommands = [];
  List<CommandEntities> filteredCommands = [];
  List<GroupEntity> groups = [];
  List<Entities> filteredallDevices = [];
  final DevicesCRUDApiService _devicesApiService = DevicesCRUDApiService();
  final _apiService = GroupsApiService();
  final CommandsApiService _commandsApiService = CommandsApiService();
  final TextEditingController _searchController = TextEditingController();
  bool isGroupsLoading = false;

  OverlayEntry? _pageSizeOverlayEntry;
  final LayerLink _pageSizeLayerLink = LayerLink();
  final List<int> pageSizeOptions = [10, 25, 50, 100];
  @override
  void initState() {
    super.initState();
    fetchAllCommands();
    _loadGroups();
    _reloadDevices();
  }

  void _filterCommands(String query) {
    final lowerQuery = query.toLowerCase();

    setState(() {
      filteredCommands =
          allcommands.where((cmd) {
            final imei = cmd.imei?.toLowerCase() ?? '';
            final command = cmd.commandSent?.toLowerCase() ?? '';

            return imei.contains(lowerQuery) || command.contains(lowerQuery);
          }).toList();

      // currentPage = 1;
      // page = 1;
    });
  }

  Future<void> fetchAllCommands() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isError = false;
      errorMessage = null;
    });

    try {
      final result = await _commandsApiService.fetchCommands(
        page: currentPage, // Use currentPage directly instead of page
        sizePerPage: sizePerPage,
      );

      if (!mounted) return;

      setState(() {
        allcommands = result.entities ?? [];
        filteredCommands = allcommands; // Apply search filter if needed
        totalCount = result.totalCount ?? 0;
        // Fix totalPages calculation
        totalPages = totalCount == 0 ? 1 : (totalCount / sizePerPage).ceil();
        isLoading = false;
      });

      // Re-apply search filter if there's a search query
      if (_searchController.text.isNotEmpty) {
        _filterCommands(_searchController.text);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = e.toString();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;

    setState(() => isGroupsLoading = true);

    try {
      final result = await _apiService.fetchGroups(
        page: 1,
        sizePerPage: 100, // load all groups
      );

      if (!mounted) return;

      setState(() {
        groups = result.entities ?? [];
        isGroupsLoading = false;
      });
    } catch (e) {
      debugPrint("Group fetch error: $e");
      if (mounted) setState(() => isGroupsLoading = false);
    }
  }

  void _hidePageSizeDropdown() {
    if (_pageSizeOverlayEntry != null) {
      try {
        _pageSizeOverlayEntry!.remove();
      } catch (_) {}
      _pageSizeOverlayEntry = null;
    }
  }

  void _showPageSizeDropdown(BuildContext context) {
    final overlay = Overlay.of(context);
    final renderObject = _pageSizeKey.currentContext?.findRenderObject();

    if (renderObject == null || renderObject is! RenderBox) {
      return;
    }

    final RenderBox renderBox = renderObject;
    final double fieldWidth = renderBox.size.width;

    _pageSizeOverlayEntry = OverlayEntry(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Positioned(
          width: fieldWidth,
          child: CompositedTransformFollower(
            link: _pageSizeLayerLink,
            offset: const Offset(0, 45),
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
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children:
                      pageSizeOptions.map((s) {
                        return InkWell(
                          onTap: () {
                            if (!mounted) return;

                            setState(() {
                              sizePerPage = s;
                              page = 1;
                              currentPage = 1;
                            });

                            _hidePageSizeDropdown();
                            fetchAllCommands();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(
                              "$s / page",
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? tWhite : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_pageSizeOverlayEntry!);
  }

  Future<void> _reloadDevices() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isError = false;
      errorMessage = null;
    });

    try {
      final result = await _devicesApiService.fetchDevices(
        page: currentPage,
        sizePerPage: sizePerPage,
      );

      if (!mounted) return;

      setState(() {
        filteredallDevices = result.entities ?? [];
        totalCount = result.totalCount ?? 0;
        totalPages = totalCount == 0 ? 1 : (totalCount / sizePerPage).ceil();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = e.toString();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  void dispose() {
    _hidePageSizeDropdown();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
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
                    'Loading Commands...',
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
  // @override
  // Widget build(BuildContext context) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Header row: title + controls
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             "Commands",
  //             style: GoogleFonts.urbanist(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //               color: isDark ? tWhite : tBlack,
  //             ),
  //           ),

  //           // Right-side controls: New User + page size
  //           Row(
  //             children: [
  //               _sendCommandButton(isDark),
  //               const SizedBox(width: 10),

  //               // Page size selector
  //               Container(
  //                 height: 42,
  //                 padding: const EdgeInsets.symmetric(horizontal: 12),
  //                 decoration: BoxDecoration(
  //                   color:
  //                       isDark ? tWhite.withOpacity(0.08) : Colors.grey.shade50,
  //                   // borderRadius: BorderRadius.circular(10),
  //                   border: Border.all(
  //                     color:
  //                         isDark
  //                             ? tWhite.withOpacity(0.10)
  //                             : Colors.grey.shade300,
  //                     width: 1.2,
  //                   ),
  //                   boxShadow: [
  //                     if (!isDark)
  //                       BoxShadow(
  //                         color: Colors.black.withOpacity(0.04),
  //                         blurRadius: 12,
  //                         offset: const Offset(0, 4),
  //                       ),
  //                   ],
  //                 ),
  //                 child: DropdownButtonHideUnderline(
  //                   child: DropdownButton<int>(
  //                     value: sizePerPage,
  //                     icon: Icon(
  //                       Icons.expand_more_rounded,
  //                       size: 20,
  //                       color:
  //                           isDark
  //                               ? tWhite.withOpacity(0.8)
  //                               : Colors.grey.shade700,
  //                     ),
  //                     dropdownColor:
  //                         isDark ? tBlack.withOpacity(0.95) : Colors.white,
  //                     borderRadius: BorderRadius.circular(10),

  //                     style: GoogleFonts.urbanist(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                       color: isDark ? tWhite : Colors.black87,
  //                     ),

  //                     items:
  //                         pageSizeOptions
  //                             .map(
  //                               (s) => DropdownMenuItem(
  //                                 value: s,
  //                                 child: Text(
  //                                   "$s / page",
  //                                   style: GoogleFonts.urbanist(
  //                                     fontSize: 14,
  //                                     fontWeight: FontWeight.w600,
  //                                     color: isDark ? tWhite : Colors.black87,
  //                                   ),
  //                                 ),
  //                               ),
  //                             )
  //                             .toList(),

  //                     onChanged: (v) {
  //                       if (v == null) return;
  //                       setState(() {
  //                         sizePerPage = v;
  //                         page = 1;
  //                       });
  //                       fetchAllCommands();
  //                     },
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
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
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Commands",
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _sendCommandButton(isDark, isMobile)),
                      const SizedBox(width: 10),
                      _buildPageSizeSelector(isDark),
                    ],
                  ),
                ],
              )
            else
              // Desktop: Horizontal layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Commands",
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                  Row(
                    children: [
                      _sendCommandButton(isDark, isMobile),
                      const SizedBox(width: 10),
                      _buildPageSizeSelector(isDark),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Expanded(child: _buildTableArea(isDark)),
            const SizedBox(height: 12),
            Opacity(
              opacity: isLoading ? 0.5 : 1.0,
              child: IgnorePointer(
                ignoring: isLoading,
                child: _buildPaginationControls(isDark, isMobile),
              ),
            ),
          ],
        ),
        if (isLoading) _buildLoadingOverlay(isDark),
      ],
    );
  }

  Widget _buildPageSizeSelector(bool isDark) {
    return CompositedTransformTarget(
      key: _pageSizeKey,
      link: _pageSizeLayerLink,
      child: GestureDetector(
        onTap: () {
          if (_pageSizeOverlayEntry == null) {
            _showPageSizeDropdown(context);
          } else {
            _hidePageSizeDropdown();
          }
        },
        child: Container(
          height: 42,
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? tWhite.withOpacity(0.08) : Colors.grey.shade50,
            border: Border.all(
              color: isDark ? tWhite.withOpacity(0.10) : Colors.grey.shade300,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$sizePerPage / page",
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? tWhite : Colors.black87,
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: isDark ? tWhite.withOpacity(0.8) : Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableArea(bool isDark) {
    if (!isLoading && filteredCommands.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('icons/nodata1.svg', height: 120, width: 120),
            const SizedBox(height: 16),
            Text(
              isError
                  ? (errorMessage ?? "Failed to load commands")
                  : "No commands found.",
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? tWhite : tBlack,
              ),
            ),
          ],
        ),
      );
    }

    // Show current page data directly
    return Opacity(
      opacity: isLoading ? 0.3 : 1.0,
      child: IgnorePointer(
        ignoring: isLoading,
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
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
                    columnSpacing: 24,
                    border: TableBorder.all(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.1)
                              : tBlack.withOpacity(0.1),
                      width: 0.4,
                    ),
                    dividerThickness: 0.01,
                    columns: const [
                      DataColumn(label: Text('S.No')),
                      DataColumn(label: Text('IMEI')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Command Sent')),
                      DataColumn(label: Text('Data Received')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('User')),
                    ],
                    rows:
                        filteredCommands.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final cmd = entry.value;
                          final imei = cmd.imei ?? "--";
                          final type = cmd.type ?? "--";
                          final commandSent = cmd.commandSent ?? "--";
                          final dataReceived = cmd.dataReceived ?? "--";
                          final date = cmd.date ?? "";
                          final userId = cmd.userId ?? "--";
                          final isReceived = type == "RECEIVED";
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '${(currentPage - 1) * sizePerPage + idx + 1}',
                                ),
                              ),
                              DataCell(Text(imei)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isReceived
                                            ? tGreen3.withOpacity(0.15)
                                            : tBlue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    type,
                                    style: GoogleFonts.urbanist(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isReceived ? tGreen3 : tBlue,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(commandSent)),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(dataReceived),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  date.isNotEmpty
                                      ? DateTime.parse(
                                        date,
                                      ).toLocal().toString().substring(0, 19)
                                      : "--",
                                ),
                              ),
                              DataCell(Text(userId)),
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
    );
  }

  //       const SizedBox(height: 16),

  //       // Table area with loading overlay
  //       Expanded(
  //         child: Stack(
  //           children: [
  //             // Table content (or error / empty)
  //             _buildTableArea(isDark),

  //             // Loading overlay
  //             if (isLoading)
  //               Positioned.fill(
  //                 child: Container(
  //                   color:
  //                       isDark
  //                           ? Colors.black.withOpacity(0.35)
  //                           : Colors.white.withOpacity(0.6),
  //                   child: const Center(child: CircularProgressIndicator()),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),

  //       // Pagination footer
  //       const SizedBox(height: 12),
  //       _buildPaginationControls(isDark),
  //     ],
  //   );
  // }

  // Widget _buildTableArea(bool isDark) {
  //   // If API returns zero items
  //   if (!isLoading && allcommands.isEmpty) {
  //     return Center(
  //       child: Text(
  //         isError
  //             ? (errorMessage ?? "Failed to load commands")
  //             : "No commands found.",
  //         style: GoogleFonts.urbanist(
  //           fontSize: 14,
  //           color: isDark ? tWhite : tBlack,
  //         ),
  //       ),
  //     );
  //   }

  //   return Scrollbar(
  //     controller: _horizontalController,
  //     thumbVisibility: true,
  //     child: SingleChildScrollView(
  //       controller: _horizontalController,
  //       scrollDirection: Axis.horizontal,
  //       child: ConstrainedBox(
  //         constraints: BoxConstraints(
  //           minWidth: MediaQuery.of(context).size.width,
  //         ),
  //         child: Scrollbar(
  //           controller: _verticalController,
  //           thumbVisibility: true,
  //           child: SingleChildScrollView(
  //             controller: _verticalController,
  //             scrollDirection: Axis.vertical,
  //             child: DataTable(
  //               headingRowColor: WidgetStateProperty.all(
  //                 isDark ? tBlue.withOpacity(0.15) : tBlue.withOpacity(0.05),
  //               ),
  //               headingTextStyle: GoogleFonts.urbanist(
  //                 fontWeight: FontWeight.w700,
  //                 color: isDark ? tWhite : tBlack,
  //                 fontSize: 13,
  //               ),
  //               dataTextStyle: GoogleFonts.urbanist(
  //                 color: isDark ? tWhite : tBlack,
  //                 fontWeight: FontWeight.w400,
  //                 fontSize: 12,
  //               ),
  //               columnSpacing: 24,
  //               border: TableBorder.all(
  //                 color:
  //                     isDark
  //                         ? tWhite.withOpacity(0.1)
  //                         : tBlack.withOpacity(0.1),
  //                 width: 0.4,
  //               ),
  //               dividerThickness: 0.01,
  //               columns: const [
  //                 DataColumn(label: Text('S.No')),
  //                 DataColumn(label: Text('IMEI')),
  //                 DataColumn(label: Text('Type')),
  //                 DataColumn(label: Text('Command Sent')),
  //                 DataColumn(label: Text('Data Received')),
  //                 DataColumn(label: Text('Date')),
  //                 DataColumn(label: Text('User')),
  //               ],

  //               rows:
  //                   allcommands.asMap().entries.map((entry) {
  //                     final idx = entry.key;
  //                     final cmd = entry.value;

  //                     final imei = cmd.imei ?? "--";
  //                     final type = cmd.type ?? "--";
  //                     final commandSent = cmd.commandSent ?? "--";
  //                     final dataReceived = cmd.dataReceived ?? "--";
  //                     final date = cmd.date ?? "";
  //                     final userId = cmd.userId ?? "--";
  //                     final isReceived = type == "RECEIVED";

  //                     return DataRow(
  //                       cells: [
  //                         DataCell(
  //                           Text('${(page - 1) * sizePerPage + idx + 1}'),
  //                         ),

  //                         DataCell(Text(imei)),

  //                         /// TYPE with colored badge
  //                         DataCell(
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 8,
  //                               vertical: 4,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color:
  //                                   isReceived
  //                                       ? tGreen3.withOpacity(0.15)
  //                                       : tBlue.withOpacity(0.15),
  //                               borderRadius: BorderRadius.circular(6),
  //                             ),
  //                             child: Text(
  //                               type,
  //                               style: GoogleFonts.urbanist(
  //                                 fontSize: 12,
  //                                 fontWeight: FontWeight.bold,
  //                                 color: isReceived ? tGreen3 : tBlue,
  //                               ),
  //                             ),
  //                           ),
  //                         ),

  //                         DataCell(Text(commandSent)),

  //                         /// Data Received (scrollable)
  //                         DataCell(
  //                           SizedBox(
  //                             width: 200,
  //                             child: SingleChildScrollView(
  //                               scrollDirection: Axis.horizontal,
  //                               child: Text(dataReceived),
  //                             ),
  //                           ),
  //                         ),

  //                         /// Date formatted
  //                         DataCell(
  //                           Text(
  //                             date.isNotEmpty
  //                                 ? DateTime.parse(
  //                                   date,
  //                                 ).toLocal().toString().substring(0, 19)
  //                                 : "--",
  //                           ),
  //                         ),

  //                         DataCell(Text(userId)),
  //                       ],
  //                     );
  //                   }).toList(),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPaginationControls(bool isDark, bool isMobile) {
    const int visiblePageCount = 5;
    final computedTotalPages = (totalCount / sizePerPage).ceil().clamp(1, 999);

    int startPage =
        ((currentPage - 1) ~/ visiblePageCount) * visiblePageCount + 1;
    int endPage = (startPage + visiblePageCount - 1).clamp(1, totalPages);

    final pageButtons = <Widget>[];

    for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
      final isSelected = pageNum == currentPage;

      pageButtons.add(
        GestureDetector(
          onTap: () {
            setState(() {
              currentPage = pageNum;
              page = currentPage;
            });
            fetchAllCommands();
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
                            setState(() {
                              currentPage--;
                              page = currentPage;
                            });
                            fetchAllCommands();
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
                            setState(() {
                              currentPage++;
                              page = currentPage;
                            });
                            fetchAllCommands();
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
                          ),
                          decoration: InputDecoration(
                            hintText: 'Page',
                            hintStyle: GoogleFonts.urbanist(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: isDark ? tWhite : tBlack,
                                width: 0.8,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: isDark ? tWhite : tBlack,
                                width: 1.2,
                              ),
                            ),
                          ),
                          onSubmitted: (value) {
                            final p = int.tryParse(value);

                            if (p != null && p >= 1 && p <= totalPages) {
                              setState(() {
                                currentPage = p;
                                page = currentPage;
                              });
                              fetchAllCommands();
                            }
                          },
                          cursorColor: isDark ? tWhite : tBlack,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Flexible(
                        child: Text(
                          'Page $currentPage of $computedTotalPages',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: isDark ? tWhite : tBlack,
                          ),
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
                            setState(() {
                              currentPage--;
                              page = currentPage;
                            });
                            fetchAllCommands();
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
                            setState(() {
                              currentPage++;
                              page = currentPage;
                            });
                            fetchAllCommands();
                          }
                        },
                      ),

                      const SizedBox(width: 16),

                      SizedBox(
                        width: 70,
                        height: 32,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            color: isDark ? tWhite : tBlack,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Page',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onSubmitted: (value) {
                            final p = int.tryParse(value);

                            if (p != null && p >= 1 && p <= totalPages) {
                              setState(() {
                                currentPage = p;
                                page = currentPage;
                              });
                              fetchAllCommands();
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        'Page $currentPage of $computedTotalPages · $totalCount items',
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
  }

  Widget _sendCommandButton(bool isDark, bool isMobile) => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: isDark ? tWhite : tBlack),
    child: TextButton(
      onPressed: () {
        showSendCommandDialog(
          context: context,
          allGroups: groups,

          // onConfirm: (groupIds, command) async {
          //   final request = MulCommandRequest(
          //     command: command,
          //     groups: groupIds,
          //   );
          //   await _commandsApiService.sendMulCommand(request);
          //   fetchAllCommands();
          // },
          onConfirm: (groupIds, command) async {
            final request = MulCommandRequest(
              command: command,
              groups: groupIds.map((id) => {"id": id}).toList(),
            );

            await _commandsApiService.sendMulCommand(request);
            fetchAllCommands();
          },
        );
      },
      child: Row(
        children: [
          SvgPicture.asset(
            'icons/commands.svg',
            width: 18,
            height: 18,
            color: isDark ? tBlack : tWhite,
          ),
          const SizedBox(width: 8),
          Text(
            isMobile ? 'Send' : 'Send Command',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: isDark ? tBlack : tWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _buildFilterBySearch(bool isDark) => Container(
    width: 180,
    height: 40,
    decoration: BoxDecoration(
      color: tTransparent,
      border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
    ),
    child: TextField(
      controller: _searchController,
      onChanged: _filterCommands,
      style: GoogleFonts.urbanist(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isDark ? tWhite : tBlack,
      ),
      decoration: InputDecoration(
        hintText: 'Search...',
        hintStyle: GoogleFonts.urbanist(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
        ),
        border: InputBorder.none,
        prefixIcon: Icon(
          Icons.search,
          size: 18,
          color: isDark ? tWhite : tBlack,
        ),
      ),
    ),
  );
}
