import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../../models/CRUDModels/groupsCRUDModel.dart';
import '../../../services/CRUDServices/groupsCRUDService.dart';
import '../../../utils/appColors.dart';
import '../../forms/groups/groupCreateUpdateForm.dart';
import '../../forms/groups/groupDeleteDialog.dart';

class GroupCRUDContent extends StatefulWidget {
  const GroupCRUDContent({super.key});

  @override
  State<GroupCRUDContent> createState() => _GroupCRUDContentState();
}

class _GroupCRUDContentState extends State<GroupCRUDContent> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final TextEditingController _pageController = TextEditingController();

  int currentPage = 1;
  int sizePerPage = 10;
  int totalCount = 0;
  int totalPages = 1;

  bool isLoading = true;

  List<GroupEntity> groups = [];
  final _apiService = GroupsApiService();

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _apiService.fetchGroups(
        page: currentPage,
        sizePerPage: sizePerPage,
      );

      if (!mounted) return;

      setState(() {
        groups = result.entities ?? [];
        totalCount = result.totalCount ?? 0;
        totalPages = (totalCount / sizePerPage).ceil();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Group fetch error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();

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
  //             "Groups",
  //             style: GoogleFonts.urbanist(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //               color: isDark ? tWhite : tBlack,
  //             ),
  //           ),
  //           _addNewGroupButton(isDark),
  //         ],
  //       ),
  //       SizedBox(height: 20),
  //       // Table Section
  //       Expanded(
  //         child:
  //             isLoading
  //                 ? Center(child: CircularProgressIndicator())
  //                 : _buildGroupsTable(isDark),
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
                  "Groups",
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                _addNewGroupButton(isDark),
              ],
            ),
            SizedBox(height: 20),
            // Table Section - Always show table structure, but data may be empty
            Expanded(
              child: _buildGroupsTable(isDark), // Always build the table
            ),
            // Pagination Footer - Always show but disable during loading
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

  // ------------------------------
  // API KEY TABLE
  // ------------------------------
  // Widget _buildGroupsTable(bool isDark) {
  //   final startIndex = (currentPage - 1) * sizePerPage;
  //   final endIndex =
  //       (startIndex + sizePerPage) > groups.length
  //           ? groups.length
  //           : (startIndex + sizePerPage);
  //   final currentPageKeys = groups.sublist(startIndex, endIndex);

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
  //                 DataColumn(label: Text('Group ID')),
  //                 DataColumn(label: Text('Group Name')),
  //                 DataColumn(label: Text('Actions')),
  //               ],
  //               rows:
  //                   currentPageKeys.asMap().entries.map((entry) {
  //                     final index = entry.key;
  //                     final group = entry.value;

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
  //                                   group.id ?? "--",
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
  //                                     ClipboardData(text: group.id ?? "--"),
  //                                   );
  //                                   ScaffoldMessenger.of(context).showSnackBar(
  //                                     const SnackBar(
  //                                       content: Text("ID Copied"),
  //                                       duration: Duration(milliseconds: 800),
  //                                     ),
  //                                   );
  //                                 },
  //                               ),
  //                             ],
  //                           ),
  //                         ),

  //                         DataCell(Text(group.name ?? "--")),

  //                         // Action Buttons
  //                         DataCell(
  //                           Row(
  //                             children: [
  //                               /// Edit
  //                               IconButton(
  //                                 icon: SvgPicture.asset(
  //                                   'icons/edit.svg',
  //                                   height: 22,
  //                                   width: 22,
  //                                   color: tBlue,
  //                                 ),
  //                                 onPressed: () {
  //                                   // open edit dialog
  //                                   showGroupCreateUpdateDialog(
  //                                     context: context,
  //                                     title: "Update Group",
  //                                     description:
  //                                         "Update the selected group name.",
  //                                     label: "Group Name",
  //                                     initialValue: group.name,
  //                                     confirmText: "Update",
  //                                     onConfirm: (value) async {
  //                                       await _apiService.updateGroup(
  //                                         group.id!,
  //                                         value,
  //                                       );
  //                                       _loadGroups();
  //                                     },
  //                                   );
  //                                 },
  //                               ),
  //                               IconButton(
  //                                 icon: SvgPicture.asset(
  //                                   'icons/delete.svg',
  //                                   height: 22,
  //                                   width: 22,
  //                                   color: tRed,
  //                                 ),
  //                                 onPressed: () {
  //                                   showGroupConfirmDeleteDialog(
  //                                     context: context,
  //                                     title: "Delete Group",
  //                                     message:
  //                                         'Are you sure you want to delete "${group.name}"?\n'
  //                                         'All related data may be affected.',
  //                                     onConfirm: () async {
  //                                       await _apiService.deleteGroup(
  //                                         group.id!,
  //                                       );
  //                                       _loadGroups();
  //                                     },
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
  Widget _buildGroupsTable(bool isDark) {
    final startIndex = (currentPage - 1) * sizePerPage;
    final endIndex =
        (startIndex + sizePerPage) > groups.length
            ? groups.length
            : (startIndex + sizePerPage);
    final currentPageKeys = groups.sublist(startIndex, endIndex);

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
                      DataColumn(label: Text('Group ID')),
                      DataColumn(label: Text('Group Name')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows:
                        currentPageKeys.asMap().entries.map((entry) {
                          final index = entry.key;
                          final group = entry.value;

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
                                        group.id ?? "--",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.copy,
                                        size: 16,
                                        color: isDark ? tWhite : tBlack,
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: group.id ?? "--"),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("ID Copied"),
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
                              DataCell(Text(group.name ?? "--")),
                              // Action Buttons
                              DataCell(
                                Row(
                                  children: [
                                    /// Edit
                                    IconButton(
                                      icon: SvgPicture.asset(
                                        'icons/edit.svg',
                                        height: 22,
                                        width: 22,
                                        color: tBlue,
                                      ),
                                      onPressed:
                                          isLoading
                                              ? null
                                              : () {
                                                showGroupCreateUpdateDialog(
                                                  context: context,
                                                  title: "Update Group",
                                                  description:
                                                      "Update the selected group name.",
                                                  label: "Group Name",
                                                  initialValue: group.name,
                                                  confirmText: "Update",
                                                  onConfirm: (value) async {
                                                    await _apiService
                                                        .updateGroup(
                                                          group.id!,
                                                          value,
                                                        );
                                                    _loadGroups();
                                                  },
                                                );
                                              },
                                    ),
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
                                                showGroupConfirmDeleteDialog(
                                                  context: context,
                                                  title: "Delete Group",
                                                  message:
                                                      'Are you sure you want to delete "${group.name}"?\n'
                                                      'All related data may be affected.',
                                                  onConfirm: () async {
                                                    await _apiService
                                                        .deleteGroup(group.id!);
                                                    _loadGroups();
                                                  },
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
                    'Loading Groups...',
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
            _loadGroups();
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
                      _loadGroups();
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
                      _loadGroups();
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
                  _loadGroups();
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

  Widget _addNewGroupButton(bool isDark) => Container(
    height: 40,
    padding: EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: isDark ? tWhite : tBlack),
    child: TextButton(
      onPressed: () {
        showGroupCreateUpdateDialog(
          context: context,
          title: "Create Group",
          description: "Create a new group to organize your vehicles.",
          label: "Group Name",
          confirmText: "Create",
          onConfirm: (value) async {
            await _apiService.createGroup(value);
            _loadGroups();
          },
        );
      },
      child: Row(
        children: [
          SvgPicture.asset(
            'icons/group.svg',
            width: 18,
            height: 18,
            color: isDark ? tBlack : tWhite,
          ),
          SizedBox(width: 5),
          Text(
            'New Group',
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
}
