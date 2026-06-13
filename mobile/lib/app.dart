import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/detection_detail_screen.dart';

class JalanCerdasApp extends StatelessWidget {
  const JalanCerdasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JalanCerdas AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF2196F3),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A2E),
          selectedItemColor: Color(0xFF2196F3),
          unselectedItemColor: Colors.grey,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2196F3),
          secondary: Color(0xFF00E676),
          surface: Color(0xFF1E1E1E),
          error: Color(0xFFFF5252),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onError: Colors.white,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detection_detail') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => DetectionDetailScreen(
              detectionId: args?['detectionId'] ?? '',
            ),
          );
        }
        return null;
      },
    );
  }
}
