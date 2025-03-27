import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pallet_manager/pallet_model.dart';
import 'package:pallet_manager/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pallet_manager/utils/log_utils.dart';

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
            LogUtils.error('Error checking migration status from server', e);
            // Continue without setting migration flag
          }
        }
        
        _isInitialized = true;
        notifyListeners();
      },
      operationName: 'initialize data repository',
    );
  }

  // Switch between data sources - ONLY used before migration
  Future<void> setDataSource(DataSource source) async {
    // If already using requested source, do nothing
    if (_dataSource == source) return;

    // If migration is complete, NEVER allow switching data sources
    if (_hasMigratedData) {
      LogUtils.warning('Migration is complete, data sources cannot be changed');
      return;
    }

    await _performOperation(
      operation: () async {
        LogUtils.info('Switching data source from $_dataSource to $source');
        _dataSource = source;
        notifyListeners();
      },
      operationName: 'switch data source',
    );
  }

  // Check if user is authenticated (only relevant for Supabase)
  bool get isAuthenticated {
    if (_dataSource == DataSource.sharedPreferences) return true;
    return SupabaseService.instance.currentUser != null;
  }

  // PALLETS

  // Load pallets from the repository
  Future<List<Pallet>> loadPallets({bool lazyLoadItems = false}) async {
    return _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          // Local storage doesn't support lazy loading
          return _loadPalletsFromSharedPreferences();
        } else {
          return _loadPalletsFromSupabase(lazyLoadItems: lazyLoadItems);
        }
      },
      operationName: 'load pallets',
    );
  }

  // Load pallets from Supabase
  Future<List<Pallet>> _loadPalletsFromSupabase({bool lazyLoadItems = false}) async {
    LogUtils.info('REPOSITORY: Loading pallets from Supabase (lazyLoadItems=$lazyLoadItems)');
    if (SupabaseService.instance.currentUser == null) {
      LogUtils.warning('REPOSITORY: Cannot load pallets from Supabase: User not authenticated');
      return [];
    }
    
    LogUtils.info('REPOSITORY: User authenticated, attempting to get pallets from Supabase');
    try {
      if (lazyLoadItems) {
        // Only load pallet headers without items for better performance
        final pallets = await SupabaseService.instance.getPalletHeaders();
        LogUtils.info('REPOSITORY: Loaded ${pallets.length} pallet headers (lazy loading)');
        return pallets;
      } else {
        // Load complete pallets with all items
        final pallets = await SupabaseService.instance.getPallets();
        LogUtils.info('REPOSITORY: Loaded ${pallets.length} pallets with items');
        return pallets;
      }
    } catch (e) {
      LogUtils.error('REPOSITORY: Error loading pallets from Supabase', e);
      return [];
    }
  }
  
  // Load items for a specific pallet (for lazy loading)
  Future<List<PalletItem>> loadPalletItems(int palletId) async {
    return _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          // For SharedPreferences, find the pallet and return its items
          final pallets = await _loadPalletsFromSharedPreferences();
          final pallet = pallets.firstWhere(
            (p) => p.id == palletId, 
            orElse: () => Pallet(
              id: -1, 
              name: 'Not Found', 
              tag: '', 
              totalCost: 0, 
              date: DateTime.now()
            ),
          );
          return pallet.id != -1 ? pallet.items : [];
        } else {
          // For Supabase, load items for this specific pallet
          return await SupabaseService.instance.getPalletItemsById(palletId);
        }
      },
      operationName: 'load pallet items',
    );
  }

  // Pallets from SharedPreferences
  Future<List<Pallet>> _loadPalletsFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final palletsJson = prefs.getString('pallets');
    LogUtils.info('📊 Loading pallets from SharedPreferences...');
    
    if (palletsJson == null) {
      LogUtils.warning('❌ No pallets data found in SharedPreferences');
      await _debugPrintSharedPrefsContents();
      return [];
    }
    
    try {
      LogUtils.info('📦 Found pallets JSON of length: ${palletsJson.length}');
      final List<dynamic> palletsList = json.decode(palletsJson);
      LogUtils.info('📋 Successfully decoded JSON, found ${palletsList.length} pallets');
      
      if (palletsList.isEmpty) {
        LogUtils.warning('⚠️ Warning: Pallets list is empty after decoding');
        return [];
      }
      
      // Test parse one pallet to catch issues
      try {
        final testPallet = Pallet.fromJson(palletsList.first);
        LogUtils.info('✅ Successfully test-parsed first pallet: ${testPallet.name}');
      } catch (e) {
        LogUtils.warning('⚠️ Warning: Error parsing test pallet: $e');
      }
      
      final result = palletsList.map((json) => Pallet.fromJson(json)).toList();
      LogUtils.info('✅ Successfully parsed ${result.length} pallets from SharedPreferences');
      return result;
    } catch (e) {
      LogUtils.error('❌ Error loading pallets from SharedPreferences', e);
      
      // Try to show a sample of the data for debugging
      if (palletsJson != null && palletsJson.isNotEmpty) {
        final sample = palletsJson.length > 100 ? palletsJson.substring(0, 100) + '...' : palletsJson;
        LogUtils.log('DEBUG', '📄 JSON sample: $sample');
      }
      
      // Check all SharedPreferences content
      await _debugPrintSharedPrefsContents();
      return [];
    }
  }

  // Debug helper to print all SharedPreferences contents
  Future<void> _debugPrintSharedPrefsContents() async {
    try {
      LogUtils.log('DEBUG', '🔍 Examining all SharedPreferences contents...');
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      LogUtils.log('DEBUG', '📑 Found ${keys.length} keys in SharedPreferences:');
      for (final key in keys) {
        try {
          if (key == 'pallets') {
            final palletStr = prefs.getString(key);
            LogUtils.log('DEBUG', '  - $key: ${palletStr == null ? "null" : "${palletStr.length} chars"}');
          } else if (key == 'tags') {
            final tagsStr = prefs.getString(key);
            if (tagsStr != null) {
              try {
                final tagsList = json.decode(tagsStr);
                LogUtils.log('DEBUG', '  - $key: ${tagsList.length} tags');
              } catch (e) {
                LogUtils.log('DEBUG', '  - $key: Error decoding - $e');
              }
            } else {
              LogUtils.log('DEBUG', '  - $key: null');
            }
          } else {
            // For other keys, just show their type and existence
            if (prefs.getString(key) != null) {
              LogUtils.log('DEBUG', '  - $key: [String]');
            } else if (prefs.getBool(key) != null) {
              LogUtils.log('DEBUG', '  - $key: [Bool] ${prefs.getBool(key)}');
            } else if (prefs.getInt(key) != null) {
              LogUtils.log('DEBUG', '  - $key: [Int] ${prefs.getInt(key)}');
            } else if (prefs.getDouble(key) != null) {
              LogUtils.log('DEBUG', '  - $key: [Double] ${prefs.getDouble(key)}');
            } else if (prefs.getStringList(key) != null) {
              LogUtils.log('DEBUG', '  - $key: [StringList] ${prefs.getStringList(key)?.length} items');
            } else {
              LogUtils.log('DEBUG', '  - $key: [Unknown type]');
            }
          }
        } catch (e) {
          LogUtils.error('  - $key: Error getting value', e);
        }
      }
      
      LogUtils.log('DEBUG', '🔍 SharedPreferences examination complete');
    } catch (e) {
      LogUtils.error('❌ Error examining SharedPreferences', e);
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
      operationName: 'save pallets',
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
      operationName: 'add pallet',
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
          LogUtils.info('Removed pallet ${pallet.id} from SharedPreferences');
        } else {
          // For Supabase, we need to delete the pallet using the supabaseId if available
          LogUtils.info('Removing pallet from Supabase, originalId: ${pallet.id}, supabaseId: ${pallet.supabaseId}');
          if (pallet.supabaseId != null) {
            // Use the direct Supabase ID if available
            await SupabaseService.instance.client
              .from('pallets')
              .delete()
              .eq('id', pallet.supabaseId);
            LogUtils.info('Deleted pallet using supabaseId: ${pallet.supabaseId}');
          } else {
            // Fall back to looking up by original_id
            await SupabaseService.instance.deletePallet(pallet.id);
            LogUtils.info('Deleted pallet using original_id: ${pallet.id}');
          }
        }
      },
      operationName: 'remove pallet',
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
            final pallet = pallets[palletIndex];
            pallet.items.removeWhere((item) => item.id == itemId);
            await _savePalletsToSharedPreferences(pallets);
          }
        } else {
          // Find the pallet first
          final pallet = await _findPalletById(palletId);
          if (pallet == null) {
            LogUtils.warning('REPOSITORY: Cannot find pallet with ID $palletId');
            return;
          }
          
          // If we have the supabaseId, use it directly
          if (pallet.supabaseId != null) {
            await SupabaseService.instance.client
              .from('pallet_items')
              .delete()
              .eq('pallet_id', pallet.supabaseId)
              .eq('original_id', itemId);
            LogUtils.info('REPOSITORY: Deleted item using pallet supabaseId: ${pallet.supabaseId}');
          } else {
            // Fall back to the old method
            await SupabaseService.instance.deletePalletItem(palletId, itemId);
            LogUtils.info('REPOSITORY: Deleted item using pallet original_id: $palletId');
          }
        }
      },
      operationName: 'remove pallet item',
    );
  }
  
  // Helper method to find a pallet by ID (used by removePalletItem)
  Future<Pallet?> _findPalletById(int palletId) async {
    final pallets = await loadPallets();
    final palletIndex = pallets.indexWhere((p) => p.id == palletId);
    return palletIndex >= 0 ? pallets[palletIndex] : null;
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
      operationName: 'load tags',
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
      operationName: 'save tags',
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
      operationName: 'add tag',
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
      operationName: 'remove tag',
    );
  }

  // COUNTERS

  // Load ID counters from SharedPreferences
  Future<Map<String, int>> loadCounters() async {
    return _performOperation(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final palletIdCounter = prefs.getInt('palletIdCounter') ?? 1;
        final itemIdCounter = prefs.getInt('itemIdCounter') ?? 1;
        
        LogUtils.info('REPOSITORY: Loaded counters: palletIdCounter=$palletIdCounter, itemIdCounter=$itemIdCounter');
        
        return {
          'palletIdCounter': palletIdCounter,
          'itemIdCounter': itemIdCounter,
        };
      },
      operationName: 'load counters',
    ).catchError((e) {
      // Provide default values if there's an error
      LogUtils.error('Error loading counters', e);
      return {
        'palletIdCounter': 1,
        'itemIdCounter': 1,
      };
    });
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
      operationName: 'save counters',
    );
  }

  // MIGRATION

  // Get a user-friendly error message from a Supabase error code
  String _getUserFriendlyError(String? errorCode) {
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
        return 'An error occurred: $errorCode';
    }
  }

  // Helper method to handle Supabase API operations with consistent error handling
  Future<T> _performOperation<T>({
    required Future<T> Function() operation,
    required String operationName,
    bool useTransaction = false,
  }) async {
    try {
      // Check authentication state
      final user = SupabaseService.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Execute the operation
      return await operation();
    } catch (e) {
      // Enhanced error logging
      if (e is PostgrestException) {
        final code = e.code;
        final message = e.message;
        final details = e.details;
        final hint = e.hint;
        
        LogUtils.error(
          'Supabase operation error in $operationName: Code: $code, Message: $message',
          e
        );
        LogUtils.error('Details: $details, Hint: $hint');
        
        // Get user-friendly error message
        final friendlyMessage = _getUserFriendlyError(code);
        throw Exception('$operationName failed: $friendlyMessage');
      } else {
        LogUtils.error('Operation error in $operationName', e);
        throw Exception('$operationName failed: ${e.toString()}');
      }
    }
  }

  // Migrate data from SharedPreferences to Supabase
  Future<bool> migrateDataToSupabase() async {
    return _performOperation(
      operation: () async {
        LogUtils.info('REPOSITORY: Starting data migration to Supabase');
        
        // Check that we have an authenticated user
        if (SupabaseService.instance.currentUser == null) {
          LogUtils.warning('Cannot migrate data: User not authenticated');
          return false;
        }
        
        // Load data from SharedPreferences
        final pallets = await _loadPalletsFromSharedPreferences();
        final tags = await loadTags();
        
        LogUtils.info('REPOSITORY: Loaded ${pallets.length} pallets and ${tags.length} tags for migration');
        
        if (pallets.isEmpty) {
          LogUtils.warning('REPOSITORY: No data to migrate');
          return false;
        }
        
        // Batch size for migrations to avoid timeouts
        const int BATCH_SIZE = 10;
        int tagsMigrated = 0;
        int palletsMigrated = 0;
        int itemsMigrated = 0;
        int totalItems = 0;
        
        // Count total items for progress tracking
        for (final pallet in pallets) {
          totalItems += pallet.items.length;
        }
        
        LogUtils.info('REPOSITORY: Total items to migrate: $totalItems');
        
        // First migrate all tags
        try {
          // Tags are usually few, migrate them in one go
          for (final tag in tags) {
            try {
              await SupabaseService.instance.addTag(tag);
              tagsMigrated++;
            } catch (e) {
              LogUtils.error('Failed to migrate tag: $tag', e);
              // Continue with other tags
            }
          }
          
          LogUtils.info('REPOSITORY: Migrated $tagsMigrated/${tags.length} tags');
        } catch (e) {
          LogUtils.error('Error during tag migration batch', e);
          // Continue with pallets anyway
        }
        
        // Then migrate pallets in batches
        try {
          for (int i = 0; i < pallets.length; i += BATCH_SIZE) {
            final int end = (i + BATCH_SIZE < pallets.length) ? i + BATCH_SIZE : pallets.length;
            final batch = pallets.sublist(i, end);
            
            LogUtils.info('REPOSITORY: Processing pallet batch ${i+1}-$end of ${pallets.length}');
            
            for (final pallet in batch) {
              try {
                // First create the pallet header
                final createdPallet = await createPalletInSupabase(pallet);
                
                if (createdPallet != null) {
                  palletsMigrated++;
                  
                  // Then add all its items
                  for (final item in pallet.items) {
                    try {
                      await createPalletItemInSupabase(item, pallet.id);
                      itemsMigrated++;
                    } catch (e) {
                      LogUtils.error('Failed to migrate item: ${item.name}', e);
                      // Continue with other items
                    }
                  }
                }
              } catch (e) {
                LogUtils.error('Failed to migrate pallet: ${pallet.name}', e);
                // Continue with other pallets
              }
            }
            
            LogUtils.info('REPOSITORY: Progress: Migrated $palletsMigrated/${pallets.length} pallets and $itemsMigrated/$totalItems items');
          }
        } catch (e) {
          LogUtils.error('Error during pallet migration', e);
          // Check if we should consider the migration successful
          if (palletsMigrated > 0) {
            LogUtils.info('REPOSITORY: Partial migration completed successfully. Will save migration flag.');
          } else {
            LogUtils.error('REPOSITORY: Migration completely failed');
            return false;
          }
        }
        
        // Set migration flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_migrated_data', true);
        _hasMigratedData = true;
        
        // Clear local data - we're now in cloud-only mode
        _clearLocalData();
        
        // Set data source to Supabase permanently
        _dataSource = DataSource.supabase;
        
        LogUtils.info('REPOSITORY: Migration completed. Migrated $palletsMigrated/${pallets.length} pallets and $itemsMigrated/$totalItems items');
        notifyListeners();
        
        return palletsMigrated > 0;
      },
      operationName: 'migrate data to Supabase',
    );
  }

  // Reset migration status when switching users
  Future<void> resetMigrationStatus() async {
    await _performOperation(
      operation: () async {
        LogUtils.info('Resetting migration status for new user');
        _hasMigratedData = false;
        _dataSource = DataSource.sharedPreferences;
        _isInitialized = true;
        
        // Update shared preferences to reflect this change
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_migrated_data', false);
        
        notifyListeners();
        LogUtils.info('Migration status reset completed');
      },
      operationName: 'reset migration status',
    );
  }
  
  // Clear local SharedPreferences data when switching users
  Future<void> clearLocalData() async {
    await _performOperation(
      operation: () async {
        LogUtils.info('Clearing local SharedPreferences data');
        final prefs = await SharedPreferences.getInstance();
        
        // Only clear pallet-related data, keep other app settings
        await prefs.remove('pallets');
        await prefs.remove('tags');
        await prefs.remove('palletIdCounter');
        await prefs.remove('itemIdCounter');
        
        LogUtils.info('Local data cleared successfully');
      },
      operationName: 'clear local data',
    );
  }
  
  // Force reload data from storage - useful for migration checks
  Future<void> forceDataReload() async {
    await _performOperation(
      operation: () async {
        LogUtils.info('Forcing data reload from ${_dataSource.toString()}');
        
        // Check migration status from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        _hasMigratedData = prefs.getBool('has_migrated_data') ?? false;
        
        // If we need to verify Supabase data existence, do it here
        if (_dataSource == DataSource.supabase && SupabaseService.instance.currentUser != null) {
          try {
            // Check if the user has data in Supabase
            final pallets = await SupabaseService.instance.getPallets();
            LogUtils.info('Found ${pallets.length} pallets in Supabase during force reload');
            
            // If the user has data in Supabase but migration flag isn't set, update it
            if (pallets.isNotEmpty && !_hasMigratedData) {
              LogUtils.info('User has data in Supabase but migration flag not set - updating flag');
              await prefs.setBool('has_migrated_data', true);
              _hasMigratedData = true;
            }
          } catch (e) {
            LogUtils.error('Error checking Supabase data during force reload', e);
          }
        }
        
        notifyListeners();
        LogUtils.info('Force reload completed - Migration status: $_hasMigratedData');
      },
      operationName: 'force data reload',
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
        LogUtils.info('REPOSITORY-PUBLIC: Loading pallets directly from Supabase');
        if (SupabaseService.instance.currentUser == null) {
          LogUtils.warning('REPOSITORY-PUBLIC: Cannot load pallets from Supabase: User not authenticated');
          return [];
        }
        
        LogUtils.info('REPOSITORY-PUBLIC: User authenticated, attempting to get pallets from Supabase');
        final pallets = await SupabaseService.instance.getPallets();
        LogUtils.info('REPOSITORY-PUBLIC: Loaded ${pallets.length} pallets from Supabase');
        
        // Log first pallet for debugging
        if (pallets.isNotEmpty) {
          final firstPallet = pallets.first;
          LogUtils.info('REPOSITORY-PUBLIC: First pallet: ${firstPallet.name} with ${firstPallet.items.length} items');
        }
        
        return pallets;
      },
      operationName: 'load pallets from Supabase',
    );
  }

  // Create a pallet in Supabase during migration
  Future<Pallet?> createPalletInSupabase(Pallet pallet) async {
    return _performOperation(
      operation: () async {
        LogUtils.info('REPOSITORY: Creating pallet in Supabase: ${pallet.name}');
        if (SupabaseService.instance.currentUser == null) {
          LogUtils.warning('REPOSITORY: Cannot create pallet: User not authenticated');
          throw Exception('User must be authenticated to create pallet');
        }
        
        try {
          final response = await SupabaseService.instance.createPallet(pallet);
          final palletId = response['id'];
          LogUtils.info('REPOSITORY: Created pallet in Supabase with ID: $palletId');
          
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
          LogUtils.error('REPOSITORY: Error creating pallet in Supabase', e);
          LogUtils.error('REPOSITORY: Stack trace', null, StackTrace.current);
          return null;
        }
      },
      operationName: 'create pallet in Supabase',
    );
  }
  
  // Create a pallet item in Supabase during migration
  Future<Map<String, dynamic>?> createPalletItemInSupabase(PalletItem item, int palletId) async {
    return _performOperation(
      operation: () async {
        LogUtils.info('REPOSITORY: Creating pallet item in Supabase: ${item.name}');
        if (SupabaseService.instance.currentUser == null) {
          LogUtils.warning('REPOSITORY: Cannot create pallet item: User not authenticated');
          throw Exception('User must be authenticated to create pallet item');
        }
        
        try {
          // First find the Supabase pallet ID using the original_id
          final palletResponse = await SupabaseService.instance.client
            .from('pallets')
            .select('id')
            .eq('original_id', palletId)
            .eq('user_id', SupabaseService.instance.currentUser!.id)
            .single();
            
          final supabasePalletId = palletResponse['id'];
          LogUtils.info('REPOSITORY: Found Supabase pallet ID: $supabasePalletId for original ID: $palletId');
          
          // Prepare item data according to schema
          final itemData = {
            'pallet_id': supabasePalletId,
            'original_id': item.id,
            'name': item.name,
            'description': item.description ?? item.name,
            'is_sold': item.isSold,
            'allocated_cost': item.allocatedCost,
            'retail_price': item.retailPrice,
            'condition': item.condition,
            'list_price': item.listPrice,
            'product_code': item.productCode,
          };
          
          // Add optional fields only if they have values
          if (item.salePrice > 0) {
            itemData['sale_price'] = item.salePrice;
          }
          
          if (item.saleDate != null) {
            itemData['sale_date'] = item.saleDate!.toIso8601String();
          }
          
          // Insert the item
          final response = await SupabaseService.instance.client
            .from('pallet_items')
            .insert(itemData)
            .select()
            .single();
            
          LogUtils.info('REPOSITORY: Created pallet item in Supabase with ID: ${response['id']}');
          return response;
        } catch (e) {
          LogUtils.error('REPOSITORY: Error creating pallet item in Supabase', e);
          rethrow;
        }
      },
      operationName: 'create pallet item in Supabase',
    );
  }
  
  // Set migration completed flag
  Future<void> setMigrationCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_migrated_data', completed);
      _hasMigratedData = completed;
      notifyListeners();
      LogUtils.info('Migration completed flag set to $completed in SharedPreferences');
    } catch (e) {
      LogUtils.error('Error setting migration flag', e);
      rethrow;
    }
  }
} 