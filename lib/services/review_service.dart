import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kalakritiapp/models/review.dart';
import 'package:kalakritiapp/services/firestore_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  // Collection references
  final CollectionReference _reviewsCollection = 
      FirebaseFirestore.instance.collection('reviews');
  final CollectionReference _productsCollection = 
      FirebaseFirestore.instance.collection('products');
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Get user reviews for a product
  Stream<List<Review>> getReviewsForProduct(String productId) {
    return _reviewsCollection
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }
  
  // Get review by ID
  Future<Review?> getReview(String reviewId) async {
    try {
      final docSnapshot = await _reviewsCollection.doc(reviewId).get();
      if (docSnapshot.exists) {
        return Review.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print('Error getting review: $e');
      return null;
    }
  }
  
  // Add a new review
  Future<Review?> addReview({
    required String productId,
    required double rating,
    required String comment,
    List<String>? imageUrls,
    bool isVerifiedPurchase = false,
  }) async {
    try {
      // Validate user is logged in
      if (currentUserId == null) {
        throw Exception('User must be logged in to add a review');
      }
      
      // Get user details
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData == null) {
        throw Exception('User profile not found');
      }
      
      // Check if user already reviewed this product
      final existingReviews = await _reviewsCollection
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      if (existingReviews.docs.isNotEmpty) {
        // Update existing review instead of creating a new one
        final existingReview = Review.fromFirestore(existingReviews.docs.first);
        
        final updatedReview = existingReview.copyWith(
          rating: rating,
          comment: comment,
          imageUrls: imageUrls,
          createdAt: DateTime.now(),
        );
        
        await _reviewsCollection.doc(existingReview.id).update(updatedReview.toFirestore());
        
        // Update product rating
        await _updateProductRating(productId);
        
        return updatedReview;
      }
      
      // Create new review
      final newReview = Review(
        id: '',  // This will be replaced with the Firestore ID
        productId: productId,
        userId: currentUserId!,
        userName: userData['name'] ?? 'Anonymous',
        userPhotoUrl: userData['photoURL'],
        rating: rating,
        comment: comment,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        isVerifiedPurchase: isVerifiedPurchase,
        helpfulCount: {},
      );
      
      // Add to Firestore
      final docRef = await _reviewsCollection.add(newReview.toFirestore());
      
      // Update product rating
      await _updateProductRating(productId);
      
      // Return the new review with the ID
      return newReview.copyWith(id: docRef.id);
    } catch (e) {
      print('Error adding review: $e');
      return null;
    }
  }
  
  // Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      // Validate user is logged in
      if (currentUserId == null) {
        return false;
      }
      
      // Get the review to check if it belongs to the current user
      final reviewDoc = await _reviewsCollection.doc(reviewId).get();
      
      if (!reviewDoc.exists) {
        return false;
      }
      
      final review = Review.fromFirestore(reviewDoc);
      
      // Check if the review belongs to the current user
      if (review.userId != currentUserId) {
        return false;
      }
      
      // Delete the review
      await _reviewsCollection.doc(reviewId).delete();
      
      // Update product rating
      await _updateProductRating(review.productId);
      
      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
  
  // Mark a review as helpful or not helpful
  Future<bool> markReviewHelpful(String reviewId, bool isHelpful) async {
    try {
      // Validate user is logged in
      if (currentUserId == null) {
        return false;
      }
      
      // Update the review's helpful count
      await _reviewsCollection.doc(reviewId).update({
        'helpfulCount.$currentUserId': isHelpful ? 1 : 0,
      });
      
      return true;
    } catch (e) {
      print('Error marking review as helpful: $e');
      return false;
    }
  }
  
  // Update product rating based on all reviews
  Future<void> _updateProductRating(String productId) async {
    try {
      // Get all reviews for the product
      final reviewsSnapshot = await _reviewsCollection
          .where('productId', isEqualTo: productId)
          .get();
      
      final reviews = reviewsSnapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
      
      // Calculate new rating
      double totalRating = 0;
      for (final review in reviews) {
        totalRating += review.rating;
      }
      
      final int reviewCount = reviews.length;
      final double averageRating = reviewCount > 0 ? totalRating / reviewCount : 0;
      
      // Update product
      await _productsCollection.doc(productId).update({
        'rating': averageRating,
        'ratingCount': reviewCount,
      });
    } catch (e) {
      print('Error updating product rating: $e');
    }
  }
  
  // Check if the current user has purchased this product
  Future<bool> hasUserPurchasedProduct(String productId) async {
    try {
      if (currentUserId == null) {
        return false;
      }
      
      // Check orders collection
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'completed')
          .get();
      
      // Check each order for the product
      for (final doc in ordersSnapshot.docs) {
        final orderData = doc.data();
        final items = orderData['items'] as List<dynamic>?;
        
        if (items != null) {
          for (final item in items) {
            if (item['productId'] == productId) {
              return true;
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking purchase: $e');
      return false;
    }
  }
  
  // Get the current user's review for a product
  Future<Review?> getUserReviewForProduct(String productId) async {
    try {
      if (currentUserId == null) {
        return null;
      }
      
      final reviewsSnapshot = await _reviewsCollection
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();
      
      if (reviewsSnapshot.docs.isNotEmpty) {
        return Review.fromFirestore(reviewsSnapshot.docs.first);
      }
      
      return null;
    } catch (e) {
      print('Error getting user review: $e');
      return null;
    }
  }
} 