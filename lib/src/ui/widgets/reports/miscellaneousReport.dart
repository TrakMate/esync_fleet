import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/appColors.dart';

class MiscellaneousReportView extends StatefulWidget {
  final String title;
  final String description;
  const MiscellaneousReportView({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<MiscellaneousReportView> createState() =>
      _MiscellaneousReportViewState();
}

class _MiscellaneousReportViewState extends State<MiscellaneousReportView> {
  DateTime? fromDate;
  DateTime? toDate;

  final TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    fromDate = now;
    toDate = now;
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return "${date.day.toString().padLeft(2, '0')} "
        "${months[date.month - 1]} "
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.urbanist(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                const SizedBox(height: 5),

                Text(
                  widget.description,
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: (isDark ? tWhite : tBlack).withOpacity(0.8),
                  ),
                ),
              ],
            ),

            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: tGreen8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Generate Report',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tBlack,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),
        Divider(
          color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
          height: 1,
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            /// FROM DATE
            Row(
              children: [
                _dateLabelBox('From', isDark),
                const SizedBox(width: 5),
                _dateValueBox(
                  _formatDate(fromDate!),
                  isDark,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fromDate!,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => fromDate = picked);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(width: 30),

            /// TO DATE
            Row(
              children: [
                _dateLabelBox('To', isDark),
                const SizedBox(width: 5),
                _dateValueBox(
                  _formatDate(toDate!),
                  isDark,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: toDate!,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => toDate = picked);
                    }
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 15),
        Text(
          'Search by  IMEI',
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        SizedBox(height: 10),
        _searchField(isDark),
      ],
    );
  }

  Widget _dateLabelBox(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tTransparent,
        border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.urbanist(
          fontSize: 13,
          color: isDark ? tWhite : tBlack,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _dateValueBox(
    String value,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tTransparent,
          border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
        ),
        child: Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _searchField(bool isDark) {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: "Enter Vehicle ID or IMEI",
        hintStyle: GoogleFonts.urbanist(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
        ),
        prefixIcon: Icon(
          Icons.search_outlined,
          size: 18,
          color: isDark ? tWhite : tBlack,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(0)),
      ),
    );
  }
}
