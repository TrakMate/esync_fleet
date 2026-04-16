import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../provider/fleetModeProvider.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../../utils/theme/appThemeProvider.dart';
import '../components/customBackground.dart';

class FleetModeSelectionScreen extends StatefulWidget {
  const FleetModeSelectionScreen({super.key});

  @override
  State<FleetModeSelectionScreen> createState() =>
      _FleetModeSelectionScreenState();
}

class _FleetModeSelectionScreenState extends State<FleetModeSelectionScreen>
    with SingleTickerProviderStateMixin {
  int hoveredIndex = -1;
  int selectedIndex = -1;

  late final AnimationController _animController;

  final List<Map<String, dynamic>> fleetModes = [
    {
      'title': 'EV Fleet',
      'description': 'Track EV performance, charging, range, and energy usage.',
      'icon': 'icons/battery.svg',
      'bgColor': const Color(0xFFE8FFF1),
      'iconColor': const Color(0xFF00C853),
    },
    {
      'title': 'ICE Fleet',
      'description':
          'Manage fuel-based fleet operations with advanced monitoring.',
      'icon': 'icons/fuel.svg',
      'bgColor': const Color(0xFFE8F0FF),
      'iconColor': const Color(0xFF3D5AFE),
    },

    {
      'title': 'Service & Dealer Management',
      'description':
          'Optimize dealer and service operations with centralized management and performance tracking.',
      'icon': 'icons/service.svg',
      'bgColor': const Color(0xFFFBF5D6),
      'iconColor': const Color(0xFFFFA000),
    },
    {
      'title': 'Combine Fleet',
      'description': 'Hybrid solution for both ICE and EV vehicles.',
      'icon': 'icons/hybrid.svg',
      'bgColor': const Color(0xFFFFF8E1),
      'iconColor': const Color(0xFFFFA000),
    },
    {
      'title': 'ADAS Fleet',
      'description': 'Advanced fleet safety with ADAS monitoring and insights.',
      'icon': 'icons/device.svg',
      'bgColor': const Color(0xFFFFEBEE),
      'iconColor': const Color(0xFFD50000),
    },
  ];

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: Container(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Stack(
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

        Positioned(
          top: 15,
          right: 10,
          child: Row(
            children: [
              // Light/Dark Toggle
              _buildTextButton(
                iconPath: isDark ? 'icons/moon.svg' : 'icons/sun.svg',
                onTap: () => themeProvider.toggleTheme(),
              ),

              const SizedBox(width: 5),

              // Logout Button
              TextButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  if (mounted) {
                    context.go('/login');
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor:
                      isDark ? tWhite.withOpacity(0.1) : tRed.withOpacity(0.05),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(width: 1, color: tRed),
                  ),
                  fixedSize: Size(100, 35),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    int gridCount =
        width > 1500
            ? 5
            : width > 1100
            ? 3
            : 2;

    return Scaffold(
      backgroundColor: isDark ? tBlack : tWhite,
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

          Positioned(
            top: 65,
            right: 40,
            child: Row(
              children: [
                // Light/Dark Toggle
                _buildTextButton(
                  iconPath: isDark ? 'icons/moon.svg' : 'icons/sun.svg',
                  onTap: () => themeProvider.toggleTheme(),
                ),

                const SizedBox(width: 10),

                // Logout Button
                TextButton.icon(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
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
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(width: 1, color: tRed),
                    ),
                    fixedSize: Size(130, 35),
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
              ],
            ),
          ),

          // ----------------------- CONTENT (TOP-LEFT START) -----------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // <-- NOT CENTER
              children: [
                const SizedBox(height: 10),

                Text(
                  'Welcome to Hero ESYNC OEM Portal',
                  style: GoogleFonts.urbanist(
                    fontSize: 35,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                Builder(
                  builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Text(
                      'Select your preferred mode to get started with monitoring and management.',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        color:
                            isDark
                                ? tWhite.withOpacity(0.6)
                                : tBlack.withOpacity(0.6),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int cross =
                          width > 1500
                              ? 5
                              : width > 1100
                              ? 3
                              : 2;
                      final visibleModes =
                          fleetModes
                              .where(
                                (m) =>
                                    m['title'] == 'EV Fleet' ||
                                    m['title'] == 'Service & Dealer Management',
                              )
                              .toList();
                      // ------ FIX OUT OF RANGE ------
                      if (hoveredIndex >= visibleModes.length)
                        hoveredIndex = -1;
                      if (selectedIndex >= visibleModes.length)
                        selectedIndex = -1;
                      // ------------------------------
                      return GridView.builder(
                        padding: const EdgeInsets.only(right: 80, bottom: 60),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, //4 cross
                          crossAxisSpacing: 35,
                          mainAxisSpacing: 35,
                          childAspectRatio: 1, // 1.7
                        ),

                        // itemCount: fleetModes.length,
                        itemCount: visibleModes.length,
                        itemBuilder: (context, index) {
                          // final card = fleetModes[index];
                          final card = visibleModes[index];
                          return _buildFleetCard(
                            card,
                            index,
                            Theme.of(context).brightness == Brightness.dark,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ======================================================
  ///                      CARD UI (UPGRADED HOVER)
  /// ======================================================
  Widget _buildFleetCard(Map<String, dynamic> card, int index, bool isDark) {
    final isHovered = hoveredIndex == index;
    final isSelected = selectedIndex == index;

    // CTA glow color
    final glowColor = (isSelected ? card['iconColor'] : card['iconColor'])
        .withOpacity(isSelected ? 0.34 : 0.18);

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: GestureDetector(
        // onTap: () => setState(() => selectedIndex = index),
        onTap: () async {
          setState(() => selectedIndex = index);

          final fleetProvider = context.read<FleetModeProvider>();
          await fleetProvider.setMode(card['title']);

          // 5-second navigation delay after selecting a card
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!mounted) return; // <- prevents errors if the user leaves early
            context.go('/home/dashboard');
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutQuint,
          transform:
              Matrix4.identity()
                ..translate(0.0, isHovered ? -10.0 : 0.0)
                ..scale(isHovered ? 1.04 : 1.0),
          decoration: BoxDecoration(
            // borderRadius: BorderRadius.circular(18),
            boxShadow: [
              // layered glow when hovered/selected
              if (isHovered || isSelected)
                BoxShadow(
                  color: glowColor,
                  blurRadius: isSelected ? 36 : 22,
                  spreadRadius: isSelected ? 1.4 : 0.6,
                  offset: const Offset(0, 10),
                ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            // borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  // borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    width:
                        isSelected
                            ? 2.6
                            : isHovered
                            ? 1.6
                            : 0,
                    color:
                        isSelected
                            ? card['iconColor']
                            : isHovered
                            ? card['iconColor'].withOpacity(0.55)
                            : Colors.transparent,
                  ),
                  gradient:
                      isDark
                          ? LinearGradient(
                            colors: [
                              Colors.grey.shade900.withOpacity(0.52),
                              Colors.grey.shade800.withOpacity(0.30),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : LinearGradient(
                            colors: [
                              tWhite.withOpacity(0.95),
                              tWhite.withOpacity(0.78),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container with subtle inner glow
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 64,
                      height: 64,
                      transform:
                          Matrix4.identity()..scale(isHovered ? 1.12 : 1.0),
                      decoration: BoxDecoration(
                        color: card['bgColor'],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: card['iconColor'].withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          card['icon'],
                          width: 32,
                          height: 32,
                          color: card['iconColor'],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      card['title'],
                      style: GoogleFonts.urbanist(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      card['description'],
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        height: 1.4,
                        color:
                            isDark
                                ? tWhite.withOpacity(0.72)
                                : tBlack.withOpacity(0.68),
                      ),
                    ),

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: isHovered ? 14 : 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient:
                                isHovered
                                    ? LinearGradient(
                                      colors: [
                                        card['iconColor'].withOpacity(0.12),
                                        card['iconColor'].withOpacity(0.06),
                                      ],
                                    )
                                    : null,
                          ),
                          child: Row(
                            children: [
                              Text(
                                isSelected ? 'Selected' : 'Choose',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: card['iconColor'],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SvgPicture.asset(
                                'icons/arrow.svg',
                                width: 18,
                                height: 18,
                                color: card['iconColor'],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton({
    required String iconPath,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor:
            isDark ? tWhite.withOpacity(0.1) : tBlack.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(width: 1, color: isDark ? tWhite : tBlack),
        fixedSize: Size(90, 35),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            height: 20,
            width: 20,
            color: isDark ? tWhite : tBlack,
          ),
          SizedBox(width: 5),
          Text(
            isDark ? 'Dark' : 'Light',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ],
      ),
    );
  }
}
