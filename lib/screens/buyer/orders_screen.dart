import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/order.dart';
import 'package:kalakritiapp/screens/buyer/order_details_screen.dart';
import 'package:kalakritiapp/services/firestore_service.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _isLoading = true;
  List<DocumentSnapshot> _orders = [];
  String? _errorMessage;
  String? _indexUrl;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final firestoreService = FirestoreService();
      final ordersSnapshot = await firestoreService.getUserOrders(userId);
      
      setState(() {
        _orders = ordersSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('failed-precondition') && 
            e.toString().contains('requires an index')) {
          // Extract the URL from the error message if possible
          final urlRegex = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
          final match = urlRegex.firstMatch(e.toString());
          final indexUrl = match?.group(0);
          
          _errorMessage = 'Database setup required';
          _indexUrl = indexUrl;
        } else {
          _errorMessage = 'Failed to load orders: $e';
        }
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'shipped':
      case 'shipping':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : _orders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrdersList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Start shopping to see your orders here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextColor.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Continue Shopping'),
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    if (_errorMessage == 'Database setup required' && _indexUrl != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'Database Index Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'The app needs a database index to be set up in Firebase. Please press the button below to create it.',
                style: TextStyle(
                  color: kTextColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Create Database Index'),
                onPressed: () async {
                  // Use url_launcher to open the Firebase console
                  final url = Uri.parse(_indexUrl!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    // Fallback to showing dialog with the URL if launching fails
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Create Database Index'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Please copy this URL and open it in a browser:'),
                              SizedBox(height: 8),
                              SelectableText(_indexUrl!),
                              SizedBox(height: 16),
                              Text('After creating the index, come back and refresh this page.'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          _errorMessage ?? 'An error occurred',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final orderData = _orders[index].data() as Map<String, dynamic>;
        final orderId = _orders[index].id;
        final orderNumber = orderData['orderNumber'] ?? orderId.substring(0, 8);
        final orderDate = orderData['orderDate'] as Timestamp?;
        final formattedDate = orderDate != null
            ? DateFormat('MMM dd, yyyy').format(orderDate.toDate())
            : 'N/A';
        final status = orderData['status'] ?? 'Pending';
        final total = orderData['total'] ?? 0.0;
        final formattedTotal = NumberFormat.currency(
                locale: 'en_IN', symbol: '₹', decimalDigits: 2)
            .format(total);
        
        // Get first item image for display
        String? imageUrl;
        if (orderData['items'] != null && (orderData['items'] as List).isNotEmpty) {
          imageUrl = (orderData['items'] as List).first['imageUrl'];
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(orderId: orderId),
                ),
              ).then((_) => _fetchOrders()); // Refresh on return
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #$orderNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formattedTotal,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shopping_bag, color: Colors.grey),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Placed on $formattedDate',
                              style: TextStyle(
                                color: kTextColor.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(status),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right,
                                  color: kTextColor.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

extension StringExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
} 