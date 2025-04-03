import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/providers/cart_provider.dart';
import 'package:kalakritiapp/providers/product_provider.dart';
import 'package:kalakritiapp/screens/product_detail_screen.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/rental_date_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kalakritiapp/services/firestore_service.dart';

// Provider for FirestoreService if not already defined elsewhere
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Create a custom Firestore provider for rental products
final rentalProductsProvider = FutureProvider<List<Product>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final products = await firestoreService.getProducts();
  return products.where((product) => product.isAvailableForRent).toList();
});

// Provider for user's active rentals
final activeRentalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  try {
    final firestoreService = ref.watch(firestoreServiceProvider);
    final rentalsSnapshot = await firestoreService.getUserRentals(user.uid);
    
    final List<Map<String, dynamic>> rentals = [];
    for (var doc in rentalsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      rentals.add(data);
    }
    
    // Sort by rental date, newest first
    rentals.sort((a, b) {
      final aDate = (a['rentDate'] as dynamic).toDate();
      final bDate = (b['rentDate'] as dynamic).toDate();
      return bDate.compareTo(aDate);
    });
    
    return rentals;
  } catch (e) {
    // Check if it's a missing index error
    if (e.toString().contains('failed-precondition') && 
        e.toString().contains('index')) {
      throw 'Firestore index is being created. Please try again in a few minutes.';
    }
    rethrow;
  }
});

class RentalsScreen extends ConsumerStatefulWidget {
  const RentalsScreen({super.key});

  @override
  ConsumerState<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends ConsumerState<RentalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Rentals',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: kPrimaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Available for Rent'),
            Tab(text: 'My Rentals'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RentalProductsTab(),
          MyRentalsTab(),
        ],
      ),
    );
  }
}

class RentalProductsTab extends ConsumerWidget {
  const RentalProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentalProductsAsync = ref.watch(rentalProductsProvider);
    
