import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/seller_product.dart';
import 'package:kalakritiapp/models/user_role.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/providers/seller_service_provider.dart';
import 'package:kalakritiapp/services/auth_service.dart';

// Provider for seller's products
final sellerProductsProvider = StreamProvider.autoDispose<List<SellerProduct>>((ref) {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  // Get products where sellerId matches current user's UID
  final productsQuery = FirebaseFirestore.instance
      .collection('sellerProducts')
      .where('sellerId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true);
  
  return productsQuery.snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => SellerProduct.fromFirestore(doc))
        .toList(),
  );
});

// Provider for pending orders for seller's products
final sellerPendingOrdersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  // Get orders where sellerId matches current user's UID and status is pending
  final ordersQuery = FirebaseFirestore.instance
      .collection('orders')
      .where('sellerIds', arrayContains: user.uid)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true);
  
  return ordersQuery.snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => {
          'id': doc.id,
          ...doc.data(),
        })
        .toList(),
  );
});

// Provider for all orders for seller's products
final sellerAllOrdersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  // Get all orders where sellerId matches current user's UID
  final ordersQuery = FirebaseFirestore.instance
      .collection('orders')
      .where('sellerIds', arrayContains: user.uid)
      .orderBy('createdAt', descending: true);
  
  return ordersQuery.snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => {
          'id': doc.id,
          ...doc.data(),
        })
        .toList(),
  );
});

// Updated provider for seller dashboard stats - now using real-time stream
final sellerStatsProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final user = ref.watch(currentUserProvider);
  final sellerService = ref.watch(sellerServiceProvider);
  
  if (user == null) {
    return Stream.value({
      'totalProducts': 0,
      'totalOrders': 0,
      'totalRevenue': 0.0,
      'pendingOrders': 0,
      'totalCustomers': 0,
      'averageRating': 0.0,
    });
  }
  
  // Use the real-time seller stats stream
  return sellerService.getSellerStatsStream();
});

// Provider to check if current user is a seller
final isSellerProvider = FutureProvider.autoDispose<bool>((ref) async {
  // Always return true to allow all users to be sellers
  return true;
}); 