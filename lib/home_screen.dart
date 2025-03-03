// File: lib/home_screen.dart - Refactored for responsiveness - PART 1
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Import with prefix to avoid ambiguity
import 'inventory_screen.dart' as inventory;
import 'analytics_screen.dart';
import 'pallet_model.dart';
import 'pallet_detail_screen.dart';
import 'responsive_utils.dart'; // Import the new responsive utilities

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if we should use tablet layout
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return Scaffold(
      body: SafeArea(
        // For ensuring content is visible when keyboard appears
        bottom: false,
        child: Consumer<PalletModel>(
          builder: (context, palletModel, child) {
            return CustomScrollView(
              slivers: [
                // App Bar with responsive dimensions
                SliverAppBar(
                  expandedHeight: isTablet ? 250.0 : 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      "Pallet Pro",
                      style: context.largeTextWeight(FontWeight.bold).copyWith(
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
                              size: isTablet ? 250 : 180,
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
                    padding: ResponsiveUtils.getPaddingHV(
                      context,
                      PaddingType.medium,
                      PaddingType.small
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Quick Actions",
                          style: context.largeTextWeight(FontWeight.bold),
                        ),
                        SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
                        // Restructured to ensure equal height and proper scaling for medium font sizes
                        _buildQuickActionCards(context),
                      ],
                    ),
                  ),
                ),

                // Analytics Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Business Insights",
                          style: context.largeTextWeight(FontWeight.bold),
                        ),
                        SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),
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

                // Recent Activity with responsive layout considerations
                SliverToBoxAdapter(
                  child: Padding(
                    padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recent Activity",
                          style: context.largeTextWeight(FontWeight.bold),
                        ),
                        SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),
                        // Grid view for tablets, list view for phones
                        isTablet
                            ? _buildRecentActivityGrid(context, palletModel)
                            : _buildRecentActivity(context, palletModel),
                      ],
                    ),
                  ),
                ),
                
                // Add bottom padding to ensure content is not hidden by navigation elements
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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

    // Check if we should use tablet layout for more space
    final isTablet = ResponsiveUtils.isTablet(context);

    return Container(
      padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
      margin: ResponsiveUtils.getPaddingHV(
          context, PaddingType.medium, PaddingType.medium),
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
            context: context,
            label: "Total Profit",
            value: "\$${profit.toStringAsFixed(2)}",
            color: profit >= 0 ? Colors.green : Colors.red,
            icon: Icons.trending_up,
          ),
          SizedBox(
            height: isTablet ? 50 : 40,
            child: VerticalDivider(thickness: 1),
          ),
          _buildStatItem(
            context: context,
            label: "Pallets",
            value: totalPallets.toString(),
            color: Colors.blue,
            icon: Icons.inventory_2,
          ),
          SizedBox(
            height: isTablet ? 50 : 40,
            child: VerticalDivider(thickness: 1),
          ),
          _buildStatItem(
            context: context,
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
  required BuildContext context,
  required String label,
  required String value,
  required Color color,
  required IconData icon,
}) {
  // Adjust font size based on text length to prevent overflow
  final valueLength = value.length;
  final fontSize = valueLength > 8
      ? FontSizeType.small
      : (valueLength > 5 ? FontSizeType.medium : FontSizeType.large);
  
  return Column(
    children: [
      Icon(
        icon, 
        color: color, 
        size: ResponsiveUtils.getIconSize(context, IconSizeType.medium)
      ),
      SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: fontSize == FontSizeType.small
              ? context.smallTextWeight(FontWeight.bold).copyWith(color: color)
              : (fontSize == FontSizeType.medium
                  ? context.mediumTextWeight(FontWeight.bold).copyWith(color: color)
                  : context.largeTextWeight(FontWeight.bold).copyWith(color: color)),
        ),
      ),
      Text(
        label,
        style: context.smallTextColor(Colors.grey),
      ),
    ],
  );
}

  // Enhanced method for building quick action cards with better visual cues
  Widget _buildQuickActionCards(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isVeryNarrow = constraints.maxWidth < 300;
      
      // For very narrow screens, stack cards vertically
      if (isVeryNarrow) {
        return Column(
          children: [
            _buildActionCard(
              context,
              icon: Icons.inventory_2_outlined,
              title: "Manage Inventory",
              subtitle: "Browse and track items",
              color: Colors.blue.shade600,
              maxWidth: constraints.maxWidth,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const inventory.InventoryScreen(),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
            _buildActionCard(
              context,
              icon: Icons.add_box_rounded,
              title: "Add Pallet",
              subtitle: "Create new inventory",
              color: Colors.green.shade600,
              maxWidth: constraints.maxWidth,
              onTap: () => showAddPalletDialog(context),
            ),
          ],
        );
      }
      
      // For other screens, use a row layout
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
          SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
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
    // Get font scale to adjust padding
    final fontScale = MediaQuery.of(context).textScaleFactor;
    final padding = fontScale > 1.3 
        ? ResponsiveUtils.getPadding(context, PaddingType.small) 
        : ResponsiveUtils.getPadding(context, PaddingType.medium);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Larger, more visible icon with background
              Container(
                width: ResponsiveUtils.getIconSize(context, IconSizeType.xLarge),
                height: ResponsiveUtils.getIconSize(context, IconSizeType.xLarge),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
              // Centered, prominent title
              Text(
                title,
                style: context.mediumTextWeight(FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
              // Subtitle with better contrast
              Text(
                subtitle,
                style: context.smallTextColor(Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
              // Visual indicator that this is an action
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: ResponsiveUtils.getIconSize(context, IconSizeType.tiny),
                    color: color.withOpacity(0.7),
                  ),
                  SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.tiny).left),
                  Text(
                    "Tap to access",
                    style: context.tinyText.copyWith(
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
          padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Profit & Loss Summary",
                    style: context.mediumTextWeight(FontWeight.bold),
                  ),
                  Icon(
                    Icons.analytics,
                    color: Colors.brown.shade300,
                    size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),

              // Modified profit display with better overflow handling
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Profit",
                          style: context.smallTextColor(Colors.grey),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            profitText,
                            style: context.xLargeTextWeight(FontWeight.bold).copyWith(
                              color: profit >= 0 ? Colors.green : Colors.red,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "ROI",
                          style: context.smallTextColor(Colors.grey),
                        ),
                        Text(
                          roiText,
                          style: context.xLargeTextWeight(FontWeight.bold).copyWith(
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
              SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),
              Center(
                child: Text(
                  "Tap to view detailed analytics →",
                  style: context.smallTextColor(Colors.grey),
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
      return Card(
        child: Padding(
          padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
          child: Center(
            child: Text(
              "No activity yet. Start by adding your first pallet!",
              style: context.mediumTextColor(Colors.grey),
              textAlign: TextAlign.center,
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
          margin: EdgeInsets.only(bottom: ResponsiveUtils.getPadding(context, PaddingType.small).bottom),
          child: ListTile(
            contentPadding: ResponsiveUtils.getPadding(context, PaddingType.small),
            leading: CircleAvatar(
              backgroundColor: Colors.brown.shade100,
              child: Icon(
                pallet.isClosed ? Icons.check_circle : Icons.inventory,
                color: Colors.brown,
                size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
              ),
            ),
            title: Text(
              pallet.name,
              style: context.mediumText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              "Tag: ${pallet.tag} • ${pallet.items.length} items (${pallet.soldItemsCount} sold)",
              style: context.smallText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              "\$${pallet.profit.toStringAsFixed(2)}",
              style: context.mediumTextWeight(FontWeight.bold).copyWith(
                color: pallet.profit >= 0 ? Colors.green : Colors.red,
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
  
  // New method for tablet grid layout of recent activity
  Widget _buildRecentActivityGrid(BuildContext context, PalletModel model) {
    if (model.pallets.isEmpty) {
      return Card(
        child: Padding(
          padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
          child: Center(
            child: Text(
              "No activity yet. Start by adding your first pallet!",
              style: context.mediumTextColor(Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Get 6 most recent pallets for tablets (more space)
    final recentPallets = [...model.pallets]
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayPallets = recentPallets.take(6).toList();
    
    // Create a grid with 2 items per row
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: ResponsiveUtils.getPadding(context, PaddingType.small).right,
        mainAxisSpacing: ResponsiveUtils.getPadding(context, PaddingType.small).bottom,
      ),
      itemCount: displayPallets.length,
      itemBuilder: (context, index) {
        final pallet = displayPallets[index];
        return Card(
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PalletDetailScreen(pallet: pallet),
              ),
            ),
            child: Padding(
              padding: ResponsiveUtils.getPadding(context, PaddingType.small),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.brown.shade100,
                        radius: 16,
                        child: Icon(
                          pallet.isClosed ? Icons.check_circle : Icons.inventory,
                          color: Colors.brown,
                          size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
                      Expanded(
                        child: Text(
                          pallet.name,
                          style: context.mediumTextWeight(FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "\$${pallet.profit.toStringAsFixed(2)}",
                        style: context.mediumTextWeight(FontWeight.bold).copyWith(
                          color: pallet.profit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: ResponsiveUtils.getPadding(context, PaddingType.medium).left),
                    child: Text(
                      "Tag: ${pallet.tag} • ${pallet.items.length} items (${pallet.soldItemsCount} sold)",
                      style: context.smallText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showAddPalletDialog(BuildContext context) {
    final palletModel = Provider.of<PalletModel>(context, listen: false);

    final int nextId =
        palletModel.getNextPalletId(); // Get ID without incrementing
    final nameController = TextEditingController(text: "Pallet $nextId");
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
        builder: (context) {
          // Directly access the model inside the builder for freshest data
          final tagsToShow =
              Provider.of<PalletModel>(context).savedTags.toList();

          return Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select a Tag",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),

                // Show tags or a message if empty
                tagsToShow.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text("No tags available"),
                      )
                    : Container(
                        height: 200, // Fixed height container
                        child: ListView.builder(
                          itemCount: tagsToShow.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Icon(Icons.label),
                              title: Text(tagsToShow[index]),
                              onTap: () {
                                tagController.text = tagsToShow[index];
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),

                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF02838A),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text("CLOSE", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
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

    // Show a dialog with keyboard awareness to handle different screen sizes and keyboard appearance
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Pallet",
            style: context.largeTextWeight(FontWeight.bold)),
        content: KeyboardAware(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Pallet Name",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.inventory_2_outlined,
                        size: ResponsiveUtils.getIconSize(
                            context, IconSizeType.medium),
                      ),
                      contentPadding: ResponsiveUtils.getPaddingHV(
                          context, PaddingType.small, PaddingType.small),
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
                    style: context.mediumText,
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getPadding(
                              context, PaddingType.medium)
                          .top),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: tagController,
                          decoration: InputDecoration(
                            labelText: "Tag",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.sell_outlined,
                              size: ResponsiveUtils.getIconSize(
                                  context, IconSizeType.medium),
                            ),
                            contentPadding: ResponsiveUtils.getPaddingHV(
                                context, PaddingType.small, PaddingType.small),
                          ),
                          readOnly: false, // Allow direct editing too
                          style: context.mediumText,
                        ),
                      ),
                      if (palletModel.savedTags.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.list,
                            size: ResponsiveUtils.getIconSize(
                                context, IconSizeType.medium),
                          ),
                          tooltip: "Select saved tag",
                          onPressed: showTagSelector,
                        ),
                    ],
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getPadding(
                              context, PaddingType.medium)
                          .top),
                  TextFormField(
                    controller: costController,
                    decoration: InputDecoration(
                      labelText: "Total Cost",
                      prefixIcon: Icon(
                        Icons.attach_money,
                        size: ResponsiveUtils.getIconSize(
                            context, IconSizeType.medium),
                      ),
                      border: OutlineInputBorder(),
                      contentPadding: ResponsiveUtils.getPaddingHV(
                          context, PaddingType.small, PaddingType.small),
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
                    style: context.mediumText,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Use fixed row layout for the actions instead of LayoutBuilder
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: context.mediumText),
            style: TextButton.styleFrom(
              minimumSize: Size(60, 36),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: submitForm,
            child: Text("ADD", style: context.mediumText),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(60, 36),
            ),
          ),
        ],
      ),
    );
  }
}