    return rentalProductsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.watch_later_outlined,
                  size: 80,
                  color: kSlateGray.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No rental products available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check back later for new rental offerings',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildRentalProductCard(context, product, ref);
          },
        );
      },
      loading: () => _buildLoadingShimmer(),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: kAccentColor),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                error.toString().contains('index') 
                    ? 'We\'re setting up some things in the database. Please check back in a few minutes.'
                    : 'Error loading rental products: $error',
                style: TextStyle(color: kAccentColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(rentalProductsProvider),
              child: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalProductCard(BuildContext context, Product product, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : 'https://via.placeholder.com/400x200?text=Product+Image',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey[400],
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              product.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    memCacheWidth: 800,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kAccentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'RENTAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Product details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Rental Rate: ',
                        style: TextStyle(
                          color: kTextColor.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '₹${product.rentalPrice}/day',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (product.isAvailableForSale) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Purchase Price: ',
                          style: TextStyle(
                            color: kTextColor.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '₹${product.price}',
                          style: TextStyle(
                            color: kTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      color: kTextColor.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Rent Now',
                          onPressed: user != null
                              ? () => _showRentalDatePicker(context, product, ref)
                              : () => _showLoginPrompt(context),
                          backgroundColor: kSecondaryColor,
                          textColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        text: 'Details',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(productId: product.id),
                            ),
                          );
                        },
                        isOutlined: true,
                        backgroundColor: kPrimaryColor,
                        width: 100,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRentalDatePicker(BuildContext context, Product product, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RentalDatePicker(
        onConfirm: (startDate, endDate) {
          if (startDate != null && endDate != null) {
            // Add to cart with rental info
            ref.read(cartProvider.notifier).addToCart(
              product,
              1,
              isRental: true,
              startDate: startDate,
              endDate: endDate,
            );
            
            // Show confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} added to cart'),
                action: SnackBarAction(
                  label: 'View Cart',
                  onPressed: () {
                    // Navigate to cart tab
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      // This would navigate to the cart tab in a real app
                    }
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please log in to rent products'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class MyRentalsTab extends ConsumerWidget {
  const MyRentalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle,
              size: 80,
              color: kSlateGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Not Logged In',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please log in to view your rentals',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: CustomButton(
                text: 'Login',
                onPressed: () {
                  // TODO: Navigate to login screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Login functionality coming soon!')),
                  );
                },
                backgroundColor: kPrimaryColor,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    final activeRentalsAsync = ref.watch(activeRentalsProvider);
    
    return activeRentalsAsync.when(
      data: (rentals) {
        if (rentals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.watch_later_outlined,
                  size: 80,
                  color: kSlateGray.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Active Rentals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You have no active rental items',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  child: CustomButton(
                    text: 'Browse Rentals',
                    onPressed: () {
                      // Switch to first tab
                      (context as Element).findAncestorStateOfType<_RentalsScreenState>()
                          ?._tabController.animateTo(0);
                    },
                    backgroundColor: kSecondaryColor,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rentals.length,
          itemBuilder: (context, index) {
            final rental = rentals[index];
            return _buildRentalOrderCard(context, rental);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: kAccentColor),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                error.toString().contains('index') 
                    ? 'We\'re setting up some things in the database. Please check back in a few minutes.'
                    : 'Error loading rentals: $error',
                style: TextStyle(color: kAccentColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(activeRentalsProvider),
              child: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalOrderCard(BuildContext context, Map<String, dynamic> rental) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');
    final String orderId = rental['id'] ?? '';
    
    // Safely handle date fields with null checks
    DateTime? rentDate;
    if (rental['rentDate'] != null) {
      try {
        rentDate = (rental['rentDate'] as dynamic).toDate();
      } catch (e) {
        print('Error parsing rentDate: $e');
      }
    }
    
    DateTime? returnDate;
    if (rental['returnDate'] != null) {
      try {
        returnDate = (rental['returnDate'] as dynamic).toDate();
      } catch (e) {
        print('Error parsing returnDate: $e');
      }
    }
    
    final double totalAmount = (rental['totalAmount'] ?? 0.0).toDouble();
    final String status = rental['status'] ?? 'Processing';
    
    // Generate a color based on status
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'completed':
        statusColor = Colors.grey;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'overdue':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = kSecondaryColor;
    }
    
    // Get the items safely
    final List<dynamic> items = rental['items'] ?? [];
    
    // If critical data is missing, show simplified card
    if (rentDate == null || returnDate == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${orderId.isNotEmpty ? orderId.substring(0, min(orderId.length, 8)) : "Unknown"}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Issue with rental data. Please contact support.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Contact Support',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support chat coming soon!'),
                    ),
                  );
                },
                backgroundColor: kPrimaryColor,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${orderId.isNotEmpty ? orderId.substring(0, min(orderId.length, 8)) : "Unknown"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rented on ${dateFormat.format(rentDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: kTextColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Rental details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rental Period:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    Text(
                      '${dateFormat.format(rentDate)} - ${dateFormat.format(returnDate)}',
                      style: TextStyle(
                        color: kTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Duration:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    Text(
                      '${returnDate.difference(rentDate).inDays + 1} days',
                      style: TextStyle(
                        color: kTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kAccentColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'Rented Items:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Rented items list
                ...items.map((item) {
                  final String name = item['name'] ?? 'Unknown Item';
                  final int quantity = item['quantity'] ?? 1;
                  final String imageUrl = item['imageUrl'] ?? '';
                  final double price = (item['price'] ?? 0.0).toDouble();
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Item image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl.isNotEmpty
                                ? imageUrl
                                : 'https://via.placeholder.com/50',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 50,
                                height: 50,
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Item details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹$price/day × $quantity',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: kTextColor.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    '₹${(price * quantity).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: kTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Extend Rental',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rental extension coming soon!'),
                            ),
                          );
                        },
                        backgroundColor: status.toLowerCase() == 'active'
                            ? kSecondaryColor
                            : Colors.grey,
                        textColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        text: 'Support',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Support chat coming soon!'),
                            ),
                          );
                        },
                        isOutlined: true,
                        backgroundColor: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 