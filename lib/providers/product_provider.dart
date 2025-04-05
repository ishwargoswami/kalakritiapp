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

// Function to add AR model to products
List<Product> _enrichProductsWithARModel(List<Product> products) {
  const String defaultModelPath = 'assets/models/alien_flowers.glb';
  
  return products.map((product) {
    // If product doesn't have an AR model, add the default one
    if (product.arModelUrl == null) {
      return product.copyWith(
        arModelUrl: defaultModelPath,
        hasARModel: true,
      );
    }
    return product;
  }).toList();
}

// Single product enrichment function
Product? _enrichProductWithARModel(Product? product) {
  if (product == null) return null;
  
  const String defaultModelPath = 'assets/models/alien_flowers.glb';
  
  // If product doesn't have an AR model, add the default one
  if (product.arModelUrl == null) {
    return product.copyWith(
      arModelUrl: defaultModelPath,
      hasARModel: true,
    );
  }
  return product;
}

// Provider for featured products with auto-refresh
final featuredProductsProvider = StreamProvider<List<Product>>((ref) async* {
  // Initial data fetch
  var products = await ref.read(firestoreServiceProvider).getFeaturedProducts();
  yield _enrichProductsWithARModel(products);
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    products = await ref.read(firestoreServiceProvider).getFeaturedProducts();
    yield _enrichProductsWithARModel(products);
  }
});

// Provider for new arrivals with auto-refresh
final newArrivalsProvider = StreamProvider<List<Product>>((ref) async* {
  // Initial data fetch
  var products = await ref.read(firestoreServiceProvider).getNewArrivals();
  yield _enrichProductsWithARModel(products);
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    products = await ref.read(firestoreServiceProvider).getNewArrivals();
    yield _enrichProductsWithARModel(products);
  }
});

// Provider for all products with auto-refresh
final productsProvider = StreamProvider<List<Product>>((ref) async* {
  // Initial data fetch
  var products = await ref.read(firestoreServiceProvider).getProducts();
  yield _enrichProductsWithARModel(products);
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    products = await ref.read(firestoreServiceProvider).getProducts();
    yield _enrichProductsWithARModel(products);
  }
});

// Provider for products by category with auto-refresh
final productsByCategoryProvider = StreamProvider.family<List<Product>, String>((ref, categoryId) async* {
  // Initial data fetch
  var products = await ref.read(firestoreServiceProvider).getProductsByCategory(categoryId);
  yield _enrichProductsWithARModel(products);
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    products = await ref.read(firestoreServiceProvider).getProductsByCategory(categoryId);
    yield _enrichProductsWithARModel(products);
  }
});

// Provider for product details with auto-refresh for real-time stock updates
final productDetailsProvider = StreamProvider.family<Product?, String>((ref, productId) {
  // Use Firestore's own real-time updates
  return _firestore
    .collection('products')
    .doc(productId)
    .snapshots()
    .map((doc) => doc.exists ? Product.fromMap(doc.id, doc.data()!) : null)
    .map((product) => _enrichProductWithARModel(product));
});

// Provider for search results (no auto-refresh needed as it's query-based)
final searchProductsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  if (query.isEmpty) {
    return [];
  }
  var products = await firestoreService.searchProducts(query);
  return _enrichProductsWithARModel(products);
});

// Provider for all products (converted to stream)
final allProductsProvider = StreamProvider<List<Product>>(
  (ref) {
    return _firestore.collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList())
        .map((products) => _enrichProductsWithARModel(products));
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
            .toList())
        .map((products) => _enrichProductsWithARModel(products));
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
            .toList())
        .map((products) => _enrichProductsWithARModel(products));
  },
);

// Provider for best selling products with auto-refresh
final bestSellersProvider = StreamProvider<List<Product>>((ref) async* {
  // Initial data fetch
  var products = await ref.read(firestoreServiceProvider).getBestSellingProducts();
  yield _enrichProductsWithARModel(products);
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    products = await ref.read(firestoreServiceProvider).getBestSellingProducts();
    yield _enrichProductsWithARModel(products);
  }
});

// Provider for products by category name with auto-refresh
final productsByCategoryNameProvider = StreamProvider.family<List<Product>, String>((ref, categoryName) async* {
  // Initial data fetch
  var products = await ref.read(firestoreServiceProvider).getProductsByCategoryName(categoryName);
  var enrichedProducts = _enrichProductsWithARModel(products);
  
  // Print debug information for troubleshooting
  if (categoryName == 'Featured' || categoryName == 'New Arrivals') {
    print('Debug - Category: $categoryName, Found ${enrichedProducts.length} products');
    for (var product in enrichedProducts) {
      print('Product: ${product.name}, Category: ${product.category}, IsFeatured: ${product.isFeatured}, HasAR: ${product.hasARModel}');
    }
  }
  
  yield enrichedProducts;
  
  // Periodic updates
  await for (final _ in Stream.periodic(autoRefreshDuration)) {
    var updatedProducts = await ref.read(firestoreServiceProvider).getProductsByCategoryName(categoryName);
    var enrichedUpdatedProducts = _enrichProductsWithARModel(updatedProducts);
    
    // Print debug information for troubleshooting on refresh
    if (categoryName == 'Featured' || categoryName == 'New Arrivals') {
      print('Debug Refresh - Category: $categoryName, Found ${enrichedUpdatedProducts.length} products');
    }
    
    yield enrichedUpdatedProducts;
  }
}); 