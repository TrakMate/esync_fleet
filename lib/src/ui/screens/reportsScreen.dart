import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../components/customTitleBar.dart';
import '../widgets/reports/alertsReport.dart';
import '../widgets/reports/batteryReport.dart';
import '../widgets/reports/batterySummaryReport.dart';
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

  final List<ReportCardModel> reportCards = [
    // 1. Vehicles Report
    ReportCardModel(
      title: 'Vehicles\nReport',
      description: 'Details and analytics of all connected vehicles & devices.',
      icon: 'icons/car.svg',
      bgColor: tBlue.withOpacity(0.1),
      iconColor: tBlue,
    ),

    // 2. Vehicle Summary Report
    ReportCardModel(
      title: 'Vehicle Summary\nReport',
      description: 'Daily summary of vehicle status, movement, and activity.',
      icon: 'icons/vehicle_Summary.svg',
      bgColor: Colors.purpleAccent.withOpacity(0.1),
      iconColor: Colors.purpleAccent,
    ),

    // 3. Trips Report
    ReportCardModel(
      title: 'Trips\nReport',
      description: 'Insights and analytics of trips and route details.',
      icon: 'icons/distance.svg',
      bgColor: tGreen.withOpacity(0.1),
      iconColor: tGreen,
    ),

    // 4. Battery Report
    ReportCardModel(
      title: 'Battery\nReport',
      description:
          'Detailed battery metrics and performance data across all vehicles (IMEIs), including voltage, health status, and usage trends.',

      icon: 'icons/battery.svg',
      bgColor: tOrange1.withOpacity(0.1),
      iconColor: tOrange1,
    ),

    //5 Battery Summary Report
    ReportCardModel(
      title: 'Battery Summary\nReport',
      description:
          'Overview of battery performance, health, and usage for a selected vehicle (IMEI).',
      icon: 'icons/battery_summary.svg',
      // bgColor: Colors.deepPurple.withOpacity(0.1),
      // iconColor: Colors.deepPurple,
      bgColor: tGreen5.withOpacity(0.1),
      iconColor: tGreen5,
    ),

    // 6. Alerts Report
    ReportCardModel(
      title: 'Alerts\nReport',
      description: 'Summary of different alerts triggered from vehicles.',
      icon: 'icons/alerts.svg',
      bgColor: tRed.withOpacity(0.1),
      iconColor: tRed,
    ),

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

    switch (selectedIndex) {
      case 0:
        return VehiclesReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
        );

      case 1:
        return VehicleSummaryReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
        );

      case 2:
        return TripsReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
        );

      case 3:
        return Batteryreport(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
        );

      case 4:
        return BatterySummaryreport(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
        );
      case 5:
        return AlertsReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
        );

      case 6:
        return MiscellaneousReportView(
          title: card.title.replaceAll('\n', ' '),
          description: card.description,
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
      tablet: _buildMobileLayout(isDark),
      desktop: _buildDesktopLayout(isDark),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Container();
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
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.6, // Adjust card height/width
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
            // borderRadius: BorderRadius.circular(12),
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
              Text(
                card.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: (isDark ? tWhite : tBlack).withOpacity(0.55),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 25),

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
