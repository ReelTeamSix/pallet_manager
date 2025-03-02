import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pallet_model.dart';

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
    // Get screen dimensions to adjust layout for different devices
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400; // Adjust for S21-sized devices

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
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 14),
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
                onPressed: () {
                  setState(() {
                    _isInfoCardExpanded = !_isInfoCardExpanded;
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Collapsible info card
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isInfoCardExpanded ? null : 50, // Collapsed height
                child: _buildPalletInfoCard(currentPallet, isNarrowScreen),
              ),

              // Button row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: Text("Add Item",
                            style:
                                TextStyle(fontSize: isNarrowScreen ? 12 : 14)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: currentPallet.isClosed
                            ? null
                            : () => _showAddItemDialog(context, currentPallet),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!currentPallet.isClosed)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.sell, size: 18),
                          label: Text("Mark Sold",
                              style: TextStyle(
                                  fontSize: isNarrowScreen ? 12 : 14)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () => _confirmMarkPalletSold(
                              context, palletModel, currentPallet),
                        ),
                      ),
                  ],
                ),
              ),

              // Items list
              Expanded(
                child: _buildItemsList(
                    context, palletModel, currentPallet, isNarrowScreen),
              ),
            ],
          ),
        );
      },
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
          leading: Icon(Icons.label,
              color: Colors.deepOrange, size: isNarrowScreen ? 18 : 22),
          title: Text(
            '${pallet.name} - Tag: ${pallet.tag}',
            style: TextStyle(fontSize: isNarrowScreen ? 13 : 14),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: pallet.isClosed
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'CLOSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                )
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
    final fontSize = isNarrowScreen ? 12.0 : 14.0;
    final iconSize = isNarrowScreen ? 16.0 : 20.0;
    final padding = isNarrowScreen ? 12.0 : 16.0;

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      child: Column(
        children: [
          // Header with pallet name, tag and status
          ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: padding, vertical: 0),
            dense: isNarrowScreen,
            leading: Icon(Icons.label,
                color: Colors.deepOrange, size: isNarrowScreen ? 18 : 24),
            title: Text(
              'Pallet: ${pallet.name}',
              style: TextStyle(
                  fontSize: fontSize + 2, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Tag: ${pallet.tag}',
              style: TextStyle(fontSize: fontSize),
            ),
            trailing: pallet.isClosed
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'CLOSED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
          ),

          // Info rows with icons and data
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.date_range,
                    color: Colors.deepOrange, size: iconSize),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Date: ${_formatDate(pallet.date)}',
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.attach_money,
                    color: Colors.deepOrange, size: iconSize),
                const SizedBox(width: 6),
                Text(
                  'Total Cost: ',
                  style: TextStyle(fontSize: fontSize),
                ),
                Text(
                  '\$${pallet.totalCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.shopping_cart,
                    color: Colors.deepOrange, size: iconSize),
                const SizedBox(width: 6),
                Text(
                  'Items: ',
                  style: TextStyle(fontSize: fontSize),
                ),
                Text(
                  '${pallet.items.length} (${pallet.soldItemsCount} sold)',
                  style: TextStyle(fontSize: fontSize),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.show_chart,
                    color: Colors.deepOrange, size: iconSize),
                const SizedBox(width: 6),
                Text(
                  'Current Profit: ',
                  style: TextStyle(fontSize: fontSize),
                ),
                Text(
                  '\$${pallet.profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: pallet.profit >= 0 ? Colors.green : Colors.red,
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No items added yet",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              "Tap 'Add Item' to get started",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Font sizes for different screen widths
    final titleFontSize = isNarrowScreen ? 13.0 : 14.0;
    final subtitleFontSize = isNarrowScreen ? 11.0 : 12.0;

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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text("Delete",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: isNarrowScreen ? 12 : 14)),
              ],
            ),
          ),
          // Swipe right to mark as sold
          secondaryBackground: Container(
            color: Colors.green,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Mark Sold",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: isNarrowScreen ? 12 : 14)),
                const SizedBox(width: 4),
                const Icon(Icons.sell, color: Colors.white, size: 18),
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
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isNarrowScreen ? 10 : 16, vertical: 4),
              dense: isNarrowScreen,
              title: Text(
                item.name,
                style: TextStyle(
                  fontWeight: item.isSold ? FontWeight.bold : FontWeight.normal,
                  fontSize: titleFontSize,
                ),
              ),
              subtitle: item.isSold
                  ? Text(
                      'Sold on: ${_formatDate(item.saleDate)} for: \$${item.salePrice.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: subtitleFontSize),
                    )
                  : Text(
                      'Not sold yet (swipe to sell or delete)',
                      style: TextStyle(fontSize: subtitleFontSize),
                    ),
              trailing: item.isSold
                  ? const Icon(Icons.check_circle,
                      color: Colors.green, size: 18)
                  : pallet.isClosed
                      ? const Icon(Icons.lock, color: Colors.grey, size: 18)
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
          title: const Text("Delete Item"),
          content: Text("Are you sure you want to delete '${item.name}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                model.removeItemFromPallet(palletId, item.id);
                Navigator.pop(context, true);
              },
              child: const Text("DELETE"),
            ),
          ],
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context, Pallet pallet) {
    final TextEditingController itemController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Item"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: itemController,
              decoration: const InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) => value!.isEmpty ? "Enter item name" : null,
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Provider.of<PalletModel>(context, listen: false)
                      .addItemToPallet(pallet.id, itemController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text("ADD"),
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
          title: const Text("Edit Pallet Name"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Pallet Name",
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixIcon: Icon(Icons.edit),
              ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  model.updatePalletName(pallet.id, nameController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text("SAVE"),
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
          title: const Text("Mark Item as Sold"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Item: ${item.name}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: "Sale Price",
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCEL"),
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
              child: const Text("MARK SOLD"),
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
          title: const Text("Mark Pallet as Sold"),
          content: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                const TextSpan(text: "Are you sure you want to mark "),
                TextSpan(
                  text: pallet.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                    text: " as closed? This will prevent further changes."),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                model.markPalletAsSold(pallet.id);
                Navigator.pop(context);
              },
              child: const Text("CLOSE PALLET"),
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
    return Container(
      width: isNarrowScreen ? 28 : 36,
      height: isNarrowScreen ? 28 : 36,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isNarrowScreen ? 14 : 18),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: isNarrowScreen ? 16 : 20,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
