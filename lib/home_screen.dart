// File: lib/home_screen.dart - Updated to use AppTheme
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Import with prefix to avoid ambiguity
import 'inventory_screen.dart' as inventory;
import 'analytics_screen.dart';
import 'pallet_model.dart';
import 'pallet_detail_screen.dart';
import 'responsive_utils.dart';
import 'utils/dialog_utils.dart';
// Import app theme
import 'theme/theme_extensions.dart'; // Import theme extensions
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Check if we should use tablet layout
    final isTablet = context.isTablet;

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
                            context.primaryDarkColor, // Using theme extension
                            context.primaryColor, // Using theme extension
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
                        context, PaddingType.medium, PaddingType.small),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Quick Actions",
                          style: context.largeTextWeight(FontWeight.bold),
                        ),
                        SizedBox(
                            height: ResponsiveUtils.getPadding(
                                    context, PaddingType.small)
                                .top),
                        // Restructured to ensure equal height and proper scaling for medium font sizes
                        _buildQuickActionCards(context),
                      ],
                    ),
                  ),
                ),

                // Analytics Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        ResponsiveUtils.getPadding(context, PaddingType.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Business Insights",
                          style: context.largeTextWeight(FontWeight.bold),
                        ),
                        SizedBox(
                            height: ResponsiveUtils.getPadding(
                                    context, PaddingType.medium)
                                .top),
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
                    padding:
                        ResponsiveUtils.getPadding(context, PaddingType.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recent Activity",
                          style: context.largeTextWeight(FontWeight.bold),
                        ),
                        SizedBox(
                            height: ResponsiveUtils.getPadding(
                                    context, PaddingType.medium)
                                .top),
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
                  child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16),
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
    final isTablet = context.isTablet;

    return Container(
      padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
      margin: ResponsiveUtils.getPaddingHV(
          context, PaddingType.medium, PaddingType.medium),
      decoration: context.standardBoxDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context: context,
            label: "Total Profit",
            value: "\$${profit.toStringAsFixed(2)}",
            color: profit >= 0 ? context.successColor : context.errorColor,
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
            color: context.infoColor,
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
            color: context.warningColor,
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
        Icon(icon,
            color: color,
            size: ResponsiveUtils.getIconSize(context, IconSizeType.medium)),
        SizedBox(
            height: ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: fontSize == FontSizeType.small
                ? context
                    .smallTextWeight(FontWeight.bold)
                    .copyWith(color: color)
                : (fontSize == FontSizeType.medium
                    ? context
                        .mediumTextWeight(FontWeight.bold)
                        .copyWith(color: color)
                    : context
                        .largeTextWeight(FontWeight.bold)
                        .copyWith(color: color)),
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
      final deviceWidth = constraints.maxWidth;
      final isVeryNarrow = deviceWidth < 300;
      final isWide = deviceWidth > 600; // For tablet layouts

      // For very narrow screens, stack cards vertically
      if (isVeryNarrow) {
        return Column(
          children: [
            _buildActionCard(
              context,
              icon: Icons.inventory_2_outlined,
              title: "Manage Inventory",
              subtitle: "Browse and track items",
              color: context.infoColor,
              maxWidth: constraints.maxWidth,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const inventory.InventoryScreen(),
                ),
              ),
            ),
            SizedBox(
                height:
                    ResponsiveUtils.getPadding(context, PaddingType.small).top),
            _buildActionCard(
              context,
              icon: Icons.add_box_rounded,
              title: "Add Pallet",
              subtitle: "Create new inventory",
              color: context.successColor,
              maxWidth: constraints.maxWidth,
              onTap: () => showAddPalletDialog(context),
            ),
            SizedBox(
                height:
                    ResponsiveUtils.getPadding(context, PaddingType.small).top),
            _buildActionCard(
              context,
              icon: Icons.add_shopping_cart,
              title: "Add Item",
              subtitle: "Quick item creation",
              color: context.accentColor,
              maxWidth: constraints.maxWidth,
              onTap: () => _showQuickAddItemDialog(context),
            ),
          ],
        );
      }

      // Two-row layout for phone screens (not very narrow and not tablet)
      if (!isWide && !isVeryNarrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // First row with two cards
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.inventory_2_outlined,
                    title: "Manage Inventory",
                    subtitle: "Browse and track items",
                    color: context.infoColor,
                    maxWidth: (deviceWidth -
                            ResponsiveUtils.getPadding(
                                    context, PaddingType.small)
                                .left) /
                        2,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const inventory.InventoryScreen(),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                    width:
                        ResponsiveUtils.getPadding(context, PaddingType.small)
                            .left),
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.add_box_rounded,
                    title: "Add Pallet",
                    subtitle: "Create new inventory",
                    color: context.successColor,
                    maxWidth: (deviceWidth -
                            ResponsiveUtils.getPadding(
                                    context, PaddingType.small)
                                .left) /
                        2,
                    onTap: () => showAddPalletDialog(context),
                  ),
                ),
              ],
            ),
            SizedBox(
                height:
                    ResponsiveUtils.getPadding(context, PaddingType.small).top),
            // Second row with centered card, but not full width
            Center(
              child: SizedBox(
                width: deviceWidth * 0.65, // 65% of width for the third card
                child: _buildActionCard(
                  context,
                  icon: Icons.add_shopping_cart,
                  title: "Add Item",
                  subtitle: "Quick item creation",
                  color: context.accentColor,
                  maxWidth: deviceWidth * 0.65,
                  onTap: () => _showQuickAddItemDialog(context),
                ),
              ),
            ),
          ],
        );
      }

      // For wide screens (tablets), use original row layout
      return Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              icon: Icons.inventory_2_outlined,
              title: "Manage Inventory",
              subtitle: "Browse and track items",
              color: context.infoColor,
              maxWidth: constraints.maxWidth / 3 - 8,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const inventory.InventoryScreen(),
                ),
              ),
            ),
          ),
          SizedBox(
              width:
                  ResponsiveUtils.getPadding(context, PaddingType.small).left),
          Expanded(
            child: _buildActionCard(
              context,
              icon: Icons.add_box_rounded,
              title: "Add Pallet",
              subtitle: "Create new inventory",
              color: context.successColor,
              maxWidth: constraints.maxWidth / 3 - 8,
              onTap: () => showAddPalletDialog(context),
            ),
          ),
          SizedBox(
              width:
                  ResponsiveUtils.getPadding(context, PaddingType.small).left),
          Expanded(
            child: _buildActionCard(
              context,
              icon: Icons.add_shopping_cart,
              title: "Add Item",
              subtitle: "Quick item creation",
              color: context.accentColor,
              maxWidth: constraints.maxWidth / 3 - 8,
              onTap: () => _showQuickAddItemDialog(context),
            ),
          ),
        ],
      );
    });
  }

  void _showQuickAddItemDialog(BuildContext context) {
    final palletModel = Provider.of<PalletModel>(context, listen: false);

    // If there are no pallets, show a message and offer to create one
    if (palletModel.pallets.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("No Pallets Available",
              style: context.largeTextWeight(FontWeight.bold)),
          content: Text("You need to create a pallet before you can add items.",
              style: context.mediumText),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: context.mediumText),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showAddPalletDialog(context);
              },
              child: Text("ADD PALLET", style: context.mediumText),
            ),
          ],
        ),
      );
      return;
    }

    // If there are only closed pallets, show a message
    final openPallets = palletModel.pallets.where((p) => !p.isClosed).toList();
    if (openPallets.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("No Open Pallets",
              style: context.largeTextWeight(FontWeight.bold)),
          content: Text(
              "All your pallets are closed. Open a pallet before adding items.",
              style: context.mediumText),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: context.mediumText),
            ),
          ],
        ),
      );
      return;
    }

    // Otherwise, continue with the dialog
    final TextEditingController itemNameController = TextEditingController();
    Pallet selectedPallet = openPallets.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Quick Add Item",
                  style: context.largeTextWeight(FontWeight.bold)),
              content: KeyboardAware(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name input
                    Text("Item Name",
                        style: context.smallTextWeight(FontWeight.bold)),
                    SizedBox(height: 6),
                    TextFormField(
                      controller: itemNameController,
                      decoration: InputDecoration(
                        hintText: "Enter item name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      style: context.mediumText,
                      textCapitalization: TextCapitalization.words,
                      autofocus: true,
                    ),

                    SizedBox(height: 16),

                    // Pallet selection
                    Text("Select Pallet",
                        style: context.smallTextWeight(FontWeight.bold)),
                    SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Pallet>(
                          isExpanded: true,
                          value: selectedPallet,
                          icon: Icon(Icons.arrow_drop_down),
                          elevation: 16,
                          style: context.mediumText.copyWith(
                              color: Colors.black87), // Fixed text color
                          onChanged: (Pallet? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedPallet = newValue;
                              });
                            }
                          },
                          items: openPallets
                              .map<DropdownMenuItem<Pallet>>((Pallet pallet) {
                            return DropdownMenuItem<Pallet>(
                              value: pallet,
                              child: Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      color:
                                          context.primaryColor), // Better icon
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      pallet.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.mediumText.copyWith(
                                          color: Colors
                                              .black87), // Fixed text color
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("CANCEL", style: context.mediumText),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor),
                  onPressed: () {
                    if (itemNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please enter an item name")));
                      return;
                    }

                    // Add the item to the selected pallet
                    final PalletItem newItem = palletModel.addItemToPallet(
                        selectedPallet.id, itemNameController.text.trim());

                    // Close dialog
                    Navigator.pop(dialogContext);

                    // Navigate to the item detail screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailScreen(
                          pallet: selectedPallet,
                          item: newItem,
                        ),
                      ),
                    );
                  },
                  child: Text("ADD", style: context.mediumText),
                ),
              ],
            );
          },
        );
      },
    );
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
      shape: context.largeRoundedShape,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.largeBorderRadius,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Larger, more visible icon with background
              Container(
                width:
                    ResponsiveUtils.getIconSize(context, IconSizeType.xLarge),
                height:
                    ResponsiveUtils.getIconSize(context, IconSizeType.xLarge),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: ResponsiveUtils.getIconSize(
                        context, IconSizeType.medium),
                  ),
                ),
              ),
              SizedBox(
                  height: ResponsiveUtils.getPadding(context, PaddingType.small)
                      .top),
              // Centered, prominent title
              Text(
                title,
                style: context.mediumTextWeight(FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                  height: ResponsiveUtils.getPadding(context, PaddingType.tiny)
                      .top),
              // Subtitle with better contrast
              Text(
                subtitle,
                style: context.smallTextColor(Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                  height: ResponsiveUtils.getPadding(context, PaddingType.small)
                      .top),
              // Visual indicator that this is an action
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size:
                        ResponsiveUtils.getIconSize(context, IconSizeType.tiny),
                    color: color.withOpacity(0.7),
                  ),
                  SizedBox(
                      width:
                          ResponsiveUtils.getPadding(context, PaddingType.tiny)
                              .left),
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
      shape: context.largeRoundedShape,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.largeBorderRadius,
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
                    size: ResponsiveUtils.getIconSize(
                        context, IconSizeType.medium),
                  ),
                ],
              ),
              SizedBox(
                  height:
                      ResponsiveUtils.getPadding(context, PaddingType.medium)
                          .top),

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
                            style: context
                                .xLargeTextWeight(FontWeight.bold)
                                .copyWith(
                                  color: profit >= 0
                                      ? context.successColor
                                      : context.errorColor,
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
                          style: context
                              .xLargeTextWeight(FontWeight.bold)
                              .copyWith(
                                color: roi >= 0
                                    ? context.successColor
                                    : context.errorColor,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                  height:
                      ResponsiveUtils.getPadding(context, PaddingType.medium)
                          .top),
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
          margin: EdgeInsets.only(
              bottom: ResponsiveUtils.getPadding(context, PaddingType.small)
                  .bottom),
          child: ListTile(
            contentPadding:
                ResponsiveUtils.getPadding(context, PaddingType.small),
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
                    color: pallet.profit >= 0
                        ? context.successColor
                        : context.errorColor,
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
        crossAxisSpacing:
            ResponsiveUtils.getPadding(context, PaddingType.small).right,
        mainAxisSpacing:
            ResponsiveUtils.getPadding(context, PaddingType.small).bottom,
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
                          pallet.isClosed
                              ? Icons.check_circle
                              : Icons.inventory,
                          color: Colors.brown,
                          size: ResponsiveUtils.getIconSize(
                              context, IconSizeType.small),
                        ),
                      ),
                      SizedBox(
                          width: ResponsiveUtils.getPadding(
                                  context, PaddingType.small)
                              .left),
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
                        style:
                            context.mediumTextWeight(FontWeight.bold).copyWith(
                                  color: pallet.profit >= 0
                                      ? context.successColor
                                      : context.errorColor,
                                ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: ResponsiveUtils.getPadding(
                                context, PaddingType.medium)
                            .left),
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
    DialogUtils.showAddPalletDialog(context);
  }
}
