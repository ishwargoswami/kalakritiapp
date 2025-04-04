import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/category.dart';
import 'package:kalakritiapp/providers/cart_provider.dart';
import 'package:kalakritiapp/services/firestore_service.dart';

// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Provider for category names (as strings)
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final categories = await firestoreService.getCategories();
  // Extract unique category names to prevent duplicates
  final categoryNames = categories.map((cat) => cat.name).toList();
  final uniqueCategories = categoryNames.toSet().toList();
  // Sort alphabetically for better user experience
  uniqueCategories.sort();
  return uniqueCategories;
});

// Provider for all category objects
final allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getCategories();
});

// Provider for category details
final categoryDetailsProvider = FutureProvider.family<Category?, String>((ref, categoryId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getCategoryById(categoryId);
}); 