import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kalakritiapp/models/cart_item.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/providers/cart_provider.dart';
import 'package:kalakritiapp/screens/buyer/address_screen.dart';
import 'package:kalakritiapp/screens/buyer/order_success_screen.dart';
import 'package:kalakritiapp/services/firestore_service.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final IconData? icon;
  final String description;
  final String cardNumber;
  final String expiryDate;
  final String cardType;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.name,
    this.icon,
    this.description = '',
    this.cardNumber = '',
    this.expiryDate = '',
    this.cardType = '',
    this.isDefault = false,
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
  String? selectedAddressId; // Default selected address
  String selectedPaymentMethodId = '1'; // Default selected payment method
  bool isLoading = false;
  String? promoCode;
  double discountAmount = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // Payment method will be set based on seller preferences later
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
    final userAsync = ref.watch(userDataProvider);
    
    return userAsync.when(
      data: (userData) {
        if (userData == null) {
          return const Center(
            child: Text('Please log in to checkout'),
          );
        }
        
        final addresses = userData.shippingAddresses;
        
        if (addresses.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'No addresses found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressScreen(),
                        ),
                      ).then((_) {
                        setState(() {
                          // Refresh
                        });
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Address'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kSecondaryColor,
                      side: BorderSide(color: kSecondaryColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // If no address is selected yet, select the default or first one
        if (selectedAddressId == null) {
          // Find default address
          final defaultAddressIndex = addresses.indexWhere((addr) => addr['isDefault'] == true);
          if (defaultAddressIndex >= 0) {
            selectedAddressId = defaultAddressIndex.toString();
          } else if (addresses.isNotEmpty) {
            selectedAddressId = '0'; // Select first address if no default
          }
        }
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Address list
              for (int i = 0; i < addresses.length; i++)
                _buildUserAddressItem(addresses[i], i.toString()),
              
              // Add new address button
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddressScreen(),
                      ),
                    ).then((_) {
                      setState(() {
                        // Refresh and update selected address
                      });
                    });
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading addresses: $error'),
      ),
    );
  }
  
  Widget _buildUserAddressItem(Map<String, dynamic> address, String id) {
    final isSelected = selectedAddressId == id;
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedAddressId = id;
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
              value: id,
              groupValue: selectedAddressId,
              onChanged: (value) {
                setState(() {
                  selectedAddressId = value;
                });
              },
              activeColor: kSecondaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address['name'] ?? 'Address',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (address['isDefault'] == true)
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
                  Text(
                    '${address['addressLine1']}\n'
                    '${address['addressLine2'] ?? ''}\n'
                    '${address['city']}, ${address['state']} ${address['postalCode']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: kTextColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${address['phoneNumber']}',
                    style: TextStyle(
                      fontSize: 14,
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

  Widget _buildPaymentSelector() {
    // We need to get the seller associated with the cart items
    final cartItems = ref.watch(cartProvider);
    
    if (cartItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // For now we'll use the seller of the first item - in the future this could be modified
    // to handle multiple sellers with separate checkout flows
    final productId = cartItems.first.productId;
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (productSnapshot.hasError) {
          return Center(child: Text('Error: ${productSnapshot.error}'));
        }
        
        if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
          return const Center(child: Text('Product not found'));
        }
        
        // Get the seller ID from the product
        final productData = productSnapshot.data!.data() as Map<String, dynamic>;
        final sellerId = productData['sellerId'] as String;
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(sellerId).get(),
          builder: (context, sellerSnapshot) {
            if (sellerSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (sellerSnapshot.hasError) {
              return Center(child: Text('Error: ${sellerSnapshot.error}'));
            }
            
            if (!sellerSnapshot.hasData || !sellerSnapshot.data!.exists) {
              return const Center(child: Text('Seller information not found'));
            }
            
            final sellerData = sellerSnapshot.data!.data() as Map<String, dynamic>;
            
            // Check which payment methods the seller has enabled
            final hasUpi = sellerData['upiId'] != null && (sellerData['upiId'] as String).isNotEmpty;
            final hasBankAccount = sellerData['bankAccountNumber'] != null && 
                                (sellerData['bankAccountNumber'] as String).isNotEmpty;
            
            // Create a list of available payment methods
            final availablePaymentMethods = <PaymentMethod>[];
            
            if (hasUpi) {
              availablePaymentMethods.add(PaymentMethod(
                id: 'upi',
                name: 'UPI',
                icon: Icons.account_balance_wallet,
                description: 'Pay using UPI ID: ${sellerData['upiId']}',
              ));
            }
            
            if (hasBankAccount) {
              availablePaymentMethods.add(PaymentMethod(
                id: 'bank',
                name: 'Bank Transfer',
                icon: Icons.account_balance,
                description: 'Pay to account: ${sellerData['bankAccountNumber']} (${sellerData['bankName']})',
              ));
            }
            
            // Also add COD as a default option
            availablePaymentMethods.add(PaymentMethod(
              id: 'cod',
              name: 'Cash on Delivery',
              icon: Icons.money,
              description: 'Pay when you receive the item',
            ));
            
            // Set the first payment method as default if not already set
            if (selectedPaymentMethodId == null && availablePaymentMethods.isNotEmpty) {
              selectedPaymentMethodId = availablePaymentMethods.first.id;
            }
            
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.payment, color: kSecondaryColor),
                        const SizedBox(width: 16),
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...availablePaymentMethods.map((method) => _buildPaymentMethodItem(method)),
                ],
              ),
            );
          },
        );
      },
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
    try {
      setState(() {
        isLoading = true;
      });
      
      // Check if address is selected
      if (selectedAddressId == null) {
        _showErrorSnackbar('Please select a delivery address');
        return;
      }
      
      // Check if payment method is selected
      if (selectedPaymentMethodId == null) {
        _showErrorSnackbar('Please select a payment method');
        return;
      }
      
      if (cartItems.isEmpty) {
        _showErrorSnackbar('Your cart is empty');
        return;
      }
      
      // Get the current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackbar('You must be logged in to place an order');
        return;
      }
      
      // Get the user data to access the selected address
      final userSnapshot = await ref.read(userDataProvider.future);
      if (userSnapshot == null) {
        _showErrorSnackbar('User data not available');
        return;
      }
      
      // Get the selected address
      final addresses = userSnapshot.shippingAddresses;
      final selectedAddressIndex = int.parse(selectedAddressId!);
      if (selectedAddressIndex >= addresses.length) {
        _showErrorSnackbar('Selected address not found');
        return;
      }
      
      final selectedAddress = addresses[selectedAddressIndex];
      
      // Calculate cart total
      final cartTotal = ref.read(cartTotalProvider);
      
      // Get a batch reference
      final batch = FirebaseFirestore.instance.batch();
      
      // Create a new order document reference
      final ordersRef = FirebaseFirestore.instance.collection('orders');
      final newOrderRef = ordersRef.doc();
      
      // Group items by seller
      final Map<String, List<CartItem>> itemsBySeller = {};
      for (var item in cartItems) {
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(item.productId)
            .get();
            
        if (!productDoc.exists) {
          _showErrorSnackbar('One of the products is no longer available');
          setState(() {
            isLoading = false;
          });
          return;
        }
        
        final productData = productDoc.data() as Map<String, dynamic>;
        final sellerId = productData['sellerId'] as String;
        
        if (!itemsBySeller.containsKey(sellerId)) {
          itemsBySeller[sellerId] = [];
        }
        
        itemsBySeller[sellerId]!.add(item);
      }
      
      // Order data
      final orderData = {
        'orderId': newOrderRef.id,
        'buyerId': currentUser.uid,
        'orderDate': FieldValue.serverTimestamp(),
        'totalAmount': cartTotal,
        'status': 'pending',
        'paymentMethod': selectedPaymentMethodId,
        'paymentStatus': 'pending',
        'shippingAddress': selectedAddress,
        'items': cartItems.map((item) => item.toMap()).toList(),
        'sellerOrders': itemsBySeller.keys.toList(),
      };
      
      // Set the main order data
      batch.set(newOrderRef, orderData);
      
      // Create seller-specific order documents
      for (var sellerId in itemsBySeller.keys) {
        final sellerItems = itemsBySeller[sellerId]!;
        final sellerTotal = sellerItems.fold(
          0.0,
          (sum, item) => sum + (item.totalPrice),
        );
        
        final sellerOrderRef = FirebaseFirestore.instance
            .collection('sellerOrders')
            .doc();
            
        final sellerOrderData = {
          'sellerId': sellerId,
          'buyerId': currentUser.uid,
          'mainOrderId': newOrderRef.id,
          'sellerOrderId': sellerOrderRef.id,
          'orderDate': FieldValue.serverTimestamp(),
          'totalAmount': sellerTotal,
          'status': 'pending',
          'paymentMethod': selectedPaymentMethodId,
          'paymentStatus': 'pending',
          'shippingAddress': selectedAddress,
          'items': sellerItems.map((item) => item.toMap()).toList(),
        };
        
        batch.set(sellerOrderRef, sellerOrderData);
      }
      
      // Clear cart
      for (var item in cartItems) {
        final cartItemRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('cart')
            .doc(item.id);
            
        batch.delete(cartItemRef);
      }
      
      // Commit the batch
      await batch.commit();
      
      // Clear the local cart
      ref.read(cartProvider.notifier).clearCart();
      
      // Navigate to order success screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(orderId: newOrderRef.id),
          ),
        );
      }
    } catch (e) {
      print('Error placing order: $e');
      _showErrorSnackbar('Failed to place order: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    setState(() {
      isLoading = false;
    });
  }

  Widget _buildEmptyCart(BuildContext context) {
    // Implement the logic to display an empty cart message
    return Center(child: Text('No items in the cart'));
  }
} 