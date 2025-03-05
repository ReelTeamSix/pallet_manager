// inventory_screen.dart - Refactored for responsiveness - PART 1
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pallet_model.dart';
import 'pallet_detail_screen.dart';
import 'responsive_utils.dart'; // Import responsive utilities
import 'utils/dialog_utils.dart'; // Import dialog utilities

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {

  @override
  Widget build(BuildContext context) {
    // Get device characteristics for responsive layouts
    final deviceSize = ResponsiveUtils.getDeviceSize(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    // Adjust based on device size
    final isNarrowScreen = deviceSize == DeviceSize.phoneXSmall ||
        deviceSize == DeviceSize.phoneSmall;

    return Scaffold(
      appBar: AppBar(
        title: Text("Inventory", style: context.largeText),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showTagFilterDialog(context),
            tooltip: "Filter by Tag",
            iconSize: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
          ),
        ],
      ),
      body: Consumer<PalletModel>(
        builder: (context, palletModel, child) {
          if (palletModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Display tag filter indicator if active
          Widget? filterIndicator;
          if (palletModel.currentTagFilter != null) {
            filterIndicator = Container(
              padding: ResponsiveUtils.getPadding(context, PaddingType.small),
              color: Colors.brown.shade50,
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list, 
                    size: ResponsiveUtils.getIconSize(context, IconSizeType.small), 
                    color: Colors.brown
                  ),
                  SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.tiny).left),
                  Expanded(
                    child: Text(
                      "Filtered by: ${palletModel.currentTagFilter}",
                      style: context.smallTextColor(Colors.brown.shade800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.close, 
                      size: ResponsiveUtils.getIconSize(context, IconSizeType.tiny)
                    ),
                    label: Text("Clear", style: context.smallText),
                    onPressed: () => palletModel.setTagFilter(null),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getPadding(context, PaddingType.tiny).left
                      ),
                      minimumSize: Size(60, 30),
                    ),
                  ),
                ],
              ),
            );
          }

          if (palletModel.pallets.isEmpty) {
            return Column(
              children: [
                if (filterIndicator != null) filterIndicator,
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: ResponsiveUtils.getIconSize(context, IconSizeType.xLarge),
                          color: Colors.grey
                        ),
                        SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
                        Text(
                          "No pallets yet",
                          style: context.mediumTextColor(Colors.grey),
                        ),
                        SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
                        Text(
                          "Tap + to add a new pallet",
                          style: context.smallTextColor(Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Use different layouts for tablet vs phone
          if (isTablet) {
            return _buildTabletLayout(
              context, 
              palletModel, 
              filterIndicator
            );
          } else {
            return _buildPhoneLayout(
              context, 
              palletModel, 
              filterIndicator, 
              isNarrowScreen
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        onPressed: () => _showAddPalletDialog(context),
        child: Icon(
          Icons.add, 
          size: ResponsiveUtils.getIconSize(context, IconSizeType.medium)
        ),
      ),
    );
  }

  // Tablet layout with grid display of pallets
  Widget _buildTabletLayout(
    BuildContext context, 
    PalletModel palletModel,
    Widget? filterIndicator
  ) {
    return Column(
      children: [
        if (filterIndicator != null) filterIndicator,
        Expanded(
          child: Padding(
            padding: ResponsiveUtils.getPadding(context, PaddingType.small),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: ResponsiveUtils.getPadding(context, PaddingType.small).left,
                mainAxisSpacing: ResponsiveUtils.getPadding(context, PaddingType.small).top,
              ),
              itemCount: palletModel.pallets.length,
              itemBuilder: (context, index) {
                final pallet = palletModel.pallets[index];
                return _buildTabletPalletCard(context, pallet, palletModel);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Phone layout with list display of pallets
  Widget _buildPhoneLayout(
    BuildContext context, 
    PalletModel palletModel,
    Widget? filterIndicator,
    bool isNarrowScreen
  ) {
    return Column(
      children: [
        if (filterIndicator != null) filterIndicator,
        Expanded(
          child: ListView.builder(
            itemCount: palletModel.pallets.length,
            itemBuilder: (context, index) {
              final pallet = palletModel.pallets[index];

              // Using a more compact layout for narrow screens
              return Dismissible(
                key: Key(pallet.id.toString()),
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
                      Text(
                        "Delete",
                        style: context.smallTextColor(Colors.white),
                      ),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.green,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getPadding(context, PaddingType.medium).left
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Mark Sold",
                        style: context.smallTextColor(Colors.white),
                      ),
                      SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.tiny).left),
                      Icon(
                        Icons.sell, 
                        color: Colors.white, 
                        size: ResponsiveUtils.getIconSize(context, IconSizeType.small)
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    return await _confirmDelete(context, palletModel, pallet);
                  } else if (direction == DismissDirection.endToStart) {
                    return await _confirmMarkSold(context, palletModel, pallet);
                  }
                  return false;
                },
                child: Card(
                  margin: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.getPadding(context, PaddingType.tiny).top,
                    horizontal: ResponsiveUtils.getPadding(context, PaddingType.small).left
                  ),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PalletDetailScreen(pallet: pallet),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getPadding(context, PaddingType.small).left,
                        vertical: isNarrowScreen 
                          ? ResponsiveUtils.getPadding(context, PaddingType.small).top
                          : ResponsiveUtils.getPadding(context, PaddingType.medium).top
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar - smaller on narrow screens
                          CircleAvatar(
                            backgroundColor: Colors.brown.shade300,
                            radius: isNarrowScreen 
                              ? ResponsiveUtils.getIconSize(context, IconSizeType.small)
                              : ResponsiveUtils.getIconSize(context, IconSizeType.medium),
                            child: Text(
                              pallet.name.isNotEmpty
                                  ? pallet.name[0].toUpperCase()
                                  : "P",
                              style: context.mediumTextColor(Colors.white),
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),

                          // Main content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Pallet name
                                Text(
                                  pallet.name,
                                  style: isNarrowScreen 
                                    ? context.smallTextWeight(FontWeight.bold)
                                    : context.mediumTextWeight(FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),

                                SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.tiny).top),

                                // Tag and metadata in a row
                                Row(
                                  children: [
                                    // Tag with icon
                                    Icon(
                                      Icons.sell_outlined,
                                      size: ResponsiveUtils.getIconSize(context, IconSizeType.tiny),
                                      color: Colors.brown.shade700
                                    ),
                                    SizedBox(width: 2),
                                    Flexible(
                                      flex: 3,
                                      child: Text(
                                        pallet.tag.isEmpty
                                            ? "No tag"
                                            : pallet.tag,
                                        style: context.tinyTextColor(Colors.brown.shade700),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),

                                    // Cost
                                    SizedBox(width: 6),
                                    Text("•", style: context.tinyTextColor(Colors.grey)),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.attach_money,
                                      size: ResponsiveUtils.getIconSize(context, IconSizeType.tiny),
                                      color: Colors.green.shade700
                                    ),
                                    Flexible(
                                      flex: 2,
                                      child: Text(
                                        pallet.totalCost.toStringAsFixed(2),
                                        style: context.tinyTextColor(Colors.green.shade700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Items count
                                    SizedBox(width: 6),
                                    Text("•", style: context.tinyTextColor(Colors.grey)),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.shopping_basket_outlined,
                                      size: ResponsiveUtils.getIconSize(context, IconSizeType.tiny),
                                      color: Colors.blueGrey
                                    ),
                                    Text(
                                      "${pallet.items.length}",
                                      style: context.tinyTextColor(Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Action buttons - more compact for narrow screens
                          if (!pallet.isClosed) ...[
                            _CompactActionButton(
                              icon: Icons.edit,
                              tooltip: "Edit Name",
                              onPressed: () => _showEditPalletNameDialog(
                                  context, palletModel, pallet),
                              isNarrowScreen: isNarrowScreen,
                            ),
                            _CompactActionButton(
                              icon: Icons.sell,
                              tooltip: "Edit Tag",
                              onPressed: () => _showEditTagDialog(
                                  context, palletModel, pallet),
                              isNarrowScreen: isNarrowScreen,
                            ),
                          ] else
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
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
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabletPalletCard(
    BuildContext context, 
    Pallet pallet, 
    PalletModel palletModel
  ) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PalletDetailScreen(pallet: pallet),
          ),
        ),
        child: Padding(
          padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.brown.shade300,
                    radius: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
                    child: Text(
                      pallet.name.isNotEmpty
                          ? pallet.name[0].toUpperCase()
                          : "P",
                      style: context.largeTextColor(Colors.white),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pallet.name,
                          style: context.largeTextWeight(FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          pallet.tag.isEmpty ? "No tag" : pallet.tag,
                          style: context.smallTextColor(Colors.brown.shade700),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (pallet.isClosed)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'CLOSED',
                            style: context.tinyTextWeight(FontWeight.bold).copyWith(
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: context.tinyTextWeight(FontWeight.bold).copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
                      Text(
                        '\$${pallet.totalCost.toStringAsFixed(2)}',
                        style: context.mediumTextColor(Colors.green.shade700),
                      ),
                    ],
                  ),
                ],
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Item count
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_basket_outlined,
                        size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
                        color: Colors.blueGrey
                      ),
                      SizedBox(width: 4),
                      Text(
                        "${pallet.items.length} items",
                        style: context.smallTextColor(Colors.blueGrey),
                      ),
                      Text(
                        " (${pallet.soldItemsCount} sold)",
                        style: context.smallTextColor(Colors.blueGrey),
                      ),
                    ],
                  ),
                  
                  // Action buttons for tablets
                  if (!pallet.isClosed)
                    Row(
                      children: [
                        _TabletActionButton(
                          icon: Icons.edit,
                          label: "Edit",
                          onPressed: () => _showEditPalletNameDialog(
                            context, palletModel, pallet),
                        ),
                        SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
                        _TabletActionButton(
                          icon: Icons.sell,
                          label: "Sell",
                          onPressed: () => _confirmMarkSold(
                            context, palletModel, pallet),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPalletNameDialog(
      BuildContext context, PalletModel model, Pallet pallet) {
    DialogUtils.showEditPalletNameDialog(context, model, pallet);
  }

  void _showTagFilterDialog(BuildContext context) {
    DialogUtils.showTagFilterDialog(context);
  }

  void _showEditTagDialog(
      BuildContext context, PalletModel palletModel, Pallet pallet) {
    final tagController = TextEditingController(text: pallet.tag);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Tag", style: context.largeTextWeight(FontWeight.bold)),
          content: KeyboardAware(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tagController,
                    decoration: InputDecoration(
                      labelText: "Tag",
                      border: OutlineInputBorder(),
                      contentPadding: ResponsiveUtils.getPaddingHV(
                        context,
                        PaddingType.small,
                        PaddingType.small
                      ),
                      prefixIcon: Icon(
                        Icons.sell_outlined,
                        size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
                      ),
                    ),
                    style: context.mediumText,
                    autofocus: true,
                  ),
                  if (palletModel.savedTags.isNotEmpty) ...[
                    SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Saved Tags:",
                        style: context.smallTextWeight(FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.15,
                      ),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: ResponsiveUtils.getPadding(context, PaddingType.tiny).left,
                          runSpacing: ResponsiveUtils.getPadding(context, PaddingType.tiny).top,
                          children: palletModel.savedTags
                              .map((tag) => ActionChip(
                                    label: Text(tag, style: context.smallText),
                                    avatar: Icon(
                                      Icons.sell_outlined, 
                                      size: ResponsiveUtils.getIconSize(context, IconSizeType.small)
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      tagController.text = tag;
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ],
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
                final newTag = tagController.text.trim();
                palletModel.updatePalletTag(pallet.id, newTag);
                Navigator.pop(context);
              },
              child: Text("SAVE", style: context.mediumText),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmDelete(
      BuildContext context, PalletModel palletModel, Pallet pallet) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Pallet", style: context.largeTextWeight(FontWeight.bold)),
          content: RichText(
            text: TextSpan(
              style: context.mediumText,
              children: [
                TextSpan(text: "Are you sure you want to delete "),
                TextSpan(
                  text: pallet.name,
                  style: context.mediumTextWeight(FontWeight.bold),
                ),
                TextSpan(text: "?"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("CANCEL", style: context.mediumText),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                palletModel.removePallet(pallet.id);
                Navigator.pop(context, true);
              },
              child: Text("DELETE", style: context.mediumText),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmMarkSold(
      BuildContext context, PalletModel palletModel, Pallet pallet) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Mark as Sold", style: context.largeTextWeight(FontWeight.bold)),
          content: Text(
            "Are you sure you want to mark '${pallet.name}' as sold?",
            style: context.mediumText,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("CANCEL", style: context.mediumText),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                palletModel.markPalletAsSold(pallet.id);
                Navigator.pop(context, true);
              },
              child: Text("MARK SOLD", style: context.mediumText),
            ),
          ],
        );
      },
    );
  }

  void _showAddPalletDialog(BuildContext context) {
    DialogUtils.showAddPalletDialog(context);
  }
}

// Helper widget for very compact action buttons
class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isNarrowScreen;

  const _CompactActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.isNarrowScreen,
  });

  @override
  Widget build(BuildContext context) {
    // Use responsive sizing
    final size = isNarrowScreen ? 30.0 : 36.0;
    final iconSize = ResponsiveUtils.getIconSize(
        context, isNarrowScreen ? IconSizeType.small : IconSizeType.medium);

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
              color: Colors.brown,
            ),
          ),
        ),
      ),
    );
  }
}

// Tablet-specific button with label for better usability
class _TabletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _TabletActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(
        icon,
        size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
      ),
      label: Text(
        label,
        style: context.smallText,
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal:
              ResponsiveUtils.getPadding(context, PaddingType.small).left,
          vertical: ResponsiveUtils.getPadding(context, PaddingType.tiny).top,
        ),
        minimumSize: Size(80, 36),
      ),
      onPressed: onPressed,
    );
  }
}
