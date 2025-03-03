import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pallet_model.dart';
import 'responsive_utils.dart'; // Import responsive utilities

class PalletDetailScreen extends StatefulWidget {
  final Pallet pallet;

  const PalletDetailScreen({super.key, required this.pallet});

  @override
  State<PalletDetailScreen> createState() => _PalletDetailScreenState();
}

class _PalletDetailScreenState extends State<PalletDetailScreen> {
  // State to track if the info card is expanded or collapsed
  bool _isInfoCardExpanded = true;

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
                        Icon(
                          Icons.edit, 
                          size: ResponsiveUtils.getIconSize(context, IconSizeType.small)
                        ),
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
                iconSize: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
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
              : _buildPhoneLayout(context, palletModel, currentPallet, isNarrowScreen),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
    if (pallet.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined, 
              size: ResponsiveUtils.getIconSize(context, IconSizeType.xLarge),
              color: Colors.grey
            ),
            SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),
            Text(
              "No items added yet",
              style: context.mediumTextColor(Colors.grey),
            ),
            SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
            Text(
              "Tap 'Add Item' to get started",
              style: context.smallTextColor(Colors.grey),
            ),
          ],
        ),
      );
    }

    // Font sizes for different screen widths
    final titleFontSize = isNarrowScreen 
        ? FontSizeType.small
        : FontSizeType.medium;
    final subtitleFontSize = isNarrowScreen 
        ? FontSizeType.tiny
        : FontSizeType.small;

    return ListView.builder(
      itemCount: pallet.items.length,
      itemBuilder: (context, index) {
        final item = pallet.items[index];
        return Dismissible(
          key: Key('item-${item.id}'),
          // Swipe left to delete
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getPadding(context, PaddingType.medium).left
            ),
            child: Row(
              children: [
                Icon(
                  Icons.delete, 
                  color: Colors.white, 
                  size: ResponsiveUtils.getIconSize(context, IconSizeType.small)
                ),
                SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.tiny).left),
                Text("Delete",
                    style: isNarrowScreen 
                        ? context.smallTextColor(Colors.white)
                        : context.mediumTextColor(Colors.white)),
              ],
            ),
          ),
          // Swipe right to mark as sold
          secondaryBackground: Container(
            color: Colors.green,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getPadding(context, PaddingType.medium).left
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Mark Sold",
                    style: isNarrowScreen 
                        ? context.smallTextColor(Colors.white)
                        : context.mediumTextColor(Colors.white)),
                SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.tiny).left),
                Icon(
                  Icons.sell, 
                  color: Colors.white, 
                  size: ResponsiveUtils.getIconSize(context, IconSizeType.small)
                ),
              ],
            ),
          ),
          // Disable swipe actions if pallet is closed or item is already sold
          direction: pallet.isClosed || item.isSold
              ? DismissDirection.none
              : DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Delete item
              return await _confirmDeleteItem(context, model, pallet.id, item);
            } else if (direction == DismissDirection.endToStart) {
              // Mark item as sold
              return await _showMarkSoldDialog(context, model, pallet.id, item);
            }
            return false;
          },
          child: Card(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getPadding(context, PaddingType.small).left,
              vertical: ResponsiveUtils.getPadding(context, PaddingType.tiny).top
            ),
            child: ListTile(
              contentPadding: ResponsiveUtils.getPaddingHV(
                context,
                isNarrowScreen ? PaddingType.small : PaddingType.medium,
                PaddingType.tiny
              ),
              dense: isNarrowScreen,
              title: Text(
                item.name,
                style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getFontSize(context, titleFontSize))
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: item.isSold
                  ? Text(
                      'Sold on: ${_formatDate(item.saleDate)} for: \$${item.salePrice.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(
                              context, subtitleFontSize)),
                    )
                  : Text(
                      'Not sold yet (swipe to sell or delete)',
                      style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(
                              context, subtitleFontSize)),
                    ),
              trailing: item.isSold
                  ? Icon(
                      Icons.check_circle,
                      color: Colors.green, 
                      size: ResponsiveUtils.getIconSize(context, IconSizeType.small)
                    )
                  : pallet.isClosed
                      ? Icon(
                          Icons.lock, 
                          color: Colors.grey, 
                          size: ResponsiveUtils.getIconSize(context, IconSizeType.small)
                        )
                      : SizedBox(
                          width: isNarrowScreen ? 80 : 100,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _ItemActionButton(
                                icon: Icons.sell,
                                tooltip: "Mark Sold",
                                onPressed: () => _showMarkSoldDialog(
                                    context, model, pallet.id, item),
                                iconColor: Colors.blue,
                                isNarrowScreen: isNarrowScreen,
                              ),
                              _ItemActionButton(
                                icon: Icons.delete,
                                tooltip: "Delete Item",
                                onPressed: () => _confirmDeleteItem(
                                    context, model, pallet.id, item),
                                iconColor: Colors.red,
                                isNarrowScreen: isNarrowScreen,
                              ),
                            ],
                          ),
                        ),
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
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Item",
              style: context.largeTextWeight(FontWeight.bold)),
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
                model.removeItemFromPallet(palletId, item.id);
                Navigator.pop(context, true);
              },
              child: Text("DELETE", style: context.mediumText),
            ),
          ],
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context, Pallet pallet) {
    final TextEditingController itemController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    

    // Check if we should use tablet layout
    final isTablet = ResponsiveUtils.isTablet(context);

    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: context.mediumText),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Provider.of<PalletModel>(context, listen: false)
                      .addItemToPallet(pallet.id, itemController.text);
                  Navigator.pop(context);
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
    final nameController = TextEditingController(text: pallet.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Pallet Name",
              style: context.largeTextWeight(FontWeight.bold)),
          content: KeyboardAware(
            child: Form(
              key: formKey,
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Pallet Name",
                  border: OutlineInputBorder(),
                  contentPadding: ResponsiveUtils.getPaddingHV(
                      context, PaddingType.small, PaddingType.small),
                  prefixIcon: Icon(
                    Icons.edit,
                    size: ResponsiveUtils.getIconSize(
                        context, IconSizeType.medium),
                  ),
                ),
                style: context.mediumText,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter pallet name";
                  }
                  // Check for duplicate names, but allow keeping the current name
                  if (value != pallet.name && model.palletNameExists(value)) {
                    return "A pallet with this name already exists";
                  }
                  return null;
                },
                autofocus: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: context.mediumText),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  model.updatePalletName(pallet.id, nameController.text);
                  Navigator.pop(context);
                }
              },
              child: Text("SAVE", style: context.mediumText),
            ),
          ],
        );
      },
    );
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

