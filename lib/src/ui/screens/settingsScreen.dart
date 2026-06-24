import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';
import '../../services/CRUDServices/usersCRUDService.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import 'CRUDScreens/apiKeyCRUDScreen.dart';
import 'CRUDScreens/canConfigCRUDScreen.dart';
import 'CRUDScreens/commandsAllCRUDScreen.dart';
import 'CRUDScreens/deviceCRUDScreen.dart';
import 'CRUDScreens/groupCRUDScreen.dart';
import 'CRUDScreens/orgsCRUDScreen.dart';
import 'CRUDScreens/userCRUDScreen.dart';

class SettingsScreen extends StatefulWidget {
  final String initialTab;

  const SettingsScreen({super.key, this.initialTab = 'profile'});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> _tabs = [];
  final UserApiService _userApiService = UserApiService();
  int selectedIndex = 0;

  String? _fullname;
  String? _role;
  String? _username;
  String? _phoneNumber;
  String? _orgName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // convert route string to index
  }

  // int _tabToIndex(String name) {
  //   switch (name) {
  //     case 'profile':
  //       return 0;
  //     case 'users':
  //       return 1;
  //     case 'groups':
  //       return 2;
  //     case 'apikey':
  //       return 3;
  //     case 'devices':
  //       return 4;
  //     case 'commands':
  //       return 5;
  //     case 'orgs':
  //       return 6;
  //     default:
  //       return 0;
  //   }
  // }

  // Future<void> _loadUserData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     _fullname = prefs.getString('fullname') ?? 'User';
  //     _role = prefs.getString('role') ?? 'Guest';
  //     _username = prefs.getString('username') ?? 'guest.user';
  //   });
  // }
  /// 🔹 ROLE BASED TAB SETUP
  ///
  ///
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final role = prefs.getString('role') ?? 'VIEWER';

    _fullname = prefs.getString('fullname') ?? 'User';
    _role = role;
    _username = prefs.getString('username') ?? 'guest.user';
    _phoneNumber =
        (prefs.getString('Phone') ?? '').isEmpty
            ? '-- --'
            : prefs.getString('Phone')!;
    _orgName = prefs.getString('Organisation') ?? '--';

    if (role == "VIEWER") {
      _tabs = ['My Profile', 'Devices'];
    } else if (role == "ADMIN") {
      _tabs = [
        'My Profile',
        'Users',
        'Groups',
        'API Key',
        'Devices',
        'Commands',
      ];
    } else {
      _tabs = [
        'My Profile',
        'Users',
        'Groups',
        'API Key',
        'Organisation',
        'CAN Config',
      ];
    }

    selectedIndex = _tabToIndex(widget.initialTab);

    setState(() {});
  }

  int _tabToIndex(String name) {
    switch (name) {
      case 'profile':
        return _tabs.indexOf('My Profile');
      case 'users':
        return _tabs.indexOf('Users');
      case 'groups':
        return _tabs.indexOf('Groups');
      case 'apikey':
        return _tabs.indexOf('API Key');
      case 'devices':
        return _tabs.indexOf('Devices');
      case 'commands':
        return _tabs.indexOf('Commands');
      case 'organisation':
        return _tabs.indexOf('Organisation');
      case 'canConfig':
        return _tabs.indexOf('CAN Config');
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveLayout(
      mobile: _buildMobileLayout(isDark),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(isDark),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Scaffold(
      backgroundColor: tTransparent,

      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: tTransparent,
        elevation: 0,

        automaticallyImplyLeading: false,

        title: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder:
                  (context) => IconButton(
                    icon: Icon(Icons.menu, color: isDark ? tWhite : tBlack),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
            ),

            // Text(
            //   _tabs.isNotEmpty ? _tabs[selectedIndex] : "Settings",
            //   style: GoogleFonts.urbanist(
            //     fontSize: 20,
            //     fontWeight: FontWeight.w600,
            //     color: isDark ? tWhite : tBlack,
            //   ),
            // ),
          ],
        ),
      ),
      drawer: _buildDrawer(isDark),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _buildTabContent(selectedIndex, isDark, isTablet: true),
      ),
    );
  }

  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 LEFT SIDEBAR MENU
        Container(
          width: 165,
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

        final tab = _tabs[index];

        switch (tab) {
          case 'My Profile':
            context.go('/home/settings/profile');
            break;
          case 'Users':
            context.go('/home/settings/users');
            break;
          case 'Groups':
            context.go('/home/settings/groups');
            break;
          case 'API Key':
            context.go('/home/settings/apikey');
            break;
          case 'Devices':
            context.go('/home/settings/devices');
            break;
          case 'Commands':
            context.go('/home/settings/commands');
            break;
          case 'Organisation':
            context.go('/home/settings/organisation');
            break;
          case 'CAN Config':
            context.go('/home/settings/canConfig');
            break;
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? tGreen8.withOpacity(0.15) : tTransparent,
          border: Border(
            right: BorderSide(
              width: 6,
              color: isSelected ? tGreen8 : tTransparent,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? tGreen8 : (isDark ? tWhite : tBlack),
          ),
        ),
      ),
    );
  }

  // Returns widget for selected tab
  Widget _buildTabContent(
    int index,
    bool isDark, {
    bool isTablet = false,
    bool isMobile = false,
  }) {
    if (_tabs.isEmpty) return const SizedBox();
    final screenSize = MediaQuery.of(context).size;
    final isMobileDevice = screenSize.width < 600;
    final isTabletDevice = screenSize.width >= 600 && screenSize.width < 1200;
    final tab = _tabs[index];

    switch (tab) {
      case 'My Profile':
        return SingleChildScrollView(
          child: Center(
            child: _buildMyProfile(
              isDark,
              isTablet: isTabletDevice,
              isMobile: isMobileDevice,
            ),
          ),
        );
      case 'Users':
        return UserCRUDContent(
          isTablet: isTabletDevice,
          isMobile: isMobileDevice,
        );
      case 'Groups':
        return GroupCRUDContent();
      case 'API Key':
        return ApiKeyCRUDContent();
      case 'Devices':
        return DevicesCRUDScreen();
      case 'Commands':
        return CommandsAllCRUDContent();
      case 'Organisation':
        return OrgCRUDScreen();
      case 'CAN Config':
        return canConfigCRUDScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      width: 260,
      backgroundColor: isDark ? tBlack : tWhite,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),

            Text(
              "Settings",
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? tWhite : tBlack,
              ),
            ),

            SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  return _buildSidebarItem(
                    label: _tabs[index],
                    index: index,
                    isDark: isDark,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyProfile(
    bool isDark, {
    bool isTablet = false,
    bool isMobile = false,
  }) {
    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
        isMobile
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: tTransparent,
                      border: Border.all(width: 0.8, color: tGrey),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      width: 125,
                      height: 140,
                      decoration: BoxDecoration(color: tGrey),
                      child: Center(
                        child: SvgPicture.asset(
                          '/icons/avataricon.svg',
                          width: 120,
                          height: 120,
                          color: tWhite,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildDetailRow(
                        "Name",
                        _fullname ?? 'Guest User',
                        isDark,
                        isMobile,
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow("Mail ID", "-- --", isDark, isMobile),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        "Phone Number",
                        _phoneNumber ?? "-",
                        isDark,
                        isMobile,
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        "Role",
                        _role ?? 'Guest',
                        isDark,
                        isMobile,
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        "Organization",
                        _orgName ?? '--',
                        isDark,
                        isMobile,
                      ),
                    ],
                  ),
                ],
              ),
            )
            : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: tTransparent,
                    border: Border.all(width: 0.8, color: tGrey),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    width: 150,
                    height: 159,
                    decoration: BoxDecoration(color: tGrey),
                    child: Center(
                      child: SvgPicture.asset(
                        '/icons/avataricon.svg',
                        width: 150,
                        height: 150,
                        color: tWhite,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  height: 159,
                  child: VerticalDivider(
                    color: isDark ? tWhite : tBlack,
                    thickness: 1,
                  ),
                ),

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      "Name",
                      _fullname ?? 'Guest User',
                      isDark,
                      isMobile,
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow("Mail ID", "-- --", isDark, isMobile),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      "Phone Number",
                      _phoneNumber ?? "-",
                      isDark,
                      isMobile,
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow("Role", _role ?? 'Guest', isDark, isMobile),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      "Organization",
                      _orgName ?? '--',
                      isDark,
                      isMobile,
                    ),
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
        // _buildEditableField("Username", _username ?? 'guest.user', isDark),

        // SizedBox(height: 12),

        // // 🔹 Password Field
        // _buildEditableField("Password", "********", isDark),
        _buildEditableField(
          label: "Username",
          value: _username ?? 'guest.user',
          isDark: isDark,
          isMobile: isMobile,
          onEdit: () async {
            final controller = TextEditingController(text: _username);

            final newUsername = await showCustomInputDialog(
              context: context,
              isDark: isDark,
              title: "Edit Username",
              controller: controller,
            );

            if (newUsername != null && newUsername.isNotEmpty) {
              try {
                await _userApiService.updateUser(_username!, {
                  "userName": newUsername,
                });

                setState(() {
                  _username = newUsername;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Username updated successfully"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          },
        ),

        const SizedBox(height: 12),

        _buildEditableField(
          label: "Password",
          value: "********",
          isDark: isDark,
          isMobile: isMobile,

          onEdit: () async {
            final controller = TextEditingController();

            final newPassword = await showCustomInputDialog(
              context: context,
              isDark: isDark,
              title: "Reset Password",
              controller: controller,
              obscureText: true,
            );

            if (newPassword != null && newPassword.isNotEmpty) {
              try {
                await _userApiService.resetPassword(_username!, newPassword);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Password updated successfully"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          },
        ),

        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark,
    bool isMobile,
  ) {
    return Row(
      mainAxisAlignment:
          isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 85 : 120,
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: isMobile ? 11 : 13,
              color: isDark ? tWhite : tBlack,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(
          width: isMobile ? 90 : 200,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: GoogleFonts.urbanist(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildEditableField(String label, String value, bool isDark) {
  //   return Row(
  //     children: [
  //       SizedBox(
  //         width: 120,
  //         child: Text(
  //           label,
  //           style: GoogleFonts.urbanist(
  //             fontSize: 13,
  //             fontWeight: FontWeight.w500,
  //             color: isDark ? tWhite : tBlack,
  //           ),
  //         ),
  //       ),

  //       Container(
  //         width: 250,
  //         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(5),
  //           border: Border.all(
  //             color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.6),
  //           ),
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               value,
  //               style: GoogleFonts.urbanist(
  //                 fontSize: 13,
  //                 color: isDark ? tWhite : tBlack,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //             GestureDetector(
  //               onTap: () {
  //                 // TODO: open edit dialog
  //               },
  //               child: SvgPicture.asset(
  //                 "icons/edit.svg",
  //                 width: 18,
  //                 height: 18,
  //                 color: isDark ? tWhite : tBlack,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildEditableField({
    required String label,
    required String value,
    required bool isDark,
    required VoidCallback onEdit,
    required bool isMobile,
  }) {
    return Row(
      children: [
        SizedBox(
          width: isMobile ? 100 : 120,
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ),

        SizedBox(
          width: isMobile ? 180 : 250,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color:
                    isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.6),
              ),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      color: isDark ? tWhite : tBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: onEdit,
                  child: SvgPicture.asset(
                    "icons/edit.svg",
                    width: isMobile ? 14 : 18,
                    height: isMobile ? 14 : 18,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> showCustomInputDialog({
    required BuildContext context,
    required bool isDark,
    required String title,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return showDialog<String>(
      context: context,

      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,

            child: Container(
              width: 420,

              decoration: BoxDecoration(
                color: isDark ? tBlack : tWhite,

                borderRadius: BorderRadius.circular(14),

                border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
              ),

              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,

                        color: isDark ? tWhite : tBlack,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: controller,

                      obscureText: obscureText,

                      cursorColor: isDark ? tWhite : tBlack,

                      style: TextStyle(color: isDark ? tWhite : tBlack),

                      decoration: InputDecoration(
                        filled: true,

                        fillColor:
                            isDark
                                ? tWhite.withOpacity(0.03)
                                : tBlack.withOpacity(0.03),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),

                          borderSide: BorderSide(
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.2)
                                    : tBlack.withOpacity(0.2),
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),

                          borderSide: BorderSide(
                            color: isDark ? tWhite : tBlack,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,

                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),

                          child: Text(
                            "Cancel",

                            style: GoogleFonts.urbanist(
                              color: isDark ? tWhite : tBlack,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tGreen8,
                          ),

                          onPressed:
                              () => Navigator.pop(context, controller.text),

                          child: Text(
                            "Save",
                            style: GoogleFonts.urbanist(color: tWhite),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
