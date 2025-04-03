import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/category.dart';
import 'package:kalakritiapp/providers/product_provider.dart';
import 'package:kalakritiapp/services/firestore_service.dart';

// Provider for all categories
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getCategories();
});

// Provider for category details
final categoryDetailsProvider = FutureProvider.family<Category?, String>((ref, categoryId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getCategoryById(categoryId);
}); 