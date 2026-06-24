import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../components/customTitleBar.dart';
import '../widgets/reports/alertsReport.dart';
import '../widgets/reports/batteryReport.dart';
import '../widgets/reports/batterySummaryReport.dart';
import '../widgets/reports/detailedTripsReport.dart';
import '../widgets/reports/deviceReport.dart';
import '../widgets/reports/miscellaneousReport.dart';
import '../widgets/reports/tripsReport.dart';
import '../widgets/reports/vehicleSummaryReport.dart';
import '../widgets/reports/vehiclesReport.dart';

class ReportCardModel {
  final String title;
  final String description;
  final String icon;
  final Color bgColor;
  final Color iconColor;

  ReportCardModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int hoveredIndex = -1;
  int selectedIndex = 0;
  bool _isMobile() {
    return MediaQuery.of(context).size.width < 600;
  }

  final List<ReportCardModel> reportCards = [
    // 1. Vehicles Report
    ReportCardModel(
      title: 'Vehicles Report',
      description: 'Details and analytics of all connected vehicles & devices.',
      icon: 'icons/car.svg',
      bgColor: tBlue.withOpacity(0.1),
      iconColor: tBlue,
    ),

    // 2. Vehicle Summary Report
    ReportCardModel(
      title: 'Vehicle Summary\n Report',
      description: 'Daily summary of vehicle status, movement, and activity.',
      icon: 'icons/vehicle_Summary.svg',
      bgColor: Colors.purpleAccent.withOpacity(0.1),
      iconColor: Colors.purpleAccent,
    ),

    // 3. Trips Report
    ReportCardModel(
      title: 'Trips Report',
      description: 'Insights and analytics of trips and route details.',
      icon: 'icons/distance.svg',
      bgColor: tGreen.withOpacity(0.1),
      iconColor: tGreen,
    ),
    //4 Battery Report
    ReportCardModel(
      title: 'Battery Report',
      description:
          'Detailed report of battery metrics including voltage, health status, and usage trends.',

      icon: 'icons/battery.svg',
      bgColor: tOrange1.withOpacity(0.1),
      iconColor: tOrange1,
    ),
    ReportCardModel(
      title: 'Battery Summary \nReport',
      description:
          'Daily summary of battery performance including charge levels, usage patterns, and health insights.',
      icon: 'icons/battery_summary.svg',
      bgColor: tOrange.withOpacity(0.1),
      iconColor: tOrange,
    ),
    // 6. Alerts Report
    ReportCardModel(
      title: 'Alerts Report',
      description: 'Summary of different alerts triggered from vehicles.',
      icon: 'icons/alerts.svg',
      bgColor: tRed.withOpacity(0.1),
      iconColor: tRed,
    ),

    // 6. Geofence Alerts Report
    // ReportCardModel(
    //   title: 'Geofence Alerts\nReport',
    //   description: 'Entry/Exit alerts inside configured geofence zones.',
    //   icon: 'icons/geofence.svg',
    //   bgColor: tOrange.withOpacity(0.1),
    //   iconColor: tOrange,
    // ),
    // 6. Detail Trip Report
    // ReportCardModel(
    //   title: ' Detailed Trips\nReport',
    //   description:
    //       'View detailed information of a specific trip including route, stops, and trip information.',
    //   icon: 'icons/distance.svg',
    //   bgColor: tBlueSky.withOpacity(0.1),
    //   iconColor: tBlueSky,
    // ),
    // // // 6. Device Report
    // ReportCardModel(
    //   title: ' Device\nReport',
    //   description:
    //       'Basic details of a device and its vehicle including ID, model, and battery information.',
    //   icon: 'icons/device.svg',
    //   bgColor: tPink.withOpacity(0.1),
    //   iconColor: tPink,
    // ),
    // 7. Miscellaneous Report
    ReportCardModel(
      title: 'Miscellaneous\nReport',
      description: 'Other supportive reports based on your data.',
      icon: 'icons/miscellaneous.svg',
      bgColor: tGrey.withOpacity(0.1),
      iconColor: tGrey,
    ),
  ];

