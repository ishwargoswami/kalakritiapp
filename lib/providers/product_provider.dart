import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/services/firestore_service.dart';

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
final searchResultsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.searchProducts(query);
}); 