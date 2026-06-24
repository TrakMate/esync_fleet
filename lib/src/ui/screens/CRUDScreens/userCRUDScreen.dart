import 'dart:async';
import 'dart:ui'; // Add this import at the top

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';
import '../../../models/CRUDModels/groupsCRUDModel.dart';
import '../../../models/CRUDModels/orgsCRUDModel.dart' as org_model;
import '../../../models/CRUDModels/usersCRUDModel.dart';
import '../../../services/CRUDServices/groupsCRUDService.dart';
import '../../../services/CRUDServices/orgCRUDService.dart';
import '../../../services/CRUDServices/usersCRUDService.dart';
import '../../../utils/appColors.dart';
import '../../forms/users/userCreateUpdateForm.dart';
import '../../forms/users/userDeleteDialog.dart';

import '../../forms/users/userResetPWDDialog.dart';

class UserCRUDContent extends StatefulWidget {
  final bool isTablet;
  final bool isMobile;
  const UserCRUDContent({
    super.key,
    this.isTablet = false,
    this.isMobile = false,
  });

  @override
  State<UserCRUDContent> createState() => _UserCRUDContentState();
}

class _UserCRUDContentState extends State<UserCRUDContent> {
  OverlayEntry? _overlayEntry;
  Timer? _searchDebounceTimer;
  final GlobalKey _pageSizeKey = GlobalKey();
  bool isSuperAdmin = false;

