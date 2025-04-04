import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kalakritiapp/models/cart_item.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/providers/cart_provider.dart';
import 'package:kalakritiapp/screens/order_confirmation_screen.dart';
import 'package:kalakritiapp/services/firestore_service.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Delivery address model
class DeliveryAddress {
  final String id;
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String phoneNumber;
  final bool isDefault;

  DeliveryAddress({
    required this.id,
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.phoneNumber,
    required this.isDefault,
  });
}

// Payment method model
class PaymentMethod {
  final String id;
  final String name;
  final String cardNumber;
  final String expiryDate;
  final String cardType;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.cardNumber,
    required this.expiryDate,
    required this.cardType,
    required this.isDefault,
  });
}

// Example data
final List<DeliveryAddress> dummyAddresses = [
  DeliveryAddress(
    id: '1',
    name: 'Home',
    addressLine1: '123 Main Street',
    addressLine2: 'Apartment 4B',
    city: 'Mumbai',
    state: 'Maharashtra',
    postalCode: '400001',
    phoneNumber: '+91 98765 43210',
    isDefault: true,
  ),
  DeliveryAddress(
    id: '2',
    name: 'Office',
    addressLine1: '456 Business Park',
    addressLine2: 'Tower 3, Floor 5',
    city: 'Mumbai',
    state: 'Maharashtra',
    postalCode: '400051',
    phoneNumber: '+91 98765 43210',
    isDefault: false,
  ),
];

