import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kalakritiapp/constants.dart';
import 'package:kalakritiapp/models/cart_item.dart';
import 'package:kalakritiapp/widgets/custom_appbar.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? orderData;
  List<Map<String, dynamic>> orderItems = [];
  String orderStatus = 'Processing';
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!orderDoc.exists) {
        setState(() {
          errorMessage = 'Order not found';
          isLoading = false;
        });
        return;
      }

      final data = orderDoc.data() as Map<String, dynamic>;
      
      // Convert Firestore items to list of map
      final List<Map<String, dynamic>> items = [];
      if (data['items'] != null) {
        for (var item in data['items']) {
          items.add(item is Map<String, dynamic> ? item : item as Map<String, dynamic>);
        }
      }

      setState(() {
        orderData = data;
        orderItems = items;
        orderStatus = data['status'] ?? 'Processing';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load order details: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Order Details'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : _buildOrderContent(),
    );
  }

  Widget _buildOrderContent() {
    if (orderData == null) {
      return const Center(child: Text('Order data not available'));
    }

    final orderDate = orderData!['orderDate'] as Timestamp?;
    final formattedDate = orderDate != null
        ? DateFormat('MMM dd, yyyy | hh:mm a').format(orderDate.toDate())
        : 'Date not available';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(formattedDate),
          const SizedBox(height: 24),
          _buildOrderStatus(),
          const SizedBox(height: 24),
          _buildOrderItems(),
          const SizedBox(height: 24),
          _buildShippingAddress(),
          const SizedBox(height: 24),
          _buildPaymentSummary(),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(String date) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${widget.orderId.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formattedCurrency.format(orderData!['totalAmount'] ?? 0),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date,
              style: TextStyle(
                color: kTextColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatus() {
    Color statusColor;
    
    switch (orderStatus.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'shipping':
        statusColor = Colors.blue;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.local_shipping, color: kSecondaryColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    orderStatus.toCapitalized(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (orderItems.isEmpty)
              const Center(child: Text('No items in this order'))
            else
              ...orderItems.map((item) => _buildOrderItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final isRental = item['isRental'] ?? false;
    final rentalStartDate = item['rentalStartDate'] is Timestamp
        ? (item['rentalStartDate'] as Timestamp).toDate()
        : null;
    final rentalEndDate = item['rentalEndDate'] is Timestamp
        ? (item['rentalEndDate'] as Timestamp).toDate()
        : null;
    
    String rentalInfo = '';
    if (isRental && rentalStartDate != null && rentalEndDate != null) {
      final start = DateFormat('MMM dd, yyyy').format(rentalStartDate);
      final end = DateFormat('MMM dd, yyyy').format(rentalEndDate);
      final days = rentalEndDate.difference(rentalStartDate).inDays + 1;
      rentalInfo = '$days days (${start} - ${end})';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(item['imageUrl'] ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Product Name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Make price and quantity info wrap properly
                Wrap(
                  children: [
                    Text(
                      '${formattedCurrency.format(item['price'] ?? 0)} × ${item['quantity'] ?? 1}',
                      style: TextStyle(
                        color: kTextColor.withOpacity(0.7),
                      ),
                    ),
                    if (isRental)
                      Text(
                        ' • $rentalInfo',
                        style: TextStyle(
                          color: kSecondaryColor.withOpacity(0.8),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formattedCurrency.format(item['totalPrice'] ?? 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddress() {
    final address = orderData!['shippingAddress'] as Map<String, dynamic>?;
    if (address == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              address['name'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(address['addressLine1'] ?? ''),
            if (address['addressLine2'] != null && address['addressLine2'].toString().isNotEmpty)
              Text(address['addressLine2']),
            Text(
              '${address['city']}, ${address['state']} ${address['postalCode']}',
            ),
            const SizedBox(height: 4),
            Text('Phone: ${address['phoneNumber']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final total = orderData!['totalAmount'] ?? 0;
    // For simplicity, assuming flat shipping rate and tax percentage
    final shipping = 50.0;
    final tax = total * 0.05;
    final subtotal = total - shipping - tax;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentRow('Subtotal', subtotal),
            _buildPaymentRow('Shipping', shipping),
            _buildPaymentRow('Tax', tax),
            const Divider(height: 24),
            _buildPaymentRow('Total', total, isBold: true),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payment, size: 16, color: kTextColor),
                const SizedBox(width: 8),
                Text(
                  'Payment Method: ${_getPaymentMethodName(orderData!['paymentMethod'])}',
                  style: TextStyle(
                    color: kTextColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? kTextColor : kTextColor.withOpacity(0.7),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            formattedCurrency.format(amount),
            style: TextStyle(
              color: isBold ? kSecondaryColor : kTextColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String? methodId) {
    switch (methodId) {
      case 'upi':
        return 'UPI';
      case 'bank':
        return 'Bank Transfer';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return methodId ?? 'Unknown';
    }
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

// Formatter for currency
final formattedCurrency = NumberFormat.currency(
  symbol: '₹',
  decimalDigits: 2,
  locale: 'en_IN',
); 