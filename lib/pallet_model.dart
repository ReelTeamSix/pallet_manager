import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pallet_manager/services/data_repository.dart';
import 'package:pallet_manager/services/supabase_service.dart';
import 'dart:math';

class PalletItem {
  int id;
  String name;
  double salePrice;
  bool isSold;
  DateTime? saleDate;
  double allocatedCost;

  // Add these new fields:
  double? retailPrice;
  String? condition;
  double? listPrice;
  String? productCode;
  List<String>? photos;

  PalletItem({
    required this.id,
    required this.name,
    this.salePrice = 0.0,
    this.isSold = false,
    this.saleDate,
    this.allocatedCost = 0.0,
    // Add these new parameters:
    this.retailPrice,
    this.condition,
    this.listPrice,
    this.productCode,
    this.photos,
  });

  // Update toJson to include new fields
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'salePrice': salePrice,
        'isSold': isSold,
        'saleDate': saleDate?.toIso8601String(),
        'allocatedCost': allocatedCost,
        // Add these new fields:
        'retailPrice': retailPrice,
        'condition': condition,
        'listPrice': listPrice,
        'productCode': productCode,
        'photos': photos,
      };

  // Update fromJson to handle new fields
  factory PalletItem.fromJson(Map<String, dynamic> json) {
    try {
      return PalletItem(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Unknown Item',
        salePrice: json['salePrice'] != null 
            ? (json['salePrice'] as num).toDouble() 
            : (json['sale_price'] != null ? (json['sale_price'] as num).toDouble() : 0.0),
        isSold: json['isSold'] ?? json['is_sold'] ?? false,
        saleDate: json['saleDate'] != null 
            ? DateTime.parse(json['saleDate']) 
            : (json['sale_date'] != null ? DateTime.parse(json['sale_date']) : null),
        allocatedCost: json['allocatedCost'] != null
            ? (json['allocatedCost'] as num).toDouble()
            : (json['allocated_cost'] != null ? (json['allocated_cost'] as num).toDouble() : 0.0),
        // Add these new fields with better null handling:
        retailPrice: _safeDoubleConversion(json['retailPrice'] ?? json['retail_price']),
        condition: json['condition'] as String?,
        listPrice: _safeDoubleConversion(json['listPrice'] ?? json['list_price']),
        productCode: json['productCode'] ?? json['product_code'],
        photos: json['photos'] != null ? List<String>.from(json['photos']) : null,
      );
    } catch (e) {
      print('Error parsing PalletItem JSON: $e');
      print('JSON was: $json');
      // Return a fallback item instead of throwing
      return PalletItem(
        id: 0,
        name: 'Error: ${json['name'] ?? 'Unknown'}',
        salePrice: 0.0,
        isSold: false
      );
    }
  }

  // Helper method to safely convert potentially null values to double
  static double? _safeDoubleConversion(dynamic value) {
    if (value == null) return null;
    try {
      return (value as num).toDouble();
    } catch (e) {
      print('Error converting $value to double: $e');
      return null;
    }
  }
}

class Pallet {
  int id;
  String name;
  String tag;
  DateTime date;
  double totalCost;
  List<PalletItem> items;
  bool isClosed;
  String? supabaseId;

  Pallet({
    required this.id, 
    required this.name, 
    required this.tag, 
    required this.totalCost, 
    required this.date, 
    List<PalletItem>? items, 
    this.isClosed = false,
    this.supabaseId,
  }) : items = items ?? [];

  // Calculate profit - only counting sold items against cost
  // Calculate profit based on the difference between sale price and allocated cost
  // Calculate profit - showing negative until full cost is recovered
  double get profit {
    // Calculate total revenue from all sold items
    double soldItemsRevenue = items
        .where((item) => item.isSold)
        .fold(0.0, (sum, item) => sum + item.salePrice);

    // For profit calculation, we'll compare total revenue against total cost
    // Only show positive profit after the entire pallet cost is recovered
    return soldItemsRevenue - totalCost;
  }

  // Get allocated cost for a single item
  double get costPerItem => items.isEmpty ? 0.0 : totalCost / items.length;

  // Get cost for sold items only
  double get soldItemsCost {
    int soldItemsCount = items.where((item) => item.isSold).length;
    return soldItemsCount > 0 ? costPerItem * soldItemsCount : 0.0;
  }

  // Calculate revenue (sum of all sold items)
  double get totalRevenue {
    return items.fold(0.0, (sum, item) => 
      sum + (item.isSold ? item.salePrice : 0.0));
  }

