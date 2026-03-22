import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/medicine_list_screen.dart';
import 'services/database_service.dart'; // <--- This missing line fixes the error!


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Turn on the Hive engine
  await DatabaseService().init();

  runApp(const ProviderScope(child: MediCartApp()));
}

class MediCartApp extends StatelessWidget {
  const MediCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediCart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF09090B), // Ultra-deep dark background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6), // Vibrant modern blue
          surface: Color(0xFF18181B), // Sleek zinc for cards
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MedicineListScreen(),
    );
  }
}