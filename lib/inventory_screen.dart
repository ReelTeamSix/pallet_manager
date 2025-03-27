// inventory_screen.dart - Refactored for responsiveness - PART 1
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pallet_model.dart';
import 'pallet_detail_screen.dart';
import 'responsive_utils.dart'; // Import responsive utilities
import 'utils/dialog_utils.dart'; // Import dialog utilities
import 'theme/theme_extensions.dart';

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
                childAspectRatio: 1.6, // Updated for new card design
                crossAxisSpacing: ResponsiveUtils.getPadding(context, PaddingType.small).left,
                mainAxisSpacing: ResponsiveUtils.getPadding(context, PaddingType.small).top,
              ),
              itemCount: palletModel.pallets.length,
              itemBuilder: (context, index) {
                final pallet = palletModel.pallets[index];
                return AnimatedBuilder(
                  animation: ModalRoute.of(context)!.animation!,
                  child: _buildTabletPalletCard(context, pallet, palletModel),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: ModalRoute.of(context)!.animation!,
                        curve: Interval(
                          0.05 * (index % 4),
                          0.6,
                          curve: Curves.easeInOut,
                        ),
                      )),
                      child: child,
                    );
                  },
                );
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
              return AnimatedBuilder(
                animation: ModalRoute.of(context)!.animation!,
                child: _buildPhonePalletCard(context, pallet, palletModel),
                builder: (context, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(1, 0),
                      end: Offset(0, 0),
                    ).animate(CurvedAnimation(
                      parent: ModalRoute.of(context)!.animation!,
                      curve: Interval(
                        0.1 + 0.05 * index,
                        0.4 + 0.05 * index,
                        curve: Curves.easeOut,
                      ),
                    )),
                    child: child,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper method to build phone pallet card
  Widget _buildPhonePalletCard(BuildContext context, Pallet pallet, PalletModel model) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Dismissible(
          key: ValueKey('pallet-${pallet.id}'),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.check, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              return await _confirmDeletePallet(context, model, pallet);
            } else {
              model.markPalletAsSold(pallet.id);
              return false; // Don't dismiss, just mark as sold
            }
          },
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PalletDetailScreen(pallet: pallet),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: pallet.isClosed 
                            ? Colors.green.shade100 
                            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          pallet.isClosed ? Icons.check_circle : Icons.inventory,
                          color: pallet.isClosed 
                              ? Colors.green 
                              : Theme.of(context).colorScheme.primary,
                          size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pallet.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Date: ${_formatDate(pallet.date)}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "\$${pallet.profit.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: pallet.profit >= 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pallet.isClosed ? "Closed" : "Open",
                            style: TextStyle(
                              fontSize: 12,
                              color: pallet.isClosed ? Colors.green : Colors.orangeAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoChip(
                        context, 
                        "${pallet.items.length} items", 
                        Icons.inventory_2_outlined
                      ),
                      _buildInfoChip(
                        context, 
                        "${pallet.soldItemsCount} sold", 
                        Icons.check_circle_outline
                      ),
                      _buildInfoChip(
                        context, 
                        pallet.tag.isEmpty ? "No tag" : pallet.tag, 
                        Icons.label_outline
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  // Helper method to build tablet pallet card
  Widget _buildTabletPalletCard(BuildContext context, Pallet pallet, PalletModel model) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PalletDetailScreen(pallet: pallet),
          ),
        ),
        onLongPress: () => _confirmDeletePallet(context, model, pallet),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: pallet.isClosed 
                        ? Colors.green.shade100 
                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      pallet.isClosed ? Icons.check_circle : Icons.inventory,
                      color: pallet.isClosed 
                          ? Colors.green 
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pallet.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Date: ${_formatDate(pallet.date)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "\$${pallet.profit.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: pallet.profit >= 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: pallet.isClosed 
                              ? Colors.green.withOpacity(0.1) 
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pallet.isClosed ? "Closed" : "Open",
                          style: TextStyle(
                            fontSize: 12,
                            color: pallet.isClosed ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    context, 
                    "${pallet.items.length} items", 
                    Icons.inventory_2_outlined
                  ),
                  _buildInfoChip(
                    context, 
                    "${pallet.soldItemsCount} sold", 
                    Icons.check_circle_outline
                  ),
                  _buildInfoChip(
                    context, 
                    pallet.tag.isEmpty ? "No tag" : pallet.tag, 
                    Icons.label_outline
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

  Future<bool?> _confirmDeletePallet(
      BuildContext context, PalletModel palletModel, Pallet pallet) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final hasItems = pallet.items.isNotEmpty;
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                "Delete Pallet",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Are you sure you want to delete '${pallet.name}'?",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              if (hasItems) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "This pallet contains ${pallet.items.length} item${pallet.items.length != 1 ? 's' : ''}. All items will be deleted.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("CANCEL"),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.delete),
              label: Text("DELETE"),
              onPressed: () {
                palletModel.removePallet(pallet.id);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  // Replace both _buildPhonePalletCard and _buildTabletPalletCard methods with this shared method
  Widget _buildPalletCard(BuildContext context, Pallet pallet, PalletModel model, bool isTablet) {
    return PalletCard(
      pallet: pallet,
      model: model,
      isTablet: isTablet,
      onDelete: _confirmDeletePallet,
    );
  }

  // Update _buildPalletList to use _buildPalletCard instead of separate methods
  Widget _buildPalletList() {
    return Consumer<PalletModel>(
      builder: (context, palletModel, child) {
        final pallets = palletModel.pallets;
        if (pallets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No pallets yet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tap + to add your first pallet",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refreshData(),
          child: ListView.builder(
            itemCount: pallets.length,
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            itemBuilder: (context, index) {
              final pallet = pallets[index];
              return _buildPalletCard(
                context,
                pallet,
                palletModel,
                _isTablet, // Pass tablet flag to build appropriate layout
              );
            },
          ),
        );
      },
    );
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

// Replace the _buildPhonePalletCard and _buildTabletPalletCard methods with this reusable widget
class PalletCard extends StatelessWidget {
  final Pallet pallet;
  final PalletModel model;
  final bool isTablet;
  final Function(BuildContext, PalletModel, Pallet) onDelete;

  const PalletCard({
    Key? key,
    required this.pallet,
    required this.model,
    required this.onDelete,
    this.isTablet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PalletDetailScreen(pallet: pallet),
          ),
        ),
        onLongPress: () => onDelete(context, model, pallet),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isTablet 
              ? _buildTabletLayout(context)
              : _buildPhoneLayout(context),
        ),
      ),
    );
  }

  // Phone layout 
  Widget _buildPhoneLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: pallet.isClosed 
                  ? Colors.green.shade100 
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                pallet.isClosed ? Icons.check_circle : Icons.inventory,
                color: pallet.isClosed 
                    ? Colors.green 
                    : Theme.of(context).colorScheme.primary,
                size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pallet.name,
                    style: context.mediumTextWeight(FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.tag,
                        size: ResponsiveUtils.getIconSize(context, IconSizeType.tiny),
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pallet.tag.isEmpty ? 'No Tag' : pallet.tag,
                        style: context.smallText.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoItem(
              context,
              'Items',
              '${pallet.items.length}',
              Icons.list,
            ),
            _buildInfoItem(
              context,
              'Cost',
              '\$${pallet.totalCost.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildInfoItem(
              context,
              'Profit',
              '\$${pallet.profit.toStringAsFixed(2)}',
              Icons.trending_up,
              valueColor: pallet.profit >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
        if (pallet.isClosed) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'CLOSED',
              style: context.tinyTextWeight(FontWeight.bold).copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Tablet layout
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: pallet.isClosed 
                  ? Colors.green.shade100 
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                pallet.isClosed ? Icons.check_circle : Icons.inventory,
                color: pallet.isClosed 
                    ? Colors.green 
                    : Theme.of(context).colorScheme.primary,
                size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pallet.name,
                    style: context.largeTextWeight(FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: ResponsiveUtils.getIconSize(context, IconSizeType.tiny),
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(pallet.date),
                        style: context.smallText.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.tag,
                        size: ResponsiveUtils.getIconSize(context, IconSizeType.tiny),
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pallet.tag.isEmpty ? 'No Tag' : pallet.tag,
                        style: context.smallText.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (pallet.isClosed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CLOSED',
                  style: context.smallTextWeight(FontWeight.bold).copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoItem(
              context,
              'Items',
              '${pallet.items.length}',
              Icons.list,
              showLabel: true,
            ),
            _buildInfoItem(
              context,
              'Total Cost',
              '\$${pallet.totalCost.toStringAsFixed(2)}',
              Icons.attach_money,
              showLabel: true,
            ),
            _buildInfoItem(
              context,
              'Profit',
              '\$${pallet.profit.toStringAsFixed(2)}',
              Icons.trending_up,
              valueColor: pallet.profit >= 0 ? Colors.green : Colors.red,
              showLabel: true,
            ),
            _buildInfoItem(
              context,
              'Revenue',
              '\$${pallet.totalRevenue.toStringAsFixed(2)}',
              Icons.payments,
              showLabel: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool showLabel = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: context.smallTextWeight(FontWeight.bold).copyWith(
                color: valueColor ?? Colors.black,
              ),
            ),
          ],
        ),
        if (showLabel) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: context.tinyText.copyWith(color: Colors.grey),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Update the inventory screen's ListView builder to use the new widget
Widget _buildInventoryContent(BuildContext context, PalletModel model) {
  final isTablet = ResponsiveUtils.isTablet(context);
  
  if (model.pallets.isEmpty) {
    return _buildEmptyState(context);
  }

  return ListView.builder(
    padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
    itemCount: model.pallets.length,
    itemBuilder: (context, index) {
      final pallet = model.pallets[index];
      return PalletCard(
        pallet: pallet,
        model: model,
        isTablet: isTablet,
        onDelete: _confirmDeletePallet,
      );
    },
  );
}
