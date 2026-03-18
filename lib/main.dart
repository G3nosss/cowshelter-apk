// ─────────────────────────────────────────────────────────────────────────────
//  lib/main.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only — makes sense for a monitoring dashboard
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialise notifications before runApp
  await NotificationService().init();

  runApp(const CowShelterApp());
}

class CowShelterApp extends StatelessWidget {
  const CowShelterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                     'Cow Shelter Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F8E9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation:       0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
