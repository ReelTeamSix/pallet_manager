import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PalletItem {
  int id;
  String name;
  double salePrice;
  bool isSold;
  DateTime? saleDate;
  double allocatedCost; // Add a field to track allocated cost

  PalletItem({
    required this.id,
    required this.name,
    this.salePrice = 0.0,
    this.isSold = false,
    this.saleDate,
    this.allocatedCost = 0.0, // Initialize with zero
  });

  // Update toJson to include allocatedCost
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'salePrice': salePrice,
        'isSold': isSold,
        'saleDate': saleDate?.toIso8601String(),
        'allocatedCost': allocatedCost,
      };

  // Update fromJson to handle allocatedCost
  factory PalletItem.fromJson(Map<String, dynamic> json) => PalletItem(
        id: json['id'],
        name: json['name'],
        salePrice: (json['salePrice'] as num).toDouble(),
        isSold: json['isSold'],
        saleDate:
            json['saleDate'] != null ? DateTime.parse(json['saleDate']) : null,
        allocatedCost: json['allocatedCost'] != null
            ? (json['allocatedCost'] as num).toDouble()
            : 0.0,
      );
}

class Pallet {
  int id;
  String name;
  String tag;
  DateTime date;
  double totalCost;
  List<PalletItem> items;
  bool isClosed;

  Pallet({
    required this.id, 
    required this.name, 
    required this.tag, 
    required this.totalCost, 
    required this.date, 
    List<PalletItem>? items, 
    this.isClosed = false
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
  };

  factory Pallet.fromJson(Map<String, dynamic> json) => Pallet(
    id: json['id'],
    name: json['name'],
    tag: json['tag'],
    date: DateTime.parse(json['date']),
    totalCost: (json['totalCost'] as num).toDouble(),
    items: (json['items'] as List).map((e) => PalletItem.fromJson(e)).toList(),
    isClosed: json['isClosed'] ?? false,
  );
}

class PalletModel extends ChangeNotifier {
  List<Pallet> _pallets = [];
  int _palletIdCounter = 1;
  int _itemIdCounter = 1;
  bool _isLoading = false;
  DateTime _currentFilterMonth = DateTime.now();
  Set<String> _savedTags = {};
  String? _currentTagFilter;

  List<Pallet> get pallets => _currentTagFilter != null 
      ? _pallets.where((p) => p.tag == _currentTagFilter).toList() 
      : _pallets;
  
  bool get isLoading => _isLoading;
  DateTime get currentFilterMonth => _currentFilterMonth;
  Set<String> get savedTags => _savedTags;
  String? get currentTagFilter => _currentTagFilter;

  // Set tag filter
  void setTagFilter(String? tag) {
    _currentTagFilter = tag;
    notifyListeners();
  }

  // Add new tag to saved tags
  void addTag(String tag) {
    if (tag.isNotEmpty) {
      _savedTags.add(tag);
      saveData();
      notifyListeners();
    }
  }

  // Remove tag from saved tags
  void removeTag(String tag) {
    _savedTags.remove(tag);
    saveData();
    notifyListeners();
  }

  // Update pallet tag
  void updatePalletTag(int palletId, String newTag) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex >= 0) {
      _pallets[palletIndex].tag = newTag;
      
      // Add to saved tags if it's new
      if (newTag.isNotEmpty) {
        _savedTags.add(newTag);
      }
      
      notifyListeners();
      saveData();
    }
  }

  bool palletNameExists(String name) {
    // Search through all pallets (not just filtered ones) and compare case-insensitively
    return _pallets
        .any((pallet) => pallet.name.toLowerCase() == name.toLowerCase());
  }

