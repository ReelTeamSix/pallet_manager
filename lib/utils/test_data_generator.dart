import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pallet_manager/pallet_model.dart';

/// A utility class to generate test data in SharedPreferences
/// This is used for testing the migration process from SharedPreferences to Supabase
class TestDataGenerator {
  static final Random _random = Random();
  
  /// Generate a random set of test data in SharedPreferences
  static Future<void> generateTestData({
    int palletCount = 5,
    int maxItemsPerPallet = 10,
    Set<String> tags = const {'Electronics', 'Clothing', 'Toys', 'Home Goods', 'Books'},
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear any existing data first to avoid conflicts
      await resetAllData();
      
      print('🔄 Starting test data generation: $palletCount pallets with up to $maxItemsPerPallet items per pallet');
      
      // Wait a bit after clearing data
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Generate pallets with items
      final List<Map<String, dynamic>> pallets = [];
      int palletIdCounter = 1;
      int itemIdCounter = 1;
      
      for (int i = 0; i < palletCount; i++) {
        final palletId = palletIdCounter++;
        final tag = tags.elementAt(_random.nextInt(tags.length));
        final itemCount = _random.nextInt(maxItemsPerPallet) + 1; // At least 1 item
        final palletDate = DateTime.now().subtract(Duration(days: _random.nextInt(60)));
        final palletCost = (_random.nextInt(5000) + 1000) / 100; // $10-$60
        
        // Generate items for this pallet
        final List<Map<String, dynamic>> items = [];
        
        for (int j = 0; j < itemCount; j++) {
          final itemId = itemIdCounter++;
          final isSold = _random.nextBool();
          final salePrice = (_random.nextInt(3000) + 500) / 100; // $5-$35
          final allocatedCost = palletCost / itemCount;
          
          // Ensure all numeric values are properly specified
          final item = {
            'id': itemId,
            'name': 'Test Item ${itemId}',
            // Use camelCase format matching the model
            'salePrice': salePrice,
            'isSold': isSold,
            'saleDate': isSold ? palletDate.add(Duration(days: _random.nextInt(30))).toIso8601String() : null,
            'allocatedCost': allocatedCost,
            'retailPrice': salePrice * 1.5,
            'condition': _getRandomCondition(),
            'listPrice': salePrice * 1.2,
            'productCode': 'PROD-${_random.nextInt(10000)}',
            'photos': null,
          };
          
          items.add(item);
        }
        
        // Create the pallet - use camelCase format matching the model
        final pallet = {
          'id': palletId,
          'name': 'Test Pallet ${palletId}',
          'tag': tag,
          'date': palletDate.toIso8601String(),
          'totalCost': palletCost,
          'isClosed': _random.nextBool(),
          'items': items,
        };
        
        pallets.add(pallet);
      }
      
      // Save in separate try-catch blocks with delays
      try {
        // Save pallets to SharedPreferences
        final palletsJson = json.encode(pallets);
        print('💾 Saving ${pallets.length} pallets to SharedPreferences');
        await prefs.setString('pallets', palletsJson);
        
        // Check if the data was saved correctly
        final savedPalletsJson = prefs.getString('pallets');
        if (savedPalletsJson == null) {
          print('❌ ERROR: Failed to save pallets to SharedPreferences - data is null after save');
        } else {
          final List<dynamic> savedPalletsList = json.decode(savedPalletsJson);
          print('✅ Verified ${savedPalletsList.length} pallets were saved correctly');
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('❌ Error saving pallets to SharedPreferences: $e');
      }
      
      try {
        // Save tags to SharedPreferences
        final tagsJson = json.encode(tags.toList());
        print('💾 Saving ${tags.length} tags to SharedPreferences');
        await prefs.setString('tags', tagsJson);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('❌ Error saving tags to SharedPreferences: $e');
      }
      
      try {
        // Save counters to SharedPreferences
        print('💾 Saving palletIdCounter=$palletIdCounter');
        await prefs.setInt('palletIdCounter', palletIdCounter);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('❌ Error saving palletIdCounter to SharedPreferences: $e');
      }
      
      try {
        print('💾 Saving itemIdCounter=$itemIdCounter');
        await prefs.setInt('itemIdCounter', itemIdCounter);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('❌ Error saving itemIdCounter to SharedPreferences: $e');
      }
      
      try {
        // Reset migration flag (in case it was set before)
        print('💾 Setting has_migrated_data=false');
        await prefs.setBool('has_migrated_data', false);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('❌ Error setting migration flag to SharedPreferences: $e');
      }
      
      // Add final delay before returning
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Do a final check to verify the data is there
      try {
        final verifyPalletsJson = prefs.getString('pallets');
        if (verifyPalletsJson == null) {
          print('⚠️ WARNING: Pallets data not found in SharedPreferences after generation');
        } else {
          final List<dynamic> verifyPalletsList = json.decode(verifyPalletsJson);
          print('✅ Final verification: ${verifyPalletsList.length} pallets in SharedPreferences');
          
          // Try to parse one pallet as a final verification
          try {
            final testPallet = verifyPalletsList.first;
            final palletName = testPallet['name'];
            print('✅ Verified first pallet can be accessed: $palletName');
          } catch (e) {
            print('⚠️ Warning: Could not verify pallet format: $e');
          }
        }
      } catch (e) {
        print('❌ Error during final verification: $e');
      }
      
      print('✅ Test data generated successfully:');
      print('- $palletCount pallets');
      print('- ${itemIdCounter - 1} total items');
      print('- ${tags.length} tags');
      
    } catch (e) {
      print('❌ Error generating test data: $e');
    }
  }
  
  /// Generate a specific amount of test data in SharedPreferences
  static Future<void> generateSpecificTestData({
    required int totalPallets,
    required int totalItems,
    required Set<String> tags,
  }) async {
    try {
      // Calculate average items per pallet (with a minimum of 1)
      final int avgItemsPerPallet = max(1, totalItems ~/ totalPallets);
      
      // Generate the test data
      await generateTestData(
        palletCount: totalPallets,
        maxItemsPerPallet: avgItemsPerPallet * 2, // Allow some variation
        tags: tags,
      );
      
    } catch (e) {
      print('❌ Error generating specific test data: $e');
    }
  }
  
  /// Reset all local data (clear SharedPreferences)
  static Future<void> resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove all saved data with individual try-catch blocks
      try {
        await prefs.remove('pallets');
        // Small delay between operations to avoid widget tree issues
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        // Use print instead of debugPrint to avoid Directionality issues
        print('Error removing pallets: $e');
      }
      
      try {
        await prefs.remove('tags');
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        print('Error removing tags: $e');
      }
      
      try {
        await prefs.remove('palletIdCounter');
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        print('Error removing palletIdCounter: $e');
      }
      
      try {
        await prefs.remove('itemIdCounter');
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        print('Error removing itemIdCounter: $e');
      }
      
      try {
        await prefs.remove('has_migrated_data');
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        print('Error removing migration flag: $e');
      }
      
      // Add delay before returning
      await Future.delayed(const Duration(milliseconds: 300));
      
      print('✅ All local data has been reset');
    } catch (e) {
      print('❌ Error resetting local data: $e');
    }
  }
  
  /// Helper method to get a random condition value
  static String _getRandomCondition() {
    final conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];
    return conditions[_random.nextInt(conditions.length)];
  }
} 