  void _hideDropdown() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (_) {}
      _overlayEntry = null;
    }
  }

  final LayerLink _layerLink = LayerLink();
  // OverlayEntry? _statusOverlayEntry;

  // void _hideStatusDropdown() {
  //   if (_statusOverlayEntry != null) {
  //     try {
  //       _statusOverlayEntry!.remove();
  //     } catch (_) {}

  //     _statusOverlayEntry = null;
  //   }
  // }

  // final LayerLink _statusLayerLink = LayerLink();

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  int page = 1;
  int sizePerPage = 10;

  int selectedStatus = -1;

  TextEditingController searchController = TextEditingController();

  bool isLoading = false;
  bool isError = false;
  String? errorMessage;
  String searchText = '';

  int totalCount = 0;
  int currentPage = 1;
  int totalPages = 1;

  int rowsPerPage = 10;
  String? selectedRole = 'ALL';
  final List<String> roleOptions = ["ALL", "SUPER ADMIN", "ADMIN", "VIEWER"];

  List<Entities> users = [];
  List<GroupEntity> groups = [];
  List<Entities> filteredUsers = [];
  final UserApiService _userApiService = UserApiService();
  final _apiService = GroupsApiService();

  bool isGroupsLoading = false;
  OverlayEntry? _pageSizeOverlayEntry;
  final LayerLink _pageSizeLayerLink = LayerLink();
  final List<int> pageSizeOptions = [10, 25, 50, 100];
  final TextEditingController _searchController = TextEditingController();
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
    _loadUserRole();

    fetchUsers();
    _loadGroups();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();

    final role = prefs.getString('role') ?? '';

    setState(() {
      isSuperAdmin = role == 'SUPER_ADMIN';
    });

    debugPrint('Role: $role');
    debugPrint('isSuperAdmin: $isSuperAdmin');

    if (isSuperAdmin) {
      await _loadOrganizations();
    }
  }

  final OrgsApiService _orgApiService = OrgsApiService();
  List<org_model.Entities> Organizations = [];

  Future<void> _loadOrganizations() async {
    try {
      final result = await _orgApiService.fetchorgs(
        currentPage: 1,
        sizePerPage: 1000,
      );

      if (!mounted) return;

      setState(() {
        Organizations.clear();
        Organizations.addAll(result.entities ?? []);
      });

      debugPrint("Organizations Loaded: ${Organizations.length}");
    } catch (e) {
      debugPrint("Organization fetch error: $e");
    }
  }

  @override
  void dispose() {
    _hideDropdown();
    _hidePageSizeDropdown();

    _searchDebounceTimer?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  final Map<String, int> statusOptions = {
    "ALL": -1,
    "ACTIVE": 0,
    "INACTIVE": 1,
  };

  void _hidePageSizeDropdown() {
    if (_pageSizeOverlayEntry != null) {
      try {
        _pageSizeOverlayEntry!.remove();
      } catch (_) {}
      _pageSizeOverlayEntry = null;
    }
  }

  void _showPageSizeDropdown(BuildContext context, bool isMobile) {
    final overlay = Overlay.of(context);

    _pageSizeOverlayEntry = OverlayEntry(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final RenderBox renderBox =
            _pageSizeKey.currentContext!.findRenderObject() as RenderBox;

        final double fieldWidth = renderBox.size.width;
        return Positioned(
          // width: 180,
          // width: isMobile ? MediaQuery.of(context).size.width - 32 : 180,
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
                            fetchUsers();
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
        role: selectedRole,
        status: selectedStatus, // int value
        searchText: _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        users = result.entities ?? [];
        filteredUsers = users;

        totalCount = result.totalCount ?? 0;
        totalPages = (totalCount / sizePerPage).ceil().clamp(1, 999);

        if (currentPage > totalPages) {
          currentPage = 1;
          page = 1;
        }

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final isTablet =
        widget.isTablet || (screenWidth >= 600 && screenWidth < 1200);
    final isMobile = widget.isMobile || (screenWidth <= 600);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_overlayEntry != null) {
        _hideDropdown();
        _hidePageSizeDropdown();
      }
    });
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // // Header row: title + controls
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     if (!isMobile)
            //       Text(
            //         "Users",
            //         style: GoogleFonts.urbanist(
            //           fontSize: 18,
            //           fontWeight: FontWeight.bold,
            //           color: isDark ? tWhite : tBlack,
            //         ),
            //       ),

            //     Container(
            //       margin:
            //           isMobile ? EdgeInsets.only(bottom: 10) : EdgeInsets.zero,
            //       child: Row(
            //         children: [
            //           // _buildFilterBySearch(isDark),
            //           // const SizedBox(width: 10),
            //           _addNewUserButton(isDark, isTablet, isMobile),
            //           const SizedBox(width: 10),

            //           // Page size selector
            //           Container(
            //             child: CompositedTransformTarget(
            //               link: _pageSizeLayerLink,
            //               child: GestureDetector(
            //                 onTap: () {
            //                   if (_pageSizeOverlayEntry == null) {
            //                     _showPageSizeDropdown(context);
            //                   } else {
            //                     _hidePageSizeDropdown();
            //                   }
            //                 },
            //                 child: Container(
            //                   height: 42,
            //                   width: 150,
            //                   padding: const EdgeInsets.symmetric(
            //                     horizontal: 12,
            //                   ),
            //                   decoration: BoxDecoration(
            //                     color:
            //                         isDark
            //                             ? tWhite.withOpacity(0.08)
            //                             : Colors.grey.shade50,
            //                     border: Border.all(
            //                       color:
            //                           isDark
            //                               ? tWhite.withOpacity(0.10)
            //                               : Colors.grey.shade300,
            //                       width: 1.2,
            //                     ),
            //                     boxShadow: [
            //                       if (!isDark)
            //                         BoxShadow(
            //                           color: Colors.black.withOpacity(0.04),
            //                           blurRadius: 12,
            //                           offset: const Offset(0, 4),
            //                         ),
            //                     ],
            //                   ),
            //                   child: Row(
            //                     mainAxisAlignment:
            //                         MainAxisAlignment.spaceBetween,
            //                     children: [
            //                       Text(
            //                         "$sizePerPage / page",
            //                         style: GoogleFonts.urbanist(
            //                           fontSize: 14,
            //                           fontWeight: FontWeight.w500,
            //                           color: isDark ? tWhite : Colors.black87,
            //                         ),
            //                       ),
            //                       Icon(
            //                         Icons.expand_more_rounded,
            //                         size: 20,
            //                         color:
            //                             isDark
            //                                 ? tWhite.withOpacity(0.8)
            //                                 : Colors.grey.shade700,
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
            // // SizedBox(height: 16),
            // // _buildFilterBySearch(isDark),
            // Row(
            //   children: [
            //     _buildFilterBySearch(isDark, isTablet, isMobile),
            //     SizedBox(width: 20),
            //     _buildRoleFilterDropdown(isDark, isTablet, isMobile),
            //     // SizedBox(width: 20),
            //     // _buildStatusFilterDropdown(isDark),
            //   ],
            // ),
            // ---------------- MOBILE LAYOUT ----------------

            // ---------------- MOBILE LAYOUT ----------------
            if (isMobile) ...[
              // FIRST ROW: Title + New User Button
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
                  _addNewUserButton(isDark, isTablet, isMobile),
                ],
              ),

              const SizedBox(height: 12),

              // SECOND ROW: Search Bar (Full width)
              _buildFilterBySearch(isDark, isTablet, isMobile),

              const SizedBox(height: 12),

              // THIRD ROW: Role Dropdown + Page Size
              Row(
                children: [
                  // Role Dropdown
                  Expanded(
                    child: _buildRoleFilterDropdown(isDark, isTablet, isMobile),
                  ),
                  const SizedBox(width: 12),
                  // Page Size Selector
                  CompositedTransformTarget(
                    link: _pageSizeLayerLink,
                    child: GestureDetector(
                      onTap: () {
                        if (_pageSizeOverlayEntry == null) {
                          _showPageSizeDropdown(context, isMobile);
                        } else {
                          _hidePageSizeDropdown();
                        }
                      },
                      child: Container(
                        height: 42,
                        // width: 100,
                        key: _pageSizeKey,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? tWhite : tBlack,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$sizePerPage / page",
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? tWhite : Colors.black87,
                              ),
                            ),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 18,
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.8)
                                      : Colors.grey.shade700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ] // ---------------- TABLET & DESKTOP LAYOUT ----------------
            else ...[
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

                  Row(
                    children: [
                      _addNewUserButton(isDark, isTablet, isMobile),
                      const SizedBox(width: 10),

                      Container(
                        child: CompositedTransformTarget(
                          link: _pageSizeLayerLink,
                          child: GestureDetector(
                            onTap: () {
                              if (_pageSizeOverlayEntry == null) {
                                _showPageSizeDropdown(context, isMobile);
                              } else {
                                _hidePageSizeDropdown();
                              }
                            },
                            child: Container(
                              key: _pageSizeKey,
                              height: 42,
                              width: 150,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
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
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    color:
                                        isDark
                                            ? tWhite.withOpacity(0.8)
                                            : Colors.grey.shade700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  _buildFilterBySearch(isDark, isTablet, isMobile),
                  SizedBox(width: 20),
                  _buildRoleFilterDropdown(isDark, isTablet, isMobile),
                ],
              ),

              // const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),
            // Table Section
            Expanded(child: _buildTableArea(isDark, isTablet, isMobile)),

            // Pagination footer
            const SizedBox(height: 12),
            _buildPaginationControls(isDark, isTablet, isMobile),
          ],
        ),

        // Loading Overlay
        if (isLoading) _buildLoadingOverlay(isDark, isTablet, isMobile),
      ],
    );
  }

  // Add this method for the loading overlay
  Widget _buildLoadingOverlay(bool isDark, bool_isTablet, isMobile) {
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

  Widget _buildTableArea(bool isDark, bool isTablet, isMobile) {
    final currentPageKeys = filteredUsers;
    if (!isLoading && currentPageKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('icons/nodata1.svg', width: 150, height: 150),
            const SizedBox(height: 12),
            Text(
              "No Users Found",
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
                                    color: isActive ? tGreen8 : tRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                        color: isActive ? tGreen8 : tRed,
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
                                            ? tGreen8.withOpacity(0.15)
                                            : tRed.withOpacity(0.15),
                                  ),
                                  child: Text(
                                    isActive ? "Active" : "Inactive",
                                    style: GoogleFonts.urbanist(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? tGreen8 : tRed,
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
                                    color: tGreen8,
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

                                      selectedOrgId: user.org,
                                      isSuperAdmin: isSuperAdmin,

                                      initialRole: user.role ?? "VIEWER",
                                      initialActive: user.active == true,

                                      allGroups: groups,
                                      allOrganizations: Organizations,
                                      onConfirm: ({
                                        required userName,
                                        required name,
                                        required phone,
                                        required groups,
                                        String? orgId,
                                        required role,
                                        required active,
                                      }) async {
                                        await _userApiService
                                            .updateUser(user.id!, {
                                              "userName": userName,
                                              "name": name,
                                              "phone": phone,

                                              if (isSuperAdmin)
                                                "org": orgId
                                              else
                                                "groups": groups,

                                              "role":
                                                  role == "SUPER ADMIN"
                                                      ? "SUPER_ADMIN"
                                                      : role,

                                              "active": active,

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
                                    color: tGreen8,
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

  Widget _buildPaginationControls(bool isDark, bool isTablet, isMobile) {
    // final computedTotalPages = totalPages < 1 ? 1 : totalPages;
    // final computedTotalPages = (filteredUsers.length / sizePerPage)
    // .ceil()
    // .clamp(1, 999);
    final computedTotalPages = totalPages;

    const int visibleWindow = 5;

    int startPage = ((currentPage - 1) ~/ visibleWindow) * visibleWindow + 1;
    int endPage = (startPage + visibleWindow - 1).clamp(1, computedTotalPages);

    final pageButtons = <Widget>[];
    final isMobile = MediaQuery.of(context).size.width < 600;
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
              color: isSelected ? tGreen8 : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    isSelected
                        ? tGreen8
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
                fontSize: isMobile ? 11 : (isTablet ? 12 : 13),
              ),
            ),
          ),
        ),
      );
    }

    final jumpController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 4),
      child:
          isMobile
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                        icon: Icon(
                          Icons.chevron_left,
                          color: isDark ? tWhite : tBlack,
                          size: 18,
                        ),
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
                        icon: Icon(
                          Icons.chevron_right,
                          color: isDark ? tWhite : tBlack,
                          size: 18,
                        ),
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
                          controller: jumpController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.urbanist(
                            fontSize: 10,
                            color: isDark ? tWhite : tBlack,
                            fontWeight: FontWeight.w500,
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
                              borderSide: BorderSide(
                                color: isDark ? tWhite : tBlack,
                                width: 0.8,
                              ),
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

                              fetchUsers();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid page number'),
                                ),
                              );
                            }
                          },
                          cursorColor: isDark ? tWhite : tBlack,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        'Page $currentPage of $computedTotalPages',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: isDark ? tWhite : tBlack,
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
                        onPressed: () {
                          if (currentPage > 1) {
                            setState(() {
                              currentPage--;
                              page = currentPage;
                            });
                            fetchUsers();
                          }
                        },
                        icon: Icon(
                          Icons.chevron_left,
                          color: isDark ? tWhite : tBlack,
                          size: 22,
                        ),
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
                        icon: Icon(
                          Icons.chevron_right,
                          color: isDark ? tWhite : tBlack,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 16),

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
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: isDark ? tWhite : tBlack,
                                width: 0.8,
                              ),
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

                              fetchUsers();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid page number'),
                                ),
                              );
                            }
                          },
                          cursorColor: isDark ? tWhite : tBlack,
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
                ),
              ),
    );
  }

  Widget _addNewUserButton(bool isDark, bool isTablet, bool isMobile) =>
      Container(
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
              allOrganizations: Organizations, // your org list
              isSuperAdmin: isSuperAdmin, // your role check

              onConfirm: ({
                required userName,
                required name,
                required phone,
                required groups,
                String? orgId,
                required role,
                required active,
              }) async {
                await _userApiService.createUser({
                  "userName": userName,
                  "name": name,
                  "phone": phone,
                  "role": role,
                  "active": active,

                  if (isSuperAdmin) "org": orgId else "groups": groups,
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

  Widget _buildFilterBySearch(
    bool isDark,
    bool isTablet,
    bool isMobile,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: isMobile ? double.infinity : 180,
        height: 42,
        decoration: BoxDecoration(
          color: tTransparent,
          border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
        ),
        child: TextField(
          controller: _searchController,
          cursorColor: isDark ? tWhite : tBlack,
          onChanged: (value) {
            if (!mounted) return;

            _searchDebounceTimer?.cancel();

            _searchDebounceTimer = Timer(
              const Duration(milliseconds: 500),
              () async {
                if (!mounted) return;

                setState(() {
                  searchText = value.trim();
                  page = 1;
                  currentPage = 1;
                });

                await fetchUsers();
              },
            );
          },
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? tWhite : tBlack,
          ),
          decoration: InputDecoration(
            hintText: isMobile ? 'Search Users...' : 'Search...',
            hintStyle: GoogleFonts.urbanist(
              fontSize: 12,
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
      ),
      // Only show note on non-mobile devices
      if (!isMobile) ...[
        const SizedBox(height: 5),
        Text(
          '(Note: Filter by Search)',
          style: GoogleFonts.urbanist(
            fontSize: 10,
            color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ],
  );

  Widget _buildRoleFilterDropdown(bool isDark, bool isTablet, bool isMobile) {
    void _showDropdown(BuildContext context) {
      final overlay = Overlay.of(context);

      _overlayEntry = OverlayEntry(
        builder: (context) {
          return Stack(
            children: [
              /// Detect tap anywhere outside dropdown
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _hideDropdown();
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),

              /// Actual dropdown
              CompositedTransformFollower(
                link: _layerLink,
                offset: const Offset(0, 46),
                showWhenUnlinked: false,
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width:
                        isMobile
                            ? MediaQuery.of(context).size.width - 138
                            : 180,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? tBlack.withOpacity(0.95)
                                : tWhite.withOpacity(0.95),
                        border: Border.all(
                          color:
                              isDark
                                  ? tWhite.withOpacity(0.9)
                                  : tBlack.withOpacity(0.9),
                          width: 1,
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
                            roleOptions.map((role) {
                              return InkWell(
                                onTap: () async {
                                  if (!mounted) return;

                                  setState(() {
                                    selectedRole = role;
                                    page = 1;
                                    currentPage = 1;
                                  });

                                  _hideDropdown();

                                  await fetchUsers();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    role,
                                    style: GoogleFonts.urbanist(
                                      fontSize: 12,
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
              ),
            ],
          );
        },
      );

      overlay.insert(_overlayEntry!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: () {
              if (_overlayEntry == null) {
                _showDropdown(context);
              } else {
                _hideDropdown();
              }
            },
            child: Container(
              width: isMobile ? double.infinity : 180,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
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
                    selectedRole ?? "ALL",
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? tWhite : Colors.black87,
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color:
                        isDark ? tWhite.withOpacity(0.8) : Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Only show note on non-mobile devices
        if (!isMobile) ...[
          const SizedBox(height: 6),
          Text(
            '(Note: Filter by Role)',
            style: GoogleFonts.urbanist(
              fontSize: 10,
              color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
