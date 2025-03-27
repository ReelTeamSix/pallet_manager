import 'package:flutter/material.dart';
import 'package:pallet_manager/services/auth_screen.dart';
import 'package:pallet_manager/services/data_migration_screen.dart';
import 'package:pallet_manager/services/data_repository.dart';
import 'package:pallet_manager/services/supabase_service.dart';
import 'package:pallet_manager/utils/app_lifecycle_manager.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pallet_model.dart';
import 'home_screen.dart';
import 'inventory_screen.dart' as inventory;
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'theme/app_theme.dart'; // Import app theme
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await SupabaseService.initialize(
    supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
    supabaseKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  
  // Create data repository instance and initialize it
  final dataRepository = DataRepository();
  await dataRepository.initialize(DataSource.sharedPreferences);
  
  // Create and initialize the PalletModel but don't load data yet
  final palletModel = PalletModel(dataRepository: dataRepository);
  
  debugPrint('✅ App initialization complete - All services ready');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dataRepository),
        ChangeNotifierProvider.value(value: palletModel),
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: const PalletApp(),
      ),
    ),
  );
}

class PalletApp extends StatefulWidget {
  const PalletApp({super.key});

  @override
  State<PalletApp> createState() => _PalletAppState();
}

class _PalletAppState extends State<PalletApp> {
  bool _isAuthenticated = false;
  bool _showMigrationScreen = false;
  bool _isMigrationCheckInProgress = false;
  bool _hasCheckedMigration = false;
  bool _isLoading = false;
  bool _isCheckingMigration = false;
  bool _migrationInProgress = false;
  bool _isInitializing = false;
  bool _isInitialized = false;
  String _errorMessage = '';
  // Track if we've already assigned the model
  bool _hasAssignedModel = false;
  
  // Add property references to avoid undefined getter errors
  late PalletModel model;
  late SupabaseService supabase;

