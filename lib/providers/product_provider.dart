import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/services/firestore_service.dart';
import 'package:kalakritiapp/providers/cart_provider.dart'; // Import to use firestoreServiceProvider

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Provider for all products
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProducts();
});

// Provider for featured products
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFeaturedProducts();
});

// Provider for new arrivals
final newArrivalsProvider = FutureProvider<List<Product>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getNewArrivals();
});

// Provider for products by category
final productsByCategoryProvider = FutureProvider.family<List<Product>, String>((ref, categoryId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProductsByCategory(categoryId);
});

// Provider for product details
final productDetailsProvider = FutureProvider.family<Product?, String>((ref, productId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProductById(productId);
});

// Provider for search results
final searchProductsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  if (query.isEmpty) {
    return [];
  }
  return firestoreService.searchProducts(query);
});

// Provider for all products
final allProductsProvider = FutureProvider<List<Product>>(
  (ref) async {
    try {
      final querySnapshot = await _firestore.collection('products')
          .get();
      
      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  },
);

// Provider for popular products (sorted by rating)
final popularProductsProvider = FutureProvider<List<Product>>(
  (ref) async {
    try {
      final querySnapshot = await _firestore.collection('products')
          .orderBy('rating', descending: true)
          .limit(10)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load popular products: $e');
    }
  },
);

// Provider for rental products
final rentalProductsProvider = FutureProvider<List<Product>>(
  (ref) async {
    try {
      final querySnapshot = await _firestore.collection('products')
          .where('isAvailableForRent', isEqualTo: true)
          .limit(20)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load rental products: $e');
    }
  },
);

// Provider for best selling products
final bestSellersProvider = FutureProvider<List<Product>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getBestSellingProducts();
});

// Provider for products by category name
final productsByCategoryNameProvider = FutureProvider.family<List<Product>, String>((ref, categoryName) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProductsByCategoryName(categoryName);
}); 