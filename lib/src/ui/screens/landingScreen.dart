import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../utils/appColors.dart';
import '../components/customBackground.dart';

// ----------------------- LANDING SCREEN -----------------------
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();

  // sections keys for scrolling
  final homeKey = GlobalKey();
  final servicesKey = GlobalKey();
  final subscriptionKey = GlobalKey();
  final aboutKey = GlobalKey();
  final contactKey = GlobalKey();

  // subscription card interactions
  int hoveredIndex = -1;
  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    if (key.currentContext == null) return;
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _navButton(String text, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? tWhite.withOpacity(0.85) : tBlack.withOpacity(0.85),
            ),
          ),
        ),
      ),
    );
  }

  // subscription cards data
  final List<Map<String, dynamic>> subscriptionCards = [
    {
      'title': "Basic",
      'description': "Real-time tracking, basic alerts and daily reports.",
      'icon': "icons/sale.svg",
      'iconColor': tBlue,
      'bgColor': tBlue.withOpacity(0.12),
    },
    {
      'title': "Business",
      'description': "Fuel monitoring, route optimization, analytics.",
      'icon': "icons/commands.svg",
      'iconColor': Colors.purpleAccent,
      'bgColor': Colors.purple.withOpacity(0.12),
    },
    {
      'title': "Enterprise",
      'description': "Full AI suite, driver behavior, fleet automation.",
      'icon': "icons/enterprise.svg",
      'iconColor': Colors.amberAccent,
      'bgColor': Colors.amber.withOpacity(0.12),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final rotation = _controller.value * 2 * pi;
    final scanOffset = _controller.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? tBlack : tWhite,
      body: Stack(
        children: [
          // background grid
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return CustomPaint(
                size: Size.infinite,
                painter: TechGridPainter(
                  tick: _controller.value,
                  isDark: isDark,
                ),
              );
            },
          ),

          // scanning
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return CustomPaint(
                size: Size.infinite,
                painter: ScanningLinesPainter(offset: scanOffset),
              );
            },
          ),

          // content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 40),

                // nav
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _brandLogo(),
                      const Spacer(),
                      _navButton('Home', () => _scrollTo(homeKey), isDark),
                      _navButton(
                        'Services',
                        () => _scrollTo(servicesKey),
                        isDark,
                      ),
                      _navButton(
                        'Subscription',
                        () => _scrollTo(subscriptionKey),
                        isDark,
                      ),
                      _navButton('About Us', () => _scrollTo(aboutKey), isDark),
                      _navButton(
                        'Contact Us',
                        () => _scrollTo(contactKey),
                        isDark,
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 600), () {
                            if (mounted) {
                              // Navigate or perform next action (e.g., check login)
                              context.go('/login');
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: tBlue),
                          ),
                          child: Text(
                            'Login',
                            style: GoogleFonts.urbanist(
                              color: tBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // hero
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(
                    children: [
                      Expanded(child: _heroText(isDark)),
                      Expanded(
                        child: SizedBox(
                          height: 400,
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (_, __) {
                              final rotation = _controller.value * 2 * pi;
                              return CustomPaint(
                                painter: RadarSweepPainter(
                                  rotation: rotation,
                                  color: tBlue,
                                  isDark: isDark,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // HOME SECTION
                _buildHomeSection(isDark),

                const SizedBox(height: 60),

                // SERVICES
                _buildServicesSection(isDark),

                const SizedBox(height: 60),

                // SUBSCRIPTION
                _buildSubscriptionSection(isDark),

                const SizedBox(height: 60),

                // ABOUT
                _buildAboutSection(isDark),

                const SizedBox(height: 60),

                // CONTACT
                _buildContactSection(isDark),

                const SizedBox(height: 120),
              ],
            ),
          ),

          // floating shapes
          Positioned(
            top: 140,
            right: 160,
            child: FloatingShape(
              anim: _controller,
              size: 70,
              amplitude: 18,
              speed: 1.2,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  border: Border.all(color: tBlue.withOpacity(0.4)),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 120,
            left: 120,
            child: FloatingShape(
              anim: _controller,
              size: 60,
              amplitude: 20,
              speed: 0.8,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        isDark
                            ? tWhite.withOpacity(0.3)
                            : tBlack.withOpacity(0.3),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandLogo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isDark
            ? SvgPicture.asset(
              'icons/shortlogo_dark.svg',
              width: 50,
              height: 50,
            )
            : SvgPicture.asset(
              'icons/shortlogo_light.svg',
              width: 50,
              height: 50,
            ),
        const SizedBox(width: 2),
        Text(
          'TrakFleet',
          style: GoogleFonts.urbanist(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: isDark ? tBlue : tBlue2,
          ),
        ),
      ],
    );
  }

  Widget _heroText(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Fleet Management\nfor Smart Businesses',
          style: GoogleFonts.urbanist(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Monitor vehicles in real-time, optimize routes, analyze driver behavior and enhance safety using AI-powered insights.',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            color: isDark ? tWhite.withOpacity(0.7) : tBlack.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: tBlue,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'Get Started',
                style: GoogleFonts.urbanist(
                  color: tWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: tBlue),
              ),
              child: Text(
                'Contact Sales',
                style: GoogleFonts.urbanist(
                  color: tBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- SECTIONS ----------------
  Widget _buildHomeSection(bool isDark) {
    return Container(
      key: homeKey,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Column(
        children: [
          Text(
            'Why TrakFleet?',
            style: GoogleFonts.urbanist(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: isDark ? tWhite : tBlack,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'A modern fleet management ecosystem designed to streamline business operations, reduce fuel costs, optimize routes and improve driver performance.',
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: 18,
              height: 1.4,
              color: isDark ? tWhite.withOpacity(0.7) : tBlack.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(bool isDark) {
    return Container(
      key: servicesKey,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Our Services',
            style: GoogleFonts.urbanist(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: isDark ? tWhite : tBlack,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 26,
            runSpacing: 26,
            children: [
              _serviceTile('Real-Time Tracking', 'icons/geofence.svg', isDark),
              _serviceTile('Route Optimization', 'icons/distance.svg', isDark),
              _serviceTile('Driver Behavior', 'icons/driver.svg', isDark),
              _serviceTile('Monitoring', 'icons/monitoring.svg', isDark),
              _serviceTile(
                'Maintenance Alerts',
                'icons/maintenance.svg',
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceTile(String title, String icon, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(22),
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : tWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? tWhite.withOpacity(0.06) : tBlack.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          // svg may fail if asset missing - using fallback circle
          SizedBox(
            height: 48,
            child: SvgPicture.asset(
              icon,
              height: 38,
              width: 38,
              color: isDark ? tWhite : tBlack,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(bool isDark) {
    return Container(
      key: subscriptionKey,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
      child: Column(
        children: [
          Text(
            'Subscription Plans',
            style: GoogleFonts.urbanist(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: isDark ? tWhite : tBlack,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 30,
            runSpacing: 30,
            children: List.generate(
              subscriptionCards.length,
              (index) => SizedBox(
                width: 320,
                child: _buildFleetCard(subscriptionCards[index], index, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetCard(Map<String, dynamic> card, int index, bool isDark) {
    final isHovered = hoveredIndex == index;
    final isSelected = selectedIndex == index;
    final glowColor = (card['iconColor'] as Color).withOpacity(
      isSelected ? 0.34 : 0.18,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: GestureDetector(
        onTap: () {
          setState(() => selectedIndex = index);
          // Delay before navigation (keeps UX from jumping instantly) - replace with your route
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return;
            // Navigator.of(context).pushNamed('/home/dashboard');
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
            boxShadow: [
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
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
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
                            ? (card['iconColor'] as Color).withOpacity(0.55)
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
                child: SizedBox(
                  height: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              color: (card['iconColor'] as Color).withOpacity(
                                0.08,
                              ),
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
                                          (card['iconColor'] as Color)
                                              .withOpacity(0.12),
                                          (card['iconColor'] as Color)
                                              .withOpacity(0.06),
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
      ),
    );
  }

  Widget _buildAboutSection(bool isDark) {
    return Container(
      key: aboutKey,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About TrakFleet',
                  style: GoogleFonts.urbanist(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'We are a technology-driven fleet intelligence company focused on automation, efficiency and data-driven operations.',
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    height: 1.4,
                    color:
                        isDark
                            ? tWhite.withOpacity(0.75)
                            : tBlack.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.white.withOpacity(0.02) : tWhite,
              ),
              child: Center(
                child: Text(
                  'Team Image',
                  style: GoogleFonts.urbanist(
                    color:
                        isDark
                            ? tWhite.withOpacity(0.6)
                            : tBlack.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isDark) {
    return Container(
      key: contactKey,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Column(
        children: [
          Text(
            'Contact Sales',
            style: GoogleFonts.urbanist(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: isDark ? tWhite : tBlack,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Need help choosing a plan? Our Sales & Marketing team will guide you.',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              color: isDark ? tWhite.withOpacity(0.7) : tBlack.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: tBlue),
                ),
                child: Text(
                  'Talk to Sales',
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: tBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
