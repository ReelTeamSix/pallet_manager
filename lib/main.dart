import 'package:flutter/material.dart';
import 'package:pallet_manager/services/auth_screen.dart';
import 'package:pallet_manager/services/data_migration_screen.dart';
import 'package:pallet_manager/services/data_repository.dart';
import 'package:pallet_manager/services/supabase_service.dart';
import 'package:pallet_manager/utils/app_lifecycle_manager.dart';
import 'package:pallet_manager/utils/log_utils.dart'; // Import LogUtils
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pallet_model.dart';
import 'home_screen.dart';
import 'inventory_screen.dart' as inventory;
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'theme/app_theme.dart'; // Import app theme
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppState {
  initializing,
  needsAuth,
  checkingMigration,
  needsMigration,
  ready,
  migrating,
  error
}

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
  late final PalletModel _model;
  late final DataRepository _repository;
  late final AuthService _authService;
  
  AppState _appState = AppState.initializing;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = DataRepository();
    _model = PalletModel(_repository);
    _authService = AuthService();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _appState = AppState.initializing);
      
      // Set up auth state listener
      _authService.authStateChanges.listen((AuthState state) {
        debugPrint('APP: Auth state changed: ${state.event}');
        
        if (state.event == AuthChangeEvent.signedIn) {
          _handleUserSignIn(state.session?.user);
        } else if (state.event == AuthChangeEvent.signedOut) {
          _handleUserSignOut();
        }
      });

      // Check if user is already signed in
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _handleUserSignIn(currentUser);
      } else {
        setState(() => _appState = AppState.needsAuth);
      }
    } catch (e) {
      debugPrint('APP: Error during initialization: $e');
      setState(() {
        _appState = AppState.error;
        _errorMessage = 'Failed to initialize app: $e';
      });
    }
  }

  Future<void> _handleUserSignIn(User? user) async {
    if (user == null) {
      setState(() => _appState = AppState.needsAuth);
      return;
    }

    try {
      setState(() => _appState = AppState.checkingMigration);
      
      // Ensure user profile exists
      await _authService.ensureUserProfileExists(user.id, user.email!);
      
      // Check migration status
      await _checkMigrationStatus();
    } catch (e) {
      debugPrint('APP: Error handling user sign in: $e');
      setState(() {
        _appState = AppState.error;
        _errorMessage = 'Failed to handle sign in: $e';
      });
    }
  }

  Future<void> _handleUserSignOut() async {
    try {
      // Clear model data
      _model.clearAllData();
      
      // Reset repository
      await _repository.resetMigrationStatus();
      _repository.setDataSource(DataSource.sharedPreferences);
      
      setState(() => _appState = AppState.needsAuth);
    } catch (e) {
      debugPrint('APP: Error handling user sign out: $e');
      setState(() {
        _appState = AppState.error;
        _errorMessage = 'Failed to handle sign out: $e';
      });
    }
  }

  Future<void> _checkMigrationStatus() async {
    try {
      final hasMigrated = await _repository.hasMigratedData;
      
      if (hasMigrated) {
        debugPrint('APP: Data already migrated, switching to Supabase');
        _repository.setDataSource(DataSource.supabase);
        await _model.initialize();
        setState(() => _appState = AppState.ready);
      } else {
        debugPrint('APP: Data needs migration');
        setState(() => _appState = AppState.needsMigration);
      }
    } catch (e) {
      debugPrint('APP: Error checking migration status: $e');
      setState(() {
        _appState = AppState.error;
        _errorMessage = 'Failed to check migration status: $e';
      });
    }
  }

  Future<void> _handleMigrationComplete() async {
    try {
      setState(() => _appState = AppState.initializing);
      
      // Repository will handle setting migration flag and data source
      await _repository.migrateDataToSupabase();
      
      // Initialize model with new data source
      await _model.initialize();
      
      setState(() => _appState = AppState.ready);
    } catch (e) {
      debugPrint('APP: Error handling migration completion: $e');
      setState(() {
        _appState = AppState.error;
        _errorMessage = 'Failed to complete migration: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pallet Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_appState) {
      case AppState.initializing:
        return _buildLoadingScreen();
      case AppState.needsAuth:
        return AuthScreen(
          onSignIn: (email, password) => _authService.signInWithEmail(email, password),
          onSignUp: (email, password) => _authService.signUpWithEmail(email, password),
        );
      case AppState.checkingMigration:
        return _buildLoadingScreen(message: 'Checking data status...');
      case AppState.needsMigration:
        return DataMigrationScreen(
          onMigrationComplete: _handleMigrationComplete,
        );
      case AppState.ready:
        return HomeScreen();
      case AppState.migrating:
        return _buildLoadingScreen(message: 'Migrating data...');
      case AppState.error:
        return _buildErrorScreen();
    }
  }

  Widget _buildLoadingScreen({String message = 'Loading...'}) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
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
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeApp,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
