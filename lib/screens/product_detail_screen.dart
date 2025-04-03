import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/providers/product_provider.dart';
import 'package:kalakritiapp/services/firestore_service.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _isRenting = false;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailsProvider(widget.productId));
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(
              child: Text('Product not found'),
            );
          }
          
          return Stack(
            children: [
              // Product details content
              CustomScrollView(
                slivers: [
                  // App bar with product image
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildProductImageGallery(product),
                    ),
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {
                            // TODO: Implement add to favorites
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            // TODO: Implement share product
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Product information
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name and rating
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 20,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${product.ratingCount})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Artisan info
                          Text(
                            'By ${product.artisanName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Price information
                          Row(
                            children: [
                              if (product.isAvailableForSale) ...[
                                Text(
                                  'Buy: ₹${product.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                              if (product.isAvailableForSale && product.isAvailableForRent)
                                const Text(' | ', style: TextStyle(fontSize: 18)),
                              if (product.isAvailableForRent) ...[
                                Text(
                                  'Rent: ₹${product.rentalPrice?.toStringAsFixed(0) ?? "N/A"}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                const Text('/day', style: TextStyle(fontSize: 14)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Stock information
                          Text(
                            'In Stock: ${product.stock}',
                            style: TextStyle(
                              fontSize: 14,
                              color: product.stock > 0 ? Colors.green[700] : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
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
                              color: Colors.grey[800],
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
                                    Text(
                                      '${entry.key}: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${entry.value}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 24),
                          ],
                          
                          // Quantity selector
                          if (product.stock > 0) ...[
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildQuantityButton(
                                  icon: Icons.remove,
                                  onPressed: () {
                                    if (_quantity > 1) {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  },
                                ),
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$_quantity',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _buildQuantityButton(
                                  icon: Icons.add,
                                  onPressed: () {
                                    if (_quantity < product.stock) {
                                      setState(() {
                                        _quantity++;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                          
                          // Space for bottom buttons
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Bottom buttons
              if (product.stock > 0)
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
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (product.isAvailableForRent)
                          Expanded(
                            child: CustomButton(
                              text: 'Rent Now',
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              isLoading: _isRenting,
                              onPressed: () => _rentProduct(product, currentUser),
                            ),
                          ),
                        if (product.isAvailableForRent && product.isAvailableForSale)
                          const SizedBox(width: 16),
                        if (product.isAvailableForSale)
                          Expanded(
                            child: CustomButton(
                              text: 'Add to Cart',
                              isLoading: _isAddingToCart,
                              onPressed: () => _addToCart(product, currentUser),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error loading product: $error'),
        ),
      ),
    );
  }

  // Build image gallery
  Widget _buildProductImageGallery(Product product) {
    if (product.imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    // For simplicity, just showing the first image
    // In a real app, you would implement a carousel or PageView
    return CachedNetworkImage(
      imageUrl: product.imageUrls[0],
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.error_outline,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  // Build quantity selector button
  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon),
        iconSize: 18,
        onPressed: onPressed,
      ),
    );
  }

  // Add product to cart
  Future<void> _addToCart(Product product, User? currentUser) async {
    if (currentUser == null) {
      _showLoginRequiredDialog();
      return;
    }
    
    setState(() {
      _isAddingToCart = true;
    });
    
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.addToCart(
        currentUser.uid,
        product.id,
        _quantity,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  // Rent product
  Future<void> _rentProduct(Product product, User? currentUser) async {
    if (currentUser == null) {
      _showLoginRequiredDialog();
      return;
    }
    
    setState(() {
      _isRenting = true;
    });
    
    try {
      // TODO: Implement rental logic with date selection
      // For now, just show a message
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rental functionality will be implemented soon'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRenting = false;
        });
      }
    }
  }

  // Show login required dialog
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to continue with this action.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to login screen
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
} 