  @override
  void initState() {
    super.initState();
    _isInitializing = true;
    _isInitialized = false;
    
    // Initialize Supabase reference safely
    supabase = SupabaseService.instance;
    
    // Use a microtask to ensure we're outside the build phase
    Future.microtask(() {
      // Initialize model safely after the first frame
      model = Provider.of<PalletModel>(context, listen: false);
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;
    
    debugPrint('Initializing app...');
    setState(() {
      _isInitializing = true;
      _isInitialized = false;
    });
    
    try {
      // Initialize PalletModel first
      await model.initialize();
      debugPrint('PalletModel initialized');
      
      // Check if the user is logged in to Supabase
      final user = supabase.currentUser; // Using the correct getter
      final isLoggedIn = user != null;
      
      // Update authentication state
      setState(() {
        _isAuthenticated = isLoggedIn;
      });
      
      // If the user is authenticated, check if we need to show the migration screen
      if (isLoggedIn) {
        debugPrint('User is authenticated, checking migration status');
        await _checkMigrationStatus();
      }
      
      // Mark initialization as complete
      setState(() {
        _isInitializing = false;
        _isInitialized = true;
      });
      
      debugPrint('App initialization complete. Auth: $_isAuthenticated, Migration: $_showMigrationScreen');
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      
      // Ensure we update state even if there's an error
      setState(() {
        _isInitializing = false;
        _isInitialized = true; // Still mark as initialized so app doesn't get stuck
      });
    }
  }

  Future<void> _checkMigrationStatus() async {
    if (!mounted) return;
    
    // Skip migration check if it's already in progress or user isn't authenticated
    if (_migrationInProgress || !_isAuthenticated) {
      debugPrint('Skipping migration check: inProgress=$_migrationInProgress, authenticated=$_isAuthenticated');
      return;
    }
    
    debugPrint('Checking migration status - starting the check process');
    
    try {
      // Set migration in progress flag to prevent concurrent checks
      _migrationInProgress = true;
      debugPrint('Set _migrationInProgress=true to prevent concurrent checks');
      
      // Force a data reload to ensure we have the latest state
      await model.forceDataReload();
      
      // Check if we've already migrated data
      final hasAlreadyMigrated = model.dataRepository.hasMigratedData;
      debugPrint('Has already migrated: $hasAlreadyMigrated');
      
      if (hasAlreadyMigrated) {
        debugPrint('Data has already been migrated, switching to Supabase mode');
        
        // Data has been migrated, make sure we're using Supabase
        if (model.dataRepository.dataSource != DataSource.supabase) {
          debugPrint('Switching to Supabase as data source is currently: ${model.dataRepository.dataSource}');
          await model.dataRepository.setDataSource(DataSource.supabase);
        }
        
        setState(() {
          _showMigrationScreen = false;
          debugPrint('Set _showMigrationScreen=false because data is already migrated');
        });
        
        return;
      }
      
      // Check if migration is needed by asking the model
      final needsMigration = await model.checkAndPrepareMigration();
      
      debugPrint('Migration needed according to model.checkAndPrepareMigration(): $needsMigration');
      
      // Update state based on migration check
      setState(() {
        _showMigrationScreen = needsMigration;
        debugPrint('Updated _showMigrationScreen=$needsMigration based on migration check');
      });
    } catch (e) {
      debugPrint('Error checking migration status: $e');
    } finally {
      // Clear the migration in progress flag
      _migrationInProgress = false;
      debugPrint('Reset _migrationInProgress=false to allow future checks');
    }
  }

  // Handle migration complete callback from migration screen
  void _handleMigrationComplete() async {
    if (!mounted) return;
    
    debugPrint('MIGRATION: Migration complete callback received');
    
    try {
      // Set loading state to prevent UI flicker
      setState(() {
        _isLoading = true;
      });
      
      // Make sure we have current model reference
      model = Provider.of<PalletModel>(context, listen: false);
      
      // Force the data repository to recognize migration is complete
      debugPrint('MIGRATION: Forcing data reload to update migration status');
      await model.dataRepository.forceDataReload();
      
      // Explicitly set data source to Supabase
      debugPrint('MIGRATION: Explicitly setting data source to Supabase');
      await model.dataRepository.setDataSource(DataSource.supabase);
      
      // Reinitialize data repository with Supabase as the source
      debugPrint('MIGRATION: Reinitializing data repository with Supabase');
      await model.dataRepository.initialize(DataSource.supabase);
      
      // Force reload data from new source
      debugPrint('MIGRATION: Reloading data from Supabase');
      // Clear existing data first
      await model.clearAllData();
      // Then reload from Supabase
      await model.loadData();
      
      // Update app state - turn off migration flags
      setState(() {
        _showMigrationScreen = false;
        _migrationInProgress = false;
        _isLoading = false;
      });
      
      debugPrint('MIGRATION: Migration complete process finished, updated app state (_showMigrationScreen=$_showMigrationScreen, _migrationInProgress=$_migrationInProgress)');
    } catch (e) {
      debugPrint('MIGRATION: Error handling migration complete: $e');
      
      // Even on error, ensure we reset the flags
      setState(() {
        _migrationInProgress = false;
        _isLoading = false;
      });
    }
  }

  void _setupAuthStateListener() {
    SupabaseService.instance.authStateChange.listen((data) async {
      if (!mounted) return;
      
      final isNowAuthenticated = data.session != null;
      final newUserId = data.session?.user.id;
      final previousUserId = SupabaseService.instance.previousUserId;
      final userChanged = isNowAuthenticated && newUserId != previousUserId && previousUserId != null;
      
      // Update the stored user ID
      if (isNowAuthenticated) {
        SupabaseService.instance.updatePreviousUserId(newUserId!);
      }
      
      // Handle sign in/sign out state change
      if (_isAuthenticated != isNowAuthenticated || userChanged) {
        setState(() {
          _isAuthenticated = isNowAuthenticated;
          
          if (!isNowAuthenticated || userChanged) {
            _showMigrationScreen = false;
            _hasCheckedMigration = false;
          }
        });
        
        // If signed out or user changed, clear data
        if (!isNowAuthenticated || userChanged) {
          final palletModel = Provider.of<PalletModel>(context, listen: false);
          await palletModel.clearAllData();
          
          // If user changed (not just signed out)
          if (userChanged) {
            debugPrint('User changed from $previousUserId to $newUserId - clearing data and reloading');
            final dataRepository = Provider.of<DataRepository>(context, listen: false);
            await dataRepository.resetMigrationStatus();
            
            // Set flag to show we detected a user change
            SupabaseService.instance.setUserChanged(true);
          }
        }
        
        if (isNowAuthenticated) {
          await Future.delayed(const Duration(milliseconds: 100));
          _checkMigrationStatus();
        }
      }
    });
  }

  void _handleAuthSuccess() {
    if (!mounted) return;
    
    setState(() {
      _isAuthenticated = true;
      _hasCheckedMigration = false;
      _isLoading = true;
    });
    
    Future.microtask(() async {
      if (mounted) {
        try {
          // Make sure model is initialized
          if (!_hasAssignedModel) {
            model = Provider.of<PalletModel>(context, listen: false);
            _hasAssignedModel = true;
          }
          
          // Clear any existing data first to prevent data leakage between users
          await model.clearAllData();
          
          // Check if this user has already migrated
          final dataRepository = model.dataRepository;
          
          // If this is a different user than before, reset migration status
          if (supabase.hasUserChanged()) {
            debugPrint('New user detected during auth, resetting migration status');
            await dataRepository.resetMigrationStatus();
            supabase.setUserChanged(false);
          }
          
          await dataRepository.initialize(DataSource.sharedPreferences);
          
          final hasMigrated = dataRepository.hasMigratedData;
          if (hasMigrated) {
            // If already migrated, force to use Supabase
            debugPrint('User has already migrated, forcing Supabase data source');
            await dataRepository.initialize(DataSource.supabase);
            
            // Load data via the initialize method instead of directly calling forceDataReload
            await model.initialize();
            debugPrint('Initialized PalletModel with data from Supabase');
          } else {
            // Initialize with SharedPreferences data
            await model.initialize();
          }
          
          // Check migration status last
          await _checkMigrationStatus();
        } catch (e) {
          debugPrint('Error during auth success handling: $e');
        } finally {
          // Make sure to end loading state
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    });
  }

  void _handleSignOut() async {
    debugPrint('Sign out initiated');
    
    try {
      // Update authentication state
      setState(() {
        _isAuthenticated = false;
        _showMigrationScreen = false;
      });
      
      // Clear model data
      final palletModel = Provider.of<PalletModel>(context, listen: false);
      await palletModel.clearAllData();
      
      // Ensure we're using local data source after sign out
      await palletModel.dataRepository.setDataSource(DataSource.sharedPreferences);
      
      // Schedule a navigation to login screen with microtask to ensure state is updated first
      Future.microtask(() {
        if (mounted) {
          debugPrint('Navigating to login screen after sign-out');
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      
      debugPrint('Sign out complete');
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }

  Widget _buildErrorWidget(FlutterErrorDetails errorDetails) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'An error occurred',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
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
  }

  Widget _buildScreen(BuildContext context, PalletModel palletModel) {
    // Ensure we're using the latest model instance
    if (!_hasAssignedModel) {
      model = palletModel;
      _hasAssignedModel = true;
    }
    
    // Special case handling - if we've already decided to show the migration screen,
    // we need to keep showing it regardless of temporary loading states
    if (_showMigrationScreen) {
      debugPrint('Main: Showing migration screen (prioritized since _showMigrationScreen=true)');
      return DataMigrationScreen(
        palletModel: palletModel,
        savedTags: palletModel.getAllTags(),
        onMigrationComplete: _handleMigrationComplete,
      );
    }
    
    // Standard loading state handling
    if (palletModel.isLoading || _isLoading || _isCheckingMigration) {
      debugPrint('Main: Showing loading screen due to: palletModel.isLoading=${palletModel.isLoading}, _isLoading=$_isLoading, _isCheckingMigration=$_isCheckingMigration');
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading your data...", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }
    
    // Finally, show home or auth screen
    debugPrint('Main: Showing ${_isAuthenticated ? "home" : "auth"} screen');
    return _isAuthenticated
        ? const HomeScreen()
        : AuthScreen(onAuthSuccess: _handleAuthSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;

    return AppLifecycleManager(
      child: MaterialApp(
        title: 'Pallet Pro',
        builder: (context, child) {
          ErrorWidget.builder = _buildErrorWidget;

          final mediaQueryData = MediaQuery.of(context);
          final constrainedTextScaler = TextScaler.linear(
              mediaQueryData.textScaler.scale(1.0).clamp(0.8, 1.5));

          return MediaQuery(
            data: mediaQueryData.copyWith(textScaler: constrainedTextScaler),
            child: child!,
          );
        },
        theme: AppTheme.getTheme(
            isTablet: isTablet, brightness: Brightness.light),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (context) {
            // Make sure the model is initialized when navigating
            if (!_hasAssignedModel) {
              model = Provider.of<PalletModel>(context, listen: false);
              _hasAssignedModel = true;
            }
            
            // First handle special cases like initialization or login
            if (_isInitializing) {
              return _buildLoadingScreen();
            }
            
            if (!_isInitialized) {
              return _buildErrorScreen();
            }
            
            if (!_isAuthenticated) {
              return AuthScreen(onAuthSuccess: _handleAuthSuccess);
            }
            
            // Then handle normal routes
            switch (settings.name) {
              case '/inventory':
                return const inventory.InventoryScreen();
              case '/analytics':
                return const AnalyticsScreen();
              case '/settings':
                return const SettingsScreen();
              case '/login':
                return AuthScreen(onAuthSuccess: _handleAuthSuccess);
              default:
                return _buildHomeScreen(context);
            }
          },
        ),
        home: Consumer<PalletModel>(
          builder: (context, palletModel, _) {
            // First handle initialization, error, auth states
            if (_isInitializing) {
              return _buildLoadingScreen();
            }
            
            if (!_isInitialized) {
              return _buildErrorScreen();
            }
            
            if (!_isAuthenticated) {
              return AuthScreen(onAuthSuccess: _handleAuthSuccess);
            }
            
            return _buildScreen(context, palletModel);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('Initializing app...', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Failed to initialize app', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _checkMigrationStatus,
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHomeScreen(BuildContext context) {
    return Consumer<PalletModel>(
      builder: (context, palletModel, _) => _buildScreen(context, palletModel),
    );
  }
}
