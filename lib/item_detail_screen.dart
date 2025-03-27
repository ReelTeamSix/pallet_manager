import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'pallet_model.dart';
import 'responsive_utils.dart';
import 'theme/theme_extensions.dart';

class ItemDetailScreen extends StatefulWidget {
  final Pallet pallet;
  final PalletItem item;

  const ItemDetailScreen({
    super.key,
    required this.pallet,
    required this.item,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _retailPriceController;
  late TextEditingController _listPriceController;
  late TextEditingController _productCodeController;
  late TabController _tabController;
  
  String _selectedCondition = 'New';
  bool _isEditing = false;
  bool _isScanning = false;
  List<String> _itemPhotos = [];
  final ImagePicker _picker = ImagePicker();
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DateTime _lastRefreshTime = DateTime.now();
  late Key _lifecycleKey;
  late DateTime _lastLifecycleRefresh;
  
  // Condition options with enhanced display details
  final List<Map<String, dynamic>> _conditionOptions = [
    {'value': 'New', 'color': Colors.green, 'icon': Icons.star_rate},
    {'value': 'Like New', 'color': Colors.green.shade300, 'icon': Icons.star_half},
    {'value': 'Very Good', 'color': Colors.lightGreen, 'icon': Icons.thumb_up},
    {'value': 'Good', 'color': Colors.amber, 'icon': Icons.thumb_up_outlined},
    {'value': 'Acceptable', 'color': Colors.orange, 'icon': Icons.check_circle_outline},
    {'value': 'For Parts', 'color': Colors.red, 'icon': Icons.handyman},
  ];

  @override
  void initState() {
    super.initState();
    _lifecycleKey = UniqueKey();
    _lastLifecycleRefresh = DateTime.now();

    _initializeControllers();

    // Set up tab controller for photo gallery
    _tabController = TabController(length: 2, vsync: this);

    // Start in edit mode for new items with no details yet
    if (widget.item.name.isEmpty &&
        !widget.pallet.isClosed &&
        !widget.item.isSold) {
      _isEditing = true;
    }
    
    // Add observer to handle app lifecycle
    WidgetsBinding.instance.addObserver(
      _AppLifecycleObserver(onResume: _handleAppResume)
    );
  }

  // Optimize app resume handling with more efficient state management
  void _handleAppResume() {
    // Prevent excessive refreshes within short time periods
    final now = DateTime.now();
    if (now.difference(_lastRefreshTime).inSeconds < 2) {
      return;
    }
    _lastRefreshTime = now;

    if (mounted) {
      // Get the latest data from the model using Provider
      final palletModel = Provider.of<PalletModel>(context, listen: false);
      
      try {
        // Get the latest pallet
        final currentPallet = palletModel.pallets.firstWhere(
          (p) => p.id == widget.pallet.id,
        );
        
        // Get the latest item
        final currentItem = currentPallet.items.firstWhere(
          (i) => i.id == widget.item.id,
        );
        
        // Only update if data has changed and we're not currently editing
        if (!_isEditing && _hasItemDataChanged(currentItem)) {
          setState(() {
            // Update controllers with latest data
            _nameController.text = currentItem.name;
            _retailPriceController.text = currentItem.retailPrice?.toString() ?? '';
            _listPriceController.text = currentItem.listPrice?.toString() ?? '';
            _productCodeController.text = currentItem.productCode ?? '';
            _selectedCondition = currentItem.condition ?? 'New';
            
            if (currentItem.photos != null) {
              _itemPhotos = List.from(currentItem.photos!);
            }
          });
        }
      } catch (e) {
        // Handle case where item or pallet is no longer in the model
        // (for example, if it was deleted while app was in background)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item may have been removed or updated'))
        );
      }
    }
  }
  
  // Helper to check if item data has changed
  bool _hasItemDataChanged(PalletItem currentItem) {
    return widget.item.name != currentItem.name ||
        widget.item.retailPrice != currentItem.retailPrice ||
        widget.item.listPrice != currentItem.listPrice ||
        widget.item.productCode != currentItem.productCode ||
        widget.item.condition != currentItem.condition ||
        widget.item.isSold != currentItem.isSold ||
        !_arePhotoListsEqual(widget.item.photos, currentItem.photos);
  }

  void _disposeControllers() {
    _nameController.dispose();
    _retailPriceController.dispose();
    _listPriceController.dispose();
    _productCodeController.dispose();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.item.name);
    _retailPriceController =
        TextEditingController(text: widget.item.retailPrice?.toString() ?? '');
    _listPriceController =
        TextEditingController(text: widget.item.listPrice?.toString() ?? '');
    _productCodeController =
        TextEditingController(text: widget.item.productCode ?? '');

    // Initialize condition if saved
    if (widget.item.condition != null && widget.item.condition!.isNotEmpty) {
      _selectedCondition = widget.item.condition!;
    }

    // Initialize photos
    if (widget.item.photos != null) {
      _itemPhotos = List.from(widget.item.photos!);
    }
  }

