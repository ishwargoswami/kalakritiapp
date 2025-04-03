import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/review.dart';
import 'package:kalakritiapp/services/review_service.dart';

// Provider for the ReviewService
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

// Provider for reviews of a specific product
final productReviewsProvider = StreamProvider.family<List<Review>, String>(
  (ref, productId) {
    final reviewService = ref.watch(reviewServiceProvider);
    return reviewService.getReviewsForProduct(productId);
  },
);

// Provider for checking if user has purchased a product
final hasUserPurchasedProductProvider = FutureProvider.family<bool, String>(
  (ref, productId) {
    final reviewService = ref.watch(reviewServiceProvider);
    return reviewService.hasUserPurchasedProduct(productId);
  },
);

// Provider for getting a user's review for a specific product
final userReviewForProductProvider = FutureProvider.family<Review?, String>(
  (ref, productId) {
    final reviewService = ref.watch(reviewServiceProvider);
    return reviewService.getUserReviewForProduct(productId);
  },
);

// Provider for the rating breakdown of a product
final ratingBreakdownProvider = FutureProvider.family<Map<int, int>, String>(
  (ref, productId) async {
    final reviewsAsync = await ref.watch(productReviewsProvider(productId).future);
    
    // Initialize counts for each rating (1-5)
    final Map<int, int> breakdown = {
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
    };
    
    // Count reviews for each rating
    for (final review in reviewsAsync) {
      final rating = review.rating.round();
      if (rating >= 1 && rating <= 5) {
        breakdown[rating] = (breakdown[rating] ?? 0) + 1;
      }
    }
    
    return breakdown;
  },
); 