import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pallet_manager/services/data_repository.dart';
import 'package:pallet_manager/services/supabase_service.dart';
import 'dart:math';
import 'package:pallet_manager/utils/log_utils.dart';

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
  String? description;

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
    this.description,
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
        'description': description,
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
        description: json['description'] as String?,
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

  // Add copyWith method to create copies with updated properties
  Pallet copyWith({
    int? id,
    String? name,
    String? tag,
    DateTime? date,
    double? totalCost,
    List<PalletItem>? items,
    bool? isClosed,
    String? supabaseId,
  }) {
    return Pallet(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      date: date ?? this.date,
      totalCost: totalCost ?? this.totalCost,
      items: items ?? this.items,
      isClosed: isClosed ?? this.isClosed,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  // Keep only one toJson method
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

  factory Pallet.fromJson(Map<String, dynamic> json) {
    try {
      // Handle different field name formats (camelCase vs snake_case)
      final id = json['id'] ?? json['original_id'] ?? 0;
      final name = json['name'] ?? 'Unknown Pallet';
      final tag = json['tag'] ?? '';
      
      // Parse date safely
      DateTime date;
      try {
        final dateStr = json['date'];
        date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
      } catch (e) {
        LogUtils.error('Error parsing date', e);
        date = DateTime.now();
      }
      
      // Parse totalCost safely
      double totalCost = 0.0;
      try {
        totalCost = json['totalCost'] != null
          ? (json['totalCost'] as num).toDouble()
          : (json['total_cost'] != null ? (json['total_cost'] as num).toDouble() : 0.0);
      } catch (e) {
        LogUtils.error('Error parsing totalCost', e);
      }
      
      // Parse items safely
      List<PalletItem> items = [];
      try {
        if (json['items'] != null) {
          items = (json['items'] as List).map((e) {
            try {
              return PalletItem.fromJson(e);
            } catch (itemError) {
              LogUtils.error('Error parsing item', itemError);
              return PalletItem(id: 0, name: 'Error Item');
            }
          }).toList();
        } else if (json['pallet_items'] != null) {
          items = (json['pallet_items'] as List).map((e) {
            try {
              return PalletItem.fromJson(e);
            } catch (itemError) {
              LogUtils.error('Error parsing pallet_items', itemError);
              return PalletItem(id: 0, name: 'Error Item');
            }
          }).toList();
        }
      } catch (e) {
        LogUtils.error('Error parsing items list', e);
      }
      
      return Pallet(
        id: id,
        name: name,
        tag: tag,
        date: date,
        totalCost: totalCost,
        items: items,
        isClosed: json['isClosed'] ?? json['is_closed'] ?? false,
        supabaseId: json['supabaseId'] ?? json['id']?.toString(),
      );
    } catch (e) {
      LogUtils.error('Error parsing Pallet JSON', e);
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
    if (_currentTagFilter != tag) {
      _currentTagFilter = tag;
      notifyListeners();
    }
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
    try {
      LogUtils.info('MODEL: Initializing PalletModel');
      await loadData();
      LogUtils.info('MODEL: PalletModel initialization complete');
    } catch (e) {
      LogUtils.error('MODEL: Error initializing PalletModel', e);
      rethrow;
    }
  }

  // Force a reload of data from the repository - consolidated notify calls
  Future<void> forceDataReload() async {
    if (_isLoading) {
      LogUtils.warning('MODEL: Already loading data, skipping redundant forceDataReload() call');
      return;
    }

    _isLoading = true;
    notifyListeners(); // Notify only once at the beginning

    try {
      LogUtils.info('MODEL: Forcing data reload from ${_dataRepository.dataSource}');
      await _dataRepository.forceDataReload();
      await loadData(notifyOnStart: false); // Skip notification at start since we already notified
    } catch (e) {
      LogUtils.error('MODEL: Error in forceDataReload', e);
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify only once at the end
    }
  }

  // Load data from repository with optimized notifications
  Future<void> loadData({bool lazyLoadItems = true, bool notifyOnStart = true}) async {
    LogUtils.info('MODEL: Loading data from ${_dataRepository.dataSource}');
    
    if (notifyOnStart) {
      _isLoading = true;
      notifyListeners();
    } else {
      _isLoading = true;
    }

    try {
      // Load pallets - with lazy loading, we only get the headers first
      _pallets = await _dataRepository.loadPallets(lazyLoadItems: lazyLoadItems);
      
      if (lazyLoadItems) {
        LogUtils.info('MODEL: Loaded ${_pallets.length} pallets with lazy loading');
      } else {
        LogUtils.info('MODEL: Loaded ${_pallets.length} pallets with all items');
      }

      // Load tags
      _savedTags = await _dataRepository.loadTags();
      LogUtils.info('MODEL: Loaded ${_savedTags.length} tags');

      // Only load counters from SharedPreferences
      if (_dataRepository.dataSource == DataSource.sharedPreferences) {
        final counters = await _dataRepository.loadCounters();
        _palletIdCounter = counters['palletIdCounter'] ?? 1;
        _itemIdCounter = counters['itemIdCounter'] ?? 1;
      }
    } catch (e) {
      LogUtils.error('MODEL: Error loading data', e);
    } finally {
      _isLoading = false;
      notifyListeners(); // Single notification at the end
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
      
      LogUtils.info('MODEL: Updated counters: palletIdCounter=$_palletIdCounter, itemIdCounter=$_itemIdCounter');
    }
  }

  // Load items for a specific pallet (for lazy loading)
  Future<void> loadPalletItems(int palletId) async {
    // Check if this pallet already has its items loaded
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex == -1) {
      LogUtils.warning('MODEL: Cannot find pallet $palletId to load items');
      return;
    }

    final pallet = _pallets[palletIndex];
    if (pallet.items.isNotEmpty) {
      LogUtils.info('MODEL: Items for pallet $palletId already loaded, skipping');
      return;
    }

    LogUtils.info('MODEL: Lazy loading items for pallet $palletId');

    try {
      final items = await _dataRepository.loadPalletItems(palletId);
      if (palletIndex >= 0 && palletIndex < _pallets.length) {
        // Update the pallet with its items
        final updatedPallet = _pallets[palletIndex].copyWith(items: items);
        _pallets[palletIndex] = updatedPallet;
        notifyListeners();
        LogUtils.info('MODEL: Loaded ${items.length} items for pallet $palletId');
      }
    } catch (e) {
      LogUtils.error('MODEL: Error loading items for pallet $palletId', e);
    }
  }

  // Save data to the repository - optimized to reduce notifyListeners calls
  Future<void> saveData() async {
    if (_dataRepository.dataSource == DataSource.sharedPreferences) {
      LogUtils.info('MODEL: Saving all data to SharedPreferences');
      try {
        await _dataRepository.savePallets(_pallets);
        await _dataRepository.saveTags(_savedTags);
        await _saveCounters();
  
        // Save tags for auto-complete
        _refreshTags();
  
        LogUtils.info('MODEL: All data saved successfully');
      } catch (e) {
        LogUtils.error('MODEL: Error saving data', e);
      }
    } else {
      LogUtils.info('MODEL: Not saving to SharedPreferences because dataSource is ${_dataRepository.dataSource}');
    }
  }
  
  // Reset all data when switching users
  Future<void> clearAllData() async {
    LogUtils.info('MODEL: Clearing all data from PalletModel');
    try {
      _pallets = [];
      _savedTags = {};
      _palletIdCounter = 1;
      _itemIdCounter = 1;
      _isLoading = false;
      
      await _dataRepository.clearLocalData();
      
      notifyListeners();
    } catch (e) {
      LogUtils.error('MODEL: Error clearing data', e);
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

  // Update just a pallet's name
  void updatePalletName(int palletId, String newName) {
    final index = _pallets.indexWhere((p) => p.id == palletId);
    if (index < 0) return;

    // Update in-memory by creating a copy with the new name
    final updatedPallet = _pallets[index].copyWith(name: newName);
    _pallets[index] = updatedPallet;
    
    // Save changes
    if (_dataRepository.dataSource == DataSource.supabase) {
      // For Supabase, update through repository
      _dataRepository.updatePallet(updatedPallet);
    } else {
      // For SharedPreferences, just save
      saveData();
    }
    
    notifyListeners();
  }

  // Add a new pallet
  void addPallet(Pallet pallet) {
    LogUtils.info('MODEL: Adding new pallet ${pallet.name} with ID ${pallet.id}');
    
    // Add to in-memory list
    _pallets.add(pallet);
    
    // Update tag store if the pallet has a tag
    if (pallet.tag.isNotEmpty) {
      _savedTags.add(pallet.tag);
    }
    
    // Update ID counter to be one more than the highest pallet ID
    _palletIdCounter = max(_palletIdCounter, pallet.id + 1);
    
    // Save changes
    if (_dataRepository.dataSource == DataSource.supabase) {
      // For Supabase, add through repository
      _dataRepository.addPallet(pallet);
    } else {
      // For SharedPreferences, just save
      saveData();
    }
    
    notifyListeners();
  }

  // Generate a unique pallet ID for use by dialog utilities
  int generatePalletId() {
    return _palletIdCounter;
  }

  // Optimize removePallet method
  void removePallet(int palletId) async {
    LogUtils.info('MODEL: Called removePallet for palletId: $palletId');
    
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex == -1) {
      LogUtils.warning('MODEL: Pallet not found in list');
      return;
    }
    
    final pallet = _pallets[palletIndex];
    
    // Remove from list first for immediate UI update
    _pallets.removeAt(palletIndex);
    notifyListeners();
    
    // Then remove from storage
    try {
      if (_dataRepository.dataSource == DataSource.sharedPreferences) {
        // For local storage, we need to save the entire list
        await saveData();
      } else {
        // For Supabase, we can delete just this pallet
        await _dataRepository.removePallet(pallet);
        LogUtils.info('MODEL: Pallet successfully removed from Supabase');
      }
    } catch (e) {
      LogUtils.error('MODEL: Error removing pallet from Supabase', e);
      
      // Add pallet back if there was an error
      _pallets.insert(palletIndex, pallet);
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
  void removeItemFromPallet(int palletId, int itemId) async {
    // Find the pallet
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex == -1) return;
    
    final pallet = _pallets[palletIndex];
    final itemIndex = pallet.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;
    
    final item = pallet.items[itemIndex];
    
    // Create a new pallet with the item removed
    final updatedItems = List<PalletItem>.from(pallet.items)..removeAt(itemIndex);
    final updatedPallet = pallet.copyWith(items: updatedItems);
    
    // Update UI
    _pallets[palletIndex] = updatedPallet;
    notifyListeners();
    
    // Update storage
    try {
      if (_dataRepository.dataSource == DataSource.sharedPreferences) {
        // For local storage, just save everything
        await saveData();
      } else {
        // For Supabase, we can delete just this item
        await _dataRepository.removePalletItem(palletId, itemId);
        LogUtils.info('MODEL: Item successfully removed from Supabase');
      }
    } catch (e) {
      LogUtils.error('MODEL: Error removing item from Supabase', e);
      
      // Revert changes on error
      _pallets[palletIndex] = pallet;
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

  // Add the missing _saveCounters method
  Future<void> _saveCounters() async {
    if (_dataRepository.dataSource == DataSource.sharedPreferences) {
      await _dataRepository.saveCounters(
        palletIdCounter: _palletIdCounter,
        itemIdCounter: _itemIdCounter,
      );
      LogUtils.info('MODEL: Updated counters: palletIdCounter=$_palletIdCounter, itemIdCounter=$_itemIdCounter');
    }
  }

  // Add the missing markItemAsSold method
  void markItemAsSold(int palletId, int itemId, double salePrice) async {
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
        item
      ).catchError((e) {
        LogUtils.error('Error marking item as sold in Supabase', e);
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

  // Add the missing markPalletAsSold method
  void markPalletAsSold(int palletId) async {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) return;

    // Update the pallet in the local list
    _pallets[palletIndex].isClosed = true;
    notifyListeners();

    if (_dataRepository.dataSource == DataSource.supabase) {
      // In Supabase mode, update the pallet in the database
      try {
        // Update through repository
        await _dataRepository.updatePallet(_pallets[palletIndex]);
      } catch (e) {
        LogUtils.error('Error marking pallet as sold in Supabase', e);
      }
    } else {
      // In SharedPreferences mode, save the changes
      saveData();
    }
  }

  // Add the missing updatePalletTag method
  void updatePalletTag(int palletId, String newTag) async {
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
        await _dataRepository.updatePallet(_pallets[palletIndex]);
      } catch (e) {
        LogUtils.error('Error updating pallet tag in Supabase', e);
      }
    } else {
      // In SharedPreferences mode, save the changes
      saveData();
    }
  }

  // Check if a pallet name already exists - used by dialog utilities
  bool palletNameExists(String name) {
    return _pallets.any((p) => p.name.toLowerCase() == name.toLowerCase());
  }

  // Fix addItemToPallet to return a non-Future PalletItem
  PalletItem addItemToPallet(int palletId, String itemName) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex < 0) {
      return PalletItem(id: -1, name: ""); // Return empty item if pallet not found
    }

    // Create new item
    final itemId = _generateItemId(palletId);
    final newItem = PalletItem(
      id: itemId,
      name: itemName,
    );

    // Add to local list for immediate UI response
    _pallets[palletIndex].items.add(newItem);
    notifyListeners();
    
    // Handle storage separately
    if (_dataRepository.dataSource == DataSource.supabase) {
      // Use the repository to add the item to Supabase
      _dataRepository.addPalletItem(palletId, newItem).catchError((e) {
        LogUtils.error('MODEL: Error adding item to Supabase', e);
        // Remove the item from the local list on error
        _pallets[palletIndex].items.removeWhere((item) => item.id == itemId);
        notifyListeners();
      });
    } else {
      // For SharedPreferences, save all data
      saveData();
    }

    return newItem; // Return the newly created item
  }

  // Method to help with migrating user data to Supabase
  Future<bool> migrateDataToSupabase() async {
    LogUtils.info('MODEL: Starting data migration to Supabase');
    try {
      // Switch data repository to Supabase
      await _dataRepository.migrateDataToSupabase();
      
      // Reload data from Supabase
      await loadData(lazyLoadItems: false);
      
      LogUtils.info('MODEL: Migration completed successfully');
      return true;
    } catch (e) {
      LogUtils.error('MODEL: Migration failed', e);
      return false;
    }
  }

  // Add method to check and prepare migration
  Future<bool> checkAndPrepareMigration() async {
    try {
      // Check if user has data in SharedPreferences that needs migration
      if (_pallets.isEmpty) {
        // Force reload from SharedPreferences
        _dataRepository.setDataSource(DataSource.sharedPreferences);
        await loadData();
      }
      
      // If we still have no data, no migration needed
      return _pallets.isNotEmpty;
    } catch (e) {
      LogUtils.error('Error checking migration status', e);
      return false;
    }
  }

  // Add this method to refresh tags from pallets
  void _refreshTags() {
    // Extract unique tags from pallets
    _savedTags = _pallets.map((p) => p.tag).where((tag) => tag.isNotEmpty).toSet();
    debugPrint('MODEL-TAGS: Refreshed tags, found ${_savedTags.length} unique tags');
  }

  // Getters
  List<Pallet> get pallets => _pallets;
  Set<String> get tags => _savedTags;
  Set<String> get savedTags => _savedTags;
  bool get isLoading => _isLoading;
  String? get currentTagFilter => _currentTagFilter;
  DataSource get dataSource => _dataRepository.dataSource;
  int get palletIdCounter => _palletIdCounter;
  int get itemIdCounter => _itemIdCounter;
  
  // Check if a pallet with this name already exists
  bool palletNameExists(String name) {
    return _pallets.any((p) => p.name.toLowerCase() == name.toLowerCase());
  }
}
