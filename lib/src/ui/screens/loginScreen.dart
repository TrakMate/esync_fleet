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
import '../components/customLoginAnimationBackground.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isUsernameValid = false;
  bool _hasUsernameInput = false;

  final RegExp _usernameRegex = RegExp(r'^[a-z]+\.[a-z]+$');
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildDesktopTabletLayout(0.5),
        desktop: _buildDesktopTabletLayout(0.5),
      ),
    );
  }

  // Desktop/Tablet Layout with two halves
  Widget _buildDesktopTabletLayout(double widthFactor) {
    return Row(
      children: [
        Expanded(
          flex: (widthFactor * 200).toInt(),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset('images/bg-cycle.png', fit: BoxFit.cover),
              ),

              //Full gradient background overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tGreen8.withOpacity(0.1),
                      tGreen8.withOpacity(0.5),
                    ],
                  ),
                ),
              ),

              //Content on top
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // maxWidth: MediaQuery.of(context).size.width * 0.5,
                      maxWidth: 700,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Powering the Future of Electric Mobility',
                          style: GoogleFonts.urbanist(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: tWhite,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'eSync is redefining electric mobility through innovative technology, smart connectivity, and sustainable solutions designed for next-generation transportation.',
                          style: GoogleFonts.urbanist(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: tWhite.withOpacity(0.95),
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 30),

                        _buildPoint(
                          'Advanced electric vehicle solutions built for performance and reliability.',
                        ),
                        _buildPoint(
                          'Smart IoT-enabled systems for seamless connectivity and control.',
                        ),
                        _buildPoint(
                          'Sustainable and eco-friendly mobility for modern transportation.',
                        ),
                        _buildPoint(
                          'Continuous innovation shaping the future of e-mobility.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right side with login form
        Expanded(
          flex: ((1 - widthFactor) * 100).toInt(),
          // child: Center(
          //   child: Container(
          //     padding: const EdgeInsets.all(40),
          //     constraints: const BoxConstraints(maxWidth: 400),
          //     child: _buildLoginForm(),
          //   ),
          // ),
          child: Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                /// Top header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _brandLogo(),

                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;

                        return _buildTextButton(
                          iconPath: isDark ? 'icons/moon.svg' : 'icons/sun.svg',
                          onTap: () => themeProvider.toggleTheme(),
                        );
                      },
                    ),
                  ],
                ),

                /// Center login form
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildLoginForm(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Mobile layout
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildLoginForm(),
      ),
    );
  }

  // Login form
  Widget _buildLoginForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return BlocProvider(
      create: (context) => LoginBloc(),

      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) async {
          LoggerUtil.getInstance.print("runtimeType>>>>>>${state.runtimeType}");

          if (state is LoginSuccess) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('accessToken', state.token);

            LoggerUtil.getInstance.print('Token saved: ${state.token}');
            Map<String, dynamic> decodedToken = JwtDecoder.decode(state.token);

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
            await prefs.setString('issuedAt', iatIST.toIso8601String());
            await prefs.setString('expiresAt', expIST.toIso8601String());

            LoggerUtil.getInstance.print('Decoded Token: $decodedToken');
            LoggerUtil.getInstance.print('IssuedAt (IST): $iatIST');
            LoggerUtil.getInstance.print('ExpiresAt (IST): $expIST');
            // Navigate after login success
            if (mounted) {
              // context.go(
              //   '/home/dashboard',
              // ); //Works only if GoRouter context is correct

              context.go('/fleetmodeselection');
            }
          } else if (state is LoginFailure) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error)));
            }
          }
        },
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _brandLogo(),

              // const SizedBox(height: 10),
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
                  // _buildTextButton(
                  //   iconPath: isDark ? 'icons/moon.svg' : 'icons/sun.svg',
                  //   onTap: () => themeProvider.toggleTheme(),
                  // ),
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
                labelText: 'Username',
                hintText: 'Enter your username',
                isDark: isDark,
                prefixIcon: CupertinoIcons.person,
                onChanged: (value) {
                  setState(() {
                    _hasUsernameInput = value.isNotEmpty;
                    _isUsernameValid = _usernameRegex.hasMatch(value);
                  });
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
                      color: tBlack,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Center(
                child: Text(
                  '© ESYNC, Hero EDU Systems Pvt. Ltd.',
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
      ),
    );
  }

  // Reusable text field widget
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required bool isDark,
    bool isPassword = false,
    bool passwordVisible = false,
    VoidCallback? togglePasswordVisibility,
    IconData? prefixIcon,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: isPassword ? !passwordVisible : false,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: GoogleFonts.urbanist(
          fontSize: 13,
          color: isDark ? tWhite : tBlack,
        ),
        hintStyle: GoogleFonts.urbanist(
          fontSize: 12,
          color: isDark ? tWhite.withOpacity(0.5) : tBlack.withOpacity(0.35),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? tWhite.withOpacity(0.5) : tBlack.withOpacity(0.35),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? tWhite : tBlack, width: 1),
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
                ? Icon(prefixIcon, color: isDark ? tWhite : tBlack, size: 20)
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
      ),
      style: GoogleFonts.urbanist(
        fontSize: 13,
        color: isDark ? tWhite : tBlack,
      ),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: tGreen8, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.urbanist(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: tWhite,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