  // Get count of sold items
  int get soldItemsCount => items.where((item) => item.isSold).length;

  // Get estimated value of pallet including sold and unsold items
  double get estimatedValue {
    double soldValue = items
        .where((item) => item.isSold)
        .fold(0.0, (sum, item) => sum + item.salePrice);
    
    // For unsold items, use the average sale price of sold items as an estimate
    double avgSalePrice = items.where((item) => item.isSold).isNotEmpty
        ? items.where((item) => item.isSold).fold(0.0, (sum, item) => sum + item.salePrice) / 
          items.where((item) => item.isSold).length
        : 0.0;
    
    double unsoldEstimate = items.where((item) => !item.isSold).length * avgSalePrice;
    
    return soldValue + unsoldEstimate;
  }

  // Get profit percentage based on sold items
  double get profitPercentage {
    double rev = totalRevenue;
    return rev > 0 ? (profit / rev * 100) : 0.0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tag': tag,
    'date': date.toIso8601String(),
    'totalCost': totalCost,
    'items': items.map((item) => item.toJson()).toList(),
    'isClosed': isClosed,
    'supabaseId': supabaseId,
  };

  factory Pallet.fromJson(Map<String, dynamic> json) {
    try {
      // Handle different field name formats (camelCase vs snake_case)
      final id = json['id'] ?? 0;
      final name = json['name'] ?? 'Unknown Pallet';
      final tag = json['tag'] ?? '';
      
      // Parse date safely
      DateTime date;
      try {
        date = DateTime.parse(json['date']);
      } catch (e) {
        print('Error parsing date: $e');
        date = DateTime.now();
      }
      
      // Parse totalCost safely
      double totalCost = 0.0;
      try {
        totalCost = json['totalCost'] != null
          ? (json['totalCost'] as num).toDouble()
          : (json['total_cost'] != null ? (json['total_cost'] as num).toDouble() : 0.0);
      } catch (e) {
        print('Error parsing totalCost: $e');
      }
      
      // Parse items safely
      List<PalletItem> items = [];
      try {
        if (json['items'] != null) {
          items = (json['items'] as List).map((e) {
            try {
              return PalletItem.fromJson(e);
            } catch (itemError) {
              print('Error parsing item: $itemError');
              return PalletItem(id: 0, name: 'Error Item');
            }
          }).toList();
        }
      } catch (e) {
        print('Error parsing items list: $e');
      }
      
      return Pallet(
        id: id,
        name: name,
        tag: tag,
        date: date,
        totalCost: totalCost,
        items: items,
        isClosed: json['isClosed'] ?? json['is_closed'] ?? false,
        supabaseId: json['supabaseId'] as String?,
      );
    } catch (e) {
      print('Error parsing Pallet JSON: $e');
      print('JSON was: $json');
      // Return a fallback pallet instead of throwing
      return Pallet(
        id: 0,
        name: 'Error Pallet',
        tag: '',
        totalCost: 0.0,
        date: DateTime.now(),
      );
    }
  }
}

class PalletModel extends ChangeNotifier {
  List<Pallet> _pallets = [];
  int _palletIdCounter = 1;
  int _itemIdCounter = 1;
  bool _isLoading = false;
  DateTime _currentFilterMonth = DateTime.now();
  Set<String> _savedTags = {};
  String? _currentTagFilter;
  
  // Add data repository
  final DataRepository _dataRepository;

  // Add getter for data repository
  DataRepository get dataRepository => _dataRepository;

  List<Pallet> get pallets => _currentTagFilter != null 
      ? _pallets.where((p) => p.tag == _currentTagFilter).toList() 
      : _pallets;
  
  bool get isLoading => _isLoading;
  DateTime get currentFilterMonth => _currentFilterMonth;
  Set<String> get savedTags => _savedTags;
  String? get currentTagFilter => _currentTagFilter;
  
  // Add getter for data source
  DataSource get dataSource => _dataRepository.dataSource;

  // Get total profit across all pallets
  double get totalProfit {
    return _pallets.fold(0.0, (sum, pallet) => sum + pallet.profit);
  }

  // Set tag filter
  void setTagFilter(String? tag) {
    _currentTagFilter = tag;
    notifyListeners();
  }

  // Add new tag to saved tags
  void addTag(String tag) {
    if (tag.isNotEmpty) {
      _savedTags.add(tag);
      
      // Save tag to data repository
      _dataRepository.addTag(tag);
      
      notifyListeners();
    }
  }

