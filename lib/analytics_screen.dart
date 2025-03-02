// analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pallet_model.dart';

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
          ),
        ],
      ),
      body: Consumer<PalletModel>(
        builder: (context, palletModel, child) {
          if (palletModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (palletModel.pallets.isEmpty) {
            return const Center(
              child: Text(
                "No pallets added yet. Add pallets to view analytics.",
                style: TextStyle(fontSize: 16),
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
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.brown.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 16, color: Colors.brown),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Filtered by tag: ${palletModel.currentTagFilter}",
                style: TextStyle(color: Colors.brown.shade800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => palletModel.setTagFilter(null),
              child: const Text("Clear"),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag filter indicator
              if (filterIndicator != null) filterIndicator,

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Selector
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: () => palletModel.previousMonth(),
                            ),
                            Text(
                              "${_getMonthName(currentMonth.month)} ${currentMonth.year}",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              onPressed: () => palletModel.nextMonth(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Current month heading
                    Text(
                      "Month: ${_getMonthName(currentMonth.month)} ${currentMonth.year}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Main metrics grid for current month
                    _buildMonthMetricsGrid(totalCostThisMonth, revenueThisMonth,
                        profitThisMonth, roiThisMonth),

                    const SizedBox(height: 20),

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
                            // Improved tab bar styling with fixed height and better spacing
                            Container(
                              height: 56, // Fixed height for consistency
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: TabBar(
                                tabs: [
                                  _buildTabItem("YTD"),
                                  _buildTabItem("All Time"),
                                  _buildTabItem("Performance"),
                                ],
                                labelColor: const Color(0xFF02838A),
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                unselectedLabelColor: Colors.grey.shade600,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorWeight: 3,
                                indicatorColor: const Color(0xFF02838A),
                                dividerColor: Colors.transparent,
                                // Improve spacing and layout
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                            const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFEEEEEE)),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: 400,
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
                                      totalItemsSold),
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
      }),
    );
  }

  // New helper method for building tab items
  Widget _buildTabItem(String label) {
    return Tab(
      height: 48,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildMonthMetricsGrid(double cost, double revenue, double profit, double roi) {
    // Use a Column with Row layout instead of GridView for better control
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactMetricCard(
                title: "Monthly Cost",
                value: _formatCurrency(cost),
                icon: Icons.shopping_cart,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactMetricCard(
                title: "Monthly Revenue",
                value: _formatCurrency(revenue),
                icon: Icons.attach_money,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactMetricCard(
                title: "Monthly Profit",
                value: _formatCurrency(profit),
                icon: Icons.trending_up,
                color: profit >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactMetricCard(
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
    final palletModel = Provider.of<PalletModel>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter by Tag"),
          content: SizedBox(
            width: double.maxFinite,
            child: palletModel.savedTags.isEmpty
                ? const Text("No tags saved yet.")
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Add "All" option
                      FilterChip(
                        label: const Text("All"),
                        selected: palletModel.currentTagFilter == null,
                        onSelected: (_) {
                          palletModel.setTagFilter(null);
                          Navigator.pop(context);
                        },
                      ),
                      // Add chips for each tag
                      ...palletModel.savedTags.map((tag) => FilterChip(
                        label: Text(tag),
                        selected: palletModel.currentTagFilter == tag,
                        onSelected: (_) {
                          palletModel.setTagFilter(tag);
                          Navigator.pop(context);
                        },
                      )),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
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
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // YTD Profit with calendar icon - enhanced design
          Container(
            padding: const EdgeInsets.all(16),
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
                      size: 20,
                      color: const Color(0xFF02838A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "YTD Profit",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatCurrency(ytdProfit),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ytdProfit >= 0 ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Monthly Breakdown Header with refined styling
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF02838A).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.insights, size: 18, color: const Color(0xFF02838A)),
                const SizedBox(width: 8),
                Text(
                  "Monthly Breakdown",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                                    color:
                                        profit >= 0 ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Use FittedBox for responsive text
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _getMonthName(month.month),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
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
                            style: TextStyle(
                              color: profit >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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

  Widget _buildAllTimePanel(BuildContext context, double revenue, double cost, double profit, int palletCount, int itemsSold) {
    // Calculate overall ROI
    final overallROI = cost > 0 ? (profit / cost * 100) : 0.0;
    final avgProfit = itemsSold > 0 ? (profit / itemsSold) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF02838A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "All-Time Performance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Main metrics
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  title: "Revenue",
                  value: _formatCurrency(revenue),
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatsCard(
                  title: "Cost",
                  value: _formatCurrency(cost),
                  icon: Icons.shopping_cart,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  title: "Profit",
                  value: _formatCurrency(profit),
                  icon: Icons.trending_up,
                  color: profit >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatsCard(
                  title: "ROI",
                  value: "${overallROI.toStringAsFixed(1)}%",
                  icon: Icons.show_chart,
                  color: overallROI >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Summary metrics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Summary",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildSimpleStatsCard(
                  title: "Total Pallets",
                  value: palletCount.toString(),
                  icon: Icons.inventory_2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleStatsCard(
                  title: "Items Sold",
                  value: itemsSold.toString(),
                  icon: Icons.sell,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleStatsCard(
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tag, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No tagged inventory yet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "Add tags to your pallets to see performance analysis",
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF02838A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Inventory Performance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            "Tap any category to filter your inventory by that tag",
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
          
          const SizedBox(height: 12),
          
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
                  margin: const EdgeInsets.only(bottom: 8),
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
                      padding: const EdgeInsets.all(12.0),
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
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tag,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (statusText.isNotEmpty)
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 12,
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
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatCurrency(profit),
                                    style: TextStyle(
                                      color: profit >= 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Text(
                                    "Tap to filter",
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (isTopPerformer) ...[
                            const SizedBox(height: 8),
                            const Text(
                              "Find more items like this to maximize profits!",
                              style: TextStyle(fontSize: 12),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
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
