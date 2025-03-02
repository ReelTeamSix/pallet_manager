import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pallet_model.dart';
import 'pallet_detail_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen width to adjust layout for different devices
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen =
        screenWidth < 400; // Adjust specifically for S21-sized devices

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showTagFilterDialog(context),
            tooltip: "Filter by Tag",
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
              padding: const EdgeInsets.all(8),
              color: Colors.brown.shade50,
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 14, color: Colors.brown),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Filtered by: ${palletModel.currentTagFilter}",
                      style:
                          TextStyle(color: Colors.brown.shade800, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text("Clear", style: TextStyle(fontSize: 12)),
                    onPressed: () => palletModel.setTagFilter(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(60, 30),
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
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          "No pallets yet",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Tap + to add a new pallet",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Row(
                          children: [
                            Icon(Icons.delete, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text("Delete",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        color: Colors.green,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("Mark Sold",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.sell, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          return await _confirmDelete(
                              context, palletModel, pallet);
                        } else if (direction == DismissDirection.endToStart) {
                          return await _confirmMarkSold(
                              context, palletModel, pallet);
                        }
                        return false;
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PalletDetailScreen(pallet: pallet),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: isNarrowScreen ? 8 : 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar - smaller on narrow screens
                                CircleAvatar(
                                  backgroundColor: Colors.brown.shade300,
                                  radius: isNarrowScreen ? 18 : 22,
                                  child: Text(
                                    pallet.name.isNotEmpty
                                        ? pallet.name[0].toUpperCase()
                                        : "P",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isNarrowScreen ? 14 : 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Main content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Pallet name
                                      Text(
                                        pallet.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isNarrowScreen ? 14 : 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),

                                      const SizedBox(height: 2),

                                      // Tag and metadata in a row
                                      Row(
                                        children: [
                                          // Tag with icon
                                          Icon(Icons.sell_outlined,
                                              size: 12,
                                              color: Colors.brown.shade700),
                                          const SizedBox(width: 2),
                                          Flexible(
                                            flex: 3,
                                            child: Text(
                                              pallet.tag.isEmpty
                                                  ? "No tag"
                                                  : pallet.tag,
                                              style: TextStyle(
                                                color: Colors.brown.shade700,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),

                                          // Cost
                                          const SizedBox(width: 6),
                                          const Text("•",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12)),
                                          const SizedBox(width: 6),
                                          Icon(Icons.attach_money,
                                              size: 12,
                                              color: Colors.green.shade700),
                                          Flexible(
                                            flex: 2,
                                            child: Text(
                                              pallet.totalCost
                                                  .toStringAsFixed(2),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green.shade700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          // Items count
                                          const SizedBox(width: 6),
                                          const Text("•",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12)),
                                          const SizedBox(width: 6),
                                          const Icon(
                                              Icons.shopping_basket_outlined,
                                              size: 12,
                                              color: Colors.blueGrey),
                                          Text(
                                            "${pallet.items.length}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.blueGrey,
                                            ),
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
                                  ),
                                  _CompactActionButton(
                                    icon: Icons.sell,
                                    tooltip: "Edit Tag",
                                    onPressed: () => _showEditTagDialog(
                                        context, palletModel, pallet),
                                  ),
                                ] else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'CLOSED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        onPressed: () => _showAddPalletDialog(context),
        child: const Icon(Icons.add),
      ),
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

  void _showTagFilterDialog(BuildContext context) {
    final palletModel = Provider.of<PalletModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter by Tag"),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          content: SizedBox(
            width: double.maxFinite,
            child: palletModel.savedTags.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text("No tags saved yet."),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // Add "All" option
                        FilterChip(
                          label:
                              const Text("All", style: TextStyle(fontSize: 12)),
                          selected: palletModel.currentTagFilter == null,
                          onSelected: (_) {
                            palletModel.setTagFilter(null);
                            Navigator.pop(context);
                          },
                          avatar: const Icon(Icons.all_inclusive, size: 14),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        // Add chips for each tag
                        ...palletModel.savedTags
                            .map((tag) => FilterChip(
                                  label: Text(tag,
                                      style: const TextStyle(fontSize: 12)),
                                  selected: palletModel.currentTagFilter == tag,
                                  onSelected: (_) {
                                    palletModel.setTagFilter(tag);
                                    Navigator.pop(context);
                                  },
                                  avatar:
                                      const Icon(Icons.sell_outlined, size: 14),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE"),
            ),
          ],
        );
      },
    );
  }

  void _showEditTagDialog(
      BuildContext context, PalletModel palletModel, Pallet pallet) {
    final tagController = TextEditingController(text: pallet.tag);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Tag"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: tagController,
                  decoration: const InputDecoration(
                    labelText: "Tag",
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  autofocus: true,
                ),
                if (palletModel.savedTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Saved Tags:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.15,
                    ),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: palletModel.savedTags
                            .map((tag) => ActionChip(
                                  label: Text(tag,
                                      style: const TextStyle(fontSize: 12)),
                                  avatar:
                                      const Icon(Icons.sell_outlined, size: 14),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () {
                final newTag = tagController.text.trim();
                palletModel.updatePalletTag(pallet.id, newTag);
                Navigator.pop(context);
              },
              child: const Text("SAVE"),
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
          title: const Text("Delete Pallet"),
          content: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                const TextSpan(text: "Are you sure you want to delete "),
                TextSpan(
                  text: pallet.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: "?"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                palletModel.removePallet(pallet.id);
                Navigator.pop(context, true);
              },
              child: const Text("DELETE"),
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
          title: const Text("Mark as Sold"),
          content:
              Text("Are you sure you want to mark '${pallet.name}' as sold?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                palletModel.markPalletAsSold(pallet.id);
                Navigator.pop(context, true);
              },
              child: const Text("MARK SOLD"),
            ),
          ],
        );
      },
    );
  }

  void _showAddPalletDialog(BuildContext context) {
    final palletModel = Provider.of<PalletModel>(context, listen: false);
    // Set default name "Pallet X" based on the next ID
    final nameController =
        TextEditingController(text: "Pallet ${palletModel.generatePalletId()}");
    final tagController = TextEditingController();
    final costController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Function to show tag selection in a bottom sheet
    void _showTagSelector() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select a Tag",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: palletModel.savedTags
                        .map((tag) => ActionChip(
                              label: Text(tag,
                                  style: const TextStyle(fontSize: 12)),
                              avatar: const Icon(Icons.sell_outlined, size: 14),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                tagController.text = tag;
                                Navigator.pop(context);
                              },
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CLOSE"),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Function to handle form submission
    void _submitForm() {
      if (formKey.currentState!.validate()) {
        final name = nameController.text;
        final tag = tagController.text.trim();
        final cost = double.tryParse(costController.text) ?? 0.0;

        Provider.of<PalletModel>(context, listen: false).addPallet(
          Pallet(
            id: Provider.of<PalletModel>(context, listen: false)
                .generatePalletId(),
            name: name,
            tag: tag,
            totalCost: cost,
            date: DateTime.now(),
          ),
        );
        Navigator.pop(context);
      }
    }

    // Show a regular dialog with simplified content
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Pallet"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Pallet Name",
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter pallet name";
                    }
                    // Check for duplicate names
                    if (palletModel.palletNameExists(value)) {
                      return "A pallet with this name already exists";
                    }
                    return null;
                  },
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: tagController,
                        decoration: const InputDecoration(
                          labelText: "Tag",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          prefixIcon: Icon(Icons.sell_outlined),
                        ),
                        readOnly: false, // Allow direct editing too
                      ),
                    ),
                    if (palletModel.savedTags.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.list, size: 20),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        tooltip: "Select saved tag",
                        onPressed: _showTagSelector,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: "Total Cost",
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Enter cost";
                    if (double.tryParse(value) == null)
                      return "Enter a valid number";
                    return null;
                  },
                  onEditingComplete: _submitForm, // Submit on keyboard done
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
            style: TextButton.styleFrom(
              minimumSize: const Size(60, 36),
            ),
          ),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text("ADD"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(60, 36),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for very compact action buttons
class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CompactActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: 16,
              color: Colors.brown,
            ),
          ),
        ),
      ),
    );
  }
}
