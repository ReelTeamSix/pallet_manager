import 'package:flutter/material.dart';
import 'package:pallet_manager/utils/app_lifecycle_manager.dart';
import 'package:provider/provider.dart';
import 'pallet_model.dart';
import 'home_screen.dart';
import 'inventory_screen.dart' as inventory;
import 'analytics_screen.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app with error handling
  runApp(const PalletApp());
}

class PalletApp extends StatelessWidget {
  const PalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PalletModel>(
      create: (context) => PalletModel(),
      child: Builder(builder: (context) {
        // Access MediaQuery here to use in theme
        final mediaQuery = MediaQuery.of(context);
        final isTablet = mediaQuery.size.shortestSide >= 600;

        

        return AppLifecycleManager(child: 
          MaterialApp(
            title: 'Pallet Pro',
            // Enable system font scaling with reasonable limits
            builder: (context, child) {
              // Set up custom error widget
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            'An error occurred',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The application encountered an unexpected error.',
                            textAlign: TextAlign.center,
                          ),
                          if (errorDetails.exception.toString().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Error details:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              width: double.infinity,
                              child: Text(
                                errorDetails.exception.toString(),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              };

              // Get the media query data
              final mediaQueryData = MediaQuery.of(context);

              // Apply minimum and maximum text scaling factors with the new API
              final constrainedTextScaler = TextScaler.linear(
                  mediaQueryData.textScaler.scale(1.0).clamp(0.8, 1.5));

              // Return child with constrained text scaling
              return MediaQuery(
                data: mediaQueryData.copyWith(
                  textScaler: constrainedTextScaler,
                ),
                child: child!,
              );
            },
            theme: ThemeData(
              primarySwatch: Colors.teal,
              scaffoldBackgroundColor: Colors.grey[50],

              // Adaptive app bar for different device sizes
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF02838A),
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                ),
                // Taller app bar for tablets
                toolbarHeight: isTablet ? 64 : 56,
                iconTheme: const IconThemeData(color: Colors.white),
                // Responsive padding
                actionsIconTheme: IconThemeData(
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
              ),

              // Button theme with responsive sizing
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02838A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  // Larger touch targets on tablets
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isTablet ? 12 : 10,
                  ),
                  // Larger text on tablets
                  textStyle: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Text button theme with responsive sizing
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF02838A),
                  // Increased padding for better touch targets
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isTablet ? 10 : 8,
                  ),
                  // Responsive text
                  textStyle: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Add responsive card themes
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: isTablet ? 10 : 8,
                ),
              ),

              // Make input decoration more adaptive
              inputDecorationTheme: InputDecorationTheme(
                isDense: !isTablet, // Only dense on phones
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isTablet ? 16 : 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                // Responsive label text
                labelStyle: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                ),
                // Responsive hint text
                hintStyle: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  color: Colors.grey.shade500,
                ),
              ),

              // Adaptive divider for different screens
              dividerTheme: DividerThemeData(
                space: isTablet ? 16 : 12,
                thickness: 1,
                color: Colors.grey.shade300,
              ),

              // Adaptive chip theme for tags, etc.
              chipTheme: ChipThemeData(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 10 : 8,
                  vertical: isTablet ? 8 : 6,
                ),
                labelStyle: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                ),
                iconTheme: IconThemeData(
                  size: isTablet ? 18 : 16,
                ),
              ),

              // Color scheme
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF02838A),
                secondary: const Color(0xFFFF9800),
                error: Colors.red[700]!,
                surface: Colors.white,
                background: Colors.grey[50]!,
              ),

              // Responsive dialog theme
              dialogTheme: DialogTheme(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                titleTextStyle: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                contentTextStyle: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.black87,
                ),
              ),

              // Responsive bottom sheet theme
              bottomSheetTheme: BottomSheetThemeData(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                // More space on tablets
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : double.infinity,
                ),
              ),
            ),
            // Use a custom route generator for responsive page transitions
            onGenerateRoute: (settings) {
              // Get appropriate transition for device type
              return MaterialPageRoute(
                settings: settings,
                builder: (context) {
                  // Handle named routes
                  switch (settings.name) {
                    case '/inventory':
                      return const inventory.InventoryScreen();
                    case '/analytics':
                      return const AnalyticsScreen();
                    default:
                      return const HomeScreen();
                  }
                },
              );
            },
            home: const HomeScreen(),
            // Provide a default error screen that's responsive
            
          ),
        );
      }),
    );
  }
}
