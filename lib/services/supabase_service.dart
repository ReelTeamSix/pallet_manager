import 'package:flutter/foundation.dart';
import 'package:pallet_manager/pallet_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;
  static Stream<AuthState>? _authStateChange;
  
  // Track user changes
  String? _previousUserId;
  bool _userChanged = false;

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    
    _client = Supabase.instance.client;
    _authStateChange = _client?.auth.onAuthStateChange;
  }

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseService._();

  SupabaseClient get _supabase {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }
    return _client!;
  }

  // Add a public getter for the Supabase client
  SupabaseClient get client => _supabase;

  Stream<AuthState> get authStateChange {
    if (_authStateChange == null) {
      throw Exception('Auth state change stream not initialized');
    }
    return _authStateChange!;
  }

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Update the user ID tracking
        updatePreviousUserId(response.user!.id);
        debugPrint('User signed in: ${response.user!.id}');
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Update the user ID tracking for the new user
        updatePreviousUserId(response.user!.id);
        debugPrint('User signed up: ${response.user!.id}');
      }
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Store the previous ID before signing out
      final oldUserId = _previousUserId;
      await _supabase.auth.signOut();
      
      // Set flag that user has changed
      if (oldUserId != null) {
        setUserChanged(true);
        debugPrint('User signed out: $oldUserId, userChanged flag set to true');
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  Future<void> createUserProfile(String userId, String email, String? name) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Create user profile error: $e');
    }
  }

  Future<Map<String, dynamic>> createPallet(Pallet pallet) async {
    if (currentUser == null) {
      throw Exception('User must be authenticated to create pallet');
    }

    try {
      final response = await _supabase.from('pallets').insert({
        'user_id': currentUser!.id,
        'name': pallet.name,
        'tag': pallet.tag,
        'date': pallet.date.toIso8601String(),
        'total_cost': pallet.totalCost,
        'is_closed': pallet.isClosed,
        'original_id': pallet.id,
      }).select().single();

      return response;
    } catch (e) {
      debugPrint('Create pallet error: $e');
      rethrow;
    }
  }

  Future<int?> createPalletItem(PalletItem item, int palletId) async {
    if (currentUser == null) {
      debugPrint('SUPABASE-ITEM: Cannot create pallet item - user not authenticated');
      throw Exception('User must be authenticated to create pallet item');
    }

    try {
      debugPrint('SUPABASE-ITEM: Creating pallet item ${item.id} for pallet $palletId');
      
      // Prepare data for insertion with correct schema column names
      final data = {
        'pallet_id': palletId,
        'original_id': item.id,
        'name': item.name,
        'description': item.name, // Use name as description 
        'purchase_price': item.allocatedCost,
        'sale_price': item.salePrice,
        'is_sold': item.isSold,
        'sale_date': item.saleDate?.toIso8601String(),
        'allocated_cost': item.allocatedCost,
        'retail_price': item.retailPrice,
        'condition': item.condition,
        'list_price': item.listPrice,
        'product_code': item.productCode,
        'quantity': 1, // Default quantity
        'category': '', // Default empty category
        'date_purchased': DateTime.now().toIso8601String(),
        'location': '', // Default empty location
        'user_id': currentUser!.id,
      };
      
      debugPrint('SUPABASE-ITEM: Data for insertion: $data');

      final response = await _supabase
          .from('pallet_items')
          .insert(data)
          .select('id')
          .single();

      debugPrint('SUPABASE-ITEM: Successfully created pallet item with ID: ${response['id']}');
      return response['id'];
    } catch (e) {
      debugPrint('SUPABASE-ITEM: Error creating pallet item: $e');
      debugPrint('SUPABASE-ITEM: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPalletItems(String palletId) async {
    if (currentUser == null) {
      throw Exception('User must be authenticated to get pallet items');
    }

    try {
      final response = await _supabase
        .from('pallet_items')
        .select('*, item_photos(url)')
        .eq('pallet_id', palletId)
        .eq('user_id', currentUser!.id);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get pallet items error: $e');
      rethrow;
    }
  }

  Future<List<Pallet>> getPallets() async {
    if (currentUser == null) {
      debugPrint('SUPABASE-GET: Cannot get pallets - user not authenticated');
      throw Exception('User must be authenticated to get pallets');
    }

    try {
      debugPrint('SUPABASE-GET: Retrieving pallets for user ${currentUser!.id}');
      final response = await _supabase
        .from('pallets')
        .select('*, pallet_items(*)')
        .eq('user_id', currentUser!.id)
        .order('date', ascending: false);

      debugPrint('SUPABASE-GET: Retrieved ${response.length} pallets from Supabase');
      
      if (response.isEmpty) {
        debugPrint('SUPABASE-GET: No pallets found for user ${currentUser!.id}');
        return [];
      }
      
      // Group pallets by originalId to handle duplicates
      final Map<int, Map<String, dynamic>> palletMap = {};
      
      for (final json in response) {
        final originalId = json['original_id'] as int;
        debugPrint('SUPABASE-GET: Processing pallet with original_id=$originalId, db_id=${json['id']}');
        
        // If this is the first time we see this originalId, store the pallet
        if (!palletMap.containsKey(originalId)) {
          palletMap[originalId] = json;
          continue;
        }
        
        // If we already have a pallet with this originalId, merge item lists
        final existingPallet = palletMap[originalId]!;
        final existingItems = existingPallet['pallet_items'] as List<dynamic>;
        final newItems = json['pallet_items'] as List<dynamic>;
        
        // Add items from the duplicate pallet to the original one
        existingItems.addAll(newItems);
        debugPrint('SUPABASE-GET: Merged items for duplicate pallet ${json['id']}');
      }
      
      debugPrint('SUPABASE-GET: After deduplication, found ${palletMap.length} unique pallets');
      
      // Convert the deduplicated map back to a list of Pallets
      final pallets = palletMap.values.map((json) {
        final pallet = _palletFromJson(json);
        debugPrint('SUPABASE-GET: Converted pallet ${pallet.id} with ${pallet.items.length} items');
        return pallet;
      }).toList();
      
      return pallets;
    } catch (e) {
      debugPrint('SUPABASE-GET: Error getting pallets: $e');
      debugPrint('SUPABASE-GET: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<Set<String>> getTags() async {
    if (currentUser == null) {
      throw Exception('User must be authenticated to get tags');
    }

    try {
      final response = await _supabase
        .from('tags')
        .select('name')
        .eq('user_id', currentUser!.id);

      return response.map((json) => json['name'] as String).toSet();
    } catch (e) {
      debugPrint('Get tags error: $e');
      rethrow;
    }
  }

  Future<void> createTag(String tag) async {
    if (currentUser == null) {
      throw Exception('User must be authenticated to create tag');
    }

    try {
      await _supabase.from('tags').insert({
        'user_id': currentUser!.id,
        'name': tag,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Create tag error: $e');
      rethrow;
    }
  }

  Future<void> deleteTag(String tag) async {
    if (currentUser == null) {
      throw Exception('User must be authenticated to delete tag');
    }

    try {
      await _supabase
        .from('tags')
        .delete()
        .eq('name', tag)
        .eq('user_id', currentUser!.id);
    } catch (e) {
      debugPrint('Delete tag error: $e');
      rethrow;
    }
  }

  Future<void> deletePallet(int originalPalletId) async {
    if (currentUser == null) {
      throw Exception('User must be authenticated to delete pallet');
    }

    try {
      debugPrint('Deleting pallet with original ID: $originalPalletId');
      
      // Find the Supabase pallet ID that matches the original ID
      final response = await _supabase
        .from('pallets')
        .select('id')
        .eq('original_id', originalPalletId)
        .eq('user_id', currentUser!.id);
      
      if (response.isEmpty) {
        debugPrint('No pallet found with original ID: $originalPalletId');
        return;
      }
      
      // Extract all Supabase pallet IDs that match this original ID
      // (in case of duplicates)
      final palletIds = response.map((row) => row['id']).toList();
      debugPrint('Found ${palletIds.length} pallets with original ID: $originalPalletId');
      
      // Delete each pallet (cascade should handle items)
      for (final palletId in palletIds) {
        debugPrint('Deleting pallet ID: $palletId');
        await _supabase
          .from('pallets')
          .delete()
          .eq('id', palletId)
          .eq('user_id', currentUser!.id);
      }
      
      debugPrint('Successfully deleted all pallets with original ID: $originalPalletId');
    } catch (e) {
      debugPrint('Delete pallet error: $e');
      rethrow;
    }
  }

  Future<void> deletePalletItem(int palletOriginalId, int itemOriginalId) async {
    if (currentUser == null) {
      throw Exception('User must be authenticated to delete pallet item');
    }

    try {
      debugPrint('Deleting item with original ID: $itemOriginalId from pallet with original ID: $palletOriginalId');
      
      // First find the Supabase pallet ID
      final palletResponse = await _supabase
        .from('pallets')
        .select('id')
        .eq('original_id', palletOriginalId)
        .eq('user_id', currentUser!.id);
      
      if (palletResponse.isEmpty) {
        debugPrint('No pallet found with original ID: $palletOriginalId');
        return;
      }
      
      // Get all matching pallet IDs (in case of duplicates)
      final palletIds = palletResponse.map((row) => row['id']).toList();
      
      // Delete the item from all matching pallets
      for (final palletId in palletIds) {
        await _supabase
          .from('pallet_items')
          .delete()
          .eq('pallet_id', palletId)
          .eq('original_id', itemOriginalId);
      }
      
      debugPrint('Successfully deleted item with original ID: $itemOriginalId');
    } catch (e) {
      debugPrint('Delete pallet item error: $e');
      rethrow;
    }
  }

  // Add a new method to clean up duplicate pallets
  Future<void> cleanupDuplicatePallets() async {
    if (currentUser == null) {
      throw Exception('User must be authenticated to clean up data');
    }
    
    try {
      debugPrint('Starting cleanup of duplicate pallets');
      
      // First, get all pallets grouped by original_id
      final response = await _supabase
        .from('pallets')
        .select('id, original_id')
        .eq('user_id', currentUser!.id);
        
      // Group by original_id
      final Map<int, List<String>> palletGroups = {};
      
      for (final pallet in response) {
        final originalId = pallet['original_id'] as int;
        final id = pallet['id'] as String;
        
        if (!palletGroups.containsKey(originalId)) {
          palletGroups[originalId] = [];
        }
        
        palletGroups[originalId]!.add(id);
      }
      
      // Find all groups with duplicates
      int duplicatesRemoved = 0;
      for (final entry in palletGroups.entries) {
        final originalId = entry.key;
        final ids = entry.value;
        
        if (ids.length > 1) {
          debugPrint('Found ${ids.length} duplicates for pallet with original_id: $originalId');
          
          // Keep the first one, delete the rest
          final keepId = ids.first;
          final removeIds = ids.skip(1).toList();
          
          for (final removeId in removeIds) {
            // Delete items from duplicate pallets
            await _supabase
              .from('pallet_items')
              .delete()
              .eq('pallet_id', removeId);
              
            // Delete the duplicate pallet
            await _supabase
              .from('pallets')
              .delete()
              .eq('id', removeId)
              .eq('user_id', currentUser!.id);
              
            duplicatesRemoved++;
          }
        }
      }
      
      debugPrint('Cleanup complete. Removed $duplicatesRemoved duplicate pallets');
    } catch (e) {
      debugPrint('Error during pallet cleanup: $e');
      rethrow;
    }
  }

  Future<void> migrateSharedPreferencesToSupabase(List<Pallet> pallets, Set<String> savedTags) async {
    if (currentUser == null) {
      throw Exception('User must be authenticated to migrate data');
    }
    
    try {
      debugPrint('Starting migration of ${pallets.length} pallets and ${savedTags.length} tags');
      
      // Clean up any existing duplicate pallets
      await cleanupDuplicatePallets();
      
      // First, check if there are already pallets in Supabase with these original IDs
      // Get a list of all existing original_ids in the database
      final existingPalletsResponse = await _supabase
        .from('pallets')
        .select('original_id')
        .eq('user_id', currentUser!.id);
      
      final Set<int> existingOriginalIds = existingPalletsResponse
        .map<int>((p) => p['original_id'] as int)
        .toSet();
        
      debugPrint('Found ${existingOriginalIds.length} existing pallets in Supabase');
      
      // Filter out pallets that already exist in Supabase
      final List<Pallet> newPallets = pallets
        .where((p) => !existingOriginalIds.contains(p.id))
        .toList();
        
      // Add all tags
      for (final tag in savedTags) {
        try {
          await createTag(tag);
        } catch (e) {
          debugPrint('Error creating tag: $e - might already exist');
          // Continue with next tag if this one fails
        }
      }
      
      // Add new pallets and their items
      debugPrint('Migrating ${newPallets.length} new pallets to Supabase');
      for (final pallet in newPallets) {
        try {
          final palletResponse = await createPallet(pallet);
          final supabasePalletId = palletResponse['id'];
          
          for (final item in pallet.items) {
            await createPalletItem(item, supabasePalletId);
          }
          debugPrint('Migrated pallet ${pallet.id} with ${pallet.items.length} items');
        } catch (e) {
          debugPrint('Error migrating pallet ${pallet.id}: $e');
          // Continue with next pallet if this one fails
        }
      }

      debugPrint('Data migration completed successfully');
    } catch (e) {
      debugPrint('Error during data migration: $e');
      rethrow;
    }
  }

  Pallet _palletFromJson(Map<String, dynamic> json) {
    final items = (json['pallet_items'] as List<dynamic>?)
        ?.map((item) => PalletItem(
              id: item['original_id'] ?? 0,
              name: item['name'],
              salePrice: (item['sale_price'] as num).toDouble(),
              isSold: item['is_sold'] ?? false,
              saleDate: item['sale_date'] != null 
                  ? DateTime.parse(item['sale_date']) 
                  : null,
              allocatedCost: (item['allocated_cost'] != null 
                  ? (item['allocated_cost'] as num).toDouble() 
                  : (item['purchase_price'] != null 
                      ? (item['purchase_price'] as num).toDouble() 
                      : 0.0)),
              retailPrice: item['retail_price'] != null 
                  ? (item['retail_price'] as num).toDouble() 
                  : null,
              condition: item['condition'],
              listPrice: item['list_price'] != null 
                  ? (item['list_price'] as num).toDouble() 
                  : null,
              productCode: item['product_code'],
              photos: item['photos'] != null 
                  ? List<String>.from(item['photos']) 
                  : null,
            ))
        .toList() ?? [];

    return Pallet(
      id: json['original_id'] ?? 0,
      name: json['name'],
      tag: json['tag'] ?? '',
      totalCost: (json['total_cost'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      items: items,
      isClosed: json['is_closed'] ?? false,
      supabaseId: json['id']?.toString(),
    );
  }

  // User tracking getters and setters
  String? get previousUserId => _previousUserId;
  
  void updatePreviousUserId(String userId) {
    if (_previousUserId != userId) {
      debugPrint('Updating previous user ID from $_previousUserId to $userId');
      _previousUserId = userId;
    }
  }
  
  void setUserChanged(bool changed) {
    _userChanged = changed;
  }
  
  bool hasUserChanged() {
    return _userChanged;
  }

  // Get pallet headers only (without items) for lazy loading
  Future<List<Pallet>> getPalletHeaders() async {
    if (currentUser == null) {
      debugPrint('SUPABASE-GET: Cannot get pallet headers - user not authenticated');
      throw Exception('User must be authenticated to get pallet headers');
    }

    try {
      debugPrint('SUPABASE-GET: Retrieving pallet headers for user ${currentUser!.id}');
      final response = await _supabase
        .from('pallets')
        .select('id, original_id, name, tag, date, total_cost, is_closed')
        .eq('user_id', currentUser!.id)
        .order('date', ascending: false);

      debugPrint('SUPABASE-GET: Retrieved ${response.length} pallet headers from Supabase');
      
      if (response.isEmpty) {
        debugPrint('SUPABASE-GET: No pallet headers found for user ${currentUser!.id}');
        return [];
      }
      
      // Convert to Pallet objects without items
      final pallets = response.map((json) {
        return Pallet(
          id: json['original_id'] ?? 0,
          name: json['name'],
          tag: json['tag'] ?? '',
          totalCost: (json['total_cost'] as num).toDouble(),
          date: DateTime.parse(json['date']),
          items: [], // Empty items list for lazy loading
          isClosed: json['is_closed'] ?? false,
          supabaseId: json['id']?.toString(),
        );
      }).toList();
      
      debugPrint('SUPABASE-GET: Converted ${pallets.length} pallet headers');
      return pallets;
    } catch (e) {
      debugPrint('SUPABASE-GET: Error getting pallet headers: $e');
      debugPrint('SUPABASE-GET: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Get items for a specific pallet by pallet ID
  Future<List<PalletItem>> getPalletItemsById(int palletId) async {
    if (currentUser == null) {
      debugPrint('SUPABASE-GET-ITEMS: Cannot get pallet items - user not authenticated');
      throw Exception('User must be authenticated to get pallet items');
    }

    try {
      debugPrint('SUPABASE-GET-ITEMS: Finding Supabase ID for pallet with original_id: $palletId');
      
      // Find the Supabase pallet ID first
      final palletResponse = await _supabase
        .from('pallets')
        .select('id')
        .eq('original_id', palletId)
        .eq('user_id', currentUser!.id)
        .single();
      
      if (palletResponse == null) {
        debugPrint('SUPABASE-GET-ITEMS: No pallet found with original_id: $palletId');
        return [];
      }
      
      final supabasePalletId = palletResponse['id'];
      debugPrint('SUPABASE-GET-ITEMS: Found Supabase ID: $supabasePalletId for pallet: $palletId');
      
      // Get items for this pallet
      final itemsResponse = await _supabase
        .from('pallet_items')
        .select('*')
        .eq('pallet_id', supabasePalletId)
        .eq('user_id', currentUser!.id);
      
      debugPrint('SUPABASE-GET-ITEMS: Retrieved ${itemsResponse.length} items for pallet $palletId');
      
      // Convert to PalletItem objects
      final items = itemsResponse.map((item) => PalletItem(
        id: item['original_id'] ?? 0,
        name: item['name'],
        salePrice: (item['sale_price'] as num).toDouble(),
        isSold: item['is_sold'] ?? false,
        saleDate: item['sale_date'] != null 
            ? DateTime.parse(item['sale_date']) 
            : null,
        allocatedCost: (item['allocated_cost'] != null 
            ? (item['allocated_cost'] as num).toDouble() 
            : (item['purchase_price'] != null 
                ? (item['purchase_price'] as num).toDouble() 
                : 0.0)),
        retailPrice: item['retail_price'] != null 
            ? (item['retail_price'] as num).toDouble() 
            : null,
        condition: item['condition'],
        listPrice: item['list_price'] != null 
            ? (item['list_price'] as num).toDouble() 
            : null,
        productCode: item['product_code'],
        photos: item['photos'] != null 
            ? List<String>.from(item['photos']) 
            : null,
      )).toList();
      
      debugPrint('SUPABASE-GET-ITEMS: Converted ${items.length} items for pallet $palletId');
      return items;
    } catch (e) {
      debugPrint('SUPABASE-GET-ITEMS: Error getting items for pallet $palletId: $e');
      debugPrint('SUPABASE-GET-ITEMS: Stack trace: ${StackTrace.current}');
      return []; // Return empty list on error
    }
  }
} 