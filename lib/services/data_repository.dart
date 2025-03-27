import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pallet_manager/pallet_model.dart';
import 'package:pallet_manager/services/supabase_service.dart';

enum DataSource {
  sharedPreferences,
  supabase,
}

class DataRepository with ChangeNotifier {
  // Current data source
  DataSource _dataSource = DataSource.sharedPreferences;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasMigratedData = false;
  String? _error;

  // Getters
  DataSource get dataSource => _dataSource;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasMigratedData => _hasMigratedData;
  String? get error => _error;

  // Initialize the repository with the desired data source
  Future<void> initialize(DataSource source) async {
    await _performOperation(
      operation: () async {
        _dataSource = source;
        
        // Always check SharedPreferences for migration status regardless of data source
        final prefs = await SharedPreferences.getInstance();
        _hasMigratedData = prefs.getBool('has_migrated_data') ?? false;
        
        // If using Supabase and we're authenticated, double-check migration status 
        if (source == DataSource.supabase && SupabaseService.instance.currentUser != null) {
          // If we need to verify migration status from the server, do it here
          try {
            // Try to get pallets as a way to check if user has data in Supabase
            final pallets = await SupabaseService.instance.getPallets();
            if (pallets.isNotEmpty && !_hasMigratedData) {
              // User has data in Supabase but migration flag isn't set, let's set it
              await prefs.setBool('has_migrated_data', true);
              _hasMigratedData = true;
            }
          } catch (e) {
            debugPrint('Error checking migration status from server: $e');
            // Continue without setting migration flag
          }
        }
        
        _isInitialized = true;
        notifyListeners();
      },
      errorMessage: 'Failed to initialize data repository',
    );
  }

  // Switch between data sources - ONLY used before migration
  Future<void> setDataSource(DataSource source) async {
    // If already using requested source, do nothing
    if (_dataSource == source) return;

    // If migration is complete, NEVER allow switching data sources
    if (_hasMigratedData) {
      debugPrint('Migration is complete, data sources cannot be changed');
      return;
    }

    await _performOperation(
      operation: () async {
        debugPrint('Switching data source from $_dataSource to $source');
        _dataSource = source;
        notifyListeners();
      },
      errorMessage: 'Failed to switch data source',
    );
  }

  // Check if user is authenticated (only relevant for Supabase)
  bool get isAuthenticated {
    if (_dataSource == DataSource.sharedPreferences) return true;
    return SupabaseService.instance.currentUser != null;
  }

  // PALLETS

