import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pallet_manager/pallet_model.dart';
import 'package:pallet_manager/services/supabase_service.dart';
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
      errorMessage: 'Failed to initialize data repository',
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
      errorMessage: 'Failed to switch data source',
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
      errorMessage: 'Failed to load pallets',
      defaultValue: [],
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
      errorMessage: 'Failed to load pallet items',
      defaultValue: [],
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
      errorMessage: 'Failed to remove pallet item',
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
  Future<bool> migrateDataToSupabase() async {
    return _performOperation(
      operation: () async {
        LogUtils.info('Starting data migration to Supabase');
        
        if (SupabaseService.instance.currentUser == null) {
          LogUtils.warning('Cannot migrate data: User not authenticated');
          return false;
        }
        
        try {
          // First, load data from SharedPreferences
          final pallets = await _loadPalletsFromSharedPreferences();
          final tags = await _loadTags();
          
          LogUtils.info('Loaded ${pallets.length} pallets and ${tags.length} tags from SharedPreferences');
          
          // Check if we have any data to migrate
          if (pallets.isEmpty && tags.isEmpty) {
            LogUtils.info('No data to migrate');
            return false;
          }
          
          // Migrate in batches to prevent timeouts
          // First migrate tags (they're simpler)
          LogUtils.info('Migrating tags...');
          int tagsMigrated = 0;
          for (final tag in tags) {
            try {
              await SupabaseService.instance.createTag(tag);
              tagsMigrated++;
            } catch (e) {
              LogUtils.error('Failed to migrate tag: $tag', e);
              // Continue with next tag
            }
          }
          LogUtils.info('Migrated $tagsMigrated/${tags.length} tags');
          
          // Then migrate pallets and their items
          LogUtils.info('Migrating pallets...');
          int palletsMigrated = 0;
          int itemsMigrated = 0;
          int totalItems = pallets.fold(0, (sum, p) => sum + p.items.length);
          
          // Process pallets in batches of 5
          for (int i = 0; i < pallets.length; i += 5) {
            final batch = pallets.skip(i).take(5).toList();
            LogUtils.info('Processing batch ${(i ~/ 5) + 1}/${(pallets.length / 5).ceil()} (${batch.length} pallets)');
            
            for (final pallet in batch) {
              try {
                // Create the pallet in Supabase
                final createdPallet = await createPalletInSupabase(pallet);
                if (createdPallet != null) {
                  int batchItemsMigrated = 0;
                  // Migrate each item in the pallet
                  for (final item in pallet.items) {
                    try {
                      await createPalletItemInSupabase(item, createdPallet.id);
                      batchItemsMigrated++;
                      itemsMigrated++;
                    } catch (e) {
                      LogUtils.error('Failed to migrate item ${item.id} in pallet ${pallet.id}', e);
                      // Continue with next item
                    }
                  }
                  LogUtils.info('Migrated ${batchItemsMigrated}/${pallet.items.length} items for pallet ${pallet.id}');
                  palletsMigrated++;
                }
              } catch (e) {
                LogUtils.error('Failed to migrate pallet ${pallet.id}', e);
                // Continue with next pallet
              }
            }
            
            // Small delay to prevent rate limiting
            await Future.delayed(Duration(milliseconds: 500));
          }
          
          LogUtils.info('Migrated $palletsMigrated/${pallets.length} pallets and $itemsMigrated/$totalItems items');
          
          // Set the migration flag in SharedPreferences
          await setMigrationCompleted(true);
          
          // Clear local data to switch to cloud-only mode
          await clearLocalData();
          
          // Switch to Supabase as data source
          setDataSource(DataSource.supabase);
          
          LogUtils.info('Migration completed, switched to Supabase as data source');
          return true;
        } catch (e) {
          LogUtils.error('Error during migration', e, StackTrace.current);
          return false;
        }
      },
      errorMessage: 'Failed to migrate data to Supabase',
      defaultValue: false,
    );
  }

  Future<T> _performOperation<T>({
    required Future<T> Function() operation,
    required String errorMessage,
    required T defaultValue,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (e is PostgrestException) {
        // Log Supabase-specific error details
        final errorCode = e.code;
        final errorMessage = e.message;
        final errorDetails = e.details;
        final errorHint = e.hint;
        
        LogUtils.error('Supabase operation failed', e);
        LogUtils.log('DETAILS', 'Code: $errorCode, Message: $errorMessage');
        if (errorDetails != null) LogUtils.log('DETAILS', 'Details: $errorDetails');
        if (errorHint != null) LogUtils.log('DETAILS', 'Hint: $errorHint');
        
        // Set user-friendly error message
        _error = _getUserFriendlyError(errorCode, errorMessage);
      } else {
        // Log general error
        LogUtils.error('Operation error: $errorMessage', e);
        _error = errorMessage;
      }
      return defaultValue;
    }
  }

  Future<void> _clearLocalData() async {
    LogUtils.info('🗑️ Clearing local data after migration...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pallets');
    await prefs.remove('tags');
    await prefs.remove('palletIdCounter');
    await prefs.remove('itemIdCounter');
    LogUtils.info('✅ Local data cleared successfully');
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
  Future<void> updatePallet(Pallet pallet) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          final pallets = await _loadPalletsFromSharedPreferences();
          final index = pallets.indexWhere((p) => p.id == pallet.id);
          
          if (index >= 0) {
            pallets[index] = pallet;
            await _savePalletsToSharedPreferences(pallets);
          }
        } else {
          // For Supabase, update the pallet using the supabaseId if available
          if (pallet.supabaseId != null) {
            await SupabaseService.instance.client
              .from('pallets')
              .update({
                'name': pallet.name,
                'tag': pallet.tag,
                'total_cost': pallet.totalCost,
                'date': pallet.date.toIso8601String(),
                'is_closed': pallet.isClosed,
              })
              .eq('id', pallet.supabaseId);
            LogUtils.info('REPOSITORY: Updated pallet using supabaseId: ${pallet.supabaseId}');
          } else {
            // Fall back to using original_id
            await SupabaseService.instance.client
              .from('pallets')
              .update({
                'name': pallet.name,
                'tag': pallet.tag,
                'total_cost': pallet.totalCost,
                'date': pallet.date.toIso8601String(),
                'is_closed': pallet.isClosed,
              })
              .eq('original_id', pallet.id)
              .eq('user_id', SupabaseService.instance.currentUser!.id);
            LogUtils.info('REPOSITORY: Updated pallet using original_id: ${pallet.id}');
          }
        }
      },
      errorMessage: 'Failed to update pallet',
    );
  }

  // Update a pallet item
  Future<void> updatePalletItem(int palletId, PalletItem item) async {
    await _performOperation(
      operation: () async {
        if (_dataSource == DataSource.sharedPreferences) {
          final pallets = await _loadPalletsFromSharedPreferences();
          final palletIndex = pallets.indexWhere((p) => p.id == palletId);
          
          if (palletIndex >= 0) {
            final pallet = pallets[palletIndex];
            final itemIndex = pallet.items.indexWhere((i) => i.id == item.id);
            
            if (itemIndex >= 0) {
              pallet.items[itemIndex] = item;
              await _savePalletsToSharedPreferences(pallets);
            }
          }
        } else {
          // Find the pallet first to get the supabaseId
          final pallet = await _findPalletById(palletId);
          if (pallet == null) {
            LogUtils.warning('REPOSITORY: Cannot find pallet with ID $palletId');
            return;
          }
          
          // Prepare update data
          final updateData = {
            'name': item.name,
            'description': item.name,
            'sale_price': item.salePrice,
            'is_sold': item.isSold,
            'sale_date': item.saleDate?.toIso8601String(),
            'allocated_cost': item.allocatedCost,
            'retail_price': item.retailPrice,
            'condition': item.condition,
            'list_price': item.listPrice,
            'product_code': item.productCode,
          };
          
          if (pallet.supabaseId != null) {
            // Use the direct Supabase ID if available
            await SupabaseService.instance.client
              .from('pallet_items')
              .update(updateData)
              .eq('pallet_id', pallet.supabaseId)
              .eq('original_id', item.id);
            LogUtils.info('REPOSITORY: Updated item using pallet supabaseId: ${pallet.supabaseId}');
          } else {
            // First find the Supabase pallet ID
            final response = await SupabaseService.instance.client
              .from('pallets')
              .select('id')
              .eq('original_id', palletId)
              .eq('user_id', SupabaseService.instance.currentUser!.id)
              .single();
              
            final supabasePalletId = response['id'];
            
            // Then update the item
            await SupabaseService.instance.client
              .from('pallet_items')
              .update(updateData)
              .eq('pallet_id', supabasePalletId)
              .eq('original_id', item.id);
            LogUtils.info('REPOSITORY: Updated item using pallet original_id: $palletId');
          }
        }
      },
      errorMessage: 'Failed to update pallet item',
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
      errorMessage: 'Failed to reset migration status',
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
      errorMessage: 'Failed to load pallets from Supabase',
      defaultValue: [],
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
      errorMessage: 'Failed to create pallet in Supabase',
      defaultValue: null,
    );
  }
  
  // Create a pallet item in Supabase during migration
  Future<int?> createPalletItemInSupabase(PalletItem item, int palletId) async {
    return _performOperation(
      operation: () async {
        LogUtils.info('REPOSITORY: Creating pallet item in Supabase for pallet $palletId');
        if (SupabaseService.instance.currentUser == null) {
          LogUtils.warning('REPOSITORY: Cannot create pallet item: User not authenticated');
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
      
      LogUtils.info('Local data cleared from SharedPreferences');
    } catch (e) {
      LogUtils.error('Error clearing local data', e);
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
      LogUtils.info('Migration completed flag set to $completed in SharedPreferences');
    } catch (e) {
      LogUtils.error('Error setting migration flag', e);
      rethrow;
    }
  }
} 
} 