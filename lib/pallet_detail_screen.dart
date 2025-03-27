import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pallet_model.dart';
import 'responsive_utils.dart'; // Import responsive utilities
import 'utils/dialog_utils.dart'; // Import dialog utilities
import 'item_detail_screen.dart'; // Import item detail screen
import 'package:pallet_manager/utils/log_utils.dart';

class PalletDetailScreen extends StatefulWidget {
  final Pallet pallet;

  const PalletDetailScreen({super.key, required this.pallet});

  @override
  State<PalletDetailScreen> createState() => _PalletDetailScreenState();
}

class _PalletDetailScreenState extends State<PalletDetailScreen> {
  // State to track if the info card is expanded or collapsed
  bool _isInfoCardExpanded = true;
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    _loadPalletItemsIfNeeded();
  }

  Future<void> _loadPalletItemsIfNeeded() async {
    final palletModel = Provider.of<PalletModel>(context, listen: false);
    
    if (palletModel.dataSource == DataSource.supabase) {
      setState(() {
        _isLoadingItems = true;
      });
      
      try {
        LogUtils.info('Loading items for pallet ${widget.pallet.id}');
        // Load items for this specific pallet
        await palletModel.loadPalletItems(widget.pallet.id);
        LogUtils.info('Successfully loaded items for pallet ${widget.pallet.id}');
      } catch (e) {
        LogUtils.error('Error loading pallet items', e);
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingItems = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get responsive characteristics
    final deviceSize = ResponsiveUtils.getDeviceSize(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    ResponsiveUtils.getFontScale(context);

    // Adjust for different phone sizes
    final isNarrowScreen = deviceSize == DeviceSize.phoneXSmall ||
        deviceSize == DeviceSize.phoneSmall;

    // Use Consumer to automatically rebuild when the model changes
    return Consumer<PalletModel>(
      builder: (context, palletModel, child) {
        // Find the current version of the pallet in the model
        final currentPallet = palletModel.pallets.firstWhere(
          (p) => p.id == widget.pallet.id,
          orElse: () => widget.pallet,
        );

        return Scaffold(
          key: UniqueKey(),
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: () => _showEditPalletNameDialog(
                        context, palletModel, currentPallet),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            currentPallet.name,
                            style: context.largeText,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.edit,
                            size: ResponsiveUtils.getIconSize(
                                context, IconSizeType.small)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              // Toggle info card expansion button
              IconButton(
                icon: Icon(_isInfoCardExpanded
                    ? Icons.expand_less
                    : Icons.expand_more),
                tooltip: _isInfoCardExpanded
                    ? "Collapse pallet info"
                    : "Expand pallet info",
                iconSize:
                    ResponsiveUtils.getIconSize(context, IconSizeType.medium),
                onPressed: () {
                  setState(() {
                    _isInfoCardExpanded = !_isInfoCardExpanded;
                  });
                },
              ),
            ],
          ),
          // Use different layouts for tablet vs phone
          body: isTablet
              ? _buildTabletLayout(context, palletModel, currentPallet)
              : _buildPhoneLayout(
                  context, palletModel, currentPallet, isNarrowScreen),
        );
      },
    );
  }

  // Tablet layout with side-by-side panels
  Widget _buildTabletLayout(
    BuildContext context, 
    PalletModel palletModel, 
    Pallet pallet
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel with pallet info
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPalletInfoCard(pallet, false),
        // Left side - Pallet info and actions
        SizedBox(
          width: 320, // Fixed sidebar width
          child: Card(
            margin: EdgeInsets.all(8),
            elevation: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pallet info
                _buildPalletInfoCard(pallet, false),
                
                // Action buttons
                Padding(
                  padding: ResponsiveUtils.getPaddingHV(
                    context,
                    PaddingType.medium,
                    PaddingType.small
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(
                          Icons.add, 
                          size: ResponsiveUtils.getIconSize(context, IconSizeType.medium)
                        ),
                        label: Text(
                          "Add Item", 
                          style: context.mediumText,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: ResponsiveUtils.getPaddingHV(
                            context,
                            PaddingType.small,
                            PaddingType.small
                          ),
                        ),
                        onPressed: pallet.isClosed
                            ? null
                            : () => _showAddItemDialog(context, pallet),
                      ),
                      SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
                      if (!pallet.isClosed)
                        ElevatedButton.icon(
                          icon: Icon(
                            Icons.sell, 
                            size: ResponsiveUtils.getIconSize(context, IconSizeType.medium)
                          ),
                          label: Text(
                            "Mark Sold", 
                            style: context.mediumText,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: ResponsiveUtils.getPaddingHV(
                              context,
                              PaddingType.small,
                              PaddingType.small
                            ),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () => _confirmMarkPalletSold(
                              context, palletModel, pallet),
                        ),
                    ],
                  ),
                ),
                
                // Analytics summary for tablet layout
                Padding(
                  padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pallet Summary", 
                            style: context.mediumTextWeight(FontWeight.bold),
                          ),
                          SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
                          _buildSummaryRow(
                            context,
                            title: "Total Items",
                            value: "${pallet.items.length}",
                            icon: Icons.inventory_2,
                          ),
                          _buildSummaryRow(
                            context,
                            title: "Sold Items",
                            value: "${pallet.soldItemsCount}",
                            icon: Icons.sell,
                          ),
                          _buildSummaryRow(
                            context,
                            title: "Profit",
                            value: "\$${pallet.profit.toStringAsFixed(2)}",
                            icon: Icons.attach_money,
                            valueColor: pallet.profit >= 0 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Spacer(),
                
                // Help text
                Padding(
                  padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
                  child: Text(
                    "Tip: Swipe items left to mark as sold, or right to delete.",
                    style: context.smallTextColor(Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Right side - Items list
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Card(
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
                    child: Text(
                      "Items",
                      style: context.largeTextWeight(FontWeight.bold),
                    ),
                  ),
                  Divider(),
                  Expanded(
                    child: _buildItemsList(context, palletModel, pallet, false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for tablet summary rows
  Widget _buildSummaryRow(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon, 
            size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
            color: Colors.grey.shade700,
          ),
          SizedBox(width: 8),
          Text(
            "$title: ",
            style: context.smallText,
          ),
          Text(
            value,
            style: context.smallTextWeight(FontWeight.bold).copyWith(
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // Phone layout with stacked panels
  Widget _buildPhoneLayout(
    BuildContext context, 
    PalletModel palletModel, 
    Pallet pallet,
    bool isNarrowScreen
  ) {
    return Column(
      children: [
        // Collapsible info card
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isInfoCardExpanded ? null : 50, // Collapsed height
          child: _buildPalletInfoCard(pallet, isNarrowScreen),
        ),

        // Button row
        Padding(
          padding: ResponsiveUtils.getPaddingHV(
            context,
            PaddingType.small,
            PaddingType.tiny
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                    Icons.add, 
                    size: ResponsiveUtils.getIconSize(context, IconSizeType.small)
                  ),
                  label: Text(
                    "Add Item",
                    style: isNarrowScreen 
                      ? context.smallText 
                      : context.mediumText,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: pallet.isClosed
                      ? null
                      : () => _showAddItemDialog(context, pallet),
                ),
              ),
              SizedBox(width: 8),
              if (!pallet.isClosed)
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.sell, 
                      size: ResponsiveUtils.getIconSize(context, IconSizeType.small)
                    ),
                    label: Text(
                      "Mark Sold",
                      style: isNarrowScreen 
                        ? context.smallText 
                        : context.mediumText,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _confirmMarkPalletSold(
                        context, palletModel, pallet),
                  ),
                ),
            ],
          ),
        ),

        // Items list
        Expanded(
          child: _buildItemsList(context, palletModel, pallet, isNarrowScreen),
        ),
      ],
    );
  }

  Widget _buildPalletInfoCard(Pallet pallet, bool isNarrowScreen) {
    if (!_isInfoCardExpanded) {
      // Collapsed view: just show a summary row
      return Card(
        margin: const EdgeInsets.all(8),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
              horizontal: isNarrowScreen ? 10 : 16, vertical: 0),
          dense: isNarrowScreen,
          leading: Icon(
            Icons.label,
            color: Colors.deepOrange, 
            size: isNarrowScreen 
              ? ResponsiveUtils.getIconSize(context, IconSizeType.small)
              : ResponsiveUtils.getIconSize(context, IconSizeType.medium)
          ),
          title: Text(
            '${pallet.name} - Tag: ${pallet.tag}',
            style: isNarrowScreen ? context.smallText : context.mediumText,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: pallet.isClosed
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'CLOSED',
                    style: context.tinyTextWeight(FontWeight.bold).copyWith(
                      color: Colors.white,
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: context.tinyTextWeight(FontWeight.bold).copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
          onTap: () {
            setState(() {
              _isInfoCardExpanded = true;
            });
          },
        ),
      );
    }

    // Expanded view with more compact layout for narrow screens
    // Get responsive sizes
    final fontSize = isNarrowScreen 
      ? FontSizeType.small 
      : FontSizeType.medium;
    final iconSize = isNarrowScreen 
      ? IconSizeType.small
      : IconSizeType.medium;
    final padding = isNarrowScreen 
      ? PaddingType.small
      : PaddingType.medium;

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      child: Column(
        children: [
          // Header with pallet name, tag and status
          ListTile(
            contentPadding: ResponsiveUtils.getPaddingHV(
              context,
              padding,
              PaddingType.zero
            ),
            dense: isNarrowScreen,
            leading: Icon(
              Icons.label,
              color: Colors.deepOrange,
              size: ResponsiveUtils.getIconSize(context, iconSize),
            ),
            title: Text(
              'Pallet: ${pallet.name}',
              style: isNarrowScreen 
                ? context.mediumTextWeight(FontWeight.bold)
                : context.largeTextWeight(FontWeight.bold),
            ),
            subtitle: Text(
              'Tag: ${pallet.tag}',
              style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, fontSize)),
            ),
            trailing: pallet.isClosed
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'CLOSED',
                      style: context.tinyTextWeight(FontWeight.bold).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: context.tinyTextWeight(FontWeight.bold).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),

          // Info rows with icons and data
          Padding(
            padding: ResponsiveUtils.getPaddingHV(
              context,
              padding,
              PaddingType.tiny
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  color: Colors.deepOrange,
                  size: ResponsiveUtils.getIconSize(context, iconSize),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Date: ${_formatDate(pallet.date)}',
                    style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getFontSize(context, fontSize)),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: ResponsiveUtils.getPaddingHV(
                context, padding, PaddingType.tiny),
            child: Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Colors.deepOrange,
                  size: ResponsiveUtils.getIconSize(context, iconSize),
                ),
                const SizedBox(width: 6),
                Text(
                  'Total Cost: ',
                  style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(
                          context, fontSize)), // ✅ Fixed
                ),
                Text(
                  '\$${pallet.totalCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    // ✅ Fixed
                    fontSize: ResponsiveUtils.getFontSize(context, fontSize),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: ResponsiveUtils.getPaddingHV(
              context,
              padding,
              PaddingType.tiny
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Colors.deepOrange,
                  size: ResponsiveUtils.getIconSize(context, iconSize),
                ),
                const SizedBox(width: 6),
                Text(
                  'Items: ',
                  style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, fontSize)),
                ),
                Text(
                  '${pallet.items.length} (${pallet.soldItemsCount} sold)',
                  style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, fontSize)),
                ),
              ],
            ),
          ),

          Padding(
            padding: ResponsiveUtils.getPaddingHV(
              context,
              padding,
              PaddingType.tiny
            ),
            child: Row(
              children: [
                Icon(
                  Icons.show_chart,
                  color: Colors.deepOrange,
                  size: ResponsiveUtils.getIconSize(context, iconSize),
                ),
                const SizedBox(width: 6),
                Text(
                  'Current Profit: ',
                  style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, fontSize)),
                ),
                Text(
                  '\$${pallet.profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context, fontSize),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Add bottom padding
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, PalletModel model, Pallet pallet,
      bool isNarrowScreen) {
    if (_isLoadingItems) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading items...', style: context.mediumText),
          ],
        ),
      );
    }
    
    if (pallet.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: ResponsiveUtils.getIconSize(context, IconSizeType.large),
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No items in this pallet',
              style: context.mediumText.copyWith(color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
            Icon(Icons.inventory_2_outlined,
                size: ResponsiveUtils.getIconSize(context, IconSizeType.xLarge),
                color: Colors.grey),
            SizedBox(
                height: ResponsiveUtils.getPadding(context, PaddingType.medium)
                    .top),
            Text(
              "No items added yet",
              style: context.mediumTextColor(Colors.grey),
            ),
            SizedBox(
                height:
                    ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
            Text(
              "Tap 'Add Item' to get started",
              style: context.smallTextColor(Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: pallet.items.length,
      itemBuilder: (context, index) {
        final item = pallet.items[index];
        // Key change: Use a stable key that reflects the item state
        return Dismissible(
          key: ValueKey('item-${item.id}-${item.isSold ? 'sold' : 'unsold'}'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(
                horizontal:
                    ResponsiveUtils.getPadding(context, PaddingType.medium)
                        .left),
            child: Row(
              children: [
                Icon(Icons.delete,
                    color: Colors.white,
                    size: ResponsiveUtils.getIconSize(
                        context, IconSizeType.small)),
                SizedBox(
                    width: ResponsiveUtils.getPadding(context, PaddingType.tiny)
                        .left),
                Text("Delete",
                    style: isNarrowScreen
                        ? context.smallTextColor(Colors.white)
                        : context.mediumTextColor(Colors.white)),
              ],
            ),
          ),
          secondaryBackground: Container(
            color: Colors.green,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(
                horizontal:
                    ResponsiveUtils.getPadding(context, PaddingType.medium)
                        .left),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Mark Sold",
                    style: isNarrowScreen
                        ? context.smallTextColor(Colors.white)
                        : context.mediumTextColor(Colors.white)),
                SizedBox(
                    width: ResponsiveUtils.getPadding(context, PaddingType.tiny)
                        .left),
                Icon(Icons.sell,
                    color: Colors.white,
                    size: ResponsiveUtils.getIconSize(
                        context, IconSizeType.small)),
              ],
            ),
          ),
          direction: pallet.isClosed || item.isSold
              ? DismissDirection.none
              : DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            bool result = false;
            if (direction == DismissDirection.startToEnd) {
              // Delete item
              result =
                  await _confirmDeleteItem(context, model, pallet.id, item) ??
                      false;
            } else if (direction == DismissDirection.endToStart) {
              // Mark item as sold
              result =
                  await _showMarkSoldDialog(context, model, pallet.id, item) ??
                      false;
            }

            // Simpler approach to rebuild after dismissible action
            if (result && mounted) {
              setState(() {});
            }

            return result;
          },
          child: Card(
            margin: EdgeInsets.symmetric(
              vertical: 4.0,
              horizontal: 8.0,
            ),
            child: ListTile(
              contentPadding: ResponsiveUtils.getPaddingHV(
                  context, PaddingType.small, PaddingType.small),
              leading: CircleAvatar(
                backgroundColor:
                    item.isSold ? Colors.green.shade100 : Colors.blue.shade100,
                child: Icon(
                  item.isSold ? Icons.check : Icons.inventory_2_outlined,
                  color: item.isSold ? Colors.green : Colors.blue,
                  size:
                      ResponsiveUtils.getIconSize(context, IconSizeType.small),
                ),
              ),
              title: Text(
                item.name,
                style: isNarrowScreen
                    ? context.smallTextWeight(FontWeight.bold)
                    : context.mediumTextWeight(FontWeight.bold),
              ),
              subtitle: item.isSold
                  ? Text(
                      "Sold for \$${item.salePrice.toStringAsFixed(2)} on ${_formatDate(item.saleDate)}",
                      style: isNarrowScreen
                          ? context.tinyTextColor(Colors.green)
                          : context.smallTextColor(Colors.green),
                    )
                  : Text(
                      "Not sold yet",
                      style:
                          isNarrowScreen ? context.tinyText : context.smallText,
                    ),
              trailing: !pallet.isClosed && !item.isSold
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: ResponsiveUtils.getIconSize(
                                context, IconSizeType.small),
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            await _confirmDeleteItem(
                                context, model, pallet.id, item);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.sell,
                            size: ResponsiveUtils.getIconSize(
                                context, IconSizeType.small),
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            await _showMarkSoldDialog(
                                context, model, pallet.id, item);
                          },
                        ),
                      ],
                    )
                  : item.isSold
                      ? Text(
                          "Sold",
                          style: isNarrowScreen
                              ? context
                                  .tinyTextWeight(FontWeight.bold)
                                  .copyWith(color: Colors.green)
                              : context
                                  .smallTextWeight(FontWeight.bold)
                                  .copyWith(color: Colors.green),
                        )
                      : null,
              // Add this onTap handler to navigate to the item detail screen
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailScreen(
                      pallet: pallet,
                      item: item,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<bool?> _confirmDeleteItem(BuildContext context, PalletModel model,
      int palletId, PalletItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Item", style: context.largeTextWeight(FontWeight.bold)),
          content: Text(
            "Are you sure you want to delete '${item.name}'?",
            style: context.mediumText,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("CANCEL", style: context.mediumText),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text("DELETE", style: context.mediumText),
            ),
          ],
        );
      },
    );

    if (result == true) {
      LogUtils.info('Deleting item ${item.id} from pallet $palletId');
      model.removeItemFromPallet(palletId, item.id);
    }
    
    return result;
  }

  void _showAddItemDialog(BuildContext context, Pallet pallet) {
    final TextEditingController itemController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Add New Item",
              style: context.largeTextWeight(FontWeight.bold)),
          content: KeyboardAware(
            child: Form(
              key: formKey,
              child: TextFormField(
                controller: itemController,
                decoration: InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                  contentPadding: ResponsiveUtils.getPaddingHV(
                      context, PaddingType.small, PaddingType.small),
                  prefixIcon: Icon(
                    Icons.inventory_2_outlined,
                    size: ResponsiveUtils.getIconSize(
                        context, IconSizeType.medium),
                  ),
                ),
                style: context.mediumText,
                validator: (value) => value!.isEmpty ? "Enter item name" : null,
                autofocus: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("CANCEL", style: context.mediumText),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Add item to pallet and get its reference
                  final PalletItem newItem =
                      Provider.of<PalletModel>(context, listen: false)
                          .addItemToPallet(pallet.id, itemController.text);

                  // Close the dialog
                  Navigator.pop(dialogContext);

                  // Navigate to the item detail screen with the new item
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailScreen(
                        pallet: pallet,
                        item: newItem,
                      ),
                    ),
                  );
                }
              },
              child: Text("ADD", style: context.mediumText),
            ),
          ],
        );
      },
    );
  }

  void _showEditPalletNameDialog(
      BuildContext context, PalletModel model, Pallet pallet) {
    DialogUtils.showEditPalletNameDialog(context, model, pallet);
  }

  Future<bool?> _showMarkSoldDialog(BuildContext context, PalletModel model,
      int palletId, PalletItem item) async {
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Mark Item as Sold",
              style: context.largeTextWeight(FontWeight.bold)),
          content: KeyboardAware(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Item: ${item.name}",
                    style: context.mediumTextWeight(FontWeight.bold),
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getPadding(
                              context, PaddingType.medium)
                          .top),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: "Sale Price",
                      border: OutlineInputBorder(),
                      contentPadding: ResponsiveUtils.getPaddingHV(
                          context, PaddingType.small, PaddingType.small),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        size: ResponsiveUtils.getIconSize(
                            context, IconSizeType.medium),
                      ),
                    ),
                    style: context.mediumText,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter sale price";
                      }
                      if (double.tryParse(value) == null) {
                        return "Enter a valid number";
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("CANCEL", style: context.mediumText),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final price = double.parse(priceController.text);
                  model.markItemAsSold(palletId, item.id, price);
                  Navigator.pop(context, true);
                }
              },
              child: Text("MARK SOLD", style: context.mediumText),
            ),
          ],
        );
      },
    );
  }

  void _confirmMarkPalletSold(
      BuildContext context, PalletModel model, Pallet pallet) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Mark Pallet as Sold",
              style: context.largeTextWeight(FontWeight.bold)),
          content: RichText(
            text: TextSpan(
              style: context.mediumText,
              children: [
                TextSpan(text: "Are you sure you want to mark "),
                TextSpan(
                  text: pallet.name,
                  style: context.mediumTextWeight(FontWeight.bold),
                ),
                TextSpan(
                    text: " as closed? This will prevent further changes."),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: context.mediumText),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                model.markPalletAsSold(pallet.id);
                Navigator.pop(context);
              },
              child: Text("CLOSE PALLET", style: context.mediumText),
            ),
          ],
        );
      },
    );
  }
}