// File: lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Import with prefix to avoid ambiguity
import 'inventory_screen.dart' as inventory;
import 'analytics_screen.dart';
import 'pallet_model.dart';
import 'pallet_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<PalletModel>(
          builder: (context, palletModel, child) {
            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      "Pallet Pro",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF026670), // Darker teal
                            const Color(0xFF02838A), // Main teal
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -50,
                            top: -20,
                            child: Icon(
                              Icons.inventory_2,
                              size: 180,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Summary Stats
                SliverToBoxAdapter(
                  child: _buildSummaryStats(context, palletModel),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Quick Actions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Restructured to ensure equal height and proper scaling for medium font sizes
                        _buildQuickActionCards(context),
                      ],
                    ),
                  ),
                ),

                // Analytics Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Business Insights",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAnalyticsCard(
                          context,
                          palletModel,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AnalyticsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent Activity
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Recent Activity",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRecentActivity(context, palletModel),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, PalletModel model) {
    final profit = model.totalProfit;
    final totalPallets = model.pallets.length;
    final itemsSold = model.totalSoldItems;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: "Total Profit",
            value: "\$${profit.toStringAsFixed(2)}",
            color: profit >= 0 ? Colors.green : Colors.red,
            icon: Icons.trending_up,
          ),
          const SizedBox(
            height: 40,
            child: VerticalDivider(thickness: 1),
          ),
          _buildStatItem(
            label: "Pallets",
            value: totalPallets.toString(),
            color: Colors.blue,
            icon: Icons.inventory_2,
          ),
          const SizedBox(
            height: 40,
            child: VerticalDivider(thickness: 1),
          ),
          _buildStatItem(
            label: "Items Sold",
            value: itemsSold.toString(),
            color: Colors.orange,
            icon: Icons.sell,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Enhanced method for building quick action cards with better visual cues
  Widget _buildQuickActionCards(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              icon: Icons.inventory_2_outlined,
              title: "Manage Inventory",
              subtitle: "Browse and track items",
              color: Colors.blue.shade600,
              maxWidth: constraints.maxWidth / 2 - 8,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const inventory.InventoryScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              context,
              icon: Icons.add_box_rounded,
              title: "Add Pallet",
              subtitle: "Create new inventory",
              color: Colors.green.shade600,
              maxWidth: constraints.maxWidth / 2 - 8,
              onTap: () => showAddPalletDialog(context),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required double maxWidth,
  }) {
    // Enhanced card design with clearer visual hierarchy and better action indication
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Larger, more visible icon with background
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Centered, prominent title
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Subtitle with better contrast
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Visual indicator that this is an action
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: color.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Tap to access",
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context, PalletModel model,
      {required VoidCallback onTap}) {
    final profit = model.totalProfit;
    final roi =
        model.totalCost > 0 ? (model.totalProfit / model.totalCost * 100) : 0.0;

    // Format numbers to handle large values
    String profitText = "\$${profit.toStringAsFixed(2)}";
    String roiText = "${roi.toStringAsFixed(1)}%";

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Profit & Loss Summary",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.analytics,
                    color: Colors.brown.shade300,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Modified profit display with better overflow handling
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Profit",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          profitText,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: profit >= 0 ? Colors.green : Colors.red,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "ROI",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          roiText,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: roi >= 0 ? Colors.green : Colors.red,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "Tap to view detailed analytics →",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, PalletModel model) {
    if (model.pallets.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "No activity yet. Start by adding your first pallet!",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Get 3 most recent pallets
    final recentPallets = [...model.pallets]
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayPallets = recentPallets.take(3).toList();

    return Column(
      children: displayPallets.map((pallet) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.brown.shade100,
              child: Icon(
                pallet.isClosed ? Icons.check_circle : Icons.inventory,
                color: Colors.brown,
              ),
            ),
            title: Text(
              pallet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              "Tag: ${pallet.tag} • ${pallet.items.length} items (${pallet.soldItemsCount} sold)",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              "\$${pallet.profit.toStringAsFixed(2)}",
              style: TextStyle(
                color: pallet.profit >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PalletDetailScreen(pallet: pallet),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void showAddPalletDialog(BuildContext context) {
    final palletModel = Provider.of<PalletModel>(context, listen: false);
    // Set default name "Pallet X" based on the next ID
    final nameController =
        TextEditingController(text: "Pallet ${palletModel.generatePalletId()}");
    final tagController = TextEditingController();
    final costController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Function to show tag selection in a bottom sheet
    void showTagSelector() {
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: palletModel.savedTags
                        .map((tag) => ActionChip(
                              label: Text(tag),
                              avatar: const Icon(Icons.sell_outlined, size: 16),
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
    void submitForm() {
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: tagController,
                        decoration: const InputDecoration(
                          labelText: "Tag",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.sell_outlined),
                        ),
                        readOnly: false, // Allow direct editing too
                      ),
                    ),
                    if (palletModel.savedTags.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.list),
                        tooltip: "Select saved tag",
                        onPressed: showTagSelector,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: "Total Cost",
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Enter cost";
                    }
                    if (double.tryParse(value) == null) {
                      return "Enter a valid number";
                    }
                    return null;
                  },
                  onEditingComplete: submitForm, // Submit on keyboard done
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: submitForm,
            child: const Text("ADD"),
          ),
        ],
      ),
    );
  }
}
