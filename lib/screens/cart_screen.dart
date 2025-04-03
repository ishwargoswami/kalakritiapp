import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kalakritiapp/models/cart_item.dart';
import 'package:kalakritiapp/providers/cart_provider.dart';
import 'package:kalakritiapp/screens/checkout_screen.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/rental_date_picker.dart';
import 'package:shimmer/shimmer.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          'My Cart',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (cartItems.isNotEmpty) 
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _showClearCartDialog(context, ref),
            ),
        ],
      ),
      body: cartItems.isEmpty 
        ? _buildEmptyCart(context)
        : _buildCartContent(context, cartItems, ref),
      bottomNavigationBar: cartItems.isNotEmpty
        ? _buildCheckoutBar(context, cartItems, cartTotal, ref)
        : null,
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: kSlateGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your cart to see them here',
            style: TextStyle(
              color: kTextColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Continue Shopping',
            onPressed: () {
              // Navigate back to home screen
              Navigator.of(context).pop();
            },
            backgroundColor: kSecondaryColor,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(
    BuildContext context, 
    List<CartItem> cartItems, 
    WidgetRef ref
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...cartItems.map((cartItem) => 
          _buildCartItemCard(context, cartItem, ref)
        ).toList(),
        
        const SizedBox(height: 16),
        _buildCartSummary(cartItems),
      ],
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartItem cartItem,
    WidgetRef ref,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: cartItem.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartItem.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Artisan: ${cartItem.artisanName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cartItem.isRental 
                            ? '₹${cartItem.price}/day (Rental)' 
                            : '₹${cartItem.price}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Quantity controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: cartItem.quantity > 1
                          ? () => ref
                              .read(cartProvider.notifier)
                              .updateQuantity(cartItem.id, cartItem.quantity - 1)
                          : null,
                      color: cartItem.quantity > 1 ? kSecondaryColor : Colors.grey,
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${cartItem.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(cartItem.id, cartItem.quantity + 1),
                      color: kSecondaryColor,
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                
                // Rental dates or total
                if (cartItem.isRental)
                  Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        size: 16,
                        color: cartItem.isRental ? kSecondaryColor : kSlateGray,
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: cartItem.isRental 
                            ? () => _showRentalDatePicker(context, cartItem, ref)
                            : null,
                        child: Text(
                          cartItem.rentalStartDate != null && cartItem.rentalEndDate != null
                              ? '${DateFormat('MMM d, yyyy').format(cartItem.rentalStartDate!)} - '
                                '${DateFormat('MMM d, yyyy').format(cartItem.rentalEndDate!)}'
                              : 'Select dates',
                          style: TextStyle(
                            fontSize: 12,
                            color: cartItem.isRental ? kSecondaryColor : kSlateGray,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '₹${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
            
            if (cartItem.isRental && cartItem.rentalStartDate != null && cartItem.rentalEndDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${cartItem.rentalDuration} days × ₹${cartItem.price} × ${cartItem.quantity} = ₹${cartItem.totalRentalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Remove button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ref.read(cartProvider.notifier).removeFromCart(cartItem.id),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remove'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(List<CartItem> cartItems) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    
    double subtotal = 0;
    int rentalItems = 0;
    int purchaseItems = 0;
    
    for (var item in cartItems) {
      if (item.isRental) {
        rentalItems += item.quantity;
        if (item.rentalStartDate != null && item.rentalEndDate != null) {
          subtotal += item.totalRentalPrice;
        }
      } else {
        purchaseItems += item.quantity;
        subtotal += item.totalPrice;
      }
    }
    
    // Assuming tax is 5% of subtotal
    final tax = subtotal * 0.05;
    final shipping = subtotal > 500 ? 0.0 : 50.0;
    final total = subtotal + tax + shipping;
    
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
              'Cart Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryItem('Purchase Items (${purchaseItems} items)', 
              purchaseItems > 0 ? '' : 'None'
            ),
            _buildSummaryItem('Rental Items (${rentalItems} items)', 
              rentalItems > 0 ? '' : 'None'
            ),
            const Divider(height: 24),
            _buildSummaryItem('Subtotal', formatter.format(subtotal)),
            _buildSummaryItem('Tax (5%)', formatter.format(tax)),
            _buildSummaryItem(
              'Shipping', 
              shipping > 0 ? formatter.format(shipping) : 'Free',
              valueColor: shipping > 0 ? null : Colors.green,
            ),
            const Divider(height: 24),
            _buildSummaryItem(
              'Total', 
              formatter.format(total),
              isBold: true,
              valueColor: kPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: kTextColor.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? kTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(
    BuildContext context, 
    List<CartItem> cartItems, 
    double total,
    WidgetRef ref
  ) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12,
                    color: kTextColor.withOpacity(0.7),
                  ),
                ),
                Text(
                  formatter.format(total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomButton(
              text: 'Checkout',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CheckoutScreen()),
                );
              },
              backgroundColor: kSecondaryColor,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showRentalDatePicker(
    BuildContext context, 
    CartItem cartItem, 
    WidgetRef ref
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: RentalDatePicker(
          initialStartDate: cartItem.rentalStartDate,
          initialEndDate: cartItem.rentalEndDate,
          onConfirm: (startDate, endDate) {
            if (startDate != null && endDate != null) {
              ref.read(cartProvider.notifier).updateRentalDates(
                cartItem.id, 
                startDate, 
                endDate,
              );
            }
          },
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(context).pop();
            },
            child: const Text('CLEAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 