// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pallet_model.dart';
import 'home_screen.dart';
import 'inventory_screen.dart' as inventory;
import 'analytics_screen.dart';

void main() {
  runApp(const PalletApp());
}

class PalletApp extends StatelessWidget {
  const PalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PalletModel>(
      create: (context) => PalletModel(),
      child: MaterialApp(
        title: 'Pallet Pro',
        theme: ThemeData(
          // Change the primary color from brown to a more modern teal/blue that's easier on the eyes
          primarySwatch: Colors.teal,  // More modern, easier on the eyes
          scaffoldBackgroundColor: Colors.grey[50],  // Light background for better contrast
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF02838A),  // Teal color that's more modern
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF02838A),  // Matching teal
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          // Add color scheme
          colorScheme: ColorScheme.light(
            primary: Color(0xFF02838A),      // Teal primary
            secondary: Color(0xFFFF9800),    // Orange accent for good contrast
            error: Colors.red[700]!,
            surface: Colors.white,
            background: Colors.grey[50]!,
          ),
        ),
        home: const HomeScreen(),
        routes: {
          '/inventory': (context) => const inventory.InventoryScreen(),
          '/analytics': (context) => const AnalyticsScreen(),
        },
      ),
    );
  }
}