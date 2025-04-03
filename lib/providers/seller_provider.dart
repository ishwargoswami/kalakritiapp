import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/seller_product.dart';
import 'package:kalakritiapp/models/user_role.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
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

// Provider for seller dashboard stats
final sellerStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return {
      'totalProducts': 0,
      'totalOrders': 0,
      'totalRevenue': 0.0,
      'pendingOrders': 0,
    };
  }
  
  final firestore = FirebaseFirestore.instance;
  
  // Get total products count
  final productsSnapshot = await firestore
      .collection('sellerProducts')
      .where('sellerId', isEqualTo: user.uid)
      .get();
  
  // Get orders data
  final ordersSnapshot = await firestore
      .collection('orders')
      .where('sellerIds', arrayContains: user.uid)
      .get();
  
  // Get pending orders count
  final pendingOrdersSnapshot = await firestore
      .collection('orders')
      .where('sellerIds', arrayContains: user.uid)
      .where('status', isEqualTo: 'pending')
      .get();
  
  // Calculate total revenue from orders
  double totalRevenue = 0.0;
  for (final doc in ordersSnapshot.docs) {
    final orderData = doc.data();
    final List<dynamic> items = orderData['items'] ?? [];
    
    for (final item in items) {
      if (item['sellerId'] == user.uid) {
        totalRevenue += (item['price'] * item['quantity']);
      }
    }
  }
  
  return {
    'totalProducts': productsSnapshot.docs.length,
    'totalOrders': ordersSnapshot.docs.length,
    'totalRevenue': totalRevenue,
    'pendingOrders': pendingOrdersSnapshot.docs.length,
  };
});

// Provider to check if current user is a seller
final isSellerProvider = FutureProvider.autoDispose<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final role = await authService.getCurrentUserRole();
  return role == UserRole.seller;
}); 