  @override
  void dispose() {
    // Remove observer before disposing
    WidgetsBinding.instance.removeObserver(
      _AppLifecycleObserver(onResume: _handleAppResume)
    );
    _disposeControllers();
    _tabController.dispose();
    super.dispose();
  }

  // Get current item from model for rebuilds after lifecycle events
  PalletItem _getCurrentItem() {
    try {
      final palletModel = Provider.of<PalletModel>(context, listen: false);
      final currentPallet = palletModel.pallets.firstWhere(
        (p) => p.id == widget.pallet.id,
        orElse: () => widget.pallet,
      );
      
      final currentItem = currentPallet.items.firstWhere(
        (i) => i.id == widget.item.id,
        orElse: () => widget.item,
      );
      
      return currentItem;
    } catch (e) {
      return widget.item;
    }
  }

  // Compare item data to detect changes
  bool _hasItemChanged(PalletItem current) {
    // Check if any properties have changed
    if (widget.item.name != current.name ||
        widget.item.retailPrice != current.retailPrice ||
        widget.item.listPrice != current.listPrice ||
        widget.item.productCode != current.productCode ||
        widget.item.condition != current.condition ||
        widget.item.isSold != current.isSold ||
        !_arePhotoListsEqual(widget.item.photos, current.photos)) {
      return true;
    }
    return false;
  }

  // Helper to check if photo lists have changed
  bool _arePhotoListsEqual(List<String>? list1, List<String>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }

