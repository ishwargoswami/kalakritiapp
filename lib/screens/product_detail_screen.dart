import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/cart_item.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/providers/cart_provider.dart';
import 'package:kalakritiapp/providers/product_provider.dart';
import 'package:kalakritiapp/providers/wishlist_provider.dart';
import 'package:kalakritiapp/screens/checkout_screen.dart';
import 'package:kalakritiapp/services/firestore_service.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/product_reviews.dart';
import 'package:kalakritiapp/widgets/rental_date_picker.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  bool _isRental = false;
  DateTime? _startDate;
  DateTime? _endDate;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _showRentalDatePicker() {
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
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          onConfirm: (start, end) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailsProvider(widget.productId));
    final isInWishlistAsync = ref.watch(isInWishlistProvider(widget.productId));
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: productAsync.when(
        data: (product) => _buildProductDetails(product!, isInWishlistAsync),
        loading: () => _buildLoadingShimmer(),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildProductDetails(Product product, AsyncValue<bool> isInWishlistAsync) {
    final isInWishlist = isInWishlistAsync.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );
    
    return Stack(
      children: [
        // Scrollable content
        CustomScrollView(
          slivers: [
            // App bar with product image
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: kPrimaryColor,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: kPrimaryColor),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? kAccentColor : kPrimaryColor,
                    ),
                  ),
                  onPressed: () async {
                    final wishlistService = ref.read(wishlistServiceProvider);
                    final result = await wishlistService.toggleWishlistStatus(product.id);
                    
                    if (result && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isInWishlist 
                              ? '${product.name} removed from wishlist'
                              : '${product.name} added to wishlist'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.share, color: kPrimaryColor),
                  ),
                  onPressed: () {
                    // TODO: Share product
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing functionality to be implemented'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: CachedNetworkImage(
                  imageUrl: product.imageUrls.isNotEmpty
                      ? product.imageUrls[_selectedImageIndex]
                      : 'https://via.placeholder.com/400',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            
            // Product details
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image thumbnails
                  if (product.imageUrls.length > 1)
                    Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: product.imageUrls.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImageIndex = index;
                              });
                            },
                            child: Container(
                              width: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _selectedImageIndex == index
                                      ? kPrimaryColor
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: product.imageUrls[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Product info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Ratings and Category
                        Row(
                          children: [
                            // Rating
                            Icon(
                              Icons.star,
                              size: 20,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product.rating.toStringAsFixed(1)} (${product.ratingCount})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Category
                            Icon(Icons.category_outlined, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              product.category,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (product.isAvailableForRent)
                              Text(
                                'Rent: ₹${product.rentalPrice?.toStringAsFixed(0) ?? "N/A"}/day',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // Stock availability
                        Text(
                          product.stock > 0
                              ? 'In Stock (${product.stock} available)'
                              : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 14,
                            color: product.stock > 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Artisan info
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Crafted by ${product.artisanName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (product.artisanLocation.isNotEmpty)
                                        Text(
                                          product.artisanLocation,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    // TODO: View artisan profile
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Artisan profile coming soon'),
                                      ),
                                    );
                                  },
                                  child: const Text('View Profile'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Specifications
                        if (product.specifications.isNotEmpty) ...[
                          const Text(
                            'Specifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...product.specifications.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '${entry.key}:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${entry.value}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 24),
                        ],
                        
                        // Rental options
                        if (product.isAvailableForRent) ...[
                          SwitchListTile(
                            title: const Text(
                              'Rent instead of buying',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Rent for ₹${product.rentalPrice?.toStringAsFixed(0) ?? "N/A"}/day',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: _isRental,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (value) {
                              setState(() {
                                _isRental = value;
                                // Reset rental dates if switching to purchase
                                if (!value) {
                                  _startDate = null;
                                  _endDate = null;
                                }
                              });
                            },
                          ),
                          
                          // Date selection for rental
                          if (_isRental) ...[
                            const SizedBox(height: 8),
                            ListTile(
                              title: const Text('Select Rental Period'),
                              subtitle: _startDate != null && _endDate != null
                                  ? Text(
                                      'From ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} to ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : const Text('Tap to select dates'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _showRentalDatePicker,
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                        
                        // Product Reviews
                        const SizedBox(height: 8),
                        ProductReviews(
                          productId: product.id,
                          rating: product.rating,
                          reviewCount: product.ratingCount,
                        ),
                        
                        // Add space at the bottom for the purchase buttons
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Bottom purchase controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity adjuster
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _decrementQuantity,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _incrementQuantity,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Add to cart button
                Expanded(
                  child: CustomButton(
                    text: 'Add to Cart',
                    onPressed: product.stock > 0
                        ? () {
                            final cartNotifier = ref.read(cartProvider.notifier);
                            
                            if (_isRental) {
                              // Validate rental dates
                              if (_startDate == null || _endDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select rental dates'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Add as rental
                              cartNotifier.addToCart(
                                product, 
                                _quantity,
                                isRental: true,
                                startDate: _startDate,
                                endDate: _endDate,
                              );
                            } else {
                              // Add as purchase
                              cartNotifier.addToCart(
                                product,
                                _quantity,
                              );
                            }
                            
                            // Show confirmation message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                action: SnackBarAction(
                                  label: 'VIEW CART',
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            );
                          }
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Buy Now button
                Expanded(
                  child: CustomButton(
                    text: 'Buy Now',
                    onPressed: product.stock > 0
                        ? () {
                            // Validate rental dates
                            if (_isRental && (_startDate == null || _endDate == null)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select rental dates'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            // Create cart item
                            final cartItem = CartItem(
                              id: '',
                              productId: product.id,
                              productName: product.name,
                              imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                              price: _isRental ? (product.rentalPrice ?? product.price * 0.1) : product.price,
                              quantity: _quantity,
                              isRental: _isRental,
                              rentalStartDate: _startDate,
                              rentalEndDate: _endDate,
                              artisanName: product.artisanName,
                            );
                            
                            // Navigate to checkout with just this item
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  items: [cartItem],
                                ),
                              ),
                            );
                          }
                        : null,
                    backgroundColor: kAccentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          expandedHeight: 300,
          pinned: true,
        ),
        SliverToBoxAdapter(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 32,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 16,
                        width: 150,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 40,
                        width: 120,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 100,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 24,
                        width: 150,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 