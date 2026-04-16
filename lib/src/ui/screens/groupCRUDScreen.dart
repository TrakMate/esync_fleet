import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../services/apiServices.dart';
import '../../utils/appColors.dart';

class GroupCRUDContent extends StatefulWidget {
  const GroupCRUDContent({super.key});

  @override
  State<GroupCRUDContent> createState() => _GroupCRUDContentState();
}

class _GroupCRUDContentState extends State<GroupCRUDContent> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  int page = 1;
  int sizePerPage = 10;

  bool isLoading = true;
  int totalCount = 0;
  int currentPage = 1;
  int totalPages = 1;

  int rowsPerPage = 10; // REQUIRED FIX

  List<dynamic> groups = [];

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";

    final url =
        "${BaseURLConfig.groupApiURL}?page=$page&sizePerPage=$sizePerPage&currentIndex=0";

    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        totalCount = data["totalCount"];
        groups = data["entities"];
        totalPages = (totalCount / sizePerPage).ceil();
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
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

        // Table Section
        Expanded(
          child:
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildGroupsTable(isDark),
        ),

        // Pagination Footer
        _buildPaginationControls(isDark),
      ],
    );
  }

  // ------------------------------
  // API KEY TABLE
  // ------------------------------
  Widget _buildGroupsTable(bool isDark) {
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage).clamp(0, groups.length);
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
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark ? tBlue.withOpacity(0.15) : tBlue.withOpacity(0.05),
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
                      final key = entry.value;

                      return DataRow(
                        cells: [
                          DataCell(Text('${startIndex + index + 1}')),

                          // API Key + Copy Icon
                          DataCell(
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    key["id"],
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
                                      ClipboardData(text: key["id"]),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("ID Copied"),
                                        duration: Duration(milliseconds: 800),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          DataCell(Text(key["name"] ?? "--")),

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
                                  onPressed: () {
                                    // open edit dialog
                                  },
                                ),
                                IconButton(
                                  icon: SvgPicture.asset(
                                    'icons/delete.svg',
                                    height: 22,
                                    width: 22,
                                    color: tRed,
                                  ),
                                  onPressed: () {},
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
    );
  }

  // ------------------------------
  // PAGINATION
  // ------------------------------
  Widget _buildPaginationControls(bool isDark) {
    const int visiblePageCount = 5;

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
            fetchGroups();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? tBlue : Colors.transparent,
              shape: BoxShape.circle,
              // borderRadius: BorderRadius.circular(6),
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
          // Previous
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
                fetchGroups();
              }
            },
          ),

          Row(children: pageButtons),

          // Next
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
                fetchGroups();
              }
            },
          ),

          const SizedBox(width: 16),

          // Jump to page
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
                final p = int.tryParse(value);
                if (p != null && p >= 1 && p <= totalPages) {
                  setState(() {
                    currentPage = p;
                    page = currentPage;
                  });
                  fetchGroups();
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

  Widget _addNewGroupButton(bool isDark) => Container(
    height: 40,
    padding: EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: isDark ? tWhite : tBlack),
    child: TextButton(
      onPressed: () {},
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
