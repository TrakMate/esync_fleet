import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../services/apiServices.dart';
import '../../utils/appColors.dart';

class UserCRUDContent extends StatefulWidget {
  const UserCRUDContent({super.key});

  @override
  State<UserCRUDContent> createState() => _UserCRUDContentState();
}

class _UserCRUDContentState extends State<UserCRUDContent> {
  // Scroll controllers for horizontal and vertical scrolling
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  // Pagination / API params
  int page = 1;
  int sizePerPage = 10;

  // UI state
  bool isLoading = false;
  bool isError = false;
  String? errorMessage;

  int totalCount = 0;
  int currentPage = 1;
  int totalPages = 1;

  int rowsPerPage = 10; // REQUIRED FIX

  // Data
  List<dynamic> users = [];

  // Page size options
  // final List<int> pageSizeOptions = [10, 25, 50, 100];

  Color _getColorForGroup(String group) {
    const colors = [
      Color(0xFF1976D2), // Blue
      Color(0xFFD32F2F), // Red
      Color(0xFF388E3C), // Green
      Color(0xFFF57C00), // Orange
      Color(0xFF7B1FA2), // Purple
      Color(0xFF455A64), // Blue Grey
    ];

    int index = group.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  void initState() {
    super.initState();
    fetchUsers(); // initial load
  }

  // -------------------------
  // API: fetch paginated users
  // -------------------------
  Future<void> fetchUsers() async {
    // defensive: if widget removed, don't start
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isError = false;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken") ?? "";

      // Build URL with current page & sizePerPage
      final url =
          "${BaseURLConfig.userApiURL}?page=$page&sizePerPage=$sizePerPage&currentIndex=${(page - 1) * sizePerPage}";

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // // Safely read response fields
        // final fetchedTotal = data["totalCount"] ?? 0;
        // final fetchedEntities = data["entities"] as List<dynamic>? ?? [];

        setState(() {
          // totalCount = fetchedTotal;
          // users = fetchedEntities;
          // totalPages =
          //     fetchedTotal == 0 ? 1 : (fetchedTotal / sizePerPage).ceil();
          // currentPage = page;
          isLoading = false;
          totalCount = data["totalCount"];
          users = data["entities"];
          totalPages = (totalCount / sizePerPage).ceil();
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          isError = true;
          errorMessage = "Failed to load users (${response.statusCode})";
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("UserError: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = "Error fetching users";
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
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
        // Header row: title + controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Users",
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? tWhite : tBlack,
              ),
            ),

            // Right-side controls: New User + page size
            Row(
              children: [
                _addNewUserButton(isDark),
                // const SizedBox(width: 10),

                // // Page size selector
                // Container(
                //   height: 42,
                //   padding: const EdgeInsets.symmetric(horizontal: 12),
                //   decoration: BoxDecoration(
                //     color:
                //         isDark ? tWhite.withOpacity(0.08) : Colors.grey.shade50,
                //     // borderRadius: BorderRadius.circular(10),
                //     border: Border.all(
                //       color:
                //           isDark
                //               ? tWhite.withOpacity(0.10)
                //               : Colors.grey.shade300,
                //       width: 1.2,
                //     ),
                //     boxShadow: [
                //       if (!isDark)
                //         BoxShadow(
                //           color: Colors.black.withOpacity(0.04),
                //           blurRadius: 12,
                //           offset: const Offset(0, 4),
                //         ),
                //     ],
                //   ),
                //   child: DropdownButtonHideUnderline(
                //     child: DropdownButton<int>(
                //       value: sizePerPage,
                //       icon: Icon(
                //         Icons.expand_more_rounded,
                //         size: 20,
                //         color:
                //             isDark
                //                 ? tWhite.withOpacity(0.8)
                //                 : Colors.grey.shade700,
                //       ),
                //       dropdownColor:
                //           isDark ? tBlack.withOpacity(0.95) : Colors.white,
                //       borderRadius: BorderRadius.circular(10),

                //       style: GoogleFonts.urbanist(
                //         fontSize: 14,
                //         fontWeight: FontWeight.w500,
                //         color: isDark ? tWhite : Colors.black87,
                //       ),

                //       items:
                //           pageSizeOptions
                //               .map(
                //                 (s) => DropdownMenuItem(
                //                   value: s,
                //                   child: Text(
                //                     "$s / page",
                //                     style: GoogleFonts.urbanist(
                //                       fontSize: 14,
                //                       fontWeight: FontWeight.w600,
                //                       color: isDark ? tWhite : Colors.black87,
                //                     ),
                //                   ),
                //                 ),
                //               )
                //               .toList(),

                //       onChanged: (v) {
                //         if (v == null) return;
                //         setState(() {
                //           sizePerPage = v;
                //           page = 1;
                //         });
                //         fetchUsers();
                //       },
                //     ),
                //   ),
                // ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Table area with loading overlay
        // Expanded(
        //   child: Stack(
        //     children: [
        //       // Table content (or error / empty)
        //       _buildTableArea(isDark),

        //       // Loading overlay
        //       if (isLoading)
        //         Positioned.fill(
        //           child: Container(
        //             color:
        //                 isDark
        //                     ? Colors.black.withOpacity(0.35)
        //                     : Colors.white.withOpacity(0.6),
        //             child: const Center(child: CircularProgressIndicator()),
        //           ),
        //         ),
        //     ],
        //   ),
        // ),

        // Table Section
        Expanded(
          child:
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildTableArea(isDark),
        ),

        // Pagination footer
        const SizedBox(height: 12),
        _buildPaginationControls(isDark),
      ],
    );
  }

  Widget _buildTableArea(bool isDark) {
    // If API returns zero items
    // if (!isLoading && users.isEmpty) {
    //   return Center(
    //     child: Text(
    //       isError
    //           ? (errorMessage ?? "Failed to load users")
    //           : "No users found.",
    //       style: GoogleFonts.urbanist(
    //         fontSize: 14,
    //         color: isDark ? tWhite : tBlack,
    //       ),
    //     ),
    //   );
    // }

    final currentPageKeys = users;

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
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Phone Number')),
                  DataColumn(label: Text('Groups')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows:
                    currentPageKeys.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final user = entry.value;

                      // safe getters
                      final name = user["name"] ?? "--";
                      final username = user["userName"] ?? user["id"] ?? "--";
                      final phone = user["phone"] ?? "--";
                      final role = user["role"] ?? "--";
                      final groupsList =
                          (user["groupsDetails"] as List<dynamic>?)
                              ?.map((g) => g["name"] ?? "")
                              .where((s) => s.isNotEmpty)
                              .toList() ??
                          [];

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '${(currentPage - 1) * rowsPerPage + idx + 1}',
                            ),
                          ), // API already paginated per page
                          DataCell(Text(name)),
                          DataCell(Text(username)),
                          DataCell(Text(phone)),

                          /// GROUPS LIST WITH COLOR PILLS
                          DataCell(
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  groupsList.isEmpty
                                      ? [Text("--")]
                                      : groupsList.map<Widget>((groupName) {
                                        final color = _getColorForGroup(
                                          groupName,
                                        );

                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.15),
                                            border: Border.all(
                                              color: color,
                                              width: 0.8,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            groupName,
                                            style: GoogleFonts.urbanist(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: color,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                            ),
                          ),
                          DataCell(Text(role)),
                          DataCell(
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color:
                                        user["active"] == true ? tBlue : tRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                        color:
                                            user["active"] == true
                                                ? tBlue
                                                : tRed,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color:
                                        user["active"] == true
                                            ? tBlue.withOpacity(0.15)
                                            : tRed.withOpacity(0.15),
                                  ),
                                  child: Text(
                                    user["active"] == true
                                        ? "Active"
                                        : "Inactive",
                                    style: GoogleFonts.urbanist(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          user["active"] == true ? tBlue : tRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: SvgPicture.asset(
                                    'icons/edit.svg',
                                    height: 20,
                                    width: 20,
                                    color: tBlue,
                                  ),
                                  onPressed: () {
                                    // TODO: open edit dialog
                                  },
                                ),
                                IconButton(
                                  icon: SvgPicture.asset(
                                    'icons/delete.svg',
                                    height: 20,
                                    width: 20,
                                    color: tRed,
                                  ),
                                  onPressed: () {
                                    // TODO: delete confirmation
                                  },
                                ),
                                IconButton(
                                  icon: SvgPicture.asset(
                                    'icons/resetpwd.svg',
                                    height: 20,
                                    width: 20,
                                    color: tBlue,
                                  ),
                                  onPressed: () {
                                    // TODO: reset password
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
    );
  }

  Widget _buildPaginationControls(bool isDark) {
    // guard: ensure at least 1 page
    final computedTotalPages = totalPages < 1 ? 1 : totalPages;
    const int visibleWindow = 5;

    int startPage = ((currentPage - 1) ~/ visibleWindow) * visibleWindow + 1;
    int endPage = (startPage + visibleWindow - 1).clamp(1, computedTotalPages);

    final pageButtons = <Widget>[];

    for (int p = startPage; p <= endPage; p++) {
      final isSelected = p == currentPage;
      pageButtons.add(
        GestureDetector(
          onTap: () {
            // if (p == currentPage) return;
            setState(() {
              currentPage = p;
              // page = p;
              page = currentPage;
            });
            fetchUsers();
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
              '$p',
              style: GoogleFonts.urbanist(
                color:
                    isSelected
                        ? tWhite
                        : (isDark
                            ? tWhite.withOpacity(0.85)
                            : tBlack.withOpacity(0.85)),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    final jumpController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Prev
          IconButton(
            // onPressed:
            //     currentPage > 1
            //         ? () {
            //           setState(() {
            //             currentPage = currentPage - 1;
            //             page = currentPage;
            //           });
            //           fetchUsers();
            //         }
            //         : null,
            onPressed: () {
              if (currentPage > 1) {
                setState(() {
                  currentPage--;
                  page = currentPage;
                });
                fetchUsers();
              }
            },

            icon: Icon(Icons.chevron_left, color: isDark ? tWhite : tBlack),
          ),

          // Page window
          Row(children: pageButtons),

          // Next
          IconButton(
            // onPressed:
            //     currentPage < computedTotalPages
            //         ? () {
            //           setState(() {
            //             currentPage = currentPage + 1;
            //             page = currentPage;
            //           });
            //           fetchUsers();
            //         }
            //         : null,
            onPressed: () {
              if (currentPage < totalPages) {
                setState(() {
                  currentPage++;
                  page = currentPage;
                });
                fetchUsers();
              }
            },

            icon: Icon(Icons.chevron_right, color: isDark ? tWhite : tBlack),
          ),

          const SizedBox(width: 12),

          // Jump to page input
          SizedBox(
            width: 80,
            child: TextField(
              controller: jumpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Page',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? tWhite : tBlack,
                    width: 0.8,
                  ),
                ),
              ),
              onSubmitted: (value) {
                // final p = int.tryParse(value);
                // if (p != null && p >= 1 && p <= computedTotalPages) {
                //   setState(() {
                //     currentPage = p;
                //     page = p;
                //   });
                //   fetchUsers();
                final p = int.tryParse(value);
                if (p != null && p >= 1 && p <= totalPages) {
                  setState(() {
                    currentPage = p;
                    page = currentPage;
                  });
                  fetchUsers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid page number')),
                  );
                }
              },
            ),
          ),

          const SizedBox(width: 12),

          // Display range
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

  Widget _addNewUserButton(bool isDark) => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: isDark ? tWhite : tBlack),
    child: TextButton(
      onPressed: () {
        // TODO: open create user dialog
      },
      child: Row(
        children: [
          SvgPicture.asset(
            'icons/user.svg',
            width: 18,
            height: 18,
            color: isDark ? tBlack : tWhite,
          ),
          const SizedBox(width: 8),
          Text(
            'New User',
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