  List<List<T>> chunkList<T>(List<T> list, int size) {
    List<List<T>> chunks = [];
    for (int i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, (i + size) > list.length ? list.length : i + size),
      );
    }
    return chunks;
  }

  Widget _buildSelectedReportView() {
    final card = reportCards[selectedIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = _isMobile();

    switch (selectedIndex) {
      case 0:
        return VehiclesReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );

      case 1:
        return VehicleSummaryReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );

      case 2:
        return TripsReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );
      case 3:
        return Batteryreport(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );
      case 4:
        return BatterySummaryreport(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );

      case 5:
        return AlertsReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );
      // case 6:
      //   return DetailedTripsReportView(
      //     title: card.title.replaceAll('\n', ' '),
      //     description: card.description,
      //             isDark: isDark,  // Add this

      //   );
      // case 7:
      //   return DeviceReportView(
      //     title: card.title.replaceAll('\n', ' '),
      //     description: card.description,
      //             isDark: isDark,  // Add this

      //   );
      case 6:
        return MiscellaneousReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );

      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveLayout(
      mobile: _buildMobileLayout(isDark),
      tablet: _buildTabletLayout(isDark),
      desktop: _buildDesktopLayout(isDark),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FleetTitleBar(isDark: isDark, title: "Reports"),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 2.1,
            ),
            itemCount: reportCards.length,
            itemBuilder: (context, index) {
              return _buildMobileCard(reportCards[index], index, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCard(ReportCardModel card, int index, bool isDark) {
    final isHovered = hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => _showReportPopup(context, card, index, isDark),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            border: Border.all(
              width: isHovered ? 1 : 0,
              color:
                  isHovered
                      ? card.iconColor.withOpacity(0.6)
                      : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                spreadRadius: 1,
                blurRadius: 8,
                color:
                    isDark ? tWhite.withOpacity(0.12) : tBlack.withOpacity(0.1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: card.bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        card.icon,
                        width: 25,
                        height: 25,
                        color: card.iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  card.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: (isDark ? tWhite : tBlack).withOpacity(0.55),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: SvgPicture.asset(
                  'icons/arrow.svg',
                  width: 16,
                  height: 16,
                  color: card.iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportPopup(
    BuildContext context,
    ReportCardModel card,
    int index,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPopupContent(card, index),
    );
  }

  Widget _buildPopupContent(ReportCardModel card, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? tBlack : tWhite,
        // borderRadius: const BorderRadius.only(
        //   topLeft: Radius.circular(20),
        //   topRight: Radius.circular(20),
        // ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: (isDark ? tWhite : tBlack).withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              // children: [
              //   IconButton(
              //     onPressed: () => Navigator.pop(context),
              //     icon: Icon(Icons.arrow_back, color: isDark ? tWhite : tBlack),
              //   ),
              // ],
            ),
          ),

          // Report content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _getReportViewByIndex(index, card),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getReportViewByIndex(int index, ReportCardModel card) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    switch (index) {
      case 0:
        return VehiclesReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );
      case 1:
        return VehicleSummaryReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );
      case 2:
        return TripsReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );
      case 3:
        return Batteryreport(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );
      case 4:
        return BatterySummaryreport(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );
      case 5:
        return AlertsReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );
      // case 6:
      //   return DetailedTripsReportView(
      //     title: card.title.replaceAll('\n', ' '),
      //     description: card.description,
      //     isDark: isDark,
      //   );
      // case 7:
      //   return DeviceReportView(
      //     title: card.title.replaceAll('\n', ' '),
      //     description: card.description,
      //     isDark: isDark,
      //   );
      case 6:
        return MiscellaneousReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
          isDark: isDark,
          isMobile: isMobile,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildTabletLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FleetTitleBar(isDark: isDark, title: "Reports"),
        // const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 1.75,
                  ),
                  itemCount: reportCards.length,
                  itemBuilder: (context, index) {
                    return _buildSingleCardForTablet(
                      reportCards[index],
                      index,
                      isDark,
                    );
                  },
                ),
              ),
              Expanded(
                flex: 6,
                child: Container(
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildSelectedReportView(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleCardForTablet(
    ReportCardModel card,
    int index,
    bool isDark,
  ) {
    final isHovered = hoveredIndex == index;
    final isSelected = selectedIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => setState(() => selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width:
                  isSelected
                      ? 2
                      : isHovered
                      ? 1.3
                      : 0,
              color:
                  isSelected
                      ? card.iconColor
                      : isHovered
                      ? card.iconColor.withOpacity(0.6)
                      : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                spreadRadius: 1,
                blurRadius: 8,
                color:
                    isDark ? tWhite.withOpacity(0.12) : tBlack.withOpacity(0.1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Smaller icon for tablet
              Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: card.bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        card.icon,
                        width: 40,
                        height: 40,
                        color: card.iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Smaller font for tablet title
                  Text(
                    card.title,
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? tWhite : tBlack,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Smaller font for tablet description
              Expanded(
                child: Text(
                  card.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.urbanist(
                    fontSize: 11,
                    color: (isDark ? tWhite : tBlack).withOpacity(0.55),
                  ),
                ),
              ),
              // Smaller arrow for tablet
              Align(
                alignment: Alignment.bottomRight,
                child: SvgPicture.asset(
                  'icons/arrow.svg',
                  width: 18,
                  height: 18,
                  color: card.iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FleetTitleBar(isDark: isDark, title: "Reports"),

        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 4, child: _buildReportCards(isDark)),
              Expanded(
                flex: 6,
                child: Container(
                  padding: EdgeInsets.all(20),
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildSelectedReportView(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportCards(bool isDark) {
    return GridView.builder(
      // padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 items per row
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.6,
        //// Adjust card height/width
      ),
      itemCount: reportCards.length,
      itemBuilder: (context, index) {
        return _buildSingleCard(reportCards[index], index, isDark);
      },
    );
  }

  Widget _buildSingleCard(ReportCardModel card, int index, bool isDark) {
    final isHovered = hoveredIndex == index;
    final isSelected = selectedIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => setState(() => selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            border: Border.all(
              width:
                  isSelected
                      ? 2
                      : isHovered
                      ? 1.3
                      : 0,
              color:
                  isSelected
                      ? card.iconColor
                      : isHovered
                      ? card.iconColor.withOpacity(0.6)
                      : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                spreadRadius: 2,
                blurRadius: 12,
                color:
                    isDark ? tWhite.withOpacity(0.12) : tBlack.withOpacity(0.1),
              ),
            ],
          ),

          // child: Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     Container(
          //       width: 55,
          //       height: 55,
          //       decoration: BoxDecoration(
          //         color: card.bgColor,
          //         borderRadius: BorderRadius.circular(10),
          //       ),
          //       child: Center(
          //         child: SvgPicture.asset(
          //           card.icon,
          //           width: 28,
          //           height: 28,
          //           color: card.iconColor,
          //         ),
          //       ),
          //     ),
          //     const SizedBox(height: 10),
          //     Text(
          //       card.title,
          //       style: GoogleFonts.urbanist(
          //         fontSize: 20,
          //         fontWeight: FontWeight.bold,
          //         color: isDark ? tWhite : tBlack,
          //       ),
          //     ),
          //     const SizedBox(height: 5),
          //     Text(
          //       card.description,
          //       maxLines: 3,
          //       overflow: TextOverflow.ellipsis,
          //       style: GoogleFonts.urbanist(
          //         fontSize: 12,
          //         color: (isDark ? tWhite : tBlack).withOpacity(0.55),
          //       ),
          //     ),
          //     const Spacer(),
          //     const SizedBox(height: 25),

          //     Align(
          //       alignment: Alignment.bottomRight,
          //       child: SvgPicture.asset(
          //         'icons/arrow.svg',
          //         width: 22,
          //         height: 22,
          //         color: card.iconColor,
          //       ),
          //     ),
          //   ],
          // ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: card.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    card.icon,
                    width: 28,
                    height: 28,
                    color: card.iconColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                card.title,
                style: GoogleFonts.urbanist(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),

              const SizedBox(height: 5),

              Expanded(
                child: Text(
                  card.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: (isDark ? tWhite : tBlack).withOpacity(0.55),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.bottomRight,
                child: SvgPicture.asset(
                  'icons/arrow.svg',
                  width: 22,
                  height: 22,
                  color: card.iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
