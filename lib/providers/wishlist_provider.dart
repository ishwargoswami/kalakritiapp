import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/services/wishlist_service.dart';

// Provider for the WishlistService
final wishlistServiceProvider = Provider<WishlistService>((ref) {
  return WishlistService();
});

// Provider for all wishlist product IDs
final wishlistIdsProvider = StreamProvider<List<String>>((ref) {
  final wishlistService = ref.watch(wishlistServiceProvider);
  return wishlistService.getWishlistIds();
});

// Provider for all wishlist products with details
final wishlistProductsProvider = StreamProvider<List<Product>>((ref) {
  final wishlistService = ref.watch(wishlistServiceProvider);
  return wishlistService.getWishlistProducts();
});

// Provider to check if a specific product is in the wishlist
final isInWishlistProvider = FutureProvider.family<bool, String>((ref, productId) async {
  final wishlistService = ref.watch(wishlistServiceProvider);
  return wishlistService.isInWishlist(productId);
});

// Provider for wishlist count
final wishlistCountProvider = Provider<int>((ref) {
  final wishlistIdsAsyncValue = ref.watch(wishlistIdsProvider);
  return wishlistIdsAsyncValue.when(
    data: (wishlistIds) => wishlistIds.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
}); 