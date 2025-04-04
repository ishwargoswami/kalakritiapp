import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/services/firestore_service.dart';
import 'package:kalakritiapp/providers/cart_provider.dart'; // Import to use firestoreServiceProvider
import 'package:rxdart/rxdart.dart'; // Import RxDart for startWith operator

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Auto-refresh timer duration
const autoRefreshDuration = Duration(minutes: 2);

// Provider for featured products with auto-refresh
final featuredProductsProvider = StreamProvider<List<Product>>((ref) async* {
  // Initial data fetch
  yield await ref.read(firestoreServiceProvider).getFeaturedProducts();
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    yield await ref.read(firestoreServiceProvider).getFeaturedProducts();
  }
});

// Provider for new arrivals with auto-refresh
final newArrivalsProvider = StreamProvider<List<Product>>((ref) async* {
  // Initial data fetch
  yield await ref.read(firestoreServiceProvider).getNewArrivals();
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    yield await ref.read(firestoreServiceProvider).getNewArrivals();
  }
});

// Provider for all products with auto-refresh
final productsProvider = StreamProvider<List<Product>>((ref) async* {
  // Initial data fetch
  yield await ref.read(firestoreServiceProvider).getProducts();
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    yield await ref.read(firestoreServiceProvider).getProducts();
  }
});

// Provider for products by category with auto-refresh
final productsByCategoryProvider = StreamProvider.family<List<Product>, String>((ref, categoryId) async* {
  // Initial data fetch
  yield await ref.read(firestoreServiceProvider).getProductsByCategory(categoryId);
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    yield await ref.read(firestoreServiceProvider).getProductsByCategory(categoryId);
  }
});

// Provider for product details with auto-refresh for real-time stock updates
final productDetailsProvider = StreamProvider.family<Product?, String>((ref, productId) {
  // Use Firestore's own real-time updates
  return _firestore
    .collection('products')
    .doc(productId)
    .snapshots()
    .map((doc) => doc.exists ? Product.fromMap(doc.id, doc.data()!) : null);
});

// Provider for search results (no auto-refresh needed as it's query-based)
final searchProductsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  if (query.isEmpty) {
    return [];
  }
  return firestoreService.searchProducts(query);
});

// Provider for all products (converted to stream)
final allProductsProvider = StreamProvider<List<Product>>(
  (ref) {
    return _firestore.collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList());
  },
);

// Provider for popular products with auto-refresh
final popularProductsProvider = StreamProvider<List<Product>>(
  (ref) {
    return _firestore.collection('products')
        .orderBy('rating', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList());
  },
);

// Provider for rental products with auto-refresh
final rentalProductsProvider = StreamProvider<List<Product>>(
  (ref) {
    return _firestore.collection('products')
        .where('isAvailableForRent', isEqualTo: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList());
  },
);

// Provider for best selling products with auto-refresh
final bestSellersProvider = StreamProvider<List<Product>>((ref) async* {
  // Initial data fetch
  yield await ref.read(firestoreServiceProvider).getBestSellingProducts();
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    yield await ref.read(firestoreServiceProvider).getBestSellingProducts();
  }
});

// Provider for products by category name with auto-refresh
final productsByCategoryNameProvider = StreamProvider.family<List<Product>, String>((ref, categoryName) async* {
  // Initial data fetch
  final products = await ref.read(firestoreServiceProvider).getProductsByCategoryName(categoryName);
  
  // Print debug information for troubleshooting
  if (categoryName == 'Featured' || categoryName == 'New Arrivals') {
    print('Debug - Category: $categoryName, Found ${products.length} products');
    for (var product in products) {
      print('Product: ${product.name}, Category: ${product.category}, IsFeatured: ${product.isFeatured}');
    }
  }
  
  yield products;
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    final updatedProducts = await ref.read(firestoreServiceProvider).getProductsByCategoryName(categoryName);
    
    // Print debug information for troubleshooting on refresh
    if (categoryName == 'Featured' || categoryName == 'New Arrivals') {
      print('Debug Refresh - Category: $categoryName, Found ${updatedProducts.length} products');
    }
    
    yield updatedProducts;
  }
}); 