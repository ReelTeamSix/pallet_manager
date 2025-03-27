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

  // Add toJson method to include supabaseId
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tag': tag,
      'totalCost': totalCost,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'isClosed': isClosed,
      'supabaseId': supabaseId,
    };
  }

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

  // Track lazily loaded pallet items
  final Map<int, bool> _loadedPalletItems = {};

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

  // Constructor to initialize with a data repository
  PalletModel(DataRepository dataRepository) 
      : _dataRepository = dataRepository;
  
  // Method to explicitly initialize the model after widgets are built
  Future<void> initialize() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();
    
    try {
      debugPrint('MODEL: Initializing PalletModel');
      await forceDataReload();
      debugPrint('MODEL: PalletModel initialization complete');
    } catch (e) {
      debugPrint('MODEL: Error initializing PalletModel: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force a reload of data from the repository
  Future<void> forceDataReload() async {
    if (_isLoading) {
      debugPrint('MODEL: Already loading data, skipping redundant forceDataReload() call');
      return;
    }
    
    debugPrint('MODEL: Forcing data reload from ${_dataRepository.dataSource}');
    
    _isLoading = true;
    // Only notify at the beginning and end of the operation to reduce UI rebuilds
    notifyListeners();
    
    try {
      await loadData();
      // Clear the loaded items tracking when forcing reload
      _loadedPalletItems.clear();
    } catch (e) {
      debugPrint('MODEL: Error in forceDataReload: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load data from the repository with optional lazy loading for items
  Future<void> loadData() async {
    debugPrint('MODEL: Loading data from ${_dataRepository.dataSource}');
    
    try {
      // Load pallets from the current data source
      if (_dataRepository.dataSource == DataSource.supabase) {
        // For Supabase, load pallets with lazy loading for items
        _pallets = await _dataRepository.loadPallets(lazyLoadItems: true);
        debugPrint('MODEL: Loaded ${_pallets.length} pallets with lazy loading');
      } else {
        // For SharedPreferences, load all data at once
        _pallets = await _dataRepository.loadPallets();
        debugPrint('MODEL: Loaded ${_pallets.length} pallets from SharedPreferences');
      }
      
      // Load tags from the current data source
      _savedTags = await _dataRepository.loadTags();
      debugPrint('MODEL: Loaded ${_savedTags.length} tags');
      
      // Load counters from SharedPreferences (only used for local data)
      final counters = await _dataRepository.loadCounters();
      _palletIdCounter = counters['palletIdCounter'] ?? 1;
      _itemIdCounter = counters['itemIdCounter'] ?? 1;
      
      // Update the highest IDs if needed
      _updateHighestIds();
    } catch (e) {
      debugPrint('MODEL: Error loading data: $e');
      throw e; // Rethrow to allow caller to handle
    }
  }

  // Helper method to update the highest IDs based on loaded pallets
  void _updateHighestIds() {
    if (_pallets.isNotEmpty) {
      _palletIdCounter = max(_palletIdCounter, _pallets.map((p) => p.id).reduce(max) + 1);
      
      if (_pallets.any((p) => p.items.isNotEmpty)) {
        _itemIdCounter = max(_itemIdCounter,
            _pallets.expand((p) => p.items.isEmpty ? [0] : p.items.map((i) => i.id)).reduce(max) + 1);
      }
      
      debugPrint('MODEL: Updated counters: palletIdCounter=$_palletIdCounter, itemIdCounter=$_itemIdCounter');
    }
  }

  // Load items for a specific pallet (for lazy loading)
  Future<void> loadPalletItems(int palletId) async {
    if (_dataRepository.dataSource != DataSource.supabase) {
      // Not needed for SharedPreferences mode
      return;
    }
    
    if (_loadedPalletItems[palletId] == true) {
      // Items already loaded
      debugPrint('MODEL: Items for pallet $palletId already loaded, skipping');
      return;
    }
    
    debugPrint('MODEL: Lazy loading items for pallet $palletId');
    
    try {
      final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
      if (palletIndex < 0) {
        debugPrint('MODEL: Cannot find pallet $palletId to load items');
        return;
      }
      
      // Load items for this pallet
      final pallet = _pallets[palletIndex];
      final items = await _dataRepository.loadPalletItems(palletId);
      
      // Update the pallet with the loaded items
      pallet.items = items;
      _loadedPalletItems[palletId] = true;
      
      debugPrint('MODEL: Loaded ${items.length} items for pallet $palletId');
      notifyListeners();
    } catch (e) {
      debugPrint('MODEL: Error loading items for pallet $palletId: $e');
    }
  }

  // Save data to the repository - optimized to reduce notifyListeners calls
  Future<void> saveData() async {
    if (_dataRepository.dataSource == DataSource.sharedPreferences) {
      debugPrint('MODEL: Saving all data to SharedPreferences');
      
      try {
        // Save pallets
        await _dataRepository.savePallets(_pallets);
        
        // Save tags
        await _dataRepository.saveTags(_savedTags);
        
        // Save counters
        await _dataRepository.saveCounters(_palletIdCounter, _itemIdCounter);
        
        debugPrint('MODEL: All data saved successfully');
      } catch (e) {
        debugPrint('MODEL: Error saving data: $e');
      }
    } else {
      debugPrint('MODEL: Not saving to SharedPreferences because dataSource is ${_dataRepository.dataSource}');
    }
  }
  
  // Reset all data when switching users
  Future<void> clearAllData() async {
    debugPrint('MODEL: Clearing all data from PalletModel');
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Reset in-memory state
      _pallets = [];
      _savedTags = {};
      _palletIdCounter = 1;
      _itemIdCounter = 1;
      _loadedPalletItems.clear();
    } catch (e) {
      debugPrint('MODEL: Error clearing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update pallet
  void updatePallet(Pallet pallet) {
    final index = _pallets.indexWhere((p) => p.id == pallet.id);
    if (index < 0) return;

    // Update in-memory
    _pallets[index] = pallet;
    
    // Save changes
    if (_dataRepository.dataSource == DataSource.supabase) {
      // For Supabase, update through repository
      _dataRepository.updatePallet(pallet);
    } else {
      // For SharedPreferences, just save
      saveData();
    }
    
    notifyListeners();
  }

  // Optimize removePallet method
  void removePallet(int palletId) {
    debugPrint('MODEL: Called removePallet for palletId: $palletId');
    
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) {
      debugPrint('MODEL: Pallet not found in list');
      return;
    }

    final pallet = _pallets[palletIndex];
    
    // Remove from local list first for UI responsiveness
    _pallets.removeAt(palletIndex);
    
    // Remove tracking for lazy loading
    _loadedPalletItems.remove(palletId);
    
    if (_dataRepository.dataSource == DataSource.supabase) {
      // For Supabase, notify UI immediately and then remove in background
      notifyListeners();
      
      _dataRepository.removePallet(pallet).then((_) {
        debugPrint('MODEL: Pallet successfully removed from Supabase');
      }).catchError((e) {
        debugPrint('MODEL: Error removing pallet from Supabase: $e');
        // If error, add back to the list
        _pallets.insert(palletIndex, pallet);
        notifyListeners();
      });
    } else {
      // For SharedPreferences, just save and notify
      saveData();
      notifyListeners();
    }
  }

  // Helper method to generate a unique item ID
  int _generateItemId(int palletId) {
    final pallet = pallets.firstWhere((p) => p.id == palletId);
    if (pallet.items.isEmpty) return 1;
    return pallet.items.map((i) => i.id).reduce(max) + 1;
  }

  // Optimize removeItemFromPallet method
  void removeItemFromPallet(int palletId, int itemId) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) return;

    final pallet = _pallets[palletIndex];
    final itemIndex = pallet.items.indexWhere((item) => item.id == itemId);
    if (itemIndex < 0) return;
    
    // Remove from local list first
    pallet.items.removeAt(itemIndex);
    
    if (_dataRepository.dataSource == DataSource.supabase) {
      // For Supabase, notify UI immediately and then remove in background
      notifyListeners();
      
      _dataRepository.removePalletItem(palletId, itemId).then((_) {
        debugPrint('MODEL: Item successfully removed from Supabase');
      }).catchError((e) {
        debugPrint('MODEL: Error removing item from Supabase: $e');
        // If error, add back to the list
        if (itemIndex >= 0 && itemIndex <= pallet.items.length) {
          pallet.items.insert(itemIndex, PalletItem(id: itemId, name: 'Error: Item restore failed'));
          notifyListeners();
        }
      });
    } else {
      // For SharedPreferences, just save and notify
      saveData();
      notifyListeners();
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

  // Update pallet name
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

  // Add this method to refresh tags from pallets
  void _refreshTags() {
    // Extract unique tags from pallets
    _savedTags = _pallets.map((p) => p.tag).where((tag) => tag.isNotEmpty).toSet();
    debugPrint('MODEL-TAGS: Refreshed tags, found ${_savedTags.length} unique tags');
  }
}
