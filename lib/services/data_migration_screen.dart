import 'package:flutter/material.dart';
import 'package:pallet_manager/pallet_model.dart';
import 'package:pallet_manager/services/supabase_service.dart';
import 'package:pallet_manager/services/data_repository.dart';

class DataMigrationScreen extends StatefulWidget {
  final PalletModel palletModel;
  final Set<String> savedTags;
  final VoidCallback onMigrationComplete;

  const DataMigrationScreen({
    Key? key,
    required this.palletModel,
    required this.savedTags,
    required this.onMigrationComplete,
  }) : super(key: key);

  @override
  State<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> {
  bool _isLoading = false;
  bool _migrationComplete = false;
  String? _errorMessage;
  bool _isDisposed = false;
  int _totalPallets = 0;
  int _totalItems = 0;
  int _totalTags = 0;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    
    // Use a delay to avoid build issues
    Future.delayed(Duration.zero, () {
      if (mounted && !_dataLoaded) _loadData();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isDisposed || _isLoading || _dataLoaded) return;
    
    debugPrint('DataMigrationScreen: Starting _loadData()');
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // Don't reload data, just use what we already have
      // Loading the summary counts doesn't need to reload the entire model
      if (_isDisposed) return;
      
      // Just calculate counts from the current state without reloading
      final totalPallets = widget.palletModel.pallets.length;
      final totalItems = widget.palletModel.pallets.fold<int>(
        0,
        (sum, pallet) => sum + pallet.items.length,
      );
      final totalTags = widget.savedTags.length;
      
      debugPrint('DataMigrationScreen: Calculated summary: $_totalPallets pallets, $_totalItems items, $_totalTags tags (without reloading)');
      
      if (mounted) {
        setState(() {
          _totalPallets = totalPallets;
          _totalItems = totalItems;
          _totalTags = totalTags;
          _isLoading = false;
          _dataLoaded = true; // Mark data as loaded to prevent reload loops
        });
      }
      
      // Log data counts for debugging
      debugPrint('Migration screen loaded data: $_totalPallets pallets, $_totalItems items, $_totalTags tags');
    } catch (e) {
      debugPrint('DataMigrationScreen: Error loading data: $e');
      if (!mounted || _isDisposed) return;
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
        _dataLoaded = true; // Even on error, mark as loaded to prevent loops
      });
    }
  }

  Future<void> _startMigration() async {
    if (_isDisposed || _isLoading) return;
    
    debugPrint('DataMigrationScreen: Starting migration process (manually triggered)');
    
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Verify user is authenticated
      final supabaseService = SupabaseService.instance;
      final currentUser = supabaseService.currentUser;
      
      if (currentUser == null) {
        debugPrint('DataMigrationScreen: Migration failed - user not authenticated');
        throw Exception('User must be logged in to migrate data');
      }

      // Add a small delay to ensure UI state is updated
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (_isDisposed || !mounted) return;

      // Use the simplified migration method from PalletModel
      debugPrint('DataMigrationScreen: Starting data migration to Supabase...');
      final success = await widget.palletModel.migrateDataToSupabase();
      
      if (_isDisposed || !mounted) return;
      
      if (success) {
        debugPrint('DataMigrationScreen: ✅ Migration completed successfully');
        // Ensure we force data reload to see the migrated data
        debugPrint('DataMigrationScreen: Reloading data after successful migration');
        await widget.palletModel.forceDataReload();
        
        if (mounted) {
          setState(() {
            _migrationComplete = true;
            _isLoading = false;
          });
          
          // REMOVED: No longer automatically calling onMigrationComplete
          // The user will now need to explicitly tap the "Continue" button
          debugPrint('DataMigrationScreen: Migration UI updated to show success state');
        }
      } else {
        debugPrint('DataMigrationScreen: ❌ Migration failed');
        if (mounted) {
          setState(() {
            _errorMessage = 'Migration failed. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('DataMigrationScreen: Migration error: $e');
      if (!mounted || _isDisposed) return;
      setState(() {
        _errorMessage = 'Migration failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Migration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildMigrationSummary(),
              const SizedBox(height: 24),
              
              if (_migrationComplete) 
                _buildSuccessView() 
              else if (_isLoading) 
                _buildProgressIndicator() 
              else if (_errorMessage != null) 
                _buildErrorView() 
              else 
                _buildStartButton(),
                
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.cloud_upload, size: 64, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          'One-Time Migration to Cloud',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Your data is currently stored locally on your device. This one-time migration will permanently move your data to our secure cloud storage.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: const Column(
            children: [
              Text(
                'Important: After migration',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Your data will exist only in the cloud\n'
                '• You\'ll need internet access to use the app\n'
                '• Your local data will be cleared\n'
                '• You cannot switch back to local storage',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMigrationSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Migration Summary:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildSummaryItem('Pallets', _totalPallets),
            _buildSummaryItem('Tags', _totalTags),
            _buildSummaryItem('Items', _totalItems),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
        const SizedBox(height: 16),
        Text(
          'Migration Complete!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your data has been successfully migrated to the cloud. Local data has been cleared.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.green),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: const Text(
            'Your app is now in cloud-only mode. You\'ll need internet access to use the app.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            // Use stronger navigation to ensure we properly move to the home screen
            debugPrint('Navigating away from migration screen to home');
            
            // First trigger the callback to update parent state
            widget.onMigrationComplete();
            
            // Navigate to home screen with a slight delay to ensure callback is processed
            Future.delayed(Duration.zero, () {
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
          child: const Text('CONTINUE TO CLOUD APP'),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      children: [
        // Error message
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 24),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startMigration,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('RETRY MIGRATION'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                debugPrint('User chose to continue without migrating');
                widget.onMigrationComplete();
                
                // Use a microtask to ensure the callback is processed first
                Future.microtask(() {
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('CONTINUE WITHOUT MIGRATING'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Note: You can attempt migration later from the Settings screen.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _startMigration,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
        backgroundColor: Colors.blue,
      ),
      child: const Text(
        'Start One-Way Migration',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(
          'Migrating data to the cloud...',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Please wait while your data is being transferred.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 