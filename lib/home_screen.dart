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
              color: context.infoColor,
              maxWidth: constraints.maxWidth / 2 - 8,
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
