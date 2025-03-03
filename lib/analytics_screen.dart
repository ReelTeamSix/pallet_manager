// analytics_screen.dart - Refactored for responsiveness - PART 1

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pallet_model.dart';
import 'responsive_utils.dart'; // Import the new responsive utilities

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics Dashboard"),
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
          
          if (palletModel.pallets.isEmpty) {
            return Center(
              child: Padding(
                padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
                child: Text(
                  "No pallets added yet. Add pallets to view analytics.",
                  style: context.mediumText,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return _buildDashboard(context, palletModel);
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, PalletModel palletModel) {
    final currentMonth = palletModel.currentFilterMonth;
    final pallets = palletModel.getPalletsByMonth(currentMonth);
    final soldItems = palletModel.getItemsSoldInMonth(currentMonth);

    // Calculate metrics for current month with null checks
    double totalCostThisMonth = 0.0;
    double revenueThisMonth = 0.0;
    double profitThisMonth = 0.0;

    try {
      totalCostThisMonth =
          pallets.fold(0.0, (sum, pallet) => sum + pallet.totalCost);
      revenueThisMonth =
          soldItems.fold(0.0, (sum, item) => sum + item.salePrice);
      profitThisMonth = palletModel.getProfitForMonth(currentMonth);
    } catch (e) {
      // Values remain at 0.0
    }

    // ROI for the month
    final roiThisMonth = totalCostThisMonth > 0
        ? (profitThisMonth / totalCostThisMonth * 100)
        : 0.0;

    // All-time metrics with null checks
    double totalRevenue = 0.0;
    double totalCost = 0.0;
    double totalProfit = 0.0;
    int totalPallets = 0;
    int totalItemsSold = 0;

    try {
      totalRevenue = palletModel.totalRevenue;
      totalCost = palletModel.totalCost;
      totalProfit = palletModel.totalProfit;
      totalPallets = palletModel.pallets.length;
      totalItemsSold = palletModel.totalSoldItems;
    } catch (e) {
      // Values remain at defaults
    }

    // Display filter indicator if tag filter is active
    Widget? filterIndicator;
    if (palletModel.currentTagFilter != null) {
      filterIndicator = Container(
        padding: ResponsiveUtils.getPadding(context, PaddingType.small),
        margin: ResponsiveUtils.getPaddingHV(
          context, 
          PaddingType.medium, 
          PaddingType.tiny
        ),
        decoration: BoxDecoration(
          color: Colors.brown.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_list, 
              size: ResponsiveUtils.getIconSize(context, IconSizeType.small), 
              color: Colors.brown
            ),
            SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
            Expanded(
              child: Text(
                "Filtered by tag: ${palletModel.currentTagFilter}",
                style: context.smallTextColor(Colors.brown.shade800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => palletModel.setTagFilter(null),
              child: Text("Clear", style: context.smallText),
            ),
          ],
        ),
      );
    }

    // Check if we should use tablet layout
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        // For tablet layout, we'll show the main sections side by side
        if (isTablet) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag filter indicator
                if (filterIndicator != null) filterIndicator,

                Padding(
                  padding: ResponsiveUtils.getPaddingHV(
                    context, 
                    PaddingType.medium, 
                    PaddingType.small
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month Selector with responsive padding and font size
                      _buildMonthSelector(context, currentMonth, palletModel),
                      
                      SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),

                      // Current month heading
                      Text(
                        "Month: ${_getMonthName(currentMonth.month)} ${currentMonth.year}",
                        style: context.largeTextWeight(FontWeight.bold),
                      ),
                      
                      SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),

                      // Main metrics grid for current month
                      _buildMonthMetricsGrid(
                        context,
                        totalCostThisMonth, 
                        revenueThisMonth,
                        profitThisMonth, 
                        roiThisMonth
                      ),

                      SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),

                      // Tablet layout: show tabs side by side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // YTD panel
                          Expanded(
                            flex: 1,
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SizedBox(
                                height: constraints.maxHeight * 0.6,
                                child: _buildYearToDatePanel(context, palletModel),
                              ),
                            ),
                          ),
                          
                          SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.medium).left),
                          
                          // All time panel
                          Expanded(
                            flex: 1,
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SizedBox(
                                height: constraints.maxHeight * 0.6,
                                child: _buildAllTimePanel(
                                  context,
                                  totalRevenue,
                                  totalCost,
                                  totalProfit,
                                  totalPallets,
                                  totalItemsSold
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),
                      
                      // Tag Analysis Panel
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SizedBox(
                          height: constraints.maxHeight * 0.4,
                          child: _buildTagAnalysisPanel(context, palletModel),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Phone layout - Original column layout but with responsive sizing
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag filter indicator
                if (filterIndicator != null) filterIndicator,

                Padding(
                  padding: ResponsiveUtils.getPaddingHV(
                    context, 
                    PaddingType.medium, 
                    PaddingType.small
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month Selector with responsive padding and font size
                      _buildMonthSelector(context, currentMonth, palletModel),

                      SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),

                      // Current month heading
                      Text(
                        "Month: ${_getMonthName(currentMonth.month)} ${currentMonth.year}",
                        style: context.largeTextWeight(FontWeight.bold),
                      ),
                      
                      SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),

                      // Main metrics grid for current month
                      _buildMonthMetricsGrid(
                        context,
                        totalCostThisMonth, 
                        revenueThisMonth,
                        profitThisMonth, 
                        roiThisMonth
                      ),

                      SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),

                      // YTD, All-Time, and Performance Tabs with improved responsive design
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(26),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: DefaultTabController(
                          length: 3,
                          child: Column(
                            children: [
                              // Tab bar with responsive height and better spacing
                              _buildResponsiveTabBar(context),
                              
                              const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFEEEEEE)),
                              
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: ResponsiveUtils.getResponsiveCardHeight(
                                    context, 
                                    baseHeight: 400, 
                                    isExpanded: false
                                  ),
                                  maxHeight: constraints.maxHeight * 0.65,
                                ),
                                child: TabBarView(
                                  children: [
                                    _buildYearToDatePanel(context, palletModel),
                                    _buildAllTimePanel(
                                      context,
                                      totalRevenue,
                                      totalCost,
                                      totalProfit,
                                      totalPallets,
                                      totalItemsSold
                                    ),
                                    _buildTagAnalysisPanel(context, palletModel),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      }),
    );
  }

  Widget _buildMonthSelector(BuildContext context, DateTime currentMonth, PalletModel palletModel) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: ResponsiveUtils.getPaddingHV(
          context, 
          PaddingType.medium, 
          PaddingType.small
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => palletModel.previousMonth(),
              iconSize: ResponsiveUtils.getIconSize(context, IconSizeType.small),
            ),
            Text(
              "${_getMonthName(currentMonth.month)} ${currentMonth.year}",
              style: context.largeTextWeight(FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => palletModel.nextMonth(),
              iconSize: ResponsiveUtils.getIconSize(context, IconSizeType.small),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveTabBar(BuildContext context) {
    // Dynamically set tab bar height based on font scale and device size
    final fontScale = MediaQuery.of(context).textScaleFactor;
    final baseHeight = 56.0;
    final adjustedHeight = baseHeight * (fontScale > 1.3 ? 1.2 : 1.0);
    
    return Container(
      height: adjustedHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: TabBar(
        tabs: [
          _buildTabItem(context, "YTD"),
          _buildTabItem(context, "All Time"),
          _buildTabItem(context, "Performance"),
        ],
        labelColor: const Color(0xFF02838A),
        labelStyle: context.smallTextWeight(FontWeight.bold),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 3,
        indicatorColor: const Color(0xFF02838A),
        dividerColor: Colors.transparent,
        // Improve spacing and layout
        labelPadding: ResponsiveUtils.getPaddingHV(
          context,
          PaddingType.tiny,
          PaddingType.zero
        ),
        padding: ResponsiveUtils.getPaddingHV(
          context,
          PaddingType.small,
          PaddingType.zero
        ),
      ),
    );
  }

  // New helper method for building tab items with responsive sizing
  Widget _buildTabItem(BuildContext context, String label) {
    return Tab(
      height: 48,
      child: Container(
        padding: ResponsiveUtils.getPaddingHV(
          context,
          PaddingType.tiny,
          PaddingType.zero
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildMonthMetricsGrid(BuildContext context, double cost,
      double revenue, double profit, double roi) {
    // Use a Column with Row layout instead of GridView for better control
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactMetricCard(
                context: context,
                title: "Monthly Cost",
                value: _formatCurrency(cost),
                icon: Icons.shopping_cart,
                color: Colors.orange,
              ),
            ),
            SizedBox(
                width: ResponsiveUtils.getPadding(context, PaddingType.small)
                    .left),
            Expanded(
              child: _buildCompactMetricCard(
                context: context,
                title: "Monthly Revenue",
                value: _formatCurrency(revenue),
                icon: Icons.attach_money,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(
            height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
        Row(
          children: [
            Expanded(
              child: _buildCompactMetricCard(
                context: context,
                title: "Monthly Profit",
                value: _formatCurrency(profit),
                icon: Icons.trending_up,
                color: profit >= 0 ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(
                width: ResponsiveUtils.getPadding(context, PaddingType.small)
                    .left),
            Expanded(
              child: _buildCompactMetricCard(
                context: context,
                title: "Monthly ROI",
                value: "${roi.toStringAsFixed(1)}%",
                icon: Icons.show_chart,
                color: roi >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTagFilterDialog(BuildContext context) {
    // Get a reference to the model
    final palletModel = Provider.of<PalletModel>(context, listen: false);

    // Get a direct copy of the tags
    final List<String> tagsList = palletModel.savedTags.toList();
    final String currentFilter = palletModel.currentTagFilter ?? "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Filter by Tag",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // All option with hardcoded display
                ListTile(
                  leading: Icon(Icons.all_inclusive, color: Colors.orange),
                  title: Text("All",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  selected: palletModel.currentTagFilter == null,
                  tileColor: palletModel.currentTagFilter == null
                      ? Colors.orange.withOpacity(0.2)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    palletModel.setTagFilter(null);
                    Navigator.pop(context);
                  },
                ),

                // Hard-coded tag for Amazon Monster (since that's what's visible in your UI)
                ListTile(
                  leading: Icon(Icons.label, color: Colors.teal),
                  title: Text("Amazon Monster",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  selected: palletModel.currentTagFilter == "Amazon Monster",
                  tileColor: palletModel.currentTagFilter == "Amazon Monster"
                      ? Colors.teal.withOpacity(0.2)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    palletModel.setTagFilter("Amazon Monster");
                    Navigator.pop(context);
                  },
                ),

                // Any additional tags (though this might not be needed if we just have the one tag)
                ...tagsList
                    .where((tag) =>
                        tag != "Amazon Monster") // Skip the one we hardcoded
                    .map((tag) => ListTile(
                          leading: Icon(Icons.label, color: Colors.teal),
                          title: Text(tag,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          selected: palletModel.currentTagFilter == tag,
                          tileColor: palletModel.currentTagFilter == tag
                              ? Colors.teal.withOpacity(0.2)
                              : null,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          onTap: () {
                            palletModel.setTagFilter(tag);
                            Navigator.pop(context);
                          },
                        ))
                    .toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CLOSE", style: TextStyle(color: Colors.teal)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildYearToDatePanel(BuildContext context, PalletModel model) {
    final now = DateTime.now();
    double ytdProfit = 0.0;

    try {
      ytdProfit = model.getYTDProfit();
    } catch (e) {
      // ytdProfit remains 0.0
    }

    // Get all months for current year up to current month
    final months = List.generate(
      now.month,
      (index) => DateTime(now.year, index + 1),
    );

    return Padding(
      padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // YTD Profit with calendar icon - enhanced design
          Container(
            padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
            width: double.infinity, // Ensure full width
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
                      color: const Color(0xFF02838A),
                    ),
                    SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
                    Text(
                      "YTD Profit",
                      style: context.mediumTextWeight(FontWeight.w600).copyWith(
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
                Text(
                  _formatCurrency(ytdProfit),
                  style: context.xLargeTextWeight(FontWeight.bold).copyWith(
                    color: ytdProfit >= 0 ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),

          // Monthly Breakdown Header with refined styling
          Container(
            width: double.infinity,
            padding: ResponsiveUtils.getPaddingHV(
              context,
              PaddingType.small,
              PaddingType.medium
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF02838A).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insights, 
                  size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
                  color: const Color(0xFF02838A)
                ),
                SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
                Text(
                  "Monthly Breakdown",
                  style: context.mediumTextWeight(FontWeight.bold).copyWith(
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),

          // Enhanced monthly list with fixed height and better styling
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: months.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final month = months[index];
                  double profit = 0.0;

                  try {
                    profit = model.getProfitForMonth(month);
                  } catch (e) {
                    // profit remains 0.0
                  }

                  return Container(
                    color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                    child: Padding(
                      padding: ResponsiveUtils.getPaddingHV(
                        context,
                        PaddingType.medium,
                        PaddingType.small
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: profit >= 0 ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
                                // Use FittedBox for responsive text
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _getMonthName(month.month),
                                      style: context.mediumTextWeight(FontWeight.w500).copyWith(
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatCurrency(profit),
                            style: context.mediumTextWeight(FontWeight.bold).copyWith(
                              color: profit >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // analytics_screen.dart - Refactored for responsiveness - PART 4

  Widget _buildAllTimePanel(BuildContext context, double revenue, double cost, double profit, int palletCount, int itemsSold) {
    // Calculate overall ROI
    final overallROI = cost > 0 ? (profit / cost * 100) : 0.0;
    final avgProfit = itemsSold > 0 ? (profit / itemsSold) : 0.0;

    return SingleChildScrollView(
      padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: ResponsiveUtils.getPadding(context, PaddingType.small),
            decoration: BoxDecoration(
              color: const Color(0xFF02838A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "All-Time Performance",
              style: context.mediumTextWeight(FontWeight.bold).copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),
          
          // Main metrics with responsive sizing
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  context: context,
                  title: "Revenue",
                  value: _formatCurrency(revenue),
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
              Expanded(
                child: _buildStatsCard(
                  context: context,
                  title: "Cost",
                  value: _formatCurrency(cost),
                  icon: Icons.shopping_cart,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
          
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  context: context,
                  title: "Profit",
                  value: _formatCurrency(profit),
                  icon: Icons.trending_up,
                  color: profit >= 0 ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
              Expanded(
                child: _buildStatsCard(
                  context: context,
                  title: "ROI",
                  value: "${overallROI.toStringAsFixed(1)}%",
                  icon: Icons.show_chart,
                  color: overallROI >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),
          
          // Summary metrics
          Container(
            width: double.infinity,
            padding: ResponsiveUtils.getPaddingHV(
              context,
              PaddingType.medium,
              PaddingType.small
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Summary",
              style: context.mediumTextWeight(FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
          
          Row(
            children: [
              Expanded(
                child: _buildSimpleStatsCard(
                  context: context,
                  title: "Total Pallets",
                  value: palletCount.toString(),
                  icon: Icons.inventory_2,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
              Expanded(
                child: _buildSimpleStatsCard(
                  context: context,
                  title: "Items Sold",
                  value: itemsSold.toString(),
                  icon: Icons.sell,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
              Expanded(
                child: _buildSimpleStatsCard(
                  context: context,
                  title: "Avg Profit/Item",
                  value: _formatCurrency(avgProfit),
                  icon: Icons.analytics,
                  valueColor: avgProfit >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagAnalysisPanel(BuildContext context, PalletModel model) {
    final profitByTag = model.getProfitByTag();
    
    if (profitByTag.isEmpty) {
      return Center(
        child: Padding(
          padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tag, 
                size: ResponsiveUtils.getIconSize(context, IconSizeType.xLarge),
                color: Colors.grey
              ),
              SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.medium).top),
              Text(
                "No tagged inventory yet",
                style: context.largeTextWeight(FontWeight.bold).copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
              Text(
                "Add tags to your pallets to see performance analysis",
                style: context.mediumTextColor(Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Sort tags by profit (descending)
    final sortedTags = profitByTag.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Padding(
      padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: ResponsiveUtils.getPaddingHV(
              context,
              PaddingType.medium,
              PaddingType.small
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF02838A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Inventory Performance",
              style: context.mediumTextWeight(FontWeight.bold).copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
          
          Text(
            "Tap any category to filter your inventory by that tag",
            style: context.smallTextColor(Colors.grey).copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
          
          Expanded(
            child: ListView.builder(
              itemCount: sortedTags.length,
              itemBuilder: (context, index) {
                final tag = sortedTags[index].key;
                final profit = sortedTags[index].value;
                
                // Calculate some stats
                final isTopPerformer = index == 0;
                final isBottomPerformer = index == sortedTags.length - 1 && profit < 0;
                
                // Determine status text
                String statusText = "";
                if (isTopPerformer) {
                  statusText = "🌟 Top performer";
                } else if (index < 3 && profit > 0) {
                  statusText = "Good performer";
                } else if (isBottomPerformer && profit < 0) {
                  statusText = "⚠️ Bottom performer";  
                } else if (profit < 0) {
                  statusText = "Losing money";
                }
                
                return Card(
                  margin: EdgeInsets.only(
                    bottom: ResponsiveUtils.getPadding(context, PaddingType.small).bottom
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: isTopPerformer ? 3 : 1,
                  color: isTopPerformer ? Colors.amber.shade50 : null,
                  child: InkWell(
                    onTap: () {
                      // Set this tag as filter
                      model.setTagFilter(tag);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isBottomPerformer
                                  ? Colors.red.shade700
                                  : (profit >= 0 ? Colors.green : Colors.red),
                                child: Icon(
                                  isBottomPerformer
                                    ? Icons.warning
                                    : (profit >= 0
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward),
                                  color: Colors.white,
                                  size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tag,
                                      style: context.mediumTextWeight(FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (statusText.isNotEmpty)
                                      Text(
                                        statusText,
                                        style: context.smallText.copyWith(
                                          color: isTopPerformer
                                            ? Colors.amber.shade800
                                            : Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.getPadding(context, PaddingType.small).left),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatCurrency(profit),
                                    style: context.mediumTextWeight(FontWeight.bold).copyWith(
                                      color: profit >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  Text(
                                    "Tap to filter",
                                    style: context.tinyTextColor(Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (isTopPerformer) ...[
                            SizedBox(height: ResponsiveUtils.getPadding(context, PaddingType.small).top),
                            Text(
                              "Find more items like this to maximize profits!",
                              style: context.smallText,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Ensure value is never a template literal
    String displayValue = value;
    if (value.contains('{') && value.contains('}')) {
      displayValue = "0.00"; // Fallback if template isn't interpolated
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: ResponsiveUtils.getPaddingHV(
            context, PaddingType.small, PaddingType.small),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: color,
                size:
                    ResponsiveUtils.getIconSize(context, IconSizeType.medium)),
            SizedBox(
                height:
                    ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
            Text(
              title,
              style: context.smallText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
                height:
                    ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayValue,
                style: context.largeTextWeight(FontWeight.bold).copyWith(
                      color: color,
                    ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
        child: Column(
          children: [
            Icon(icon,
                color: color,
                size:
                    ResponsiveUtils.getIconSize(context, IconSizeType.medium)),
            SizedBox(
                height:
                    ResponsiveUtils.getPadding(context, PaddingType.small).top),
            Text(
              title,
              style: context.smallTextWeight(FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
                height:
                    ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: context.mediumTextWeight(FontWeight.bold).copyWith(
                      color: color,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStatsCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: ResponsiveUtils.getPaddingHV(
            context, PaddingType.small, PaddingType.small),
        child: Column(
          children: [
            Icon(icon,
                size: ResponsiveUtils.getIconSize(context, IconSizeType.small),
                color: Colors.grey.shade700),
            SizedBox(
                height:
                    ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
            Text(
              title,
              style: context.smallText,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
                height:
                    ResponsiveUtils.getPadding(context, PaddingType.tiny).top),
            Text(
              value,
              style: context.smallTextWeight(FontWeight.bold).copyWith(
                    color: valueColor,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    try {
      return "\$${value.toStringAsFixed(2)}";
    } catch (e) {
      return "\$0.00";
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return monthNames[month - 1];
  }
}