  // Remove tag from saved tags
  void removeTag(String tag) {
    _savedTags.remove(tag);
    
    // Remove tag from data repository
    _dataRepository.removeTag(tag);
    
    notifyListeners();
  }

  // Update pallet tag
  void updatePalletTag(int palletId, String newTag) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) return;

    // Update the tag in the local list
    _pallets[palletIndex].tag = newTag;
    
    // Add to saved tags if it's new
    if (newTag.isNotEmpty) {
      _savedTags.add(newTag);
      _dataRepository.addTag(newTag);
    }
    
    notifyListeners();

    if (_dataRepository.dataSource == DataSource.supabase) {
      // In Supabase mode, update the tag in the database
      try {
        // Update the pallet directly through the repository
        _dataRepository.updatePallet(palletId, {'tag': newTag});
      } catch (e) {
        debugPrint('Error updating pallet tag in Supabase: $e');
      }
    } else {
      // In SharedPreferences mode, save the changes
      saveData();
    }
  }

  bool palletNameExists(String name) {
    // Search through all pallets (not just filtered ones) and compare case-insensitively
    return _pallets
        .any((pallet) => pallet.name.toLowerCase() == name.toLowerCase());
  }

  // Update a pallet's name
  void updatePalletName(int palletId, String newName) {
    // Prevent duplicate names
    if (newName.isEmpty ||
        (_pallets.any((p) =>
            p.id != palletId &&
            p.name.toLowerCase() == newName.toLowerCase()))) {
      return; // Reject the change - name is empty or already exists
    }

    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) return;

    // Update the name in the local list
    _pallets[palletIndex].name = newName;
    notifyListeners();

    if (_dataRepository.dataSource == DataSource.supabase) {
      // In Supabase mode, update the name in the database
      try {
        // Update the pallet directly through the repository
        _dataRepository.updatePallet(palletId, {'name': newName});
      } catch (e) {
        debugPrint('Error updating pallet name in Supabase: $e');
      }
    } else {
      // In SharedPreferences mode, save the changes
      saveData();
    }
  }

  // Filter pallets by month
  List<Pallet> getPalletsByMonth(DateTime month) {
    List<Pallet> filteredByMonth = _pallets.where((pallet) => 
      pallet.date.year == month.year && 
      pallet.date.month == month.month
    ).toList();
    
    // Apply tag filter if active
    return _currentTagFilter != null 
        ? filteredByMonth.where((p) => p.tag == _currentTagFilter).toList() 
        : filteredByMonth;
  }

  // Filter items by month they were sold
  List<PalletItem> getItemsSoldInMonth(DateTime month) {
    List<PalletItem> result = [];
    
    // If tag filter is active, only consider pallets with that tag
    final palletsToCheck = _currentTagFilter != null 
        ? _pallets.where((p) => p.tag == _currentTagFilter) 
        : _pallets;
    
    for (var pallet in palletsToCheck) {
      result.addAll(pallet.items.where((item) => 
        item.isSold && 
        item.saleDate != null &&
        item.saleDate!.year == month.year && 
        item.saleDate!.month == month.month
      ));
    }
    
    return result;
  }

  // Set filter month
  void setFilterMonth(DateTime month) {
    _currentFilterMonth = month;
    notifyListeners();
  }

  // Get next month
  void nextMonth() {
    if (_currentFilterMonth.month == 12) {
      _currentFilterMonth = DateTime(_currentFilterMonth.year + 1, 1);
    } else {
      _currentFilterMonth = DateTime(_currentFilterMonth.year, _currentFilterMonth.month + 1);
    }
    notifyListeners();
  }

  // Get previous month
  void previousMonth() {
    if (_currentFilterMonth.month == 1) {
      _currentFilterMonth = DateTime(_currentFilterMonth.year - 1, 12);
    } else {
      _currentFilterMonth = DateTime(_currentFilterMonth.year, _currentFilterMonth.month - 1);
    }
    notifyListeners();
  }

  // Get year-to-date pallets
  List<Pallet> getYearToDatePallets() {
    final now = DateTime.now();
    List<Pallet> ytdPallets = _pallets.where((pallet) => 
      pallet.date.year == now.year && 
      pallet.date.isBefore(now)
    ).toList();
    
    // Apply tag filter if active
    return _currentTagFilter != null 
        ? ytdPallets.where((p) => p.tag == _currentTagFilter).toList() 
        : ytdPallets;
  }

  // Get profit by tag
  Map<String, double> getProfitByTag() {
    Map<String, double> result = {};
    
    for (var pallet in _pallets) {
      if (pallet.tag.isNotEmpty) {
        result[pallet.tag] = (result[pallet.tag] ?? 0) + pallet.profit;
      }
    }
    
    return result;
  }

  // Constructor to initialize with a data repository
  // Updated constructor to take DataRepository
  PalletModel({required DataRepository dataRepository}) 
      : _dataRepository = dataRepository {
    // Don't call loadData() here to avoid widget lifecycle issues
  }
  
  // Method to explicitly initialize the model after widgets are built
  Future<void> initialize() async {
    debugPrint('MODEL: Initializing PalletModel');
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasMigrated = prefs.getBool(_migrationCompletedKey) ?? false;
      debugPrint('MODEL: Migration status from SharedPreferences: $hasMigrated');
      
      // Set data source based on migration status
      if (hasMigrated) {
        debugPrint('MODEL: Setting data source to SUPABASE since migration is complete');
        _dataSource = DataSource.supabase;
      } else {
        debugPrint('MODEL: Setting data source to LOCAL since migration is not complete');
        _dataSource = DataSource.sharedPreferences;
      }
      
      _initialized = true;
      debugPrint('MODEL: Model initialization complete. Data source: $_dataSource');
      
      // Force reload after initialization
      await forceDataReload();
    } catch (e) {
      debugPrint('MODEL: Error initializing PalletModel: $e');
      debugPrint('MODEL: Stack trace: ${StackTrace.current}');
      _initialized = true; // Still mark as initialized to prevent loops
      _dataSource = DataSource.sharedPreferences; // Default to sharedPreferences on error
    }
  }

  // Update to use DataRepository for saving data
  Future<void> saveData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // If using Supabase, after migration there's no need to call saveData
      // as operations are done directly to the database
      if (_dataRepository.dataSource == DataSource.sharedPreferences) {
        // Only save to SharedPreferences if that's our data source
        await _dataRepository.savePallets(_pallets);
        await _dataRepository.saveTags(_savedTags);
        await _dataRepository.saveCounters(
          palletIdCounter: _palletIdCounter, 
          itemIdCounter: _itemIdCounter,
        );
      }
    } catch (e) {
      debugPrint('Error saving data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load data from the data repository
  Future<void> loadData() async {
    // If we're already loading, don't start again
    if (_isLoading) {
      debugPrint('Already loading data, skipping redundant loadData() call');
      return;
    }
    
    // Set the loading flag but DON'T notify listeners (caller should set _isLoading)
    _isLoading = true;
    
    debugPrint('📂 Starting loadData in PalletModel from ${_dataRepository.dataSource}');
    
    // Delay notifyListeners until the end of this method to batch all changes
    try {
      // Load pallets from the current data source
      debugPrint('Loading pallets from ${_dataRepository.dataSource}');
      _pallets = await _dataRepository.loadPallets();
      debugPrint('Loaded ${_pallets.length} pallets');
      
      // Load tags from the current data source
      debugPrint('Loading tags from ${_dataRepository.dataSource}');
      _savedTags = await _dataRepository.loadTags();
      debugPrint('Loaded ${_savedTags.length} tags');
      
      // Load counters from SharedPreferences (only used for local data)
      debugPrint('Loading counters from repository');
      final counters = await _dataRepository.loadCounters();
      _palletIdCounter = counters['palletIdCounter'] ?? 1;
      _itemIdCounter = counters['itemIdCounter'] ?? 1;
      debugPrint('Loaded counters: palletIdCounter=$_palletIdCounter, itemIdCounter=$_itemIdCounter');
      
      // Update the highest IDs if needed
      if (_pallets.isNotEmpty) {
        _palletIdCounter = max(_palletIdCounter, _pallets.map((p) => p.id).reduce(max) + 1);
        if (_pallets.any((p) => p.items.isNotEmpty)) {
          _itemIdCounter = max(_itemIdCounter,
              _pallets.expand((p) => p.items.isEmpty ? [0] : p.items.map((i) => i.id)).reduce(max) + 1);
        }
        debugPrint('Updated counters after checking pallets: palletIdCounter=$_palletIdCounter, itemIdCounter=$_itemIdCounter');
      }
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      // If we failed to load data, see if we need to reset the data source
      try {
        if (_dataRepository.dataSource != DataSource.sharedPreferences) {
          debugPrint('⚠️ Error loading from ${_dataRepository.dataSource}, attempting to switch to SharedPreferences');
          await _dataRepository.setDataSource(DataSource.sharedPreferences);
          
          // Try again with SharedPreferences
          debugPrint('Retrying data load from SharedPreferences');
          _pallets = await _dataRepository.loadPallets();
          _savedTags = await _dataRepository.loadTags();
          final counters = await _dataRepository.loadCounters();
          _palletIdCounter = counters['palletIdCounter'] ?? 1;
          _itemIdCounter = counters['itemIdCounter'] ?? 1;
          
          debugPrint('✅ Recovery successful: loaded ${_pallets.length} pallets from SharedPreferences');
        }
      } catch (retryError) {
        debugPrint('❌ Recovery attempt also failed: $retryError');
      }
    } finally {
      // Now that all updates are complete, update the loading state and notify once
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add method to get all tags directly
  Set<String> getAllTags() {
    return _savedTags;
  }

  // Force reload data from the repository
  Future<void> forceDataReload() async {
    if (!_initialized) {
      debugPrint('MODEL-RELOAD: Model not initialized yet, skipping reload');
      return;
    }
    
    // Don't reload if already loading
    if (_isLoading) {
      debugPrint('MODEL-RELOAD: Already loading, skipping reload');
      return;
    }
    
    debugPrint('MODEL-RELOAD: Forcing data reload from ${_dataSource == DataSource.sharedPreferences ? "LOCAL" : "SUPABASE"}');
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Decide which source to load from
      if (_dataSource == DataSource.supabase) {
        debugPrint('MODEL-RELOAD: Loading data from Supabase');
        _pallets = await _dataRepository.loadPalletsFromSupabase();
        debugPrint('MODEL-RELOAD: Supabase data loaded: ${_pallets.length} pallets');
      } else {
        debugPrint('MODEL-RELOAD: Loading data from SharedPreferences');
        _pallets = await _dataRepository.loadPallets();
        debugPrint('MODEL-RELOAD: Local data loaded: ${_pallets.length} pallets');
      }
      
      // Extract unique tags
      _refreshTags();
      
      debugPrint('MODEL-RELOAD: Data reload complete. Pallets: ${_pallets.length}, Tags: ${_savedTags.length}');
    } catch (e) {
      debugPrint('MODEL-RELOAD: Error during data reload: $e');
      debugPrint('MODEL-RELOAD: Stack trace: ${StackTrace.current}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a safer method to check and trigger migration
  Future<bool> checkAndPrepareMigration() async {
    _isLoading = true;
    print('Checking migration status in PalletModel...');
    notifyListeners();
    
    try {
      // First check repository's cached migration status
      if (_dataRepository.hasMigratedData) {
        print('Data already migrated according to DataRepository');
        return false;
      }
      
      // Make sure we've loaded the most recent local data
      print('Reloading data to check migration requirements');
      await loadData();
      
      // Double-check migration status after loading data
      if (_dataRepository.hasMigratedData) {
        print('Data already migrated (detected after data load)');
        return false;
      }
      
      // Check if user is authenticated - only authenticated users need migration
      final isUserAuthenticated = _dataRepository.isAuthenticated;
      if (!isUserAuthenticated) {
        print('User not authenticated, no need for migration');
        return false;
      }
      
      // Check if the user is already using Supabase as data source
      if (_dataRepository.dataSource == DataSource.supabase) {
        print('Already using Supabase as data source, no need to migrate');
        return false;
      }
      
      // Check if we have any data to migrate in local storage
      final hasData = _pallets.isNotEmpty || _savedTags.isNotEmpty;
      print('Has local data to migrate: $hasData (pallets: ${_pallets.length}, tags: ${_savedTags.length})');
      
      if (!hasData) {
        print('No local data to migrate, skipping migration');
        return false;
      }
      
      // Need migration if user is authenticated, data isn't migrated, and we have data
      final needsMigration = hasData && isUserAuthenticated && !_dataRepository.hasMigratedData;
      print('Migration needed: $needsMigration');
      return needsMigration;
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Migrate data from SharedPreferences to Supabase
  Future<bool> migrateDataToSupabase() async {
    debugPrint('MODEL-MIGRATE: Starting data migration to Supabase');
    _isMigrating = true;
    notifyListeners();
    
    try {
      // Get pallets from local storage
      final localPallets = await _dataRepository.loadPallets();
      debugPrint('MODEL-MIGRATE: Loaded ${localPallets.length} pallets from local storage');
      
      if (localPallets.isEmpty) {
        debugPrint('MODEL-MIGRATE: No local pallets to migrate, checking if Supabase already has data');
        
        // Check if there are already pallets in Supabase
        final supabasePallets = await _dataRepository.loadPalletsFromSupabase();
        
        if (supabasePallets.isNotEmpty) {
          debugPrint('MODEL-MIGRATE: Found ${supabasePallets.length} pallets in Supabase, considering migration successful');
          // Set migration as complete
          await _dataRepository.setMigrationCompleted(true);
          _dataSource = DataSource.supabase;
          
          // Load data from Supabase
          await forceDataReload();
          
          _isMigrating = false;
          notifyListeners();
          return true;
        }
        
        debugPrint('MODEL-MIGRATE: No pallets found in Supabase either, migration not needed');
        _isMigrating = false;
        notifyListeners();
        return false;
      }
      
      // Check for existing pallets in Supabase to avoid duplicates
      final existingPallets = await _dataRepository.loadPalletsFromSupabase();
      final existingPalletIds = existingPallets.map((p) => p.id).toSet();
      
      debugPrint('MODEL-MIGRATE: Found ${existingPallets.length} existing pallets in Supabase');
      
      // Filter out pallets that already exist in Supabase
      final palletsToMigrate = localPallets.where((p) => !existingPalletIds.contains(p.id)).toList();
      
      if (palletsToMigrate.isEmpty && existingPallets.isNotEmpty) {
        debugPrint('MODEL-MIGRATE: All pallets already exist in Supabase, marking migration as complete');
        await _dataRepository.setMigrationCompleted(true);
        _dataSource = DataSource.supabase;
        
        // Load data from Supabase
        await forceDataReload();
        
        _isMigrating = false;
        notifyListeners();
        return true;
      }
      
      debugPrint('MODEL-MIGRATE: Migrating ${palletsToMigrate.length} pallets to Supabase');
      
      // Track migration success
      int successfulPallets = 0;
      
      // Migrate each pallet and its items
      for (final pallet in palletsToMigrate) {
        try {
          debugPrint('MODEL-MIGRATE: Migrating pallet ${pallet.id}: ${pallet.name}');
          
          // Create pallet in Supabase
          final createdPallet = await _dataRepository.createPalletInSupabase(pallet);
          
          if (createdPallet != null) {
            debugPrint('MODEL-MIGRATE: Successfully created pallet in Supabase');
            
            // Migrate each item
            for (final item in pallet.items) {
              try {
                debugPrint('MODEL-MIGRATE: Migrating item ${item.id} for pallet ${pallet.id}');
                await _dataRepository.createPalletItemInSupabase(item, createdPallet.id);
              } catch (itemError) {
                debugPrint('MODEL-MIGRATE: Error migrating item ${item.id}: $itemError');
              }
            }
            
            successfulPallets++;
          }
        } catch (palletError) {
          debugPrint('MODEL-MIGRATE: Error migrating pallet ${pallet.id}: $palletError');
        }
      }
      
      // Consider migration successful if at least one pallet was migrated or pallets already exist
      final migrationSuccessful = successfulPallets > 0 || existingPallets.isNotEmpty;
      
      debugPrint('MODEL-MIGRATE: Migration ${migrationSuccessful ? "successful" : "failed"}. '
          'Migrated $successfulPallets pallets, ${existingPallets.length} already existed');
      
      if (migrationSuccessful) {
        // Mark migration as complete and clear local data
        await _dataRepository.setMigrationCompleted(true);
        await _dataRepository.clearLocalData();
        
        // Update data source
        _dataSource = DataSource.supabase;
        
        // Load data from Supabase
        await forceDataReload();
      }
      
      _isMigrating = false;
      notifyListeners();
      return migrationSuccessful;
    } catch (e) {
      debugPrint('MODEL-MIGRATE: Error during migration: $e');
      debugPrint('MODEL-MIGRATE: Stack trace: ${StackTrace.current}');
      _isMigrating = false;
      notifyListeners();
      return false;
    }
  }

  int generatePalletId() => _palletIdCounter++;

  int getNextPalletId() {
    return _palletIdCounter; // Returns without incrementing
  }

  // Add a new pallet
  void addPallet(Pallet pallet) {
    if (_dataRepository.dataSource == DataSource.supabase) {
      // In Supabase mode, add directly to the database
      _dataRepository.addPallet(pallet).then((_) {
        // Reload data after adding to ensure we have the latest from the server
        loadData();
      }).catchError((e) {
        debugPrint('Error adding pallet to Supabase: $e');
      });
    } else {
      // In SharedPreferences mode, add to local list and save
      _pallets.add(pallet);
      
      // Add to saved tags if not empty
      if (pallet.tag.isNotEmpty) {
        _savedTags.add(pallet.tag);
      }
      
      notifyListeners();
      saveData();
    }
  }

  // Remove a pallet
  void removePallet(int palletId) {
    debugPrint('Called removePallet for palletId: $palletId');
    
    // First find the pallet to delete
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) {
      debugPrint('Pallet not found in list');
      return;
    }

    final pallet = _pallets[palletIndex];
    
    if (_dataRepository.dataSource == DataSource.supabase) {
      debugPrint('Removing pallet from Supabase, palletId: $palletId');
      
      // First remove from local list to update UI immediately
      _pallets.removeAt(palletIndex);
      notifyListeners();
      
      // Then remove from the database using repository
      _dataRepository.removePallet(pallet).then((_) {
        debugPrint('Pallet successfully removed from Supabase');
      }).catchError((e) {
        debugPrint('Error removing pallet from Supabase: $e');
        // If there was an error, add the pallet back to the list
        _pallets.insert(palletIndex, pallet);
        notifyListeners();
      });
    } else {
      // In SharedPreferences mode, remove from local list and save
      _pallets.removeAt(palletIndex);
      notifyListeners();
      saveData();
    }
  }

  // Add an item to a pallet
  PalletItem addItemToPallet(int palletId, String itemName) {
    final palletIndex = pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) {
      return PalletItem(id: -1, name: ""); // Return empty item if pallet not found
    }

    // Create new item
    final itemId = _generateItemId(palletId);
    final newItem = PalletItem(
      id: itemId,
      name: itemName,
    );

    if (_dataRepository.dataSource == DataSource.supabase) {
      // In Supabase mode, add to local list for immediate UI update
      pallets[palletIndex].items.add(newItem);
      notifyListeners();
      
      // Use the repository to add the item to Supabase
      _dataRepository.addPalletItem(palletId, newItem).catchError((e) {
        debugPrint('Error adding item to Supabase: $e');
      });
    } else {
      // In SharedPreferences mode, add to local list and save
      pallets[palletIndex].items.add(newItem);
      notifyListeners();
      saveData();
    }

    return newItem; // Return the newly created item
  }

// Helper method to generate a unique item ID
  int _generateItemId(int palletId) {
    final pallet = pallets.firstWhere((p) => p.id == palletId);
    if (pallet.items.isEmpty) return 1;
    return pallet.items.map((i) => i.id).reduce(max) + 1;
  }

  // Remove an item from a pallet
  void removeItemFromPallet(int palletId, int itemId) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) return;

    if (_dataRepository.dataSource == DataSource.supabase) {
      // In Supabase mode, remove from the database using repository
      _dataRepository.removePalletItem(palletId, itemId).then((_) {
        // Remove from local list
        _pallets[palletIndex].items.removeWhere((item) => item.id == itemId);
        notifyListeners();
      }).catchError((e) {
        debugPrint('Error removing item from Supabase: $e');
      });
    } else {
      // In SharedPreferences mode, remove from local list and save
      _pallets[palletIndex].items.removeWhere((item) => item.id == itemId);
      notifyListeners();
      saveData();
    }
  }

  // Mark an item as sold
  void markItemAsSold(int palletId, int itemId, double salePrice) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) return;

    final pallet = _pallets[palletIndex];
    final itemIndex = pallet.items.indexWhere((i) => i.id == itemId);
    if (itemIndex < 0) return;

    // Update the item locally
    final item = pallet.items[itemIndex];
    item.isSold = true;
    item.salePrice = salePrice;
    item.saleDate = DateTime.now();
    
    if (_dataRepository.dataSource == DataSource.supabase) {
      // Use repository to update the item in Supabase
      _dataRepository.updatePalletItem(
        palletId, 
        itemId, 
        {
          'is_sold': true,
          'sale_price': salePrice,
          'sale_date': DateTime.now().toIso8601String(),
        },
      ).catchError((e) {
        debugPrint('Error marking item as sold in Supabase: $e');
        // Revert change on error
        item.isSold = false;
        item.salePrice = 0;
        item.saleDate = null;
        notifyListeners();
      });
    }
    
    notifyListeners();
    
    // For SharedPreferences, we need to call saveData
    if (_dataRepository.dataSource == DataSource.sharedPreferences) {
      saveData();
    }
  }

  // Mark a pallet as closed/sold
  void markPalletAsSold(int palletId) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) return;

    // Update the pallet in the local list
    _pallets[palletIndex].isClosed = true;
    notifyListeners();

    if (_dataRepository.dataSource == DataSource.supabase) {
      // In Supabase mode, update the pallet in the database
      try {
        // Update through repository
        _dataRepository.updatePallet(palletId, {'is_closed': true});
      } catch (e) {
        debugPrint('Error marking pallet as sold in Supabase: $e');
      }
    } else {
      // In SharedPreferences mode, save the changes
      saveData();
    }
  }

  // Calculate metrics for current filter month
  double getProfitForMonth(DateTime month) {
    // Get pallets for the month (already applies tag filter if active)
    List<Pallet> monthPallets = getPalletsByMonth(month);
    
    return monthPallets.fold(0.0, (sum, pallet) {
      double palletProfit = 0.0;
      
      for (var item in pallet.items) {
        if (item.isSold && item.saleDate != null && 
            item.saleDate!.year == month.year && 
            item.saleDate!.month == month.month) {
          
          // Calculate cost per item
          double itemCost = pallet.items.isNotEmpty 
              ? pallet.totalCost / pallet.items.length 
              : 0.0;
          
          palletProfit += item.salePrice - itemCost;
        }
      }
      
      return sum + palletProfit;
    });
  }

  // Calculate metrics for year to date
  double getYTDProfit() {
    final now = DateTime.now();
    double ytdProfit = 0.0;
    
    for (int month = 1; month <= now.month; month++) {
      ytdProfit += getProfitForMonth(DateTime(now.year, month));
    }
    
    return ytdProfit;
  }

  // Calculate total revenue across all pallets (respects tag filter)
  double get totalRevenue => pallets.fold(0.0, (sum, pallet) => sum + pallet.totalRevenue);
  
  // Calculate total cost across all pallets (respects tag filter)
  double get totalCost => pallets.fold(0.0, (sum, pallet) => sum + pallet.totalCost);
  
  // Get total count of sold items across all pallets (respects tag filter)
  int get totalSoldItems => pallets.fold(0, (sum, pallet) => sum + pallet.soldItemsCount);

  // Update item details with new information
  void updateItemDetails({
    required int palletId,
    required int itemId,
    String? name,
    double? retailPrice,
    String? condition,
    double? listPrice,
    String? productCode,
    List<String>? photos,
  }) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) return;

    final itemIndex =
        _pallets[palletIndex].items.indexWhere((i) => i.id == itemId);
    if (itemIndex < 0) return;

    final item = _pallets[palletIndex].items[itemIndex];

    // Update fields if provided
    if (name != null) item.name = name;
    if (retailPrice != null) item.retailPrice = retailPrice;
    if (condition != null) item.condition = condition;
    if (listPrice != null) item.listPrice = listPrice;
    if (productCode != null) item.productCode = productCode;
    if (photos != null) item.photos = photos;

    notifyListeners();
    saveData();
  }

  // Reset all data when switching users
  Future<void> clearAllData() async {
    debugPrint('Clearing all data from PalletModel');
    
    // Set loading state first
    _isLoading = true;
    notifyListeners();
    
    try {
      // Reset in-memory state in a single update
      _pallets = [];
      _savedTags = {};
      _palletIdCounter = 1;
      _itemIdCounter = 1;
      
      // Add a small delay to ensure state is processed
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      debugPrint('Error clearing data: $e');
    } finally {
      // Reset loading state and notify once at the end
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add these fields
  DataSource _dataSource = DataSource.sharedPreferences;
  bool _initialized = false;
  bool _isMigrating = false;
  static const String _migrationCompletedKey = 'has_migrated_data';
  
  // Add this method to refresh tags from pallets
  void _refreshTags() {
    // Extract unique tags from pallets
    _savedTags = _pallets.map((p) => p.tag).where((tag) => tag.isNotEmpty).toSet();
    debugPrint('MODEL-TAGS: Refreshed tags, found ${_savedTags.length} unique tags');
  }
}