    return true;
  }
  
  // Refresh controllers and data
  void _refreshData() {
    if (!mounted) return;

    // Prevent excessive refreshes by checking the time since last refresh
    final now = DateTime.now();
    if (now.difference(_lastRefreshTime).inMilliseconds < 200) {
      return; // Skip if refreshed very recently
    }
    _lastRefreshTime = now;
    
    final currentItem = _getCurrentItem();

    if (_hasItemChanged(currentItem)) {
      // For a complete refresh, dispose and recreate controllers
      _disposeControllers();
      
      // Create new controllers with fresh data
      _nameController = TextEditingController(text: currentItem.name);
      _retailPriceController = TextEditingController(text: currentItem.retailPrice?.toString() ?? '');
      _listPriceController = TextEditingController(text: currentItem.listPrice?.toString() ?? '');
      _productCodeController = TextEditingController(text: currentItem.productCode ?? '');
        
      if (currentItem.condition != null && currentItem.condition!.isNotEmpty) {
        _selectedCondition = currentItem.condition!;
      }
      
      if (currentItem.photos != null) {
        _itemPhotos = List.from(currentItem.photos!);
      }

      // Force a complete rebuild of the content
      setState(() {});
    }
  }

  // Save changes to the item details
  void _saveChanges() {
    // Get updated values
    final name = _nameController.text;
    final retailPrice = double.tryParse(_retailPriceController.text) ?? 0.0;
    final listPrice = double.tryParse(_listPriceController.text) ?? 0.0;
    final productCode = _productCodeController.text;
    
    // Update the item in the model
    Provider.of<PalletModel>(context, listen: false).updateItemDetails(
      palletId: widget.pallet.id,
      itemId: widget.item.id,
      name: name,
      retailPrice: retailPrice,
      condition: _selectedCondition,
      listPrice: listPrice,
      productCode: productCode,
      photos: _itemPhotos,
    );
    
    // Exit editing mode
    setState(() {
      _isEditing = false;
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Item details saved successfully'),
          ],
        ),
        backgroundColor: context.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(8),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error', style: context.largeTextWeight(FontWeight.bold)),
        content: Text(message, style: context.mediumText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK', style: context.mediumTextWeight(FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // New method to scan and lookup products
  Future<void> _scanAndLookupProduct() async {
    try {
      setState(() {
        _isScanning = true;
      });

      // Launch the scanner in a fullscreen mode
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Scan Product'),
              backgroundColor: context.primaryColor,
            ),
            body: Stack(
              children: [
                MobileScanner(
                  controller: MobileScannerController(
                    facing: CameraFacing.back,
                    formats: [BarcodeFormat.all],
                  ),
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes[0].rawValue != null) {
                      // Return the scanned value
                      Navigator.of(context).pop(barcodes[0].rawValue);
                    }
                  },
                ),
                // Overlay with scan instructions
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Scan product barcode or UPC',
                        style: context
                            .mediumTextWeight(FontWeight.bold)
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (!mounted) return;

      if (result != null && result.isNotEmpty) {
        setState(() {
          _isScanning = false;
        });

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
          ),
        );

        // Simulated API call
        await Future.delayed(Duration(seconds: 2));

        // Hide loading indicator
        Navigator.of(context).pop();

        // Show product preview
        _showProductPreviewDialog(result);
      } else {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isScanning = false;
      });
      _showErrorDialog('Error scanning product: $e');
    }
  }

