import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:svg_flutter/svg.dart';

import '../../../models/CRUDModels/orgsCRUDModel.dart';
import '../../../services/CRUDServices/orgCRUDService.dart';
import '../../../utils/appColors.dart';
import '../../forms/orgs/orgsUpdateForm.dart';
import '../../forms/users/userDeleteDialog.dart';
import '../../forms/users/userResetPWDDialog.dart';

class OrgCRUDScreen extends StatefulWidget {
  final bool isMobile;
  final bool isTablet;
  const OrgCRUDScreen({
    super.key,
    this.isTablet = false,
    this.isMobile = false,
  });

  @override
  State<OrgCRUDScreen> createState() => _OrgCRUDScreenState();
}

class _OrgCRUDScreenState extends State<OrgCRUDScreen> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final GlobalKey _pageSizeKey = GlobalKey();

  List<Entities> orgs = [];

  final OrgsApiService _apiService = OrgsApiService();

  int page = 1;
  int sizePerPage = 10;
  int totalCount = 0;
  int totalPages = 1;
  int currentPage = 1;
  final List<int> pageSizeOptions = [10, 25, 50, 100];

  final TextEditingController _searchController = TextEditingController();
  List<Entities> filteredallOrgs = []; // filtered data
  List<Entities> allOrgs = [];
  bool isLoading = false;
  bool isError = false;
  OverlayEntry? _pageSizeOverlayEntry;
  final LayerLink _pageSizeLayerLink = LayerLink();
  @override
  void initState() {
    super.initState();
    fetchOrgs();
  }

  Future<void> fetchOrgs() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final res = await _apiService.fetchorgs(
        currentPage: page,
        sizePerPage: sizePerPage,
      );

      if (!mounted) return;

      setState(() {
        orgs = res.entities ?? [];
        allOrgs = res.entities ?? [];
        filteredallOrgs = orgs;

        totalCount = res.totalCount ?? 0;
        totalPages = (totalCount / sizePerPage).ceil();

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isError = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  void _filterOrgs(String query) {
    final lowerQuery = query.toLowerCase();

    setState(() {
      filteredallOrgs =
          allOrgs.where((org) {
            final name = org.name?.toLowerCase() ?? '';

            final deviceType = getDeviceType(org.orgDeviceType).toLowerCase();

            return name.contains(lowerQuery) || deviceType.contains(lowerQuery);
          }).toList();
    });
  }

  String getDeviceType(int? type) {
    switch (type) {
      case 1:
        return "Non-EV";
      case 2:
        return "EV";
      case 3:
        return "Both";
      default:
        return "--";
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
                            fetchOrgs();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet =
        widget.isTablet || (screenWidth >= 600 && screenWidth < 1200);
    final isMobile = widget.isMobile || (screenWidth <= 600);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- MOBILE LAYOUT ----------------
            if (isMobile) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Organizations",
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                  _addNewOrgButton(isDark),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildFilterBySearch(isDark, isMobile)),
                  const SizedBox(width: 12),
                  CompositedTransformTarget(
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
                        width: 100,
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
                              "$sizePerPage",
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
            ]
            // ---------------- TABLET & DESKTOP LAYOUT ----------------
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Organizations",
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                  Row(
                    children: [
                      _addNewOrgButton(isDark),
                      const SizedBox(width: 10),
                      CompositedTransformTarget(
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
                ],
              ),

              const SizedBox(height: 14),

              // Search bar for tablet/desktop
              _buildFilterBySearch(isDark, isMobile),
            ],

            const SizedBox(height: 16),

            // Table Section
            Expanded(child: _buildTable(isDark)),

            const SizedBox(height: 12),

            // Pagination footer
            _buildPaginationControls(isDark),
          ],
        ),

        if (isLoading) _buildLoader(isDark),
      ],
    );
  }

  Widget _buildTable(bool isDark) {
    // final currentPageKeys = orgs;
    final startIndex = (currentPage - 1) * sizePerPage;
    final endIndex = startIndex + sizePerPage;

    // final currentPageKeys = orgs.sublist(
    //   startIndex,
    //   endIndex > orgs.length ? orgs.length : endIndex,
    // );
    final sourceList = _searchController.text.isEmpty ? orgs : filteredallOrgs;

    final currentPageKeys = sourceList.sublist(
      startIndex,
      endIndex > sourceList.length ? sourceList.length : endIndex,
    );
    if (!isLoading && currentPageKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('icons/nodata1.svg', width: 150, height: 150),
            const SizedBox(height: 12),
            Text(
              "No Organisations Found",
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
                  DataColumn(label: Text('Org Name')),
                  DataColumn(label: Text('Org ID')),
                  DataColumn(label: Text('Created Date')),
                  DataColumn(label: Text('Device Type')),
                  DataColumn(label: Text('CAN Tabs')),
                  DataColumn(label: Text('Actions')),
                ],
                rows:
                    currentPageKeys.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final org = entry.value;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text('${(page - 1) * sizePerPage + idx + 1}'),
                          ),
                          DataCell(Text(org.name ?? "--")),
                          DataCell(Text(org.id ?? "--")),
                          DataCell(Text(org.createdDate ?? "--")),
                          DataCell(Text(getDeviceType(org.orgDeviceType))),

                          /// CAN TABS
                          DataCell(
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  (org.canTabs == null || org.canTabs!.isEmpty)
                                      ? [Text("--")]
                                      : org.canTabs!.map<Widget>((tab) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(
                                              0.15,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            tab,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        );
                                      }).toList(),
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
                                    showOrgCreateUpdateDialog(
                                      context: context,
                                      title: "Update Organisation",
                                      confirmText: "Update",
                                      initialName: org.name,
                                      initialDeviceType: org.orgDeviceType ?? 1,

                                      onConfirm: ({
                                        required name,
                                        required deviceType,
                                      }) async {
                                        await _apiService.updateOrg(org.id!, {
                                          "name": name,
                                          "orgDeviceType": deviceType,
                                        });

                                        fetchOrgs();
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
                                      title: "Delete Organisation",
                                      message:
                                          "Are you sure you want to delete this organisation?",
                                      onConfirm: () async {
                                        await OrgsApiService.deleteOrg(org.id!);
                                        fetchOrgs();
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1200;

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
            fetchOrgs();
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
                            fetchOrgs();
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
                            fetchOrgs();
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
                              fetchOrgs();
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
                            fetchOrgs();
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
                            fetchOrgs();
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
                              fetchOrgs();
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

  // Widget _buildLoader(bool isDark) {
  //   return Positioned.fill(
  //     child: AbsorbPointer(
  //       child: BackdropFilter(
  //         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
  //         child: Container(
  //           color: Colors.black.withOpacity(0.2),
  //           child: const Center(child: CircularProgressIndicator()),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _buildLoader(bool isDark) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true, // blocks touch
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.15),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/gifs/loading1.json',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading Organisations...',
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

  Widget _buildFilterBySearch(bool isDark, bool isMobile) => Column(
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
            _filterOrgs(value);
          },
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? tWhite : tBlack,
          ),
          decoration: InputDecoration(
            hintText: isMobile ? 'Search...' : 'Search...',
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

  @override
  void dispose() {
    _hidePageSizeDropdown();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Widget _addNewOrgButton(bool isDark) => Container(
    height: 40,
    padding: EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: isDark ? tWhite : tBlack),
    child: TextButton(
      onPressed: () {
        showOrgCreateUpdateDialog(
          context: context,
          title: "New Organisation",
          confirmText: "Create",

          initialName: "",
          initialDeviceType: 1,

          onConfirm: ({required name, required deviceType}) async {
            await _apiService.createOrg({
              "name": name,
              "orgDeviceType": deviceType,
            });

            fetchOrgs(); // refresh
          },
        );
      },
      child: Row(
        children: [
          SvgPicture.asset(
            'icons/org.svg',
            width: 18,
            height: 18,
            color: isDark ? tBlack : tWhite,
          ),
          SizedBox(width: 5),
          Text(
            'New Organisation',
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
