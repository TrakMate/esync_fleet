import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import 'CRUDScreens/apiKeyCRUDScreen.dart';
import 'CRUDScreens/commandsAllCRUDScreen.dart';
import 'CRUDScreens/deviceCRUDScreen.dart';
import 'CRUDScreens/groupCRUDScreen.dart';
import 'CRUDScreens/userCRUDScreen.dart';

class SettingsScreen extends StatefulWidget {
  final String initialTab;

  const SettingsScreen({super.key, this.initialTab = 'profile'});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _tabs = [
    'My Profile',
    'Users',
    'Groups',
    'API Key',
    'Devices',
    'Commands',
  ];

  int selectedIndex = 0; // <-- Added selected index

  String? _fullname;
  String? _role;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // convert route string to index
    selectedIndex = _tabToIndex(widget.initialTab);
  }

  int _tabToIndex(String name) {
    switch (name) {
      case 'profile':
        return 0;
      case 'users':
        return 1;
      case 'groups':
        return 2;
      case 'apikey':
        return 3;
      case 'devices':
        return 4;
      case 'commands':
        return 5;
      default:
        return 0;
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullname = prefs.getString('fullname') ?? 'User';
      _role = prefs.getString('role') ?? 'Guest';
      _username = prefs.getString('username') ?? 'guest.user';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(isDark),
    );
  }

  Widget _buildMobileLayout() =>
      const Center(child: Text("Mobile Layout Coming Soon"));

  Widget _buildTabletLayout() =>
      const Center(child: Text("Tablet Layout Coming Soon"));

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 LEFT SIDEBAR MENU
        Container(
          width: 225,
          decoration: BoxDecoration(
            color: tTransparent,
            border: Border(
              right: BorderSide(
                width: 0.7,
                color:
                    isDark ? tWhite.withOpacity(0.3) : tBlack.withOpacity(0.3),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              _tabs.length,
              (index) => _buildSidebarItem(
                label: _tabs[index],
                index: index,
                isDark: isDark,
              ),
            ),
          ),
        ),

        SizedBox(width: 20),

        // 🔹 RIGHT CONTENT AREA
        Expanded(child: _buildTabContent(selectedIndex, isDark)),
      ],
    );
  }

  Widget _buildSidebarItem({
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() => selectedIndex = index);

        switch (index) {
          case 0:
            context.go('/home/settings/profile');
            break;
          case 1:
            context.go('/home/settings/users');
            break;
          case 2:
            context.go('/home/settings/groups');
            break;
          case 3:
            context.go('/home/settings/apikey');
            break;
          case 4:
            context.go('/home/settings/devices');
            break;
          case 5:
            context.go('/home/settings/commands');
            break;
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? tBlue.withOpacity(0.15) : tTransparent,
          border: Border(
            right: BorderSide(
              width: 6,
              color: isSelected ? tBlue : tTransparent,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? tBlue : (isDark ? tWhite : tBlack),
          ),
        ),
      ),
    );
  }

  // Returns widget for selected tab
  Widget _buildTabContent(int index, bool isDark) {
    switch (index) {
      case 0:
        return _buildMyProfile(isDark);
      case 1:
        return UserCRUDContent();
      case 2:
        return GroupCRUDContent();
      case 3:
        return ApiKeyCRUDContent();
      case 4:
        return DevicesCRUDScreen();
      case 5:
        return CommandsAllCRUDContent();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMyProfile(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Profile Box
            Container(
              decoration: BoxDecoration(
                color: tTransparent,
                border: Border.all(width: 0.8, color: tBlue),
              ),
              padding: EdgeInsets.all(6),
              child: Container(
                width: 150,
                height: 159,
                decoration: BoxDecoration(color: tBlue),
              ),
            ),

            SizedBox(width: 10),

            // Divider
            SizedBox(
              height: 159,
              child: VerticalDivider(
                color: isDark ? tWhite : tBlack,
                thickness: 1,
              ),
            ),

            SizedBox(width: 10),

            // Profile Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("Name", _fullname ?? 'Guest User', isDark),
                SizedBox(height: 12),

                _buildDetailRow("Mail ID", "baxy.team@gmail.com", isDark),
                SizedBox(height: 12),

                _buildDetailRow("Phone Number", "+91 727626", isDark),
                SizedBox(height: 12),

                _buildDetailRow("Role", _role ?? 'Guest', isDark),
                SizedBox(height: 12),

                _buildDetailRow("Organization", "BAXY Corp", isDark),
              ],
            ),
          ],
        ),

        SizedBox(height: 20),

        // 🔹 Professional Note Container
        Container(
          decoration: BoxDecoration(
            color: tRedDark.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            'To update your login credentials, modify the username and password in the fields below.',
            style: GoogleFonts.urbanist(
              fontSize: 12,
              color: tRedDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 15),

        // 🔹 Username Field
        _buildEditableField("Username", _username ?? 'guest.user', isDark),

        SizedBox(height: 12),

        // 🔹 Password Field
        _buildEditableField("Password", "********", isDark),

        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: isDark ? tWhite : tBlack,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(
          width: 200,
          child: Text(
            value,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, String value, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ),

        Container(
          width: 250,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  color: isDark ? tWhite : tBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: open edit dialog
                },
                child: SvgPicture.asset(
                  "icons/edit.svg",
                  width: 18,
                  height: 18,
                  color: isDark ? tWhite : tBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
