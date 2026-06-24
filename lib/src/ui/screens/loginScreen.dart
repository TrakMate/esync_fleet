import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';
import '../../bloc/login/login_bloc.dart';
import '../../bloc/login/login_event.dart';
import '../../bloc/login/login_state.dart';
import '../../utils/appColors.dart';
import '../../utils/appLogger.dart';
import '../../utils/appResponsive.dart';
import '../../utils/theme/appThemeProvider.dart';
import '../components/customBackground.dart';
import '../components/customLoginAnimationBackground.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isUsernameValid = false;
  bool _hasUsernameInput = false;

  final RegExp _usernameRegex = RegExp(r'^[a-z]+\.[a-z]+$');

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

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

    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void showErrorPopup({
    required BuildContext context,
    required String message,
    int? statusCode,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 420,
            decoration: BoxDecoration(
              color: isDark ? tBlack : tWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? Colors.white.withOpacity(0.7) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SvgPicture.asset(
                          'icons/delete-button.svg',
                          width: 22,
                          height: 22,
                          color: tRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Text(
                            "Login Failed",
                            style: GoogleFonts.urbanist(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? tWhite : tBlack,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    statusCode != null ? "$statusCode $message" : message,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark
                              ? tWhite.withOpacity(0.85)
                              : tBlack.withOpacity(0.85),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tGreen8,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          "OK",
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showSuccessPopup({
    required BuildContext context,
    required String message,
    required VoidCallback onNavigate,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 420,
            decoration: BoxDecoration(
              color: isDark ? tBlack : tWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? Colors.white.withOpacity(0.7) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tGreen3.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SvgPicture.asset(
                          'icons/checkmark.svg',
                          width: 22,
                          height: 22,
                          color: tGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Login Successful",
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(message, style: GoogleFonts.urbanist(fontSize: 14)),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close dialog
        onNavigate(); // navigate
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: ResponsiveLayout(
              mobile: _buildMobileLayout(),
              tablet: _buildDesktopTabletLayout(0.5),
              desktop: _buildDesktopTabletLayout(0.5),
            ),
          ),
        ),
      ),
    );
  }

  // Desktop/Tablet Layout with two halves
  Widget _buildDesktopTabletLayout(double widthFactor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1100;

    return Row(
      children: [
        Expanded(
          flex: (widthFactor * 200).toInt(),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(70, 40, 70, 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 36 : 48,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: isDark ? tWhite : tBlack,
                        ),
                        children: [
                          const TextSpan(text: "Drive smarter\nwith "),
                          TextSpan(
                            text: "your data",
                            style: TextStyle(
                              color: tGreen8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Text(
                        "Monitor, manage and optimize your vehicles in real-time with advanced IoT telematics technology. Track fleets, analyze driver behavior, improve operational efficiency and gain actionable insights through a unified intelligent platform.",
                        style: GoogleFonts.urbanist(
                          fontSize: isTablet ? 12 : 14,
                          height: 1.8,
                          fontWeight: FontWeight.w500,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Wrap(
                      spacing: isTablet ? 10 : 20,
                      runSpacing: isTablet ? 10 : 20,
                      children: [
                        _featureGlassCard(
                          svg: "icons/tracking.svg",
                          title: "Live Tracking",
                          description:
                              "Real-time GPS tracking with route history and geofencing.",
                          color: const Color(0xFF3B82F6), // Blue
                        ),

                        _featureGlassCard(
                          svg: "icons/car.svg",
                          title: "Fleet Analytics",
                          description:
                              "Vehicle utilization, trip reports and performance insights.",
                          color: const Color(0xFF10B981), // Green
                        ),

                        _featureGlassCard(
                          svg: "icons/battery.svg",
                          title: "ICE & EV Monitoring",
                          description:
                              "Fuel level, mileage, SOC, DTE, battery health and charging analytics.",
                          color: const Color(0xFFF59E0B), // Orange
                        ),

                        _featureGlassCard(
                          svg: "icons/alerts.svg",
                          title: "Smart Alerts",
                          description:
                              "Instant notifications for ignition, overspeed and faults.",
                          color: const Color(0xFFEF4444), // Red
                        ),

                        _featureGlassCard(
                          svg: "icons/analytics.svg",
                          title: "Remote Diagnostics",
                          description:
                              "Monitor device health and troubleshoot remotely.",
                          color: const Color(0xFF8B5CF6), // Purple
                        ),

                        _featureGlassCard(
                          svg: "icons/maintenance.svg",
                          title: "Maintenance",
                          description:
                              "Schedule preventive maintenance and reduce vehicle downtime.",
                          color: tGreen3,
                        ),
                        _featureGlassCard(
                          svg: "icons/report_file.svg",
                          title: "Reports",
                          description:
                              "Automated reports for trips, fuel, utilization and more.",
                          color: const Color(0xFF06B6D4), // Cyan
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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

              // ---------------- SCANNING LINES ----------------
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ScanningLinesPainter(
                        offset: _animController.value,
                      ),
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
                      final pulse =
                          0.9 + 0.1 * sin(_animController.value * 2 * pi);
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
                                  (isDark
                                          ? Colors.tealAccent
                                          : Colors.orangeAccent)
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
            ],
          ),
        ),

        Expanded(
          flex: isTablet ? 45 : ((1 - widthFactor) * 100).toInt(),
          child: Center(
            child: Container(
              padding: EdgeInsets.all(isTablet ? 24 : 40),
              constraints: BoxConstraints(maxWidth: isTablet ? 320 : 400),
              child: _buildLoginForm(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureGlassCard({
    required String svg,
    required String title,
    required String description,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1100;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: isTablet ? 220 : 280,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isTablet ? 40 : 50,
                height: isTablet ? 40 : 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: color.withOpacity(0.20),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    svg,
                    height: isTablet ? 20 : 25,
                    width: isTablet ? 20 : 25,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.urbanist(
                        color: isDark ? tWhite : tBlack,
                        fontSize: isTablet ? 13 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        color: isDark ? tWhite : tBlack,
                        fontSize: isTablet ? 10 : 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(double widthFactor) {
    return Row(
      children: [
        Expanded(
          flex: (widthFactor * 170).toInt(),
          child: Stack(
            children: [
              //Animated geometric shapes behind everything
              const AnimatedShapesBackground(),

              //Full gradient background overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade700.withOpacity(0.8),
                      Colors.blue.shade400.withOpacity(0.6),
                    ],
                  ),
                ),
              ),

              // Glass/frosted blur overlay
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: Colors.white.withOpacity(0.1)),
                ),
              ),

              //Content on top
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage your fleet efficiently',
                        style: GoogleFonts.urbanist(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: tWhite,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'TrakFleet provides professional telematics solutions to streamline your fleet operations.',
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          color: tWhite.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildPoint(
                        'Real-time GPS tracking for accurate fleet location monitoring.',
                      ),
                      _buildPoint(
                        'Detailed driver behavior reports to improve safety and efficiency.',
                      ),
                      _buildPoint(
                        'Automated maintenance alerts to reduce downtime and costs.',
                      ),
                      _buildPoint(
                        'Customizable analytics dashboards to monitor fleet performance at a glance.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right side with login form
        Expanded(
          flex: ((1 - widthFactor) * 100).toInt(),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 40,
                right: 40,
                top: 40,
                bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildLoginForm(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile layout
  // Widget _buildMobileLayout() {
  //   return SingleChildScrollView(
  //     child: Padding(
  //       padding: const EdgeInsets.all(20),
  //       child: _buildLoginForm(),
  //     ),
  //   );
  // }
  // Mobile layout - Fixed version

  Widget _buildMobileLayout() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(child: _buildLoginForm()),
            ),
          );
        },
      ),
    );
  }
  // Widget _buildMobileLayout() {
  //   return SafeArea(
  //     child: SingleChildScrollView(
  //       physics: const BouncingScrollPhysics(),
  //       keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  //       padding: EdgeInsets.only(
  //         bottom: MediaQuery.of(context).viewInsets.bottom,
  //       ),
  //       child: ConstrainedBox(
  //         constraints: BoxConstraints(
  //           minHeight: MediaQuery.of(context).size.height,
  //         ),
  //         child: Padding(
  //           padding: const EdgeInsets.all(20),
  //           child: _buildLoginForm(),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Login form
  Widget _buildLoginForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    // return BlocProvider(
    //   create: (context) => LoginBloc(),

    //   child: BlocConsumer<LoginBloc, LoginState>(
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) async {
        LoggerUtil.getInstance.print("runtimeType>>>>>>${state.runtimeType}");

        if (state is LoginSuccess) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', state.token);

          LoggerUtil.getInstance.print('Token saved: ${state.token}');
          Map<String, dynamic> decodedToken = JwtDecoder.decode(state.token);
          final role = (decodedToken['auth'] ?? '').toString().toLowerCase();
          // Convert timestamps (iat, exp) → IST DateTime
          DateTime iatUtc = DateTime.fromMillisecondsSinceEpoch(
            decodedToken['iat'] * 1000,
            isUtc: true,
          );
          DateTime expUtc = DateTime.fromMillisecondsSinceEpoch(
            decodedToken['exp'] * 1000,
            isUtc: true,
          );
          DateTime iatIST = iatUtc.add(const Duration(hours: 5, minutes: 30));
          DateTime expIST = expUtc.add(const Duration(hours: 5, minutes: 30));

          // Store all values
          await prefs.setString('username', decodedToken['sub'] ?? '');
          await prefs.setString('role', decodedToken['auth'] ?? '');
          await prefs.setString('fullname', decodedToken['fullname'] ?? '');
          await prefs.setString('Phone', decodedToken['phone'] ?? '');
          await prefs.setString('Organisation', decodedToken['orgName'] ?? '');
          await prefs.setString('issuedAt', iatIST.toIso8601String());
          await prefs.setString('expiresAt', expIST.toIso8601String());

          LoggerUtil.getInstance.print('Decoded Token: $decodedToken');
          LoggerUtil.getInstance.print('IssuedAt (IST): $iatIST');
          LoggerUtil.getInstance.print('ExpiresAt (IST): $expIST');
          // Navigate after login success
          // if (mounted) {
          //   // context.go(
          //   //   '/home/dashboard',
          //   // ); //Works only if GoRouter context is correct

          //   context.go('/fleetmodeselection');
          // }
          // if (mounted) {
          //   showSuccessPopup(
          //     context: context,
          //     message: "You have been successfully logged in..",
          //     onNavigate: () {
          //       context.go('/fleetmodeselection');
          //     },
          //   );
          // }
          if (mounted) {
            showSuccessPopup(
              context: context,
              message: "You have been successfully logged in..",
              onNavigate: () {
                final role =
                    (decodedToken['auth'] ?? '').toString().toLowerCase();

                if (role == 'super_admin') {
                  context.go('/home/settings');
                } else {
                  context.go('/fleetmodeselection');
                }
              },
            );
          }
        } else if (state is LoginFailure) {
          if (mounted) {
            // ScaffoldMessenger.of(
            //   context,
            // ).showSnackBar(SnackBar(content: Text(state.error)));
            if (mounted) {
              showErrorPopup(
                context: context,
                message: state.error,
                statusCode: state.statusCode,
              );
            }
          }
        }
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _brandLogo(),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Login',
                  style: GoogleFonts.urbanist(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                _buildTextButton(
                  iconPath: isDark ? 'icons/moon1.svg' : 'icons/sun1.svg',
                  onTap: () => themeProvider.toggleTheme(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description under Login
            Text(
              'Welcome back! Please login to your account.',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? tWhite : tBlack,
              ),
            ),
            const SizedBox(height: 20),

            // Username field
            _buildCustomTextField(
              controller: _usernameController,
              focusNode: _usernameFocus,
              labelText: 'Username',
              hintText: 'Enter your username',
              isDark: isDark,
              prefixIcon: CupertinoIcons.person,
              // onChanged: (value) {
              //   setState(() {
              //     _hasUsernameInput = value.isNotEmpty;
              //     _isUsernameValid = _usernameRegex.hasMatch(value);
              //   });
              // },
              onChanged: (value) {
                final hasInput = value.isNotEmpty;
                final isValid = _usernameRegex.hasMatch(value);

                if (_hasUsernameInput != hasInput ||
                    _isUsernameValid != isValid) {
                  setState(() {
                    _hasUsernameInput = hasInput;
                    _isUsernameValid = isValid;
                  });
                }
              },
              suffixIcon:
                  _hasUsernameInput
                      ? Icon(
                        _isUsernameValid ? Icons.check_circle : Icons.cancel,
                        color: _isUsernameValid ? tGreen3 : tRed,
                        size: 20,
                      )
                      : null,
            ),
            const SizedBox(height: 15),

            // Password field
            _buildCustomTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              labelText: 'Password',
              hintText: 'Enter your password',
              isDark: isDark,
              isPassword: true,
              passwordVisible: _passwordVisible,
              togglePasswordVisibility: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
              prefixIcon: Icons.password,
            ),
            const SizedBox(height: 20),

            // Full width login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  LoggerUtil.getInstance.print("CALL LogIn API");
                  BlocProvider.of<LoginBloc>(context).add(
                    LoginSubmitted(
                      username: _usernameController.text,
                      password: _passwordController.text,
                    ),
                  );
                  // context.go('/fleetmodeselection');
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: tGreen8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Login',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: tWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            Center(
              child: Text(
                '© TrakMate Design Solutions Pvt Ltd',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark
                          ? tWhite.withOpacity(0.6)
                          : tBlack.withOpacity(0.6),
                ),
              ),
            ),
          ],
        );
      },
      // ),
    );
  }

  // Reusable text field widget
  // Widget _buildCustomTextField({
  //   required TextEditingController controller,
  //   required String labelText,
  //   required String hintText,
  //   required bool isDark,
  //   FocusNode? focusNode,
  //   bool isPassword = false,
  //   bool passwordVisible = false,
  //   VoidCallback? togglePasswordVisibility,
  //   IconData? prefixIcon,
  //   Widget? suffixIcon,
  //   ValueChanged<String>? onChanged,
  // }) {
  //   return TextField(
  //     controller: controller,
  //     onChanged: onChanged,
  //     focusNode: focusNode,
  //     obscureText: isPassword ? !passwordVisible : false,
  //     decoration: InputDecoration(
  //       labelText: labelText,
  //       hintText: hintText,
  //       labelStyle: GoogleFonts.urbanist(
  //         fontSize: 13,
  //         color: isDark ? tWhite : tBlack,
  //       ),
  //       hintStyle: GoogleFonts.urbanist(
  //         fontSize: 12,
  //         color: isDark ? tWhite.withOpacity(0.5) : tBlack.withOpacity(0.35),
  //       ),
  //       enabledBorder: OutlineInputBorder(
  //         borderSide: BorderSide(
  //           color: isDark ? tWhite.withOpacity(0.5) : tBlack.withOpacity(0.35),
  //         ),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderSide: BorderSide(color: isDark ? tWhite : tBlack, width: 1),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       errorBorder: OutlineInputBorder(
  //         borderSide: const BorderSide(color: tRed, width: 1),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       focusedErrorBorder: OutlineInputBorder(
  //         borderSide: const BorderSide(color: tRed, width: 1),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       prefixIcon:
  //           prefixIcon != null
  //               ? Icon(prefixIcon, color: isDark ? tWhite : tBlack, size: 20)
  //               : null,
  //       suffixIcon:
  //           isPassword
  //               ? IconButton(
  //                 icon: Icon(
  //                   passwordVisible
  //                       ? CupertinoIcons.eye
  //                       : CupertinoIcons.eye_slash,
  //                   color: isDark ? tWhite : tBlack,
  //                   size: 20,
  //                 ),
  //                 onPressed: togglePasswordVisibility,
  //               )
  //               : suffixIcon,
  //     ),
  //     style: GoogleFonts.urbanist(
  //       fontSize: 13,
  //       color: isDark ? tWhite : tBlack,
  //     ),
  //     cursorColor: isDark ? tWhite : tBlack,
  //   );
  // }
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required bool isDark,
    FocusNode? focusNode,
    bool isPassword = false,
    bool passwordVisible = false,
    VoidCallback? togglePasswordVisibility,
    IconData? prefixIcon,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? tWhite.withOpacity(0.8) : tBlack.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          focusNode: focusNode,
          obscureText: isPassword ? !passwordVisible : false,
          keyboardType:
              isPassword ? TextInputType.visiblePassword : TextInputType.text,
          textInputAction:
              isPassword ? TextInputAction.done : TextInputAction.next,
          // onEditingComplete: () {
          //   if (isPassword) {
          //     FocusScope.of(context).unfocus();
          //   } else if (focusNode != null) {
          //     FocusScope.of(context).nextFocus();
          //   }
          // },
          onSubmitted: (_) {
            if (isPassword) {
              FocusScope.of(context).unfocus();
            } else {
              FocusScope.of(context).nextFocus();
            }
          },

          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.urbanist(
              fontSize: 12,
              color:
                  isDark ? tWhite.withOpacity(0.5) : tBlack.withOpacity(0.35),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color:
                    isDark ? tWhite.withOpacity(0.5) : tBlack.withOpacity(0.35),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? tWhite : tBlack,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: tRed, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: tRed, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon:
                prefixIcon != null
                    ? Icon(
                      prefixIcon,
                      color: isDark ? tWhite : tBlack,
                      size: 20,
                    )
                    : null,
            suffixIcon:
                isPassword
                    ? IconButton(
                      icon: Icon(
                        passwordVisible
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        color: isDark ? tWhite : tBlack,
                        size: 20,
                      ),
                      onPressed: togglePasswordVisibility,
                    )
                    : suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: isDark ? tWhite : tBlack,
          ),
          cursorColor: isDark ? tWhite : tBlack,
        ),
      ],
    );
  }

  Widget _brandLogo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tGreen8.withOpacity(0.1),
            borderRadius: BorderRadius.circular(0),
          ),
          child: SvgPicture.asset(
            'icons/esync_logo.svg',
            width: 30,
            height: 30,
            color: tGreen8,
          ),
        ),

        const SizedBox(width: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hero ESYNC',
              style: GoogleFonts.urbanist(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: tGreen8,
                letterSpacing: 0.5,
              ),
            ),

            Row(
              children: [
                Text(
                  'OEM Portal',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tGreen8,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 5),

                Container(
                  width: 70,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tOrange1, tWhite, tGreen3],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
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
            isDark ? tWhite.withOpacity(0.15) : tBlack.withOpacity(0.15),
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

  Widget _buildPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        '• $text',
        style: GoogleFonts.urbanist(
          fontSize: 16,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }
}
