import 'dart:ui'; // Add this import at the top

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; // Add this import
import 'package:svg_flutter/svg_flutter.dart';

import '../../../models/CRUDModels/groupsCRUDModel.dart';
import '../../../models/CRUDModels/usersCRUDModel.dart';
import '../../../services/CRUDServices/groupsCRUDService.dart';
import '../../../services/CRUDServices/usersCRUDService.dart';
import '../../../utils/appColors.dart';
import '../../forms/users/userCreateUpdateForm.dart';
import '../../forms/users/userDeleteDialog.dart';
import '../../forms/users/userResetPWDDialog.dart';

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
  List<Entities> users = [];
  List<GroupEntity> groups = [];
  final UserApiService _userApiService = UserApiService();
  final _apiService = GroupsApiService();

  bool isGroupsLoading = false;

  // Page size options
  final List<int> pageSizeOptions = [10, 25, 50, 100];

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
    _loadGroups();
  }

  // -------------------------
  // API: fetch paginated users
  // -------------------------
  Future<void> fetchUsers() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isError = false;
      errorMessage = null;
    });

    try {
      final result = await _userApiService.fetchUsers(
        page: page,
        sizePerPage: sizePerPage,
      );

      if (!mounted) return;

      setState(() {
        users = result.entities ?? [];
        totalCount = result.totalCount ?? 0;
        totalPages = (totalCount / sizePerPage).ceil();
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

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
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
                    const SizedBox(width: 10),

                    // Page size selector
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? tWhite.withOpacity(0.08)
                                : Colors.grey.shade50,
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
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: sizePerPage,
                          icon: Icon(
                            Icons.expand_more_rounded,
                            size: 20,
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.8)
                                    : Colors.grey.shade700,
                          ),
                          dropdownColor:
                              isDark ? tBlack.withOpacity(0.95) : Colors.white,
                          borderRadius: BorderRadius.circular(10),

                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? tWhite : Colors.black87,
                          ),

                          items:
                              pageSizeOptions
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        "$s / page",
                                        style: GoogleFonts.urbanist(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDark ? tWhite : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),

                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              sizePerPage = v;
                              page = 1;
                            });
                            fetchUsers();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Table Section
            Expanded(child: _buildTableArea(isDark)),

            // Pagination footer
            const SizedBox(height: 12),
            _buildPaginationControls(isDark),
          ],
        ),

        // Loading Overlay
        if (isLoading) _buildLoadingOverlay(isDark),
      ],
    );
  }

  // Add this method for the loading overlay
  Widget _buildLoadingOverlay(bool isDark) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true, // block all touches
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: tBlack.withOpacity(isDark ? 0.35 : 0.15),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/gifs/loading1.json', // Make sure this path is correct
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                  Text(
                    'Loading Users...',
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

  Widget _buildTableArea(bool isDark) {
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
                      final name = user.name ?? "--";
                      final username = user.userName ?? user.id ?? "--";
                      final phone = user.phone ?? "--";
                      final role = user.role ?? "--";
                      final groupsList =
                          (user.groupsDetails)
                              ?.map((g) => g.name ?? "")
                              .where((s) => s.isNotEmpty)
                              .toList() ??
                          [];
                      final isActive = user.active == true;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text('${(page - 1) * sizePerPage + idx + 1}'),
                          ),
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
                                    color: isActive ? tBlue : tRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                        color: isActive ? tBlue : tRed,
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
                                        isActive
                                            ? tBlue.withOpacity(0.15)
                                            : tRed.withOpacity(0.15),
                                  ),
                                  child: Text(
                                    isActive ? "Active" : "Inactive",
                                    style: GoogleFonts.urbanist(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? tBlue : tRed,
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
                                    showUserCreateUpdateDialog(
                                      context: context,
                                      title: "Update User",
                                      confirmText: "Update",
                                      initialUsername: user.userName ?? "",
                                      initialName: user.name ?? "",
                                      initialPhone: user.phone ?? "",
                                      initialGroups:
                                          user.groupsDetails
                                              ?.map((g) => g.id ?? "")
                                              .where((s) => s.isNotEmpty)
                                              .toList() ??
                                          [],
                                      initialRole: user.role ?? "VIEWER",
                                      initialActive: user.active == true,
                                      allGroups: groups,
                                      onConfirm: ({
                                        required userName,
                                        required name,
                                        required phone,
                                        required groups,
                                        required role,
                                        required active,
                                      }) async {
                                        await _userApiService
                                            .updateUser(user.id!, {
                                              "userName": userName,
                                              "name": name,
                                              "phone": phone,
                                              "groups": groups,
                                              "role": role,
                                              "active": active,
                                              "org": user.org,
                                              "orgName": user.orgName,
                                              "createdDate": user.createdDate,
                                              "loginCount": user.loginCount,
                                              "profileImage": user.profileImage,
                                            });
                                        fetchUsers();
                                      },
                                    );
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
                                    showUserDeleteConfirmDialog(
                                      context: context,
                                      title: "Delete User",
                                      message:
                                          "Are you sure you want to delete this user?",
                                      onConfirm: () async {
                                        await _userApiService.deleteUser(
                                          user.id!,
                                        );
                                        fetchUsers();
                                      },
                                    );
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
                                    showResetPasswordDialog(
                                      context: context,
                                      userName: user.userName!,
                                      onConfirm: (pwd) async {
                                        await _userApiService.resetPassword(
                                          user.id!,
                                          pwd,
                                        );
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
    );
  }

  Widget _buildPaginationControls(bool isDark) {
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
            setState(() {
              currentPage = p;
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
          IconButton(
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

          Row(children: pageButtons),

          IconButton(
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

          SizedBox(
            width: 70,
            height: 32,
            child: TextField(
              controller: jumpController,
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
        showUserCreateUpdateDialog(
          context: context,
          title: "Create User",
          confirmText: "Create",
          allGroups: groups,
          onConfirm: ({
            required userName,
            required name,
            required phone,
            required groups,
            required role,
            required active,
          }) async {
            await _userApiService.createUser({
              "userName": userName,
              "name": name,
              "phone": phone,
              "groups": groups,
              "role": role,
              "active": active,
            });
            fetchUsers();
          },
        );
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
