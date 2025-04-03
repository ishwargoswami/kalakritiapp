import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kalakritiapp/models/product.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;
  
  // Add product to wishlist
  Future<bool> addToWishlist(String productId) async {
    try {
      if (_currentUserId == null) {
        return false;
      }
      
      // Check if product exists
      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) {
        return false;
      }
      
      // Add to user's wishlist in Firestore
      await _firestore.collection('users').doc(_currentUserId).update({
        'favoriteProducts': FieldValue.arrayUnion([productId]),
      });
      
      return true;
    } catch (e) {
      print('Error adding to wishlist: $e');
      return false;
    }
  }
  
  // Remove product from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    try {
      if (_currentUserId == null) {
        return false;
      }
      
      // Remove from user's wishlist in Firestore
      await _firestore.collection('users').doc(_currentUserId).update({
        'favoriteProducts': FieldValue.arrayRemove([productId]),
      });
      
      return true;
    } catch (e) {
      print('Error removing from wishlist: $e');
      return false;
    }
  }
  
  // Toggle wishlist status (add if not in wishlist, remove if already in wishlist)
  Future<bool> toggleWishlistStatus(String productId) async {
    try {
      if (_currentUserId == null) {
        return false;
      }
      
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData == null) {
        return false;
      }
      
      final List<dynamic> wishlist = userData['favoriteProducts'] ?? [];
      
      if (wishlist.contains(productId)) {
        return await removeFromWishlist(productId);
      } else {
        return await addToWishlist(productId);
      }
    } catch (e) {
      print('Error toggling wishlist status: $e');
      return false;
    }
  }
  
  // Check if a product is in the user's wishlist
  Future<bool> isInWishlist(String productId) async {
    try {
      if (_currentUserId == null) {
        return false;
      }
      
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData == null) {
        return false;
      }
      
      final List<dynamic> wishlist = userData['favoriteProducts'] ?? [];
      return wishlist.contains(productId);
    } catch (e) {
      print('Error checking wishlist status: $e');
      return false;
    }
  }
  
  // Get all products in user's wishlist
  Stream<List<String>> getWishlistIds() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }
    
    return _firestore.collection('users').doc(_currentUserId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return [];
      }
      
      final userData = snapshot.data() as Map<String, dynamic>;
      final List<dynamic> wishlist = userData['favoriteProducts'] ?? [];
      return wishlist.cast<String>().toList();
    });
  }
  
  // Get wishlist products with details
  Stream<List<Product>> getWishlistProducts() {
    return getWishlistIds().asyncMap((productIds) async {
      if (productIds.isEmpty) {
        return [];
      }
      
      // Get product details for each ID
      final List<Product> products = [];
      
      // Firestore doesn't support 'where in' queries with more than 10 items
      // So we need to batch the requests
      for (int i = 0; i < productIds.length; i += 10) {
        final end = (i + 10 < productIds.length) ? i + 10 : productIds.length;
        final batch = productIds.sublist(i, end);
        
        final querySnapshot = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        final batchProducts = querySnapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList();
        
        products.addAll(batchProducts);
      }
      
      return products;
    });
  }
} 