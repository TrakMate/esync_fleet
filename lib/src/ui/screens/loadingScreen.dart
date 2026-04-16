import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../utils/appColors.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Simulate loading complete after 3 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        // Navigate or perform next action (e.g., check login)
        context.go('/login');
        // context.go('/landing');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final glow = Tween(begin: 0.2, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            );

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo or Icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'icons/esync_logo.svg',
                      width: 25,
                      height: 25,
                      color: tGreen8,
                    ),

                    SizedBox(width: 10),

                    // App Title
                    Text(
                      'Esync OEM',
                      style: GoogleFonts.urbanist(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: tGreen8,
                        // letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Subtext
                Text(
                  'Managing Your Fleet, Simplified',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                const SizedBox(height: 20),

                // Animated Loading Bar
                Container(
                  width: 200,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color:
                        isDark
                            ? tWhite.withOpacity(0.1)
                            : tBlack.withOpacity(0.1),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: glow.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [isDark ? tBlue : tBlue2, tOrange1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