// Helper widget for compact item action buttons
class _ItemActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color iconColor;
  final bool isNarrowScreen;

  const _ItemActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.iconColor,
    required this.isNarrowScreen,
  });

  @override
  Widget build(BuildContext context) {
    final size = isNarrowScreen
        ? ResponsiveUtils.getIconSize(context, IconSizeType.medium) + 8
        : ResponsiveUtils.getIconSize(context, IconSizeType.medium) + 12;

    final iconSize = isNarrowScreen
        ? ResponsiveUtils.getIconSize(context, IconSizeType.small)
        : ResponsiveUtils.getIconSize(context, IconSizeType.medium);

    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
  
 /* In the code above, we have a  PalletDetailScreen  widget that displays the details of a pallet. The screen layout is responsive and adjusts based on the device size. The screen uses the  ResponsiveUtils  class to get the device size, font scale, and icon size. The screen layout changes based on the device size, with different layouts for tablets and phones. 
  The screen uses the  Consumer  widget to listen to changes in the  PalletModel  and automatically rebuilds when the model changes. The screen displays the pallet details, action buttons, and a list of items. The screen also includes dialogs to add items, edit the pallet name, mark items as sold, and confirm marking the pallet as sold. 
  The  _buildTabletLayout  method creates a side-by-side layout for tablets, with a sidebar for pallet info and actions, and a main panel for the items list. The  _buildPhoneLayout  method creates a stacked layout for phones, with a collapsible info card and a button row for actions. The  _buildItemsList  method creates a list of items with swipe actions to mark items as sold or delete them. 
  The screen uses the  _ItemActionButton  widget to create compact action buttons for items. The  _ItemActionButton  widget displays an icon button with a tooltip and an  InkWell  widget for the tap effect. The  _ItemActionButton  widget adjusts the size and icon size based on the screen width. 
  Conclusion 
  In this tutorial, we learned how to create responsive Flutter layouts using the  ResponsiveUtils  class. We created a responsive layout for a pallet detail screen that adjusts based on the device size. We used the  ResponsiveUtils  class to get the device size, font scale, and icon size. We created different layouts for tablets and phones, with side-by-side panels for tablets and stacked panels for phones. We also created a compact action button widget for items that adjusts based on the screen width. 
  The complete source code for this tutorial is available on  GitHub. 
  Related Posts: Flutter Responsive Layout Tutorial Flutter Responsive Layout Tutorial Flutter State Management with Provider Flutter State Management with Provider Flutter Provider Tutorial Flutter Provider Tutorial Flutter ListView with Image and Checkbox Flutter ListView with Image and Checkbox Flutter ListView with Image and Tag Flutter ListView with Image and Tag Flutter ListView with Image and Subtitle Flutter ListView with Image and Subtitle Flutter ListView with Image and Icon Flutter ListView with Image and Icon Flutter ListView with */