  // Load pallets from the current data source
  Future<List<Pallet>> loadPallets() async {
    return _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          return _loadPalletsFromSharedPreferences();
        }
        return _loadPalletsFromSupabase();
      },
      errorMessage: 'Failed to load pallets',
      defaultValue: [],
    );
  }

  // Pallets from SharedPreferences
  Future<List<Pallet>> _loadPalletsFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final palletsJson = prefs.getString('pallets');
    print('📊 Loading pallets from SharedPreferences...');
    
    if (palletsJson == null) {
      print('❌ No pallets data found in SharedPreferences');
      await _debugPrintSharedPrefsContents();
      return [];
    }
    
    try {
      print('📦 Found pallets JSON of length: ${palletsJson.length}');
      final List<dynamic> palletsList = json.decode(palletsJson);
      print('📋 Successfully decoded JSON, found ${palletsList.length} pallets');
      
      if (palletsList.isEmpty) {
        print('⚠️ Warning: Pallets list is empty after decoding');
        return [];
      }
      
      // Test parse one pallet to catch issues
      try {
        final testPallet = Pallet.fromJson(palletsList.first);
        print('✅ Successfully test-parsed first pallet: ${testPallet.name}');
      } catch (e) {
        print('⚠️ Warning: Error parsing test pallet: $e');
      }
      
      final result = palletsList.map((json) => Pallet.fromJson(json)).toList();
      print('✅ Successfully parsed ${result.length} pallets from SharedPreferences');
      return result;
    } catch (e) {
      print('❌ Error loading pallets from SharedPreferences: $e');
      
      // Try to show a sample of the data for debugging
      if (palletsJson != null && palletsJson.isNotEmpty) {
        final sample = palletsJson.length > 100 ? palletsJson.substring(0, 100) + '...' : palletsJson;
        print('📄 JSON sample: $sample');
      }
      
      // Check all SharedPreferences content
      await _debugPrintSharedPrefsContents();
      return [];
    }
  }

  // Debug helper to print all SharedPreferences contents
  Future<void> _debugPrintSharedPrefsContents() async {
    try {
      print('🔍 DEBUG: Examining all SharedPreferences contents...');
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      print('📑 Found ${keys.length} keys in SharedPreferences:');
      for (final key in keys) {
        try {
          if (key == 'pallets') {
            final palletStr = prefs.getString(key);
            print('  - $key: ${palletStr == null ? "null" : "${palletStr.length} chars"}');
          } else if (key == 'tags') {
            final tagsStr = prefs.getString(key);
            if (tagsStr != null) {
              try {
                final tagsList = json.decode(tagsStr);
                print('  - $key: ${tagsList.length} tags');
              } catch (e) {
                print('  - $key: Error decoding - $e');
              }
            } else {
              print('  - $key: null');
            }
          } else {
            // For other keys, just show their type and existence
            if (prefs.getString(key) != null) {
              print('  - $key: [String]');
            } else if (prefs.getBool(key) != null) {
              print('  - $key: [Bool] ${prefs.getBool(key)}');
            } else if (prefs.getInt(key) != null) {
              print('  - $key: [Int] ${prefs.getInt(key)}');
            } else if (prefs.getDouble(key) != null) {
              print('  - $key: [Double] ${prefs.getDouble(key)}');
            } else if (prefs.getStringList(key) != null) {
              print('  - $key: [StringList] ${prefs.getStringList(key)?.length} items');
            } else {
              print('  - $key: [Unknown type]');
            }
          }
        } catch (e) {
          print('  - $key: Error getting value - $e');
        }
      }
      
      print('🔍 SharedPreferences examination complete');
    } catch (e) {
      print('❌ Error examining SharedPreferences: $e');
    }
  }

  // Pallets from Supabase
  Future<List<Pallet>> _loadPalletsFromSupabase() async {
    try {
      debugPrint('REPOSITORY: Loading pallets directly from Supabase');
      if (SupabaseService.instance.currentUser == null) {
        debugPrint('REPOSITORY: Cannot load pallets from Supabase: User not authenticated');
        return [];
      }
      
      debugPrint('REPOSITORY: User authenticated, attempting to get pallets from Supabase');
      final pallets = await SupabaseService.instance.getPallets();
      debugPrint('REPOSITORY: Loaded ${pallets.length} pallets from Supabase');
      
      // Log first pallet for debugging
      if (pallets.isNotEmpty) {
        final firstPallet = pallets.first;
        debugPrint('REPOSITORY: First pallet: ${firstPallet.name} with ${firstPallet.items.length} items');
      }
      
      return pallets;
    } catch (e) {
      debugPrint('REPOSITORY: Error loading pallets from Supabase: $e');
      // Include stack trace for better debugging
      debugPrint('REPOSITORY: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Save pallets to the current data source
  Future<void> savePallets(List<Pallet> pallets) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          await _savePalletsToSharedPreferences(pallets);
        } else {
          await _savePalletsToSupabase(pallets);
        }
      },
      errorMessage: 'Failed to save pallets',
    );
  }

  // Save pallets to SharedPreferences
  Future<void> _savePalletsToSharedPreferences(List<Pallet> pallets) async {
    final prefs = await SharedPreferences.getInstance();
    final palletsJson = json.encode(pallets.map((p) => p.toJson()).toList());
    await prefs.setString('pallets', palletsJson);
  }

  // Add a single pallet
  Future<void> addPallet(Pallet pallet) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          final pallets = await _loadPalletsFromSharedPreferences();
          pallets.add(pallet);
          await _savePalletsToSharedPreferences(pallets);
        } else {
          // For Supabase, we just create the pallet
          // Items will be added separately through createPalletItem
          await SupabaseService.instance.createPallet(pallet);
        }
      },
      errorMessage: 'Failed to add pallet',
    );
  }

  // Remove a pallet from the repository
  Future<void> removePallet(Pallet pallet) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          final pallets = await _loadPalletsFromSharedPreferences();
          pallets.removeWhere((p) => p.id == pallet.id);
          await _savePalletsToSharedPreferences(pallets);
          debugPrint('Removed pallet ${pallet.id} from SharedPreferences');
        } else {
          // For Supabase, we need to delete the pallet
          debugPrint('Removing pallet ${pallet.id} from Supabase');
          await SupabaseService.instance.deletePallet(pallet.id);
        }
      },
      errorMessage: 'Failed to remove pallet',
    );
  }

  // Remove a pallet item from the repository
  Future<void> removePalletItem(int palletId, int itemId) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          final pallets = await _loadPalletsFromSharedPreferences();
          final palletIndex = pallets.indexWhere((p) => p.id == palletId);
          
          if (palletIndex >= 0) {
            pallets[palletIndex].items.removeWhere((i) => i.id == itemId);
            await _savePalletsToSharedPreferences(pallets);
            debugPrint('Removed item $itemId from pallet $palletId in SharedPreferences');
          }
        } else {
          // For Supabase, we need to find the pallet first, then delete the item
          debugPrint('Removing item $itemId from pallet $palletId in Supabase');
          await SupabaseService.instance.deletePalletItem(palletId, itemId);
        }
      },
      errorMessage: 'Failed to remove pallet item',
    );
  }

  // TAGS

  // Load tags from the current data source
  Future<Set<String>> loadTags() async {
    return _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          return _loadTagsFromSharedPreferences();
        }
        return await SupabaseService.instance.getTags();
      },
      errorMessage: 'Failed to load tags',
      defaultValue: {},
    );
  }

  // Tags from SharedPreferences
  Future<Set<String>> _loadTagsFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final tagsJson = prefs.getString('tags');
    if (tagsJson == null) return {};
    
    final List<dynamic> tagsList = json.decode(tagsJson);
    return tagsList.map((tag) => tag.toString()).toSet();
  }

  // Save tags to the current data source
  Future<void> saveTags(Set<String> tags) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          await _saveTagsToSharedPreferences(tags);
        } else {
          for (final tag in tags) {
            await SupabaseService.instance.createTag(tag);
          }
        }
      },
      errorMessage: 'Failed to save tags',
    );
  }

  // Save tags to SharedPreferences
  Future<void> _saveTagsToSharedPreferences(Set<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final tagsJson = json.encode(tags.toList());
    await prefs.setString('tags', tagsJson);
  }

  // Add a tag
  Future<void> addTag(String tag) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          final tags = await _loadTagsFromSharedPreferences();
          tags.add(tag);
          await _saveTagsToSharedPreferences(tags);
        } else {
          await SupabaseService.instance.createTag(tag);
        }
      },
      errorMessage: 'Failed to add tag',
    );
  }

  // Remove a tag
  Future<void> removeTag(String tag) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          final tags = await _loadTagsFromSharedPreferences();
          tags.remove(tag);
          await _saveTagsToSharedPreferences(tags);
        } else {
          await SupabaseService.instance.deleteTag(tag);
        }
      },
      errorMessage: 'Failed to remove tag',
    );
  }

  // COUNTERS

  // Load counters from SharedPreferences (Supabase doesn't use these)
  Future<Map<String, int>> loadCounters() async {
    if (_dataSource == DataSource.supabase) {
      return {'palletIdCounter': 1, 'itemIdCounter': 1};
    }

    return _performOperation(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        return {
          'palletIdCounter': prefs.getInt('palletIdCounter') ?? 1,
          'itemIdCounter': prefs.getInt('itemIdCounter') ?? 1,
        };
      },
      errorMessage: 'Failed to load counters',
      defaultValue: {'palletIdCounter': 1, 'itemIdCounter': 1},
    );
  }

  // Save counters to SharedPreferences (Supabase doesn't use these)
  Future<void> saveCounters({
    required int palletIdCounter,
    required int itemIdCounter,
  }) async {
    if (_dataSource == DataSource.supabase) return;

    await _performOperation(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('palletIdCounter', palletIdCounter);
        await prefs.setInt('itemIdCounter', itemIdCounter);
      },
      errorMessage: 'Failed to save counters',
    );
  }

  // MIGRATION

  // Add this method at the top of the class
  String _getUserFriendlyError(String errorCode, String message) {
    switch (errorCode) {
      case '42501':
        return 'Permission denied. Please check your account settings.';
      case '23503':
        return 'Data error: Related information is missing. Please try again.';
      case '23505':
        return 'This item already exists.';
      case '42P01':
        return 'Database error: Table not found. Please contact support.';
      default:
        return 'An error occurred: $message';
    }
  }

  // Migrate data from SharedPreferences to Supabase - THIS IS A ONE-WAY OPERATION
  Future<void> migrateDataToSupabase() async {
    if (_isLoading) return;
    
    // If already migrated, don't do it again
    if (_hasMigratedData) {
      debugPrint('REPOSITORY: Data already migrated, skipping migration');
      return;
    }
    
    await _performOperation(
      operation: () async {
        debugPrint('REPOSITORY: Starting one-way migration to Supabase...');
        
        // Check authentication
        if (!isAuthenticated) {
          throw Exception('User must be authenticated to migrate data to Supabase');
        }

        // Load data from SharedPreferences
        final pallets = await _loadPalletsFromSharedPreferences();
        final tags = await _loadTagsFromSharedPreferences();

        // Check if there's data to migrate
        if (pallets.isEmpty && tags.isEmpty) {
          debugPrint('REPOSITORY: No data to migrate, setting migration flag and switching to Supabase');
        } else {
          debugPrint('REPOSITORY: Migrating data from SharedPreferences to Supabase...');
          debugPrint('REPOSITORY: - ${pallets.length} pallets with ${pallets.fold(0, (sum, p) => sum + p.items.length)} items');
          debugPrint('REPOSITORY: - ${tags.length} tags');
          
          try {
            // Migrate tags first
            for (final tag in tags) {
              try {
                await SupabaseService.instance.createTag(tag);
              } catch (e) {
                debugPrint('REPOSITORY: Error migrating tag $tag: $e');
                // Continue with next tag if this one fails
              }
            }

            // Migrate pallets in batches
            const batchSize = 50;
            for (var i = 0; i < pallets.length; i += batchSize) {
              final batch = pallets.skip(i).take(batchSize).toList();
              debugPrint('REPOSITORY: Migrating batch ${(i ~/ batchSize) + 1} of ${(pallets.length / batchSize).ceil()}');
              
              for (final pallet in batch) {
                try {
                  // Create pallet
                  final palletResponse = await SupabaseService.instance.createPallet(pallet);
                  final supabasePalletId = palletResponse['id'];
                  
                  // Migrate items in smaller batches
                  const itemBatchSize = 20;
                  for (var j = 0; j < pallet.items.length; j += itemBatchSize) {
                    final itemBatch = pallet.items.skip(j).take(itemBatchSize).toList();
                    for (final item in itemBatch) {
                      try {
                        await SupabaseService.instance.createPalletItem(item, supabasePalletId);
                      } catch (e) {
                        debugPrint('REPOSITORY: Error migrating item ${item.id} for pallet ${pallet.id}: $e');
                        // Continue with next item if this one fails
                      }
                    }
                  }
                } catch (e) {
                  debugPrint('REPOSITORY: Error migrating pallet ${pallet.id}: $e');
                  // Continue with next pallet if this one fails
                }
              }
            }
            
            debugPrint('REPOSITORY: Data migration completed successfully');
          } catch (e) {
            debugPrint('REPOSITORY: Error during data migration: $e');
            rethrow;
          }
        }

        // Set migration flag - THIS SHOULD ONLY HAPPEN ONCE
        _hasMigratedData = true;
        final prefs = await SharedPreferences.getInstance();
        debugPrint('REPOSITORY: Setting migration flag in SharedPreferences...');
        await prefs.setBool('has_migrated_data', true);
        debugPrint('REPOSITORY: Migration flag set successfully');
        
        // Switch to Supabase permanently - NO GOING BACK
        _dataSource = DataSource.supabase;
        
        // Clear local data after migration is complete since we're fully committed to cloud storage
        await _clearLocalData();
        
        notifyListeners();
        debugPrint('REPOSITORY: Migration to Supabase complete - App is now in CLOUD-ONLY mode');
      },
      errorMessage: 'Failed to migrate data to Supabase',
    );
  }

  Future<T> _performOperation<T>({
    required Future<T> Function() operation,
    required String errorMessage,
    T? defaultValue,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await operation();
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      if (e is PostgrestException) {
        debugPrint('REPOSITORY: Postgrest error - code: ${e.code}, message: ${e.message}, details: ${e.details}, hint: ${e.hint}');
        _error = _getUserFriendlyError(e.code, e.message);
      } else {
        debugPrint('REPOSITORY: Operation error: $e');
        _error = '$errorMessage: ${e.toString()}';
      }
      
      if (defaultValue != null) return defaultValue;
      rethrow;
    }
  }

  Future<void> _clearLocalData() async {
    debugPrint('🗑️ Clearing local data after migration...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pallets');
    await prefs.remove('tags');
    await prefs.remove('palletIdCounter');
    await prefs.remove('itemIdCounter');
    debugPrint('✅ Local data cleared successfully');
  }

  Future<void> _savePalletsToSupabase(List<Pallet> pallets) async {
    for (final pallet in pallets) {
      await SupabaseService.instance.createPallet(pallet);
    }
  }

  // Add a pallet item
  Future<void> addPalletItem(int palletId, PalletItem item) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          final pallets = await _loadPalletsFromSharedPreferences();
          final palletIndex = pallets.indexWhere((p) => p.id == palletId);
          
          if (palletIndex >= 0) {
            pallets[palletIndex].items.add(item);
            await _savePalletsToSharedPreferences(pallets);
          }
        } else {
          // Find the Supabase pallet ID first
          final response = await SupabaseService.instance.client
            .from('pallets')
            .select('id')
            .eq('original_id', palletId)
            .eq('user_id', SupabaseService.instance.currentUser!.id)
            .single();
            
          final supabasePalletId = response['id'];
          await SupabaseService.instance.createPalletItem(item, supabasePalletId);
        }
      },
      errorMessage: 'Failed to add pallet item',
    );
  }

  // Update a pallet
  Future<void> updatePallet(int palletId, Map<String, dynamic> updateData) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          final pallets = await _loadPalletsFromSharedPreferences();
          final palletIndex = pallets.indexWhere((p) => p.id == palletId);
          
          if (palletIndex >= 0) {
            // Update fields based on updateData
            if (updateData.containsKey('name')) {
              pallets[palletIndex].name = updateData['name'];
            }
            if (updateData.containsKey('tag')) {
              pallets[palletIndex].tag = updateData['tag'];
            }
            if (updateData.containsKey('is_closed')) {
              pallets[palletIndex].isClosed = updateData['is_closed'];
            }
            
            await _savePalletsToSharedPreferences(pallets);
          }
        } else {
          await SupabaseService.instance.client
            .from('pallets')
            .update(updateData)
            .eq('original_id', palletId)
            .eq('user_id', SupabaseService.instance.currentUser!.id);
        }
      },
      errorMessage: 'Failed to update pallet',
    );
  }

  // Update a pallet item
  Future<void> updatePalletItem(int palletId, int itemId, Map<String, dynamic> updateData) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          final pallets = await _loadPalletsFromSharedPreferences();
          final palletIndex = pallets.indexWhere((p) => p.id == palletId);
          
          if (palletIndex >= 0) {
            final itemIndex = pallets[palletIndex].items.indexWhere((i) => i.id == itemId);
            
            if (itemIndex >= 0) {
              final item = pallets[palletIndex].items[itemIndex];
              
              // Update fields based on updateData
              if (updateData.containsKey('name')) {
                item.name = updateData['name'];
              }
              if (updateData.containsKey('is_sold')) {
                item.isSold = updateData['is_sold'];
              }
              if (updateData.containsKey('sale_price')) {
                item.salePrice = updateData['sale_price'];
              }
              if (updateData.containsKey('sale_date') && updateData['sale_date'] != null) {
                item.saleDate = DateTime.parse(updateData['sale_date']);
              }
              if (updateData.containsKey('allocated_cost')) {
                item.allocatedCost = updateData['allocated_cost'];
              }
              
              await _savePalletsToSharedPreferences(pallets);
            }
          }
        } else {
          // Find the Supabase pallet ID first
          final palletResponse = await SupabaseService.instance.client
            .from('pallets')
            .select('id')
            .eq('original_id', palletId)
            .eq('user_id', SupabaseService.instance.currentUser!.id)
            .single();
            
          final supabasePalletId = palletResponse['id'];
          
          // Update the item
          await SupabaseService.instance.client
            .from('pallet_items')
            .update(updateData)
            .eq('pallet_id', supabasePalletId)
            .eq('original_id', itemId);
        }
      },
      errorMessage: 'Failed to update pallet item',
    );
  }

  // Reset migration status when switching users
  Future<void> resetMigrationStatus() async {
    await _performOperation(
      operation: () async {
        debugPrint('Resetting migration status for new user');
        _hasMigratedData = false;
        _dataSource = DataSource.sharedPreferences;
        _isInitialized = true;
        
        // Update shared preferences to reflect this change
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_migrated_data', false);
        
        notifyListeners();
        debugPrint('Migration status reset completed');
      },
      errorMessage: 'Failed to reset migration status',
    );
  }
  
  // Force reload data from storage - useful for migration checks
  Future<void> forceDataReload() async {
    await _performOperation(
      operation: () async {
        debugPrint('Forcing data reload from ${_dataSource.toString()}');
        
        // Check migration status from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        _hasMigratedData = prefs.getBool('has_migrated_data') ?? false;
        
        // If we need to verify Supabase data existence, do it here
        if (_dataSource == DataSource.supabase && SupabaseService.instance.currentUser != null) {
          try {
            // Check if the user has data in Supabase
            final pallets = await SupabaseService.instance.getPallets();
            debugPrint('Found ${pallets.length} pallets in Supabase during force reload');
            
            // If the user has data in Supabase but migration flag isn't set, update it
            if (pallets.isNotEmpty && !_hasMigratedData) {
              debugPrint('User has data in Supabase but migration flag not set - updating flag');
              await prefs.setBool('has_migrated_data', true);
              _hasMigratedData = true;
            }
          } catch (e) {
            debugPrint('Error checking Supabase data during force reload: $e');
          }
        }
        
        notifyListeners();
        debugPrint('Force reload completed - Migration status: $_hasMigratedData');
      },
      errorMessage: 'Failed to force data reload',
    );
  }

  // Load pallets string directly from SharedPreferences (for migration)
  Future<String?> loadPalletsString() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pallets');
  }

  // Load pallets directly from Supabase (for migration and testing)
  Future<List<Pallet>> loadPalletsFromSupabase() async {
    return _performOperation(
      operation: () async {
        debugPrint('REPOSITORY-PUBLIC: Loading pallets directly from Supabase');
        if (SupabaseService.instance.currentUser == null) {
          debugPrint('REPOSITORY-PUBLIC: Cannot load pallets from Supabase: User not authenticated');
          return [];
        }
        
        debugPrint('REPOSITORY-PUBLIC: User authenticated, attempting to get pallets from Supabase');
        final pallets = await SupabaseService.instance.getPallets();
        debugPrint('REPOSITORY-PUBLIC: Loaded ${pallets.length} pallets from Supabase');
        
        // Log first pallet for debugging
        if (pallets.isNotEmpty) {
          final firstPallet = pallets.first;
          debugPrint('REPOSITORY-PUBLIC: First pallet: ${firstPallet.name} with ${firstPallet.items.length} items');
        }
        
        return pallets;
      },
      errorMessage: 'Failed to load pallets from Supabase',
      defaultValue: [],
    );
  }

  // Create a pallet in Supabase during migration
  Future<Pallet?> createPalletInSupabase(Pallet pallet) async {
    return _performOperation(
      operation: () async {
        debugPrint('REPOSITORY: Creating pallet in Supabase: ${pallet.name}');
        if (SupabaseService.instance.currentUser == null) {
          debugPrint('REPOSITORY: Cannot create pallet: User not authenticated');
          throw Exception('User must be authenticated to create pallet');
        }
        
        try {
          final response = await SupabaseService.instance.createPallet(pallet);
          final palletId = response['id'];
          debugPrint('REPOSITORY: Created pallet in Supabase with ID: $palletId');
          
          // Create a copy of the pallet with the Supabase ID
          final createdPallet = Pallet(
            id: pallet.id, // Keep original ID for reference
            name: pallet.name,
            tag: pallet.tag,
            date: pallet.date,
            totalCost: pallet.totalCost,
            isClosed: pallet.isClosed,
            items: pallet.items,
            supabaseId: palletId, // Add Supabase ID
          );
          
          return createdPallet;
        } catch (e) {
          debugPrint('REPOSITORY: Error creating pallet in Supabase: $e');
          debugPrint('REPOSITORY: Stack trace: ${StackTrace.current}');
          return null;
        }
      },
      errorMessage: 'Failed to create pallet in Supabase',
      defaultValue: null,
    );
  }
  
  // Create a pallet item in Supabase during migration
  Future<int?> createPalletItemInSupabase(PalletItem item, int palletId) async {
    return _performOperation(
      operation: () async {
        debugPrint('REPOSITORY: Creating pallet item in Supabase for pallet $palletId');
        if (SupabaseService.instance.currentUser == null) {
          debugPrint('REPOSITORY: Cannot create pallet item: User not authenticated');
          throw Exception('User must be authenticated to create pallet item');
        }
        
        return await SupabaseService.instance.createPalletItem(item, palletId);
      },
      errorMessage: 'Failed to create pallet item in Supabase',
      defaultValue: null,
    );
  }
  
  // Clear local data after migration
  Future<void> clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Keep the migration flag
      final hasMigrated = prefs.getBool('has_migrated_data') ?? false;
      
      // Clear pallets and tags data
      await prefs.remove('pallets');
      await prefs.remove('tags');
      await prefs.remove('palletIdCounter');
      await prefs.remove('itemIdCounter');
      
      // Restore migration flag
      await prefs.setBool('has_migrated_data', hasMigrated);
      
      debugPrint('Local data cleared from SharedPreferences');
    } catch (e) {
      debugPrint('Error clearing local data: $e');
      rethrow;
    }
  }
  
  // Set migration completed flag
  Future<void> setMigrationCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_migrated_data', completed);
      _hasMigratedData = completed;
      notifyListeners();
      debugPrint('Migration completed flag set to $completed in SharedPreferences');
    } catch (e) {
      debugPrint('Error setting migration flag: $e');
      rethrow;
    }
  }
} 