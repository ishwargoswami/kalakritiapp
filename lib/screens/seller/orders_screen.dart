import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kalakritiapp/models/order.dart';
import 'package:kalakritiapp/providers/seller_service_provider.dart';
import 'package:kalakritiapp/utils/firebase_constants.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerAllOrdersProvider);
    
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Orders'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'All Orders'),
              Tab(text: 'Pending'),
              Tab(text: 'Processing'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return _buildEmptyState();
            }
            
            // Filter orders for each tab
            final List<Order> allOrders = orders.map((order) => Order.fromMap(order)).toList();
            final List<Order> pendingOrders = allOrders
                .where((order) => order.status == FirebaseConstants.orderStatusPending)
                .toList();
            final List<Order> processingOrders = allOrders
                .where((order) => order.status == FirebaseConstants.orderStatusProcessing)
                .toList();
            final List<Order> completedOrders = allOrders
                .where((order) => 
                    order.status == FirebaseConstants.orderStatusDelivered || 
                    order.status == FirebaseConstants.orderStatusShipped)
                .toList();
            
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(allOrders),
                _buildOrdersList(pendingOrders),
                _buildOrdersList(processingOrders),
                _buildOrdersList(completedOrders),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Error loading orders: $error'),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When customers purchase your products,\ntheir orders will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrdersList(List<Order> orders) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }
  
  Widget _buildOrderCard(Order order) {
    final orderDate = order.orderDate != null
        ? DateFormat('MMM dd, yyyy').format(order.orderDate!)
        : 'Unknown date';
        
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    orderDate,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getStatusColor(order.status).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  _getStatusText(order.status),
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Items preview (limited to 2)
              ...order.items.take(2).map((item) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '₹${item.price} × ${item.quantity}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${(item.price * item.quantity).toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Show message if there are more items
              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '+ ${order.items.length - 2} more items',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              
              const Divider(),
              
              // Total amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${order.total.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              
              // Action buttons based on status
              if (order.status == FirebaseConstants.orderStatusPending || 
                  order.status == FirebaseConstants.orderStatusProcessing) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order.status == FirebaseConstants.orderStatusPending)
                      OutlinedButton(
                        onPressed: () => _updateOrderStatus(
                          order, 
                          FirebaseConstants.orderStatusProcessing,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                        child: const Text('Accept'),
                      ),
                    const SizedBox(width: 8),
                    if (order.status == FirebaseConstants.orderStatusProcessing)
                      OutlinedButton(
                        onPressed: () => _showShippingDialog(order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                        child: const Text('Ship Order'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Order date
                  if (order.orderDate != null)
                    Text(
                      'Placed on ${DateFormat('MMMM d, yyyy').format(order.orderDate!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Status with detailed tracking
                  _buildOrderTracking(order),
                  const SizedBox(height: 24),
                  
                  // Items
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // All order items
                  ...order.items.map((item) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (item.size != null)
                                  Text(
                                    'Size: ${item.size}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${item.price} × ${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${(item.price * item.quantity).toInt()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                  
                  const Divider(),
                  
                  // Price breakdown
                  _buildPriceDetail('Subtotal', order.subtotal),
                  _buildPriceDetail('Shipping', order.shippingCost),
                  _buildPriceDetail('Tax', order.tax),
                  const SizedBox(height: 8),
                  _buildPriceDetail('Total', order.total, isTotal: true),
                  const SizedBox(height: 24),
                  
                  // Customer info
                  const Text(
                    'Customer Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(order.customerName),
                    subtitle: Text(order.customerEmail),
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Shipping address
                  const Text(
                    'Shipping Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Card(
                    elevation: 0,
                    color: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.shippingAddress.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(order.shippingAddress.addressLine1),
                          if (order.shippingAddress.addressLine2 != null && 
                              order.shippingAddress.addressLine2!.isNotEmpty)
                            Text(order.shippingAddress.addressLine2!),
                          Text(
                            '${order.shippingAddress.city}, ${order.shippingAddress.state} ${order.shippingAddress.postalCode}',
                          ),
                          Text(order.shippingAddress.country),
                          const SizedBox(height: 4),
                          Text(
                            'Phone: ${order.shippingAddress.phoneNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  if (order.status == FirebaseConstants.orderStatusPending || 
                      order.status == FirebaseConstants.orderStatusProcessing) ...[
                    Row(
                      children: [
                        if (order.status == FirebaseConstants.orderStatusPending)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateOrderStatus(
                                order, 
                                FirebaseConstants.orderStatusProcessing,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Accept Order'),
                            ),
                          ),
                        
                        if (order.status == FirebaseConstants.orderStatusProcessing) ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showShippingDialog(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Ship Order'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildOrderTracking(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getStatusText(order.status),
            style: TextStyle(
              color: _getStatusColor(order.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Tracking info if available
        if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracking Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Carrier: ${order.shippingCarrier ?? "Unknown"}',
                ),
                Text(
                  'Tracking #: ${order.trackingNumber}',
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildPriceDetail(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '₹${amount.toInt()}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showShippingDialog(Order order) {
    final TextEditingController trackingController = TextEditingController();
    final TextEditingController carrierController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ship Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: carrierController,
              decoration: const InputDecoration(
                labelText: 'Shipping Carrier',
                hintText: 'e.g., BlueDart, DTDC',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(
                labelText: 'Tracking Number',
                hintText: 'Enter tracking number',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(
                order, 
                FirebaseConstants.orderStatusShipped,
                trackingNumber: trackingController.text.trim(),
                shippingCarrier: carrierController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Shipping'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateOrderStatus(
    Order order, 
    String newStatus, {
    String? trackingNumber,
    String? shippingCarrier,
  }) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ref.read(sellerServiceProvider).updateOrderStatus(
        orderId: order.id,
        status: newStatus,
        trackingNumber: trackingNumber,
        shippingCarrier: shippingCarrier,
      );
      
      // Refresh orders
      ref.refresh(sellerAllOrdersProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.orderNumber} updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.split('_').map((s) => s.substring(0, 1).toUpperCase() + s.substring(1)).join(' ');
    }
  }
} 