import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pallet_manager/pallet_model.dart';
import 'package:pallet_manager/services/data_repository.dart';
import 'package:pallet_manager/services/supabase_service.dart';
import 'package:provider/provider.dart';
import 'package:pallet_manager/utils/test_data_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pallet_manager/utils/log_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  @override
  Widget build(BuildContext context) {
    final palletModel = Provider.of<PalletModel>(context);
    final theme = Theme.of(context);
    final isUsingSupabase = palletModel.dataSource == DataSource.supabase;
    final isLoggedIn = SupabaseService.instance.currentUser != null;
    final hasMigratedData = palletModel.dataRepository.hasMigratedData;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // App info section
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Info'),
            onTap: () => _showAppInfoDialog(context),
          ),
          
          const Divider(),
          
          // Data management section
          _buildSectionHeader(context, 'Data Management'),
          
          // Data source status - remove explicit cloud/Supabase references
          if (hasMigratedData)
            ListTile(
              leading: const Icon(Icons.cloud_done, color: Colors.green),
              title: const Text('Data Storage'),
              subtitle: const Text('Your data is stored in the cloud'),
              enabled: false,
            )
          else
            // Data source selection - only available before migration
          ListTile(
            leading: Icon(
              isUsingSupabase ? Icons.cloud : Icons.phone_android,
            ),
              title: const Text('Data Storage'),
            subtitle: Text(
                isUsingSupabase ? 'Cloud Storage' : 'Local Storage (Device)',
            ),
            onTap: () => _showDataSourceDialog(context, palletModel),
          ),
          
          // Backup & Restore
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Manage your data backups'),
            onTap: () => _showBackupRestoreDialog(context, palletModel),
          ),
          
          // Database cleanup - only show if migrated
          if (hasMigratedData)
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Database Maintenance'),
              subtitle: const Text('Clean up duplicate data'),
              onTap: () => _showDatabaseCleanupDialog(context, palletModel),
            ),
          
          // Data migration - only show if not using Supabase, logged in, and not migrated
          if (!isUsingSupabase && isLoggedIn && !hasMigratedData)
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Migrate to Cloud'),
              subtitle: const Text('Move your data to cloud storage (one-time operation)'),
              onTap: () => _showMigrationDialog(context, palletModel),
            ),
          
          const Divider(),
          
          // Account section (only if using Supabase)
          if (isUsingSupabase || isLoggedIn) ...[
            _buildSectionHeader(context, 'Account'),
            
            // User info
            if (isLoggedIn)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Account'),
                subtitle: Text(SupabaseService.instance.currentUser?.email ?? ''),
                onTap: () {},
              ),
            
            // Sign out button
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () => _signOut(context),
            ),
            
            const Divider(),
          ],
          
          // Testing section (visible in debug mode only)
          if (kDebugMode) ...[
            _buildSectionHeader(context, 'Testing Tools'),
            
            // Generate Test Data button
            ListTile(
              leading: const Icon(Icons.data_array),
              title: const Text('Generate Test Data'),
              subtitle: const Text('Create random data in SharedPreferences'),
              onTap: () => _showGenerateTestDataDialog(context),
            ),
            
            // Reset Local Data button
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Reset Local Data'),
              subtitle: const Text('Clear all data in SharedPreferences'),
              onTap: () => _showResetDataDialog(context),
            ),
            
            // Force Migration Check button
            ListTile(
              leading: const Icon(Icons.sync_problem),
              title: const Text('Force Migration Check'),
              subtitle: const Text('Manually trigger migration detection'),
              onTap: () => _forceMigrationCheck(context),
            ),
            
            const Divider(),
          ],
          
          // Display messages
          if (_errorMessage != null || _successMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _errorMessage != null
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage ?? _successMessage ?? '',
                  style: TextStyle(
                    color: _errorMessage != null
                        ? Colors.red.shade900
                        : Colors.green.shade900,
                  ),
                ),
              ),
            ),
          
          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Pallet Pro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version: 1.0.0'),
            const SizedBox(height: 8),
            const Text(
              'Pallet Pro helps you manage inventory and provides performance analytics for pallet sales.',
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2023 Pallet Pro',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
  
  void _showDataSourceDialog(BuildContext context, PalletModel palletModel) {
    final currentSource = palletModel.dataSource;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Data Storage Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose where your data will be stored:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Local option
            _buildDataSourceOption(
              context,
              icon: Icons.phone_android,
              title: 'Local Storage',
              description: 'Store data on this device only',
              isSelected: currentSource == DataSource.sharedPreferences,
              onTap: () => _switchDataSource(
                context, 
                palletModel, 
                DataSource.sharedPreferences,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cloud option
            _buildDataSourceOption(
              context,
              icon: Icons.cloud,
              title: 'Cloud Storage',
              description: 'Store data in the cloud and access from multiple devices',
              isSelected: currentSource == DataSource.supabase,
              onTap: SupabaseService.instance.currentUser != null
                  ? () => _switchDataSource(
                      context, 
                      palletModel, 
                      DataSource.supabase,
                    )
                  : () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You need to sign in to use cloud storage'),
                        ),
                      );
                    },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataSourceOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.shade50 : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
  
  void _showBackupRestoreDialog(BuildContext context, PalletModel palletModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup & Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Create Backup'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backup functionality not implemented yet'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore from Backup'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restore functionality not implemented yet'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
  
  void _showDatabaseCleanupDialog(BuildContext context, PalletModel palletModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database Maintenance'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will clean up potential duplicate data in your cloud database.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'This process:',
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Removes duplicate pallets'),
                  Text('• Ensures data consistency'),
                  Text('• May take a few moments to complete'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cleanupDatabase(context, palletModel);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('CLEAN UP DATABASE'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _switchDataSource(
    BuildContext context, 
    PalletModel palletModel, 
    DataSource newSource,
  ) async {
    Navigator.of(context).pop();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      // Get the data repository from the PalletModel
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      
      // Switch data source
      await dataRepository.setDataSource(newSource);
      
      // Reload data
      await palletModel.forceDataReload();
      
      setState(() {
        _successMessage = 'Data source switched to ${newSource == DataSource.sharedPreferences ? 'local' : 'cloud'} successfully';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to switch data source: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _migrateData(BuildContext context, PalletModel palletModel) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      // Migrate data
      await palletModel.migrateDataToSupabase();
      
      setState(() {
        _successMessage = 'Data migrated to cloud successfully';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to migrate data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showMigrationDialog(BuildContext context, PalletModel palletModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migrate to Cloud'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Do you want to migrate your data from local storage to the cloud?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'This is a one-time, permanent operation. After migration:',
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Your data will only exist in the cloud'),
                  Text('• You\'ll need internet to access your data'),
                  Text('• Local data will be cleared from this device'),
                  Text('• You cannot switch back to local storage'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _migrateData(context, palletModel);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('MIGRATE PERMANENTLY'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _cleanupDatabase(BuildContext context, PalletModel palletModel) async {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
                _successMessage = null;
              });
              
              try {
      // Run the cleanup function
      await SupabaseService.instance.cleanupDuplicatePallets();
      
      // Reload data after cleanup
                await palletModel.forceDataReload();
                
                setState(() {
        _successMessage = 'Database cleanup completed successfully';
                });
              } catch (e) {
                setState(() {
        _errorMessage = 'Failed to clean up database: ${e.toString()}';
                });
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
  }
  
  Future<void> _signOut(BuildContext context) async {
    // Confirm sign-out with dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldSignOut) return;
    
    // Show loading indicator
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Signing out...'),
            ],
          ),
        ),
      ),
    );
    
    try {
      // Clear model data
      final model = Provider.of<PalletModel>(context, listen: false);
      await model.clearAllData();
      
      // Reset data source to local
      if (model.dataRepository.dataSource == DataSource.supabase) {
        await model.dataRepository.setDataSource(DataSource.sharedPreferences);
      }
      
      // Sign out from Supabase
      final supabaseService = SupabaseService.instance;
      await supabaseService.signOut();
      
      LogUtils.info('Sign out successful, navigating to login screen');
      
      // Navigate away from settings screen
      Future.delayed(Duration.zero, () {
        // Close loading dialog if still showing
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        if (context.mounted) {
          // Use strong navigation to force a complete stack clear and return to login
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
    } catch (e) {
      LogUtils.error('Error signing out', e);
      
      // Close loading dialog if still open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showGenerateTestDataDialog(BuildContext context) {
    int palletCount = 5;
    int itemsPerPallet = 10;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Generate Test Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This will generate random test data in SharedPreferences.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                
                // Pallet count slider
                Row(
                  children: [
                    const Text('Pallets:'),
                    Expanded(
                      child: Slider(
                        value: palletCount.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: palletCount.toString(),
                        onChanged: (value) {
                          setState(() {
                            palletCount = value.round();
                          });
                        },
                      ),
                    ),
                    Text('$palletCount'),
                  ],
                ),
                
                // Items per pallet slider
                Row(
                  children: [
                    const Text('Items:'),
                    Expanded(
                      child: Slider(
                        value: itemsPerPallet.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: itemsPerPallet.toString(),
                        onChanged: (value) {
                          setState(() {
                            itemsPerPallet = value.round();
                          });
                        },
                      ),
                    ),
                    Text('$itemsPerPallet'),
                  ],
                ),
                
                // Total items calculation
                Text(
                  'Total: ~${palletCount * itemsPerPallet} items',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  // Close dialog first, then execute in a separate call
                  Navigator.of(context).pop();
                  _executeGenerateTestData(context, palletCount, itemsPerPallet);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
                child: const Text('GENERATE'),
              ),
            ],
          );
        }
      ),
    );
  }
  
  // Separate method to generate test data safely
  Future<void> _executeGenerateTestData(BuildContext context, int palletCount, int maxItemsPerPallet) async {
    if (!mounted) return;
    
    // Capture references BEFORE any async operations
    final navigatorContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    final palletModel = Provider.of<PalletModel>(context, listen: false);
    
    // Show loading indicator using a SnackBar
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Generating test data...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // Move the entire logic outside widget tree operations
    Future.microtask(() async {
      try {
        print('Starting test data generation process...');
        
        // First, reset all data to ensure a clean slate
        print('Resetting all local data first...');
        await TestDataGenerator.resetAllData();
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Ensure we're using SharedPreferences
        if (dataRepository.dataSource != DataSource.sharedPreferences) {
          print('Switching data source to SharedPreferences for test data generation');
          await dataRepository.setDataSource(DataSource.sharedPreferences);
        }
        
        // Generate test data
        print('Starting test data generation with $palletCount pallets and up to $maxItemsPerPallet items per pallet');
        await TestDataGenerator.generateTestData(
          palletCount: palletCount,
          maxItemsPerPallet: maxItemsPerPallet,
        );
        
        // Wait a bit before reloading
        print('Test data generation complete, waiting before reloading...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Re-initialize the data repository to ensure it's using the right source
        print('Re-initializing data repository to SharedPreferences');
        await dataRepository.initialize(DataSource.sharedPreferences);
        
        // Force a complete data reload
        print('Forcing complete data reload after test data generation');
        await palletModel.forceDataReload();
        
        // Additional check to verify the data was loaded
        print('After reload: ${palletModel.pallets.length} pallets loaded into model');
        
        // If there are still no pallets loaded, try again with a different approach
        if (palletModel.pallets.isEmpty) {
          print('No pallets loaded on first attempt, trying an alternative approach...');
          
          // Try to ensure SharedPreferences is synced to disk
          print('Ensuring SharedPreferences is synced to disk...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.reload(); // Force reload from disk
          
          // Reload data again
          await Future.delayed(const Duration(milliseconds: 300));
          print('Attempting final data reload from disk...');
          await palletModel.forceDataReload();
          
          print('After final reload attempt: ${palletModel.pallets.length} pallets');
        }
        
        // Only show a snackbar if the context is still valid
        if (navigatorContext.mounted) {
          final message = palletModel.pallets.isEmpty
              ? 'Generated data, but app could not load it. Try restarting the app.'
              : 'Test data generated successfully: ${palletModel.pallets.length} pallets';
              
          final color = palletModel.pallets.isEmpty ? Colors.orange : Colors.green;
          
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: color,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        print('Error during generate test data: $e');
        if (navigatorContext.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error generating test data: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    });
  }
  
  void _showResetDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Local Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will delete ALL data in SharedPreferences.',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
            ),
            SizedBox(height: 16),
            Text(
              'Warning: This operation cannot be undone!',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              // Close the dialog first, then execute reset in a separate call
              Navigator.of(context).pop();
              _executeResetData(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
  
  // Separate method for resetting data to avoid widget tree issues
  Future<void> _executeResetData(BuildContext context) async {
    if (!mounted) return;
    
    // Show loading indicator using a SnackBar instead
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resetting local data...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      // Reset all local data
      await TestDataGenerator.resetAllData();
      
      // Wait a bit before reloading to ensure SharedPreferences updates are complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Reload data
      final palletModel = Provider.of<PalletModel>(context, listen: false);
      await palletModel.forceDataReload();
      
      // Reset data source to SharedPreferences
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      await dataRepository.initialize(DataSource.sharedPreferences);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local data reset successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      LogUtils.error('Error during reset data', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _forceMigrationCheck(BuildContext context) {
    final palletModel = Provider.of<PalletModel>(context, listen: false);
    
    // Show loading indicator using a SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking migration status...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    Future.microtask(() async {
      try {
        final needsMigration = await palletModel.checkAndPrepareMigration();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(needsMigration 
                  ? 'Migration needed - check should appear on next app start' 
                  : 'No migration needed'),
              backgroundColor: needsMigration ? Colors.orange : Colors.green,
            ),
          );
        }
      } catch (e) {
        LogUtils.error('Error during migration check', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to check migration: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }
} 