// Product preview and autofill dialog
  void _showProductPreviewDialog(String barcode) {
    // Simulated product data - replace with actual API response
    final productData = {
      'name': 'Example Product Name',
      'retailPrice': 49.99,
      'condition': 'New',
      'imageUrl': null,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Product Found',
            style: context.mediumTextWeight(FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product image or placeholder
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            ),
            SizedBox(height: 16),
            Text(productData['name'] as String,
                style: context.mediumTextWeight(FontWeight.bold)),
            Text('Retail Price: \$${productData['retailPrice']}',
                style: context.smallText),
            Text('Condition: ${productData['condition']}',
                style: context.smallText),
            SizedBox(height: 8),
            Text('Barcode: $barcode',
                style: context.smallTextColor(Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: context.mediumText),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
            onPressed: () {
              // Autofill form fields
              _nameController.text = productData['name'] as String;
              _retailPriceController.text =
                  (productData['retailPrice'] as double).toString();
              _selectedCondition = productData['condition'] as String;

              // Calculate suggested list price (e.g., 70% of retail)
              final retailPrice = productData['retailPrice'] as double;
              final suggestedPrice = (retailPrice * 0.7).toStringAsFixed(2);
              _listPriceController.text = suggestedPrice;

              // Enable editing mode if not already
              if (!_isEditing &&
                  !widget.pallet.isClosed &&
                  !widget.item.isSold) {
                setState(() {
                  _isEditing = true;
                });
              }

              Navigator.pop(context);
            },
            child: Text('USE THIS PRODUCT', style: context.mediumText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get responsive size indicators
    final isTablet = ResponsiveUtils.isTablet(context);
    final deviceSize = ResponsiveUtils.getDeviceSize(context);
    final isSmallPhone = deviceSize == DeviceSize.phoneSmall ||
        deviceSize == DeviceSize.phoneXSmall;

    return KeyedSubtree(
      key: _lifecycleKey,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: context.primaryColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Check if we're in edit mode and have unsaved changes
              if (_isEditing) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Unsaved Changes'),
                    content: Text(
                        'You have unsaved changes. Do you want to discard them?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Keep Editing'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        child: Text('Discard Changes'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                      ),
                    ],
                  ),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
            iconSize: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
          ),
          title: Text(
            widget.item.name.isEmpty ? 'New Item' : widget.item.name,
            style: context
                .largeTextWeight(FontWeight.bold)
                .copyWith(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            // Add scan button in the app bar
            if (!widget.pallet.isClosed && !widget.item.isSold)
              IconButton(
                icon: Icon(Icons.qr_code_scanner),
                tooltip: "Scan Product",
                onPressed: _scanAndLookupProduct,
                iconSize:
                    ResponsiveUtils.getIconSize(context, IconSizeType.medium),
              ),
          ],
          centerTitle: false,
          // Removed the edit button from app bar since we have the FAB
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(8),
            child: Container(
              color: context.primaryColor,
              height: 8,
            ),
          ),
        ),
        body: Consumer<PalletModel>(
          builder: (context, palletModel, _) {
            // Get the most recent version of the item from the model
            final currentPallet = palletModel.pallets.firstWhere(
              (p) => p.id == widget.pallet.id,
              orElse: () => widget.pallet,
            );

            final currentItem = currentPallet.items.firstWhere(
              (i) => i.id == widget.item.id,
              orElse: () => widget.item,
            );

            // Check if data has changed and needs refresh
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_hasItemChanged(currentItem)) {
                _refreshData();
              }
            });

            return Stack(
              children: [
                if (isTablet)
                  _buildTabletLayout(context, currentPallet, currentItem)
                else
                  _buildPhoneLayout(
                      context, currentPallet, currentItem, isSmallPhone),

                // FAB-style Edit button that appears when not in edit mode
                if (!_isEditing &&
                    !widget.pallet.isClosed &&
                    !widget.item.isSold)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.extended(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: Icon(Icons.edit),
                      label: Text("Edit Item"),
                      backgroundColor: context.primaryColor,
                    ),
                  ),

                // FAB-style Save button that appears when in edit mode
                if (_isEditing &&
                    !widget.pallet.isClosed &&
                    !widget.item.isSold)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.extended(
                      onPressed: _saveChanges,
                      icon: Icon(Icons.save),
                      label: Text("Save"),
                      backgroundColor: context.successColor,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, PalletItem item) {
    if (item.isSold) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.successColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.successColor.withAlpha(77),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'SOLD',
              style: context.mediumTextWeight(FontWeight.bold).copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    } else if (widget.pallet.isClosed) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(77),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'PALLET CLOSED',
              style: context.mediumTextWeight(FontWeight.bold).copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.infoColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.infoColor.withAlpha(77),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2,
            size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Text(
            'ACTIVE',
            style: context.mediumTextWeight(FontWeight.bold).copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, Pallet pallet, PalletItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left side - photo and status
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status badge
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    width: double.infinity,
                    padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildStatusBadge(context, item),
                        if (item.isSold)
                          Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'Sold for \$${item.salePrice.toStringAsFixed(2)} on ${_formatDate(item.saleDate)}',
                              style: context.mediumText,
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Photo card
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Main photo container
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: _itemPhotos.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.photo_camera,
                                        size: ResponsiveUtils.getIconSize(context, IconSizeType.xLarge),
                                        color: Colors.grey.shade300,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No Photo',
                                        style: context.largeTextWeight(FontWeight.bold).copyWith(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () {
                                    // Show the photo in full-screen when tapped
                                    if (_itemPhotos.isNotEmpty) {
                                      _showFullScreenImage(context, 0);
                                    }
                                  },
                                  child: Hero(
                                    tag: 'main-photo-${widget.item.id}',
                                    child: Image.file(
                                      File(_itemPhotos[0]),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                        ),

                        // Edit overlay for adding/changing photo
                        if (_isEditing && !widget.pallet.isClosed && !widget.item.isSold)
                          Positioned.fill(
                            child: Material(
                              color: Colors.black.withAlpha(100),
                              child: InkWell(
                                onTap: _itemPhotos.isEmpty ? _takePhoto : _showPhotoOptions,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _itemPhotos.isEmpty ? Icons.add_a_photo : Icons.edit,
                                        size: ResponsiveUtils.getIconSize(context, IconSizeType.xLarge),
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        _itemPhotos.isEmpty ? 'Add Photo' : 'Change Photo',
                                        style: context.largeTextWeight(FontWeight.bold).copyWith(
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Photo counter if we have multiple photos (future expansion)
                if (_itemPhotos.length > 1)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(
                      child: Text(
                        '1/${_itemPhotos.length} photos - tap to view',
                        style: context.smallText.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Right side - item details
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: _buildItemDetailsCard(context, pallet, item),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(
      BuildContext context, Pallet pallet, PalletItem item, bool isSmallPhone) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status banner
          _buildStatusBanner(context, item, pallet),

          // Simplified Photo Area - Just a single photo
          _buildSimplifiedPhotoArea(context, isSmallPhone),

          // Item details card with product lookup capabilities
          _buildItemDetailsCard(context, pallet, item),

          // Add spacing to accommodate the FAB
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSimplifiedPhotoArea(BuildContext context, bool isSmallPhone) {
    final photoHeight = isSmallPhone ? 220.0 : 280.0;

    return Card(
      margin: EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Main photo container
          Container(
            height: photoHeight,
            width: double.infinity,
            child: _itemPhotos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_camera,
                          size: ResponsiveUtils.getIconSize(
                              context, IconSizeType.xLarge),
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Photo',
                          style: context
                              .mediumTextWeight(FontWeight.bold)
                              .copyWith(
                                color: Colors.grey.shade500,
                              ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      // Show the photo in full-screen when tapped
                      if (_itemPhotos.isNotEmpty) {
                        _showFullScreenImage(context, 0);
                      }
                    },
                    child: Hero(
                      tag: 'main-photo-${widget.item.id}',
                      child: Image.file(
                        File(_itemPhotos.isNotEmpty ? _itemPhotos[0] : ''),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
          ),

          // Edit overlay for adding/changing photo
          if (_isEditing && !widget.pallet.isClosed && !widget.item.isSold)
            Positioned.fill(
              child: Material(
                color: Colors.black.withAlpha(100),
                child: InkWell(
                  onTap: _itemPhotos.isEmpty ? _takePhoto : _showPhotoOptions,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _itemPhotos.isEmpty ? Icons.add_a_photo : Icons.edit,
                          size: ResponsiveUtils.getIconSize(
                              context, IconSizeType.large),
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          _itemPhotos.isEmpty ? 'Add Photo' : 'Change Photo',
                          style: context
                              .mediumTextWeight(FontWeight.bold)
                              .copyWith(
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Photo counter if we have multiple photos (future expansion)
          if (_itemPhotos.length > 1)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(153),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '1/${_itemPhotos.length}',
                  style: context.smallText.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemDetailsCard(
      BuildContext context, Pallet pallet, PalletItem item) {
    return Card(
      margin: EdgeInsets.fromLTRB(12, 4, 12, 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with lookup capability
          Container(
            color: context.primaryColor.withAlpha(230),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size:
                      ResponsiveUtils.getIconSize(context, IconSizeType.small),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Item Details',
                    style: context
                        .mediumTextWeight(FontWeight.bold)
                        .copyWith(color: Colors.white),
                  ),
                ),
                if (_isEditing &&
                    !widget.pallet.isClosed &&
                    !widget.item.isSold)
                  // Barcode lookup button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: !_isScanning ? _performProductLookup : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isScanning
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: ResponsiveUtils.getIconSize(
                                        context, IconSizeType.small),
                                  ),
                            SizedBox(width: 4),
                            Text(
                              'Lookup',
                              style: context
                                  .smallTextWeight(FontWeight.bold)
                                  .copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Form content with a more workflow-oriented layout
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Divider with "Product Information" label
                _buildSectionDivider(context, 'Product Information'),

                // Name field
                _buildItemNameField(context),
                SizedBox(height: 16),

                // Retail price with estimated value explanation
                _buildRetailPriceField(context),
                SizedBox(height: 16),

                // Divider with "Listing Information" label
                _buildSectionDivider(context, 'Listing Information'),

                // Condition buttons with visual price impact
                _buildEnhancedConditionSelector(context),
                SizedBox(height: 16),

                // List price with suggested pricing
                _buildListPriceWithSuggestion(context),

                // Pallet information at the bottom for reference
                if (pallet.name.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: ResponsiveUtils.getIconSize(
                            context, IconSizeType.small),
                        color: Colors.grey.shade700,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'From Pallet: ',
                        style: context.smallText,
                      ),
                      Expanded(
                        child: Text(
                          pallet.name,
                          style: context.smallTextWeight(FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (pallet.tag.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.sell,
                          size: ResponsiveUtils.getIconSize(
                              context, IconSizeType.small),
                          color: Colors.grey.shade700,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tag: ',
                          style: context.smallText,
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pallet.tag,
                            style: context
                                .smallTextWeight(FontWeight.bold)
                                .copyWith(
                                  color: Colors.grey.shade800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for section dividers
  Widget _buildSectionDivider(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(thickness: 1),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: context.smallTextWeight(FontWeight.bold).copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ),
          Expanded(
            child: Divider(thickness: 1),
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt, color: context.primaryColor),
            title: Text('Take New Photo'),
            onTap: () {
              Navigator.pop(context);
              _takePhoto();
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library, color: context.primaryColor),
            title: Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickPhotos();
            },
          ),
          if (_itemPhotos.isNotEmpty)
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Remove Photo'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _itemPhotos.clear());

                // Also save the photo removal immediately
                if (!widget.pallet.isClosed && !widget.item.isSold) {
                  Provider.of<PalletModel>(context, listen: false)
                      .updateItemDetails(
                    palletId: widget.pallet.id,
                    itemId: widget.item.id,
                    photos: _itemPhotos,
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  // Helper method to show full screen image
  void _showFullScreenImage(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(217),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: EdgeInsets.all(80),
              minScale: 0.5,
              maxScale: 3,
              child: Center(
                child: Hero(
                  tag: 'main-photo-${widget.item.id}',
                  child: Image.file(
                    File(_itemPhotos[index]),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Material(
                color: Colors.black.withAlpha(128),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => Navigator.pop(ctx),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: ResponsiveUtils.getIconSize(
                          context, IconSizeType.medium),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Product lookup method for future integration with Amazon/Walmart API
  void _performProductLookup() async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Simulate API lookup for now
      await Future.delayed(Duration(seconds: 2));

      // For now, just show a message about future integration
      if (mounted) {
        setState(() {
          _isScanning = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Product lookup feature coming soon! This will auto-fill product details from Amazon/Walmart.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _showErrorDialog('Error looking up product: $e');
      }
    }
  }

  // Enhanced condition selector with pricing impact visualization
  Widget _buildEnhancedConditionSelector(BuildContext context) {
    // Calculate retail price as a number
    final retailPrice = double.tryParse(_retailPriceController.text) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Condition',
              style: context.smallTextWeight(FontWeight.bold),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '(Affects suggested listing price)',
                style: context.tinyText.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: _conditionOptions.map((condition) {
            final isSelected = _selectedCondition == condition['value'];
            final isEnabled =
                _isEditing && !widget.pallet.isClosed && !widget.item.isSold;

            // Calculate suggested price based on condition
            // New: 70-80% of retail, Like New: 60-70%, Very Good: 50-60%,
            // Good: 40-50%, Acceptable: 30-40%, For Parts: 20-30%
            final priceRangeMap = {
              'New': [0.7, 0.8],
              'Like New': [0.6, 0.7],
              'Very Good': [0.5, 0.6],
              'Good': [0.4, 0.5],
              'Acceptable': [0.3, 0.4],
              'For Parts': [0.2, 0.3],
            };

            final priceRange = priceRangeMap[condition['value']] ?? [0.5, 0.6];
            final minPrice = (retailPrice * priceRange[0]).toStringAsFixed(2);
            final maxPrice = (retailPrice * priceRange[1]).toStringAsFixed(2);

            return InkWell(
              onTap: isEnabled
                  ? () {
                      setState(() {
                        _selectedCondition = condition['value'] as String;

                        // Auto-suggest a price in the middle of the range
                        if (retailPrice > 0) {
                          final midPrice = retailPrice *
                              ((priceRange[0] + priceRange[1]) / 2);
                          _listPriceController.text =
                              midPrice.toStringAsFixed(2);
                        }
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: (MediaQuery.of(context).size.width - 64) /
                    2, // Two columns with padding
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? condition['color'].withAlpha(isEnabled ? 50 : 30)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? condition['color'] as Color
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          condition['icon'] as IconData,
                          color: condition['color'] as Color,
                          size: ResponsiveUtils.getIconSize(
                              context, IconSizeType.small),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            condition['value'] as String,
                            style: context
                                .smallTextWeight(FontWeight.bold)
                                .copyWith(
                                  color: isSelected
                                      ? condition['color'] as Color
                                      : Colors.grey.shade800,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: condition['color'] as Color,
                            size: ResponsiveUtils.getIconSize(
                                context, IconSizeType.small),
                          ),
                      ],
                    ),
                    if (retailPrice > 0) ...[
                      SizedBox(height: 6),
                      Text(
                        'Suggested: \$$minPrice-\$$maxPrice',
                        style: context.tinyText.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // List price field with pricing suggestions
  Widget _buildListPriceWithSuggestion(BuildContext context) {
    final retailPrice = double.tryParse(_retailPriceController.text) ?? 0.0;

    // Calculate suggested price based on selected condition
    final priceRangeMap = {
      'New': [0.7, 0.8],
      'Like New': [0.6, 0.7],
      'Very Good': [0.5, 0.6],
      'Good': [0.4, 0.5],
      'Acceptable': [0.3, 0.4],
      'For Parts': [0.2, 0.3],
    };

    final priceRange = priceRangeMap[_selectedCondition] ?? [0.5, 0.6];
    final suggestedPrice = retailPrice > 0
        ? (retailPrice * ((priceRange[0] + priceRange[1]) / 2))
            .toStringAsFixed(2)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'List Price',
              style: context.smallTextWeight(FontWeight.bold),
            ),
            if (retailPrice > 0 && _isEditing) ...[
              SizedBox(width: 8),
              InkWell(
                onTap: () {
                  // Set suggested price on tap
                  _listPriceController.text = suggestedPrice;
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: context.primaryColor.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: ResponsiveUtils.getIconSize(
                            context, IconSizeType.tiny),
                        color: context.primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Suggest: \$$suggestedPrice',
                        style: context.tinyTextWeight(FontWeight.bold).copyWith(
                              color: context.primaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: _listPriceController,
          decoration: InputDecoration(
            hintText: 'Enter your listing price...',
            prefixIcon: Icon(
              Icons.price_change,
              color: _isEditing ? context.primaryColor : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primaryColor, width: 2),
            ),
            contentPadding: ResponsiveUtils.getPaddingHV(
              context,
              PaddingType.medium,
              PaddingType.small,
            ),
            fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
            filled: true,
          ),
          style: context.mediumText,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          enabled: _isEditing && !widget.pallet.isClosed && !widget.item.isSold,
        ),
        if (retailPrice > 0 && _isEditing)
          Padding(
            padding: EdgeInsets.only(top: 6, left: 8),
            child: Text(
              'Profit margin: ${_calculateProfitMargin(retailPrice)}',
              style: context.smallText.copyWith(
                color: _getProfitMarginColor(retailPrice),
              ),
            ),
          ),
      ],
    );
  }

  // Calculate the profit margin percentage based on retail price and list price
  String _calculateProfitMargin(double retailPrice) {
    final listPrice = double.tryParse(_listPriceController.text) ?? 0.0;
    if (retailPrice <= 0 || listPrice <= 0) return 'N/A';

    final margin = ((listPrice / retailPrice) * 100).toStringAsFixed(1);
    return '$margin% of retail';
  }

  // Get color based on profit margin
  Color _getProfitMarginColor(double retailPrice) {
    final listPrice = double.tryParse(_listPriceController.text) ?? 0.0;
    if (retailPrice <= 0 || listPrice <= 0) return Colors.grey.shade600;

    final margin = (listPrice / retailPrice) * 100;

    if (margin < 30) return Colors.red;
    if (margin < 50) return Colors.orange;
    if (margin < 70) return Colors.green;
    return Colors.blue;
  }

  Widget _buildStatusBanner(
      BuildContext context, PalletItem item, Pallet pallet) {
    return Column(
      children: [
        Container(
          color: item.isSold
              ? context.successColor
              : (pallet.isClosed ? Colors.grey.shade700 : context.infoColor),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.isSold
                    ? Icons.check_circle
                    : (pallet.isClosed ? Icons.lock : Icons.inventory_2),
                color: Colors.white,
                size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
              ),
              SizedBox(width: 8),
              Text(
                item.isSold
                    ? 'SOLD'
                    : (pallet.isClosed ? 'PALLET CLOSED' : 'ACTIVE ITEM'),
                style: context
                    .mediumTextWeight(FontWeight.bold)
                    .copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        if (item.isSold)
          Container(
            color: context.successColor.withAlpha(26),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              'Sold for \$${item.salePrice.toStringAsFixed(2)} on ${_formatDate(item.saleDate)}',
              style: context.mediumText,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildItemNameField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Name',
          style: context.smallTextWeight(FontWeight.bold),
        ),
        SizedBox(height: 6),
        TextFormField(
          key: ValueKey('name-field-${_nameController.text}'),
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Enter item name...',
            prefixIcon: Icon(
              Icons.inventory_2_outlined,
              color: _isEditing ? context.primaryColor : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primaryColor, width: 2),
            ),
            contentPadding: ResponsiveUtils.getPaddingHV(
              context,
              PaddingType.medium,
              PaddingType.small,
            ),
            fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
            filled: true,
          ),
          style: context.mediumText,
          enabled: _isEditing && !widget.pallet.isClosed && !widget.item.isSold,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildRetailPriceField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Retail Price',
          style: context.smallTextWeight(FontWeight.bold),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: _retailPriceController,
          decoration: InputDecoration(
            hintText: 'Enter estimated retail value...',
            prefixIcon: Icon(
              Icons.attach_money,
              color: _isEditing ? context.primaryColor : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primaryColor, width: 2),
            ),
            contentPadding: ResponsiveUtils.getPaddingHV(
              context,
              PaddingType.medium,
              PaddingType.small,
            ),
            fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
            filled: true,
          ),
          style: context.mediumText,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          enabled: _isEditing && !widget.pallet.isClosed && !widget.item.isSold,
        ),
      ],
    );
  }

  // We'll need to modify the take photo method to handle the single photo case
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (image != null && mounted) {
        setState(() {
          // Replace first photo or add new if empty
          if (_itemPhotos.isEmpty) {
            _itemPhotos.add(image.path);
          } else {
            _itemPhotos[0] = image.path;
          }
        });

        // Immediately save the photo to prevent loss
        if (!widget.pallet.isClosed && !widget.item.isSold) {
          Provider.of<PalletModel>(context, listen: false).updateItemDetails(
            palletId: widget.pallet.id,
            itemId: widget.item.id,
            photos: _itemPhotos,
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Could not access camera: $e');
    }
  }

  // Modified to handle the single photo case
  Future<void> _pickPhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (images.isNotEmpty && mounted) {
        setState(() {
          // Use only the first selected image for our simplified UI
          if (_itemPhotos.isEmpty) {
            _itemPhotos.add(images.first.path);
          } else {
            _itemPhotos[0] = images.first.path;
          }
        });

        // Immediately save the photo to prevent loss
        if (!widget.pallet.isClosed && !widget.item.isSold) {
          Provider.of<PalletModel>(context, listen: false).updateItemDetails(
            palletId: widget.pallet.id,
            itemId: widget.item.id,
            photos: _itemPhotos,
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Could not access gallery: $e');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

}

// Add this improved AppLifecycleObserver at the end of the file
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  
  _AppLifecycleObserver({required this.onResume});
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
