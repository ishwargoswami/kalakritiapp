import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kalakritiapp/models/review.dart';
import 'package:kalakritiapp/providers/review_provider.dart';
import 'package:kalakritiapp/services/review_service.dart';
import 'package:kalakritiapp/widgets/add_review_dialog.dart';
import 'package:kalakritiapp/widgets/rating_bar.dart';
import 'package:shimmer/shimmer.dart';

class ProductReviews extends ConsumerWidget {
  final String productId;
  final double rating;
  final int reviewCount;

  const ProductReviews({
    super.key,
    required this.productId,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(productId));
    final userReviewAsync = ref.watch(userReviewForProductProvider(productId));
    final hasUserPurchasedAsync = ref.watch(hasUserPurchasedProductProvider(productId));
    final ratingBreakdownAsync = ref.watch(ratingBreakdownProvider(productId));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and add review button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews & Ratings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddReviewDialog(context, ref),
              icon: const Icon(Icons.rate_review),
              label: const Text('Write a Review'),
            ),
          ],
        ),
        
        // Rating overview
        _buildRatingOverview(context, ref),
        
        // User's review
        userReviewAsync.when(
          data: (userReview) {
            if (userReview != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Your Review',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildReviewCard(context, ref, userReview, isUserReview: true),
                  const Divider(),
                ],
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        
        // Review list
        const SizedBox(height: 16),
        reviewsAsync.when(
          data: (reviews) {
            // Filter out user's own review if it exists
            final filteredReviews = userReviewAsync.maybeWhen(
              data: (userReview) {
                if (userReview != null) {
                  return reviews.where((r) => r.id != userReview.id).toList();
                }
                return reviews;
              },
              orElse: () => reviews,
            );
            
            if (filteredReviews.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Reviews (${filteredReviews.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                ...filteredReviews.map((review) => _buildReviewCard(context, ref, review)),
              ],
            );
          },
          loading: () => _buildReviewSkeleton(),
          error: (_, __) => const Center(
            child: Text('Failed to load reviews'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRatingOverview(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Average rating
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                RatingBar(
                  rating: rating,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Rating breakdown
          Expanded(
            flex: 3,
            child: ref.watch(ratingBreakdownProvider(productId)).when(
              data: (breakdown) {
                // Find maximum count for scaling
                final maxCount = breakdown.values.fold(0, (max, count) => count > max ? count : max);
                
                return Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = breakdown[star] ?? 0;
                    final percent = maxCount > 0 ? count / maxCount * 1.0 : 0.0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation(
                                  star > 3 ? Colors.green : (star > 1 ? Colors.amber : Colors.red),
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load breakdown'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewCard(BuildContext context, WidgetRef ref, Review review, {bool isUserReview = false}) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final reviewService = ref.read(reviewServiceProvider);
    final userId = reviewService.currentUserId;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Review header
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: review.userPhotoUrl != null
                      ? CachedNetworkImageProvider(review.userPhotoUrl!)
                      : null,
                  child: review.userPhotoUrl == null
                      ? Text(
                          review.userName.isNotEmpty
                              ? review.userName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                // User name and verified badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (review.isVerifiedPurchase) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Verified Purchase',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        dateFormat.format(review.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Edit button for user's own review
                if (isUserReview)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showAddReviewDialog(context, ref, existingReview: review),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Rating
            RatingBar(rating: review.rating),
            
            const SizedBox(height: 8),
            
            // Review content
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14),
            ),
            
            // Review images if any
            if (review.imageUrls != null && review.imageUrls!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: review.imageUrls![index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Helpful button
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Helpful count
                if (review.totalVotes > 0)
                  Text(
                    '${review.totalHelpfulCount} of ${review.totalVotes} found this helpful',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                
                // Helpful button
                if (!isUserReview && userId != null)
                  OutlinedButton.icon(
                    onPressed: () => _markReviewHelpful(ref, review),
                    icon: Icon(
                      Icons.thumb_up_alt_outlined,
                      size: 16,
                      color: review.isMarkedHelpfulBy(userId)
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[700],
                    ),
                    label: Text(
                      'Helpful',
                      style: TextStyle(
                        fontSize: 12,
                        color: review.isMarkedHelpfulBy(userId)
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[700],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReviewSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(3, (index) => 
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 150,
            ),
          ),
        ),
      ),
    );
  }
  
  void _showAddReviewDialog(BuildContext context, WidgetRef ref, {Review? existingReview}) {
    // Check if the user is logged in first
    final reviewService = ref.read(reviewServiceProvider);
    final userId = reviewService.currentUserId;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to write a review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show the add review dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReviewDialog(
        productId: productId,
        existingReview: existingReview,
      ),
    );
  }
  
  void _markReviewHelpful(WidgetRef ref, Review review) async {
    final reviewService = ref.read(reviewServiceProvider);
    final userId = reviewService.currentUserId;
    
    if (userId == null) return;
    
    final isCurrentlyHelpful = review.isMarkedHelpfulBy(userId);
    await reviewService.markReviewHelpful(review.id, !isCurrentlyHelpful);
  }
} 