import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kalakritiapp/models/seller_product.dart';
import 'package:kalakritiapp/providers/seller_provider.dart';
import 'package:kalakritiapp/providers/seller_service_provider.dart';
import 'package:kalakritiapp/screens/seller/add_product_screen.dart';
import 'package:kalakritiapp/screens/seller/edit_product_screen.dart';
import 'package:kalakritiapp/screens/seller/orders_screen.dart';
import 'package:kalakritiapp/screens/chats_list_screen.dart';
import 'package:kalakritiapp/services/seller_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kalakritiapp/utils/sample_data_util.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/rendering.dart';
import 'package:kalakritiapp/providers/chat_provider.dart';

// Advanced providers for seller analytics
final sellerRevenueAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final sellerService = ref.watch(sellerServiceProvider);
  return await sellerService.getRevenueAnalytics();
});

final sellerMonthlyRevenueProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final sellerService = ref.watch(sellerServiceProvider);
  return await sellerService.getMonthlyRevenue();
});

final sellerTopProductsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final sellerService = ref.watch(sellerServiceProvider);
  return await sellerService.getTopProducts();
});

final sellerRecentActivitiesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final sellerService = ref.watch(sellerServiceProvider);
  return sellerService.getRecentActivities();
});

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Using asyncValue.when() for each data stream to properly handle loading/error states
    final sellerProductsAsync = ref.watch(sellerProductsProvider);
    final sellerStatsAsync = ref.watch(sellerStatsProvider);
    final revenueAnalyticsAsync = ref.watch(sellerRevenueAnalyticsProvider);
    final monthlyRevenueAsync = ref.watch(sellerMonthlyRevenueProvider);
    final topProductsAsync = ref.watch(sellerTopProductsProvider);
    final recentActivitiesAsync = ref.watch(sellerRecentActivitiesProvider);
    
    // Explicitly allow screenshots in seller dashboard
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.data_array),
            onPressed: () => _showAddSampleDataDialog(context),
            tooltip: 'Add Sample Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // When refreshing, we invalidate all providers to fetch fresh data
          ref.refresh(sellerProductsProvider);
          ref.refresh(sellerStatsProvider);
          ref.refresh(sellerRevenueAnalyticsProvider);
          ref.refresh(sellerMonthlyRevenueProvider);
          ref.refresh(sellerTopProductsProvider);
          ref.refresh(sellerRecentActivitiesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatisticsSection(context, sellerStatsAsync),
                const SizedBox(height: 24),
                
                // Revenue Analytics Chart
                _buildRevenueAnalytics(context, revenueAnalyticsAsync, monthlyRevenueAsync),
                const SizedBox(height: 24),
                
                // Recent Activities Feed
                _buildRecentActivities(context, recentActivitiesAsync),
                const SizedBox(height: 24),
                
                // Top Products Section
                _buildTopProducts(context, topProductsAsync),
                const SizedBox(height: 24),
                
                // Products Management Section
                _buildProductsSection(context, sellerProductsAsync, ref),
                
                // Add extra padding at the bottom to prevent FAB overlap
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Product',
      ),
    );
  }

  void _showAddSampleDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sample Data'),
        content: const Text('Do you want to add sample products and categories to help you get started?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Adding sample data...')),
              );
              
              try {
                await SampleDataUtil.addSampleCategories();
                await SampleDataUtil.addSellerProducts();
                
                // Create a sample order to show in seller dashboard
                await SampleDataUtil.createSampleOrder();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sample data added successfully! Pull down to refresh.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding sample data: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        final totalProducts = stats['totalProducts'] ?? 0;
        final totalOrders = stats['totalOrders'] ?? 0;
        final totalRevenue = stats['totalRevenue'] ?? 0.0;
        final pendingOrders = stats['pendingOrders'] ?? 0;
        final totalCustomers = stats['totalCustomers'] ?? 0;
        final averageRating = stats['averageRating'] ?? 0.0;
        
        final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
        
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Stats grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      context,
                      title: 'Products',
                      value: totalProducts.toString(),
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Orders',
                      value: totalOrders.toString(),
                      icon: Icons.shopping_bag,
                      color: Colors.green,
                      subtitle: '$pendingOrders pending',
                    ),
                    _buildStatCard(
                      context,
                      title: 'Revenue',
                      value: currencyFormatter.format(totalRevenue),
                      icon: Icons.payments,
                      color: Colors.purple,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Customers',
                      value: totalCustomers.toString(),
                      icon: Icons.people,
                      color: Colors.amber,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Avg. Order',
                      value: totalOrders > 0 
                          ? currencyFormatter.format(totalRevenue / totalOrders)
                          : '₹0',
                      icon: Icons.analytics,
                      color: Colors.orange,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Rating',
                      value: averageRating.toStringAsFixed(1),
                      icon: Icons.star,
                      color: Colors.amber,
                      subtitle: 'Average Product Rating',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to Seller Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your dashboard is being prepared',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    // Increase the vertical padding to accommodate potential overflow
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      // Further increase the height to fully resolve the overflow
      height: subtitle != null ? 95 : 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            // Wrap in a flexible widget to handle overflow gracefully
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevenueAnalytics(
    BuildContext context, 
    AsyncValue<Map<String, dynamic>> revenueAnalyticsAsync,
    AsyncValue<List<Map<String, dynamic>>> monthlyRevenueAsync,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Revenue Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            monthlyRevenueAsync.when(
              data: (monthlyData) {
                if (monthlyData.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text('No revenue data available'),
                    ),
                  );
                }
                
                return Container(
                  height: 250,
                  padding: const EdgeInsets.only(top: 16, right: 16),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: monthlyData.map((item) => item['amount'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    monthlyData[value.toInt()]['month'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  '₹${value.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      barGroups: List.generate(
                        monthlyData.length,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: monthlyData[index]['amount'],
                              color: Theme.of(context).colorScheme.primary,
                              width: 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => SizedBox(
                height: 200,
                child: Center(
                  child: Text('Error loading revenue data: $error'),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            revenueAnalyticsAsync.when(
              data: (analytics) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAnalyticItem(
                      title: 'This Week',
                      value: '₹${analytics['thisWeekRevenue']?.toInt() ?? 0}',
                      percentChange: analytics['weeklyGrowth'] ?? 0.0,
                    ),
                    _buildAnalyticItem(
                      title: 'This Month',
                      value: '₹${analytics['thisMonthRevenue']?.toInt() ?? 0}',
                      percentChange: analytics['monthlyGrowth'] ?? 0.0,
                    ),
                    _buildAnalyticItem(
                      title: 'Growth Rate',
                      value: '${analytics['growthRate']?.toStringAsFixed(1) ?? 0}%',
                      isGrowthRate: true,
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalyticItem({
    required String title,
    required String value,
    double percentChange = 0.0,
    bool isGrowthRate = false,
  }) {
    final isPositive = percentChange >= 0;
    
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!isGrowthRate) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Colors.green : Colors.red,
                size: 12,
              ),
              Text(
                '${percentChange.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRecentActivities(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> activitiesAsync,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activities',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            activitiesAsync.when(
              data: (activities) {
                if (activities.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No recent activities'),
                    ),
                  );
                }
                
                return SizedBox(
                  height: 240,
                  child: ListView.builder(
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      final timestamp = activity['timestamp'] as DateTime;
                      
                      return ListTile(
                        leading: _getActivityIcon(activity['type']),
                        title: Text(activity['title'] ?? 'Activity'),
                        subtitle: Text(activity['description'] ?? ''),
                        trailing: Text(
                          timeago.format(timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error loading activities: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _getActivityIcon(String type) {
    switch (type) {
      case 'order':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          radius: 16,
          child: Icon(Icons.shopping_bag, color: Colors.white, size: 16),
        );
      case 'product':
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          radius: 16,
          child: Icon(Icons.inventory_2, color: Colors.white, size: 16),
        );
      case 'review':
        return const CircleAvatar(
          backgroundColor: Colors.amber,
          radius: 16,
          child: Icon(Icons.star, color: Colors.white, size: 16),
        );
      case 'payment':
        return const CircleAvatar(
          backgroundColor: Colors.purple,
          radius: 16,
          child: Icon(Icons.payment, color: Colors.white, size: 16),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          radius: 16,
          child: Icon(Icons.notifications, color: Colors.white, size: 16),
        );
    }
  }

  Widget _buildTopProducts(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> topProductsAsync,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performing Products',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            topProductsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No product data available'),
                    ),
                  );
                }
                
                return Column(
                  children: products.map((product) {
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: product['imageUrl'] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                      title: Text(
                        product['name'] ?? 'Unknown Product',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${product['sales'] ?? 0} sales · ₹${product['revenue']?.toInt() ?? 0}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            '${product['rating']?.toStringAsFixed(1) ?? '0.0'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error loading top products: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(
    BuildContext context,
    AsyncValue<List<SellerProduct>> productsAsync,
    WidgetRef ref,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Products',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddProductScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 72,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first product to start selling',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddProductScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      elevation: 0,
                      color: Colors.grey[100],
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrls.isNotEmpty
                                    ? product.imageUrls.first
                                    : '',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Price: ₹${product.price.toInt()}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'In Stock: ${product.quantity}',
                                    style: TextStyle(
                                      color: product.quantity > 0
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: product.isApproved
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          product.isApproved
                                              ? 'Approved'
                                              : 'Pending Approval',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: product.isApproved
                                                ? Colors.green[700]
                                                : Colors.orange[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (product.isFeatured)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Featured',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.purple[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Action buttons
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: Colors.blue,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProductScreen(
                                          productId: product.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(context, product, ref);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error loading products: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    SellerProduct product,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final sellerService = ref.read(sellerServiceProvider);
                await sellerService.deleteProduct(product.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting product: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 