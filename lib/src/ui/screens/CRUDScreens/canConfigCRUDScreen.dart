import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:svg_flutter/svg.dart';
import '../../../models/CRUDModels/cancofigOrgNameModel.dart';
import '../../../services/CRUDServices/canConfigOrgNameService.dart';
import '../../../services/CRUDServices/canConfigTabNameService.dart';
import '../../../utils/appColors.dart';

class canConfigCRUDScreen extends StatefulWidget {
  const canConfigCRUDScreen({super.key});

  @override
  State<canConfigCRUDScreen> createState() => _canConfigCRUDScreenState();
}

class _canConfigCRUDScreenState extends State<canConfigCRUDScreen> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final CanConfigTabNameApiService _tabNameService =
      CanConfigTabNameApiService();

  final CanConfigOrgNameService _orgNameService = CanConfigOrgNameService();
  int page = 1;
  int sizePerPage = 10;
  int totalCount = 0;
  int totalPages = 1;
  int currentPage = 1;
  final List<int> pageSizeOptions = [10, 25, 50, 100];

  List<Entities> orgFilteredData = [];
  List<Entities> orgAllData = [];
  List<String> newCanTabs = [];
  List<dynamic> tabFilteredData = [];
  List<dynamic> tabAllData = [];
  bool isLoading = false;
  bool isError = false;
  OverlayEntry? _pageSizeOverlayEntry;
  Entities? selectedOrg;
  @override
  void initState() {
    super.initState();
    fetchCanConfigData();
    fetchOrgCanConfigData();
  }

  Future<void> fetchCanConfigData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final response = await _tabNameService.fetchCanTabNames();
      if (!mounted) return;

      if (response != null && response.entities != null) {
        setState(() {
          tabAllData = response.entities!;
          tabFilteredData = response.entities!;

          totalCount = tabAllData.length;
          totalPages = (totalCount / sizePerPage).ceil();

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching CAN Config data : $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  Future<void> fetchOrgCanConfigData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _orgNameService.fetchOrgCanTabMapping();

      if (!mounted) return;

      if (response != null && response.entities != null) {
        setState(() {
          orgAllData = response.entities!;
          orgFilteredData = response.entities!;

          totalCount = orgAllData.length;
          totalPages = (totalCount / sizePerPage).ceil();

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Org CAN Mapping : $e");

      setState(() {
        isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "CAN Config",
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(children: [const SizedBox(width: 10)]),
              ],
            ),

            const SizedBox(height: 16),
            _buildTableSection(isDark),
          ],
        ),
        if (isLoading) _buildLoader(isDark),
      ],
    );
  }

  Widget _buildTableSection(bool isDark) {
    return Expanded(
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          controller: _verticalController,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  DataTable(
                    showCheckboxColumn: false,
                    headingRowColor: WidgetStateProperty.all(
                      isDark
                          ? tGreen8.withOpacity(0.15)
                          : tGreen8.withOpacity(0.05),
                    ),

                    border: TableBorder.all(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.1)
                              : tBlack.withOpacity(0.1),
                      width: 0.4,
                    ),
                    dividerThickness: 0.01,

                    columns: const [
                      DataColumn(label: Text("Organisation Name")),
                    ],

                    rows:
                        orgAllData.map((org) {
                          final bool isSelected = selectedOrg?.id == org.id;

                          return DataRow(
                            selected: isSelected,

                            onSelectChanged: (value) {
                              setState(() {
                                selectedOrg = org;

                                newCanTabs = List<String>.from(
                                  org.canTabs ?? [],
                                );
                              });
                            },

                            color: WidgetStateProperty.resolveWith<Color?>((
                              states,
                            ) {
                              if (isSelected) {
                                return tGrey.withOpacity(0.15);
                              }
                              return null;
                            }),

                            cells: [DataCell(Text(org.name ?? "--"))],
                          );
                        }).toList(),
                  ),
                ],
              ),

              const SizedBox(width: 30),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  DataTable(
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
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),

                    border: TableBorder.all(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.1)
                              : tBlack.withOpacity(0.1),
                      width: 0.5,
                    ),
                    dividerThickness: 0.01,

                    columns: const [DataColumn(label: Text("Configured Tabs"))],

                    rows:
                        selectedOrg == null
                            ? [
                              const DataRow(
                                cells: [DataCell(Text("Select Organisation"))],
                              ),
                            ]
                            : selectedOrg!.canTabs == null ||
                                selectedOrg!.canTabs!.isEmpty
                            ? [
                              const DataRow(cells: [DataCell(Text("--"))]),
                            ]
                            : selectedOrg!.canTabs!.map<DataRow>((tab) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),

                                      child: Text(
                                        tab,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? tWhite : tBlack,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                  ),
                ],
              ),

              const SizedBox(width: 30),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      isDark
                          ? tGreen8.withOpacity(0.15)
                          : tGreen8.withOpacity(0.05),
                    ),

                    headingTextStyle: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w700,
                      color: isDark ? tWhite : tBlack,
                      fontSize: 12,
                    ),

                    dataTextStyle: GoogleFonts.urbanist(
                      color: isDark ? tWhite : tBlack,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),

                    border: TableBorder.all(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.1)
                              : tBlack.withOpacity(0.1),
                      width: 0.5,
                    ),
                    dividerThickness: 0.01,

                    columns: const [DataColumn(label: Text("Available Tabs"))],

                    rows:
                        tabAllData.map((tabEntity) {
                          final String tabName = tabEntity.toString();

                          return DataRow(
                            cells: [
                              DataCell(
                                GestureDetector(
                                  onTap: () {
                                    if (selectedOrg == null) return;

                                    setState(() {
                                      if (!newCanTabs.contains(tabName)) {
                                        newCanTabs.add(tabName);
                                      }
                                    });
                                  },

                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),

                                    // decoration: BoxDecoration(
                                    //   color:
                                    //       alreadyAdded
                                    //           ? tGreen3.withOpacity(0.15)
                                    //           : tBlueSky.withOpacity(0.15),

                                    //   border: Border.all(
                                    //     color:
                                    //         alreadyAdded ? tGreen3 : tBlueSky,
                                    //   ),

                                    //   borderRadius: BorderRadius.circular(20),
                                    // ),
                                    child: Text(
                                      tabName,

                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,

                                        color: isDark ? tWhite : tBlack,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ],
              ),

              const SizedBox(width: 30),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      isDark
                          ? tGreen8.withOpacity(0.15)
                          : tGreen8.withOpacity(0.05),
                    ),

                    headingTextStyle: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w700,
                      color: isDark ? tWhite : tBlack,
                      fontSize: 12,
                    ),

                    dataTextStyle: GoogleFonts.urbanist(
                      color: isDark ? tWhite : tBlack,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),

                    border: TableBorder.all(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.1)
                              : tBlack.withOpacity(0.1),
                      width: 0.5,
                    ),
                    dividerThickness: 0.01,

                    columns: const [
                      DataColumn(label: Text("New CAN Tab")),
                      DataColumn(label: Text("Action")),
                    ],

                    rows:
                        selectedOrg == null
                            ? []
                            : newCanTabs.isEmpty
                            ? [
                              const DataRow(
                                cells: [
                                  DataCell(Text("No Tabs ")),
                                  DataCell(Text("--")),
                                ],
                              ),
                            ]
                            : newCanTabs.map<DataRow>((tab) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),

                                      child: Text(
                                        tab,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? tWhite : tBlack,
                                        ),
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    IconButton(
                                      icon: SvgPicture.asset(
                                        'icons/delete.svg',
                                        height: 20,
                                        width: 20,
                                        color: tRed,
                                      ),

                                      onPressed: () {
                                        setState(() {
                                          newCanTabs.remove(tab);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get startIndex => (currentPage - 1) * sizePerPage;
  int get endIndex => startIndex + sizePerPage;

  Widget _buildLoader(bool isDark) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
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
                    'Loading Data...',
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

  @override
  void dispose() {
    _hidePageSizeDropdown();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }
}
