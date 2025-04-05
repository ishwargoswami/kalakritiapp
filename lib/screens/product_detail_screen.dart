import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/cart_item.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/models/user.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/providers/cart_provider.dart';
import 'package:kalakritiapp/providers/product_provider.dart';
import 'package:kalakritiapp/providers/wishlist_provider.dart';
import 'package:kalakritiapp/screens/artisan_profile_screen.dart';
import 'package:kalakritiapp/screens/checkout_screen.dart';
import 'package:kalakritiapp/screens/buyer/product_ar_view.dart';
import 'package:kalakritiapp/services/firestore_service.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/product_reviews.dart';
import 'package:kalakritiapp/widgets/rental_date_picker.dart';
import 'package:shimmer/shimmer.dart';

// Provider to get seller information with auto-refresh
final sellerProvider = StreamProvider.family<UserModel?, String>((ref, artisanId) async* {
  try {
    final authService = ref.read(authServiceProvider);
    // Initial data fetch
    yield await authService.getUserDataById(artisanId);
    
    // Periodic updates
    await for (final _ in Stream.periodic(const Duration(minutes: 5))) {
      yield await authService.getUserDataById(artisanId);
    }
  } catch (e) {
    print('Error fetching seller: $e');
    yield null;
  }
});

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

  // Function to refresh product data
  Future<void> _refreshProductData() async {
    // Invalidate providers to force refresh
    ref.invalidate(productDetailsProvider(widget.productId));
    ref.invalidate(isInWishlistProvider(widget.productId));
    // Get the seller ID and refresh seller data too
    final product = await ref.read(productDetailsProvider(widget.productId).future);
    if (product != null) {
      ref.invalidate(sellerProvider(product.artisanId));
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
    // Explicitly allow screenshots
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    final productAsync = ref.watch(productDetailsProvider(widget.productId));
    final isInWishlistAsync = ref.watch(isInWishlistProvider(widget.productId));
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshProductData,
        child: productAsync.when(
          data: (product) => product != null 
            ? _buildProductDetails(product, isInWishlistAsync)
            : const Center(child: Text('Product not found')),
          loading: () => _buildLoadingShimmer(),
          error: (error, stackTrace) => Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ),
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
          physics: const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator to work
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
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.view_in_ar, color: kPrimaryColor),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductARView(productId: product.id),
                      ),
                    );
                  },
                ),
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
                        
                        // Seller/Artisan Information
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildArtisanSection(product.artisanId),
                        
                        // Description
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildArtisanSection(String artisanId) {
    final sellerAsync = ref.watch(sellerProvider(artisanId));
    
    return sellerAsync.when(
      data: (seller) {
        if (seller == null) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Artisan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArtisanProfileScreen(
                      artisanId: seller.uid,
                      artisanName: seller.name,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: seller.photoURL != null
                        ? CachedNetworkImageProvider(seller.photoURL!)
                        : null,
                    child: seller.photoURL == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (seller.businessName != null && seller.businessName!.isNotEmpty)
                          Text(
                            seller.businessName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        if (seller.artisanStory != null && seller.artisanStory!.isNotEmpty)
                          Text(
                            'Tap to view artisan story',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
} 