final List<PaymentMethod> dummyPaymentMethods = [
  PaymentMethod(
    id: '1',
    name: 'RBL Bank Credit Card',
    cardNumber: '**** **** **** 4567',
    expiryDate: '12/25',
    cardType: 'visa',
    isDefault: true,
  ),
  PaymentMethod(
    id: '2',
    name: 'HDFC Bank Debit Card',
    cardNumber: '**** **** **** 8901',
    expiryDate: '09/24',
    cardType: 'mastercard',
    isDefault: false,
  ),
  PaymentMethod(
    id: '3',
    name: 'Cash on Delivery',
    cardNumber: '',
    expiryDate: '',
    cardType: 'cod',
    isDefault: false,
  ),
];

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItem>? items;
  
  const CheckoutScreen({
    super.key,
    this.items,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String selectedAddressId = '1'; // Default selected address
  String selectedPaymentMethodId = '1'; // Default selected payment method
  bool isLoading = false;
  String? promoCode;
  double discountAmount = 0.0;
  
  @override
  void initState() {
    super.initState();
    // Set default selections
    final defaultAddress = dummyAddresses.firstWhere(
      (address) => address.isDefault,
      orElse: () => dummyAddresses.first,
    );
    selectedAddressId = defaultAddress.id;
    
    final defaultPayment = dummyPaymentMethods.firstWhere(
      (payment) => payment.isDefault,
      orElse: () => dummyPaymentMethods.first,
    );
    selectedPaymentMethodId = defaultPayment.id;
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(context)
          : _buildCheckoutContent(context, cartItems),
    );
  }

  Widget _buildCheckoutContent(BuildContext context, List<CartItem> cartItems) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    
    // Calculate totals
    final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final shipping = 50.0;
    final tax = subtotal * 0.05;
    final total = subtotal + shipping + tax - discountAmount;
    
    return Stack(
      children: [
        // Main content
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery address section
              _buildSectionTitle('Delivery Address'),
              _buildAddressSelector(),
              const SizedBox(height: 24),
              
              // Payment method section
              _buildSectionTitle('Payment Method'),
              _buildPaymentSelector(),
              const SizedBox(height: 24),
              
              // Promo code section
              _buildSectionTitle('Promo Code'),
              _buildPromoCodeInput(),
              const SizedBox(height: 24),
              
              // Order summary section
              _buildSectionTitle('Order Summary'),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Items summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${cartItems.length} items'),
                          Text(formatter.format(subtotal)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Shipping
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shipping'),
                          Text(formatter.format(shipping)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Tax
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (5%)'),
                          Text(formatter.format(tax)),
                        ],
                      ),
                      
                      // Discount (if applicable)
                      if (discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Discount${promoCode != null ? ' ($promoCode)' : ''}',
                              style: TextStyle(color: kAccentColor),
                            ),
                            Text(
                              '-${formatter.format(discountAmount)}',
                              style: TextStyle(color: kAccentColor),
                            ),
                          ],
                        ),
                      ],
                      
                      const Divider(height: 24),
                      
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            formatter.format(total),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Space for the fixed bottom bar
              const SizedBox(height: 80),
            ],
          ),
        ),
        
        // Fixed bottom bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: CustomButton(
                text: 'Place Order (${formatter.format(total)})',
                onPressed: isLoading ? null : () => _placeOrder(context, cartItems, total),
                isLoading: isLoading,
                backgroundColor: kAccentColor,
                textColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildAddressSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Address list
          ...dummyAddresses.map((address) => _buildAddressItem(address)),
          
          // Add new address button
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to add address screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add new address functionality')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Address'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kSecondaryColor,
                side: BorderSide(color: kSecondaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressItem(DeliveryAddress address) {
    final isSelected = selectedAddressId == address.id;
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedAddressId = address.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: address.id,
              groupValue: selectedAddressId,
              onChanged: (value) {
                setState(() {
                  selectedAddressId = value!;
                });
              },
              activeColor: kSecondaryColor,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kSlateGray.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              color: kSlateGray,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address.addressLine1),
                  if (address.addressLine2.isNotEmpty) Text(address.addressLine2),
                  Text('${address.city}, ${address.state} ${address.postalCode}'),
                  const SizedBox(height: 4),
                  Text(
                    address.phoneNumber,
                    style: TextStyle(color: kTextColor.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () {
                // TODO: Navigate to edit address screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit address functionality')),
                );
              },
              color: kSecondaryColor,
              splashRadius: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Payment methods list
          ...dummyPaymentMethods.map((payment) => _buildPaymentMethodItem(payment)),
          
          // Add new payment method button
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to add payment method screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add new payment method functionality')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Payment Method'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kSecondaryColor,
                side: BorderSide(color: kSecondaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(PaymentMethod payment) {
    final isSelected = selectedPaymentMethodId == payment.id;
    
    // Card type icon
    IconData cardIcon;
    Color cardColor;
    
    switch (payment.cardType) {
      case 'visa':
        cardIcon = Icons.credit_card;
        cardColor = const Color(0xFF1A1F71);
        break;
      case 'mastercard':
        cardIcon = Icons.credit_card;
        cardColor = const Color(0xFFFF5F00);
        break;
      case 'cod':
        cardIcon = Icons.money;
        cardColor = const Color(0xFF4CAF50);
        break;
      default:
        cardIcon = Icons.credit_card;
        cardColor = Colors.grey;
    }
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedPaymentMethodId = payment.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: payment.id,
              groupValue: selectedPaymentMethodId,
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethodId = value!;
                });
              },
              activeColor: kSecondaryColor,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                cardIcon,
                color: cardColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        payment.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (payment.isDefault)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kSlateGray.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              color: kSlateGray,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (payment.cardNumber.isNotEmpty)
                    Text(
                      '${payment.cardNumber} - Expires ${payment.expiryDate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: kTextColor.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeInput() {
    final TextEditingController promoController = TextEditingController(text: promoCode);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: promoController,
                decoration: const InputDecoration(
                  hintText: 'Enter promo code',
                  border: InputBorder.none,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final code = promoController.text.trim();
                if (code.isEmpty) {
                  setState(() {
                    promoCode = null;
                    discountAmount = 0.0;
                  });
                  return;
                }
                
                // Apply promo code
                if (code.toUpperCase() == 'WELCOME10') {
                  setState(() {
                    promoCode = code.toUpperCase();
                    // 10% discount
                    final cartItems = ref.read(cartProvider);
                    final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
                    discountAmount = subtotal * 0.1;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Promo code applied! You saved ₹${discountAmount.toStringAsFixed(2)}'),
                        backgroundColor: kSecondaryColor,
                      ),
                    );
                  });
                } else {
                  setState(() {
                    promoCode = null;
                    discountAmount = 0.0;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Invalid promo code'),
                      backgroundColor: kAccentColor,
                    ),
                  );
                }
              },
              child: Text(
                promoCode != null ? 'Change' : 'Apply',
                style: TextStyle(
                  color: kSecondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, List<CartItem> cartItems, double total) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to place an order')),
      );
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final firestoreService = ref.read(cartFirestoreServiceProvider);
      
      // Get the selected address
      final selectedAddress = dummyAddresses.firstWhere(
        (address) => address.id == selectedAddressId,
      );
      
      // Get the selected payment method
      final selectedPayment = dummyPaymentMethods.firstWhere(
        (payment) => payment.id == selectedPaymentMethodId,
      );
      
      // Get user info for the order
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final customerName = userData['name'] ?? user.displayName ?? 'Customer';
      final customerEmail = userData['email'] ?? user.email ?? '';
      
      // Prepare items and collect seller IDs
      final orderItems = _prepareOrderItems(cartItems);
      
      // Extract all unique seller IDs from items
      final sellerIds = cartItems
          .map((item) => item.sellerId)
          .where((id) => id != null)
          .toSet()
          .toList();
      
      // Generate order number
      final orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';
      
      // Prepare order data
      final Map<String, dynamic> orderData = {
        'orderNumber': orderNumber,
        'userId': user.uid,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'items': orderItems,
        'shippingAddress': {
          'name': selectedAddress.name,
          'addressLine1': selectedAddress.addressLine1,
          'addressLine2': selectedAddress.addressLine2,
          'city': selectedAddress.city,
          'state': selectedAddress.state,
          'postalCode': selectedAddress.postalCode,
          'phoneNumber': selectedAddress.phoneNumber,
        },
        'paymentMethod': selectedPayment.cardType,
        'subtotal': total - 50.0 - (total * 0.05) + discountAmount, // Reverse calculate subtotal
        'shippingCost': 50.0,
        'tax': total * 0.05,
        'total': total,
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'sellerIds': sellerIds, // Add seller IDs to order data
        'isPaid': false, // For now, assume not paid
      };
      
      // Create the order
      final orderRef = await firestoreService.createOrder(orderData);
      
      // Clear the cart
      await ref.read(cartProvider.notifier).clearCart();
      
      setState(() {
        isLoading = false;
      });
      
      // Navigate to order confirmation
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderId: orderRef.id,
              orderTotal: total,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _prepareOrderItems(List<CartItem> cartItems) {
    final List<Map<String, dynamic>> items = [];
    // Create a set to collect unique seller IDs
    final Set<String> sellerIds = {};
    
    for (var item in cartItems) {
      // Ensure we have a seller ID
      final sellerId = item.sellerId ?? 'unknown';
      // Add to the set of seller IDs
      sellerIds.add(sellerId);
      
      final Map<String, dynamic> itemData = {
        'productId': item.productId,
        'name': item.productName,
        'price': item.price,
        'quantity': item.quantity,
        'imageUrl': item.imageUrl,
        'isRental': item.isRental,
        'totalPrice': item.totalPrice,
        'sellerId': sellerId, // Include seller ID in order item
      };
      
      if (item.isRental && item.rentalStartDate != null && item.rentalEndDate != null) {
        itemData['rentalStartDate'] = item.rentalStartDate;
        itemData['rentalEndDate'] = item.rentalEndDate;
        itemData['rentalDays'] = item.rentalEndDate!.difference(item.rentalStartDate!).inDays + 1;
      }
      
      items.add(itemData);
    }
    
    return items;
  }

  Widget _buildEmptyCart(BuildContext context) {
    // Implement the logic to display an empty cart message
    return Center(child: Text('No items in the cart'));
  }
} 