import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'src/provider/fleetModeProvider.dart';
import 'src/utils/appColors.dart';
import 'src/utils/route/appRouter.dart';
import 'src/utils/theme/appThemeProvider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    if (Platform.isAndroid || Platform.isIOS) {
      // Get device info from window size to check for tablet
      final window = WidgetsBinding.instance.platformDispatcher.views.first;
      final size = window.physicalSize / window.devicePixelRatio;
      final isTablet = size.shortestSide >= 600; // common tablet threshold

      if (isTablet) {
        // Tablets → allow all orientations
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        // Phones → portrait only
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    } else {
      // Desktop platforms → allow all
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }
  // ============= HYDRATE FLEET MODE PROVIDER =============
  final fleetModeProvider = await FleetModeProvider.init();

  // runApp(
  //   ChangeNotifierProvider(
  //     create: (_) => ThemeProvider(),
  //     child: const TrakFleetApp(),
  //   ),
  // );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<FleetModeProvider>.value(
          value: fleetModeProvider,
        ),
      ],
      child: const ESyncFleetApp(),
    ),
  );
}

class ESyncFleetApp extends StatelessWidget {
  const ESyncFleetApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'TrakFleet',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: GoogleFonts.urbanistTextTheme(),
        scaffoldBackgroundColor: tWhite,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.urbanistTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: tBlack,
      ),
    );
  }
}
