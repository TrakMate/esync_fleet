import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../../utils/theme/appThemeProvider.dart';
import '../components/customBackground.dart';

class HomeScreen extends StatefulWidget {
  final Widget child; //ShellRoute child

  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _selectedMenu = 'Dashboard';
  String? _fullname;
  String? _role;

  final _controller = ScrollController();
  late final AnimationController _animController;

  final List<Map<String, String>> menus = [
    {
      'icon': 'icons/dashboard.svg',
      'label': 'Dashboard',
      'route': '/home/dashboard',
    },
    {'icon': 'icons/device.svg', 'label': 'Devices', 'route': '/home/devices'},
    {'icon': 'icons/distance.svg', 'label': 'Trips', 'route': '/home/trips'},
    // {
    //   'icon': 'icons/tracking.svg',
    //   'label': 'Tracking',
    //   'route': '/home/tracking',
    // },
    {'icon': 'icons/alert.svg', 'label': 'Alerts', 'route': '/home/alerts'},
    {'icon': 'icons/reports.svg', 'label': 'reports', 'route': '/home/reports'},
    {
      'icon': 'icons/settings.svg',
      'label': 'Settings',
      'route': '/home/settings',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncMenuWithRoute();
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
  // void _syncMenuWithRoute() {
  //   final currentPath = GoRouterState.of(context).uri.toString();

  //   for (final menu in menus) {
  //     if (currentPath.startsWith(menu['route']!)) {
  //       setState(() {
  //         _selectedMenu = menu['label']!;
  //       });
  //       break;
  //     }
  //   }
  // }

  void _syncMenuWithRoute() {
    final uri = GoRouterState.of(context).uri;
    final currentPath = uri.path;

    for (final menu in menus) {
      if (currentPath.startsWith(menu['route']!)) {
        setState(() {
          _selectedMenu = menu['label']!;
        });
        return;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMenuWithRoute();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullname = prefs.getString('fullname') ?? 'User';
      _role = prefs.getString('role') ?? 'Guest';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      drawer: _buildSidebarMenu(),
      // body: ResponsiveLayout(
      //   mobile: _buildMobileLayout(),
      //   tablet: _buildTabletLayout(),
      //   desktop: _buildDesktopLayout(),
      // ),
      body: Stack(
        children: [
          // ----------------------- TECH GRID -----------------------
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: TechGridPainter(
                    tick: _animController.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),

          // ----------------------- SCANNING LINES -----------------------
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScanningLinesPainter(offset: _animController.value),
                );
              },
            ),
          ),

          // ----------------------- RADAR SWEEP -----------------------
          Positioned(
            bottom: 40,
            left: 30,
            child: SizedBox(
              width: 420,
              height: 420,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RadarSweepPainter(
                      rotation: _animController.value * 2 * pi,
                      color: Colors.greenAccent.withOpacity(0.18),
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),
          ),

          // ----------------------- FLOATING SHAPES (parallax) -----------------------
          Positioned(
            top: 80,
            right: 60,
            child: FloatingShape(
              anim: _animController,
              size: 120,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orangeAccent.withOpacity(0.18),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SizedBox(width: 120, height: 120),
              ),
            ),
          ),

          Positioned(
            top: 220,
            left: 140,
            child: FloatingShape(
              anim: _animController,
              speed: 1.2,
              amplitude: 14,
              size: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blueAccent.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 40,
            child: FloatingShape(
              anim: _animController,
              speed: 0.6,
              amplitude: 18,
              size: 90,
              child: Transform.rotate(
                angle: -0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyanAccent.withOpacity(0.07),
                        Colors.transparent,
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.02),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: SizedBox(width: 90, height: 90),
                ),
              ),
            ),
          ),

          // ----------------------- SPOTLIGHT BEHIND CONTENT -----------------------
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  // subtle pulsing of spotlight
                  final pulse = 0.9 + 0.1 * sin(_animController.value * 2 * pi);
                  return Container(
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.fromLTRB(40, 120, 0, 0),
                    child: Transform.scale(
                      scale: pulse,
                      origin: const Offset(0, 0),
                      child: Container(
                        width: 1100,
                        height: 540,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.4, -0.6),
                            radius: 0.9,
                            colors: [
                              (isDark ? Colors.tealAccent : Colors.orangeAccent)
                                  .withOpacity(0.06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // const FuturisticHudBackground(),
          ResponsiveLayout(
            mobile: _buildMobileLayout(),
            tablet: _buildTabletLayout(),
            desktop: _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  // ---------------- Desktop Layout ----------------
  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 5),
          _buildMenuBar(),
          const SizedBox(height: 10),
          Expanded(child: widget.child), //replaced RouterOutlet
          SizedBox(height: 10),
          _copyright(),
        ],
      ),
    );
  }

  // ---------------- Mobile Layout ----------------
  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: _buildHeader(),
          ),
          const SizedBox(height: 10),
          Expanded(child: widget.child),
          SizedBox(height: 10),
          _copyright(),
        ],
      ),
    );
  }

  // ---------------- Tablet Layout ----------------
  Widget _buildTabletLayout() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: _buildHeader(),
          ),
          const SizedBox(height: 5),
          _buildMenuBar(),
          const SizedBox(height: 10),
          Expanded(child: widget.child),
          SizedBox(height: 10),
          _copyright(),
        ],
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _brandLogo(),
        Row(
          children: [
            _buildIconButton(
              iconPath: isDark ? 'icons/moon.svg' : 'icons/sun.svg',
              onTap: () => themeProvider.toggleTheme(),
            ),
            _buildIconButton(iconPath: 'icons/notify.svg', onTap: () {}),
            // _buildIconButton(iconPath: 'icons/language.svg', onTap: () {}),
            const SizedBox(width: 5),
            GestureDetector(
              onTapDown: (details) async {
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
                await showMenu(
                  context: context,
                  position: RelativeRect.fromRect(
                    details.globalPosition & const Size(100, 100),
                    Offset.zero & overlay.size,
                  ),

                  // position: RelativeRect.fromLTRB(left, top, right, bottom),
                  color: isDark ? tBlack.withOpacity(0.95) : tWhite,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.2)
                              : tBlack.withOpacity(0.1),
                    ),
                  ),
                  items: [
                    PopupMenuItem(
                      enabled: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [
                              Text(
                                'UserName',
                                style: GoogleFonts.urbanist(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color:
                                      isDark
                                          ? tWhite.withOpacity(0.6)
                                          : tBlack.withOpacity(0.6),
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                _fullname ?? '',
                                style: GoogleFonts.urbanist(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Role',
                                style: GoogleFonts.urbanist(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color:
                                      isDark
                                          ? tWhite.withOpacity(0.6)
                                          : tBlack.withOpacity(0.6),
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                _role ?? '',
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,

                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 15),
                          Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.clear();

                                if (mounted) {
                                  context.go('/login');
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                backgroundColor:
                                    isDark
                                        ? tWhite.withOpacity(0.1)
                                        : tRed.withOpacity(0.05),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.logout, size: 18),
                              label: Text(
                                "Logout",
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 1,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                    child: SvgPicture.asset(
                      'icons/avatar.svg',
                      fit: BoxFit.scaleDown,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                  SizedBox(width: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _fullname ?? '',
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                      Text(
                        _role ?? '',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark
                                  ? tWhite.withOpacity(0.6)
                                  : tBlack.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- Brand Logo ----------------
  Widget _brandLogo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Builder(
          builder: (ctx) {
            return GestureDetector(
              onTap: () {
                final scaffold = Scaffold.maybeOf(ctx);

                if (scaffold != null && scaffold.hasDrawer) {
                  scaffold.openDrawer();
                }
              },
              child: SvgPicture.asset(
                'icons/esync_logo.svg',
                width: 20,
                height: 20,
                color: tGreen8,
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Text(
          'Esync OEM',
          style: GoogleFonts.urbanist(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: tGreen8,
          ),
        ),
      ],
    );
  }

  // ---------------- Menu Bar (Desktop + Tablet) ----------------
  Widget _buildMenuBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tTransparent,
        border: Border(
          top: BorderSide(color: tBlue, width: 0.5),
          bottom: BorderSide(color: tBlue, width: 0.5),
        ),
      ),

      /// FIX → Wrap inside LayoutBuilder OR always show thumb
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        notificationPredicate: (_) => true, // Needed for horizontal scroll
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          primary: false, // FIX → prevent PrimaryScrollController conflict
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children:
                menus.map((menu) {
                  final isSelected = _selectedMenu == menu['label'];

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedMenu = menu['label']!);
                      context.go(menu['route']!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                menu['icon']!,
                                width: 20,
                                height: 20,
                                color:
                                    isSelected
                                        ? tGreen8
                                        : (isDark ? tWhite : tBlack),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                menu['label']!,
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w400,
                                  color:
                                      isSelected
                                          ? tGreen8
                                          : (isDark ? tWhite : tBlack),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            height: 2,
                            width: isSelected ? 35 : 0,
                            decoration: BoxDecoration(
                              color: tGreen8,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  // ---------------- Sidebar Drawer (Mobile) ----------------
  Widget _buildSidebarMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 250, // fixed width for sidebar
      color: isDark ? tBlack : tWhite,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 100,
              color: tTransparent,
              alignment: Alignment.center,
              child: _brandLogo(),
            ),
            // Menu items
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: menus.length,
                itemBuilder: (context, index) {
                  final menu = menus[index];
                  final isSelected = _selectedMenu == menu['label'];
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedMenu = menu['label']!);
                      context.go(menu['route']!);
                    },
                    onHover: (hovering) {
                      // Optional: you can add hover effect here
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? (isDark
                                    ? tBlue1.withOpacity(0.1)
                                    : tBlue1.withOpacity(0.1))
                                : Colors.transparent,
                        border:
                            isSelected
                                ? Border(
                                  right: BorderSide(width: 4, color: tBlue1),
                                )
                                : null,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            menu['icon']!,
                            width: 22,
                            height: 22,
                            color:
                                isSelected
                                    ? tBlue1
                                    : (isDark ? tWhite : tBlack),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            menu['label']!,
                            style: GoogleFonts.urbanist(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                              color:
                                  isSelected
                                      ? tBlue1
                                      : (isDark ? tWhite : tBlack),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Optional: Bottom section
            Center(
              child: Text(
                "Version 1.0.0",
                style: GoogleFonts.urbanist(
                  color: isDark ? tWhite : tBlack,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _copyright() {
    final int currentYear = DateTime.now().year;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Text(
        '© $currentYear ESYNC, Hero EDU Systems Pvt. Ltd. All rights reserved.',
        textAlign: TextAlign.center,
        style: GoogleFonts.urbanist(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? tWhite : tBlack,
        ),
      ),
    );
  }

  // ---------------- Reusable Icon Button ----------------
  Widget _buildIconButton({
    required String iconPath,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: onTap,
      icon: SvgPicture.asset(
        iconPath,
        height: 22,
        width: 22,
        color: isDark ? tWhite : tBlack,
      ),
    );
  }
}
