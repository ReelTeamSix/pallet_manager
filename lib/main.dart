import 'package:flutter/material.dart';
import 'package:pallet_manager/utils/app_lifecycle_manager.dart';
import 'package:provider/provider.dart';
import 'pallet_model.dart';
import 'home_screen.dart';
import 'inventory_screen.dart' as inventory;
import 'analytics_screen.dart';
import 'theme/app_theme.dart'; // Import app theme

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

        return AppLifecycleManager(
          child: MaterialApp(
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
            // Use AppTheme to get the theme based on device type and brightness
            theme: AppTheme.getTheme(
                isTablet: isTablet, brightness: Brightness.light),
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
          ),
        );
      }),
    );
  }
}
