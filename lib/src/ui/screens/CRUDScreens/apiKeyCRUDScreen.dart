import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../../models/CRUDModels/apiKeyCRUDModel.dart';
import '../../../services/CRUDServices/apiKeyCRUDService.dart';
import '../../../utils/appColors.dart';

class ApiKeyCRUDContent extends StatefulWidget {
  const ApiKeyCRUDContent({super.key});

  @override
  State<ApiKeyCRUDContent> createState() => _ApiKeyCRUDContentState();
}

class _ApiKeyCRUDContentState extends State<ApiKeyCRUDContent> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final TextEditingController _pageController = TextEditingController();

  final _apiService = ApiKeyApiService();

  List<Entities> apiKeys = [];

  int currentPage = 1;
  int sizePerPage = 10;
  int totalCount = 0;
  int totalPages = 1;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _apiService.fetchApiKeys(
        currentPage: currentPage,
        sizePerPage: sizePerPage,
      );

      if (!mounted) return;

      setState(() {
        apiKeys = result.entities ?? [];
        totalCount = result.totalCount ?? 0;
        totalPages = (totalCount / sizePerPage).ceil();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("API Key fetch error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _createApiKey() async {
    try {
      await _apiService.createApiKey();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("API Key created successfully")),
      );

      _loadApiKeys();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create API Key"),
          backgroundColor: tRed,
        ),
      );
    }
  }

  Future<void> _deleteApiKey(String id) async {
    try {
      await _apiService.deleteApiKey(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("API Key deleted successfully")),
      );

      _loadApiKeys();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete API Key"),
          backgroundColor: tRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Header Row
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             "API Keys",
  //             style: GoogleFonts.urbanist(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //               color: isDark ? tWhite : tBlack,
  //             ),
  //           ),

  //           _addNewApiKeyButton(isDark),
  //         ],
  //       ),

  //       SizedBox(height: 20),

  //       // Table Section
  //       Expanded(
  //         child:
  //             isLoading
  //                 ? Center(child: CircularProgressIndicator())
  //                 : _buildApiKeyTable(isDark),
  //       ),

  //       // Pagination Footer
  //       _buildPaginationControls(isDark),
  //     ],
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "API Keys",
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                _addNewApiKeyButton(isDark),
              ],
            ),
            SizedBox(height: 20),
            // Table Section - Always visible
            Expanded(child: _buildApiKeyTable(isDark)),
            // Pagination Footer - Dimmed during loading
            Opacity(
              opacity: isLoading ? 0.5 : 1.0,
              child: IgnorePointer(
                ignoring: isLoading,
                child: _buildPaginationControls(isDark),
              ),
            ),
          ],
        ),
        // Loading Overlay
        if (isLoading) _buildLoadingOverlay(isDark),
      ],
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
                    'Loading API Keys...',
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

  // ------------------------------
  // API KEY TABLE
  // ------------------------------
  // Widget _buildApiKeyTable(bool isDark) {
  //   final startIndex = (currentPage - 1) * sizePerPage;
  //   final endIndex = (startIndex + sizePerPage).clamp(0, apiKeys.length);
  //   final currentPageKeys = apiKeys.sublist(startIndex, endIndex);

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
  //               columnSpacing: 30,
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
  //                 DataColumn(label: Text('API Key')),
  //                 DataColumn(label: Text('Created Date')),
  //                 DataColumn(label: Text('Created By')),
  //                 DataColumn(label: Text('Last Used')),
  //                 DataColumn(label: Text('Actions')),
  //               ],
  //               rows:
  //                   currentPageKeys.asMap().entries.map((entry) {
  //                     final index = entry.key;
  //                     final key = entry.value;

  //                     return DataRow(
  //                       cells: [
  //                         DataCell(
  //                           Text(
  //                             '${(currentPage - 1) * sizePerPage + index + 1}',
  //                           ),
  //                         ),

  //                         // API Key + Copy Icon
  //                         DataCell(
  //                           Row(
  //                             children: [
  //                               Expanded(
  //                                 child: Text(
  //                                   key.apiKey ?? "--",
  //                                   overflow: TextOverflow.ellipsis,
  //                                 ),
  //                               ),
  //                               IconButton(
  //                                 icon: Icon(
  //                                   Icons.copy,
  //                                   size: 16,
  //                                   color: isDark ? tWhite : tBlack,
  //                                 ),
  //                                 onPressed: () {
  //                                   Clipboard.setData(
  //                                     ClipboardData(text: key.apiKey ?? ""),
  //                                   );
  //                                   ScaffoldMessenger.of(context).showSnackBar(
  //                                     const SnackBar(
  //                                       content: Text("API Key Copied"),
  //                                       duration: Duration(milliseconds: 800),
  //                                     ),
  //                                   );
  //                                 },
  //                               ),
  //                             ],
  //                           ),
  //                         ),

  //                         // Created Date
  //                         DataCell(
  //                           Text(
  //                             DateFormat(
  //                               'dd MMM yyyy, hh:mm a',
  //                             ).format(DateTime.parse(key.createdDate ?? "")),
  //                           ),
  //                         ),

  //                         // Created By
  //                         DataCell(Text(key.userId ?? "--")),

  //                         // Last Used
  //                         DataCell(
  //                           Text(
  //                             key.lastUsed != null
  //                                 ? DateFormat(
  //                                   'dd MMM yyyy, hh:mm a',
  //                                 ).format(DateTime.parse(key.lastUsed!))
  //                                 : "Never",
  //                           ),
  //                         ),

  //                         // Action Buttons
  //                         DataCell(
  //                           Row(
  //                             children: [
  //                               IconButton(
  //                                 icon: SvgPicture.asset(
  //                                   'icons/delete.svg',
  //                                   height: 22,
  //                                   width: 22,
  //                                   color: tRed,
  //                                 ),
  //                                 onPressed: () {
  //                                   _showDeleteApiKeyDialog(
  //                                     isDark: isDark,
  //                                     apiKeyId: key.id!, // make sure id exists
  //                                   );
  //                                 },
  //                               ),
  //                             ],
  //                           ),
  //                         ),
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
  Widget _buildApiKeyTable(bool isDark) {
    final startIndex = (currentPage - 1) * sizePerPage;
    final endIndex = (startIndex + sizePerPage).clamp(0, apiKeys.length);
    final currentPageKeys = apiKeys.sublist(startIndex, endIndex);

    return Scrollbar(
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
              child: Opacity(
                opacity: isLoading ? 0.3 : 1.0,
                child: IgnorePointer(
                  ignoring: isLoading,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      isDark
                          ? tBlue.withOpacity(0.15)
                          : tBlue.withOpacity(0.05),
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
                    columnSpacing: 30,
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
                      DataColumn(label: Text('API Key')),
                      DataColumn(label: Text('Created Date')),
                      DataColumn(label: Text('Created By')),
                      DataColumn(label: Text('Last Used')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows:
                        currentPageKeys.asMap().entries.map((entry) {
                          final index = entry.key;
                          final key = entry.value;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '${(currentPage - 1) * sizePerPage + index + 1}',
                                ),
                              ),
                              // API Key + Copy Icon
                              DataCell(
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        key.apiKey ?? "--",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.copy,
                                        size: 16,
                                        color: isDark ? tWhite : tBlack,
                                      ),
                                      onPressed:
                                          isLoading
                                              ? null
                                              : () {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: key.apiKey ?? "",
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "API Key Copied",
                                                    ),
                                                    duration: Duration(
                                                      milliseconds: 800,
                                                    ),
                                                  ),
                                                );
                                              },
                                    ),
                                  ],
                                ),
                              ),
                              // Created Date
                              DataCell(
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(
                                    DateTime.parse(key.createdDate ?? ""),
                                  ),
                                ),
                              ),
                              // Created By
                              DataCell(Text(key.userId ?? "--")),
                              // Last Used
                              DataCell(
                                Text(
                                  key.lastUsed != null
                                      ? DateFormat(
                                        'dd MMM yyyy, hh:mm a',
                                      ).format(DateTime.parse(key.lastUsed!))
                                      : "Never",
                                ),
                              ),
                              // Action Buttons
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: SvgPicture.asset(
                                        'icons/delete.svg',
                                        height: 22,
                                        width: 22,
                                        color: tRed,
                                      ),
                                      onPressed:
                                          isLoading
                                              ? null
                                              : () {
                                                _showDeleteApiKeyDialog(
                                                  isDark: isDark,
                                                  apiKeyId: key.id!,
                                                );
                                              },
                                    ),
                                  ],
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
    );
  }

  // ------------------------------
  // PAGINATION
  // ------------------------------
  Widget _buildPaginationControls(bool isDark) {
    const int visiblePageCount = 5;
    final int computedTotalPages = totalPages < 1 ? 1 : totalPages;

    final int startPage =
        ((currentPage - 1) ~/ visiblePageCount) * visiblePageCount + 1;

    final int endPage = (startPage + visiblePageCount - 1).clamp(
      1,
      computedTotalPages,
    );

    final List<Widget> pageButtons = [];

    for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
      final bool isSelected = pageNum == currentPage;

      pageButtons.add(
        GestureDetector(
          onTap: () {
            if (pageNum == currentPage) return;

            setState(() => currentPage = pageNum);
            _loadApiKeys();
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isSelected
                        ? tWhite
                        : (isDark
                            ? tWhite.withOpacity(0.8)
                            : tBlack.withOpacity(0.8)),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Previous
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 22,
              color: isDark ? tWhite : tBlack,
            ),
            onPressed:
                currentPage > 1
                    ? () {
                      setState(() => currentPage--);
                      _loadApiKeys();
                    }
                    : null,
          ),

          Row(children: pageButtons),

          /// Next
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              size: 22,
              color: isDark ? tWhite : tBlack,
            ),
            onPressed:
                currentPage < computedTotalPages
                    ? () {
                      setState(() => currentPage++);
                      _loadApiKeys();
                    }
                    : null,
          ),

          const SizedBox(width: 16),

          /// Jump to page
          SizedBox(
            width: 70,
            height: 32,
            child: TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                color: isDark ? tWhite : tBlack,
              ),
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
                final int? p = int.tryParse(value);
                if (p != null && p >= 1 && p <= computedTotalPages) {
                  setState(() => currentPage = p);
                  _loadApiKeys();
                }
                _pageController.clear();
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
    );
  }

  // ------------------------------
  // BUTTON: Add New API KEY
  // ------------------------------
  Widget _addNewApiKeyButton(bool isDark) => Container(
    height: 40,
    padding: EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: isDark ? tWhite : tBlack),
    child: TextButton(
      // onPressed: () {},
      onPressed: () => _showCreateApiKeyDialog(isDark),
      child: Row(
        children: [
          SvgPicture.asset(
            'icons/key.svg',
            width: 18,
            height: 18,
            color: isDark ? tBlack : tWhite,
          ),
          SizedBox(width: 5),
          Text(
            'New ApiKey',
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

  void _showCreateApiKeyDialog(bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: isDark ? tBlack : tWhite,
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tBlue.withOpacity(0.15),
                          // shape: BoxShape.circle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.vpn_key_rounded,
                          color: tBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Create API Key',
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// Description
                  Text(
                    'Do you want to create a new API key? '
                    'This key will be shown only once. '
                    'Make sure to copy and store it securely.',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.7)
                              : tBlack.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 26),

                  /// Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      /// Cancel
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.7)
                                    : tBlack.withOpacity(0.7),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// Create
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _createApiKey();
                        },
                        child: Text(
                          'Create',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
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
      },
    );
  }

  void _showDeleteApiKeyDialog({
    required bool isDark,
    required String apiKeyId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: isDark ? tBlack : tWhite,
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.delete_forever_rounded,
                          color: tRed,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete API Key',
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// Message
                  Text(
                    'Are you sure you want to delete this API key? '
                    'This action cannot be undone.',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      height: 1.5,
                      color:
                          isDark
                              ? Colors.white70
                              : Colors.black.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 26),

                  /// Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tRed,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _deleteApiKey(apiKeyId);
                        },
                        child: Text(
                          'Delete',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
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
      },
    );
  }
}