// Update a pallet's name with validation
  void updatePalletName(int palletId, String newName) {
    // Prevent duplicate names
    if (newName.isEmpty ||
        (_pallets.any((p) =>
            p.id != palletId &&
            p.name.toLowerCase() == newName.toLowerCase()))) {
      return; // Reject the change - name is empty or already exists
    }

    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex >= 0) {
      _pallets[palletIndex].name = newName;
      notifyListeners();
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

  PalletModel() {
    loadData();
  }

  // Optimized to batch save
  Future<void> saveData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pallets', jsonEncode(_pallets.map((p) => p.toJson()).toList()));
      await prefs.setInt('palletIdCounter', _palletIdCounter);
      await prefs.setInt('itemIdCounter', _itemIdCounter);
      await prefs.setStringList('savedTags', _savedTags.toList());
    } catch (e) {
      debugPrint('Error saving data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final palletsString = prefs.getString('pallets');
      final savedTagsList = prefs.getStringList('savedTags');
      
      if (palletsString != null) {
        final decodedList = jsonDecode(palletsString) as List<dynamic>;
        _pallets = decodedList.map((e) => Pallet.fromJson(e)).toList();
        _palletIdCounter = prefs.getInt('palletIdCounter') ?? 1;
        _itemIdCounter = prefs.getInt('itemIdCounter') ?? 1;
      }
      
      if (savedTagsList != null) {
        _savedTags = savedTagsList.toSet();
      }
      
      // Also collect all tags from existing pallets
      for (var pallet in _pallets) {
        if (pallet.tag.isNotEmpty) {
          _savedTags.add(pallet.tag);
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int generatePalletId() => _palletIdCounter++;

  void addPallet(Pallet pallet) {
    _pallets.add(pallet);
    
    // Add to saved tags if not empty
    if (pallet.tag.isNotEmpty) {
      _savedTags.add(pallet.tag);
    }
    
    notifyListeners();
    saveData();
  }

  void removePallet(int palletId) {
    _pallets.removeWhere((p) => p.id == palletId);
    notifyListeners();
    saveData();
  }

  void addItemToPallet(int palletId, String itemName) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex >= 0) {
      _pallets[palletIndex].items.add(
        PalletItem(id: _itemIdCounter++, name: itemName)
      );
      notifyListeners();
      saveData();
    }
  }

  void removeItemFromPallet(int palletId, int itemId) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex >= 0) {
      _pallets[palletIndex].items.removeWhere((item) => item.id == itemId);
      notifyListeners();
      saveData();
    }
  }

  void markItemAsSold(int palletId, int itemId, double salePrice) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex >= 0) {
      final pallet = _pallets[palletIndex];
      final itemIndex = pallet.items.indexWhere((i) => i.id == itemId);

      if (itemIndex >= 0) {
        // Calculate cost per item at the time of sale
        double costPerItem = pallet.items.isNotEmpty
            ? pallet.totalCost / pallet.items.length
            : 0.0;

        // Store the allocated cost with the item
        pallet.items[itemIndex].allocatedCost = costPerItem;
        pallet.items[itemIndex].isSold = true;
        pallet.items[itemIndex].salePrice = salePrice;
        pallet.items[itemIndex].saleDate = DateTime.now();

        notifyListeners();
        saveData();
      }
    }
  }

  void markPalletAsSold(int palletId) {
    final palletIndex = _pallets.indexWhere((p) => p.id == palletId);
    if (palletIndex >= 0) {
      _pallets[palletIndex].isClosed = true;
      notifyListeners();
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

  // Calculate total profit across all pallets (respects tag filter)
  double get totalProfit => pallets.fold(0.0, (sum, pallet) => sum + pallet.profit);
  
  // Calculate total revenue across all pallets (respects tag filter)
  double get totalRevenue => pallets.fold(0.0, (sum, pallet) => sum + pallet.totalRevenue);
  
  // Calculate total cost across all pallets (respects tag filter)
  double get totalCost => pallets.fold(0.0, (sum, pallet) => sum + pallet.totalCost);
  
  // Get total count of sold items across all pallets (respects tag filter)
  int get totalSoldItems => pallets.fold(0, (sum, pallet) => sum + pallet.soldItemsCount);
}

