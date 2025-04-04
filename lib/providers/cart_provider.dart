import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/cart_item.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/services/firestore_service.dart';

// Firestore service provider
final cartFirestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Cart items provider
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  return CartNotifier(ref, user?.uid);
});

// Cart total price provider
final cartTotalProvider = Provider<double>((ref) {
  final cartItems = ref.watch(cartProvider);
  
  return cartItems.fold(0, (total, item) {
    if (item.isRental && item.rentalStartDate != null && item.rentalEndDate != null) {
      // For rental items, calculate based on rental duration
      return total + item.totalRentalPrice;
    } else {
      // For regular purchases
      return total + (item.price * item.quantity);
    }
  });
});

// Cart item count provider
final cartItemCountProvider = Provider<int>((ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.fold(
    0, 
    (total, item) => total + item.quantity
  );
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  final Ref _ref;
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CartNotifier(this._ref, this._userId) : super([]) {
    if (_userId != null) {
      _loadCartItems();
    }
  }

  Future<void> _loadCartItems() async {
    if (_userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .get();

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return CartItem.fromMap(doc.id, data);
      }).toList();

      state = items;
    } catch (e) {
      print('Error loading cart items: $e');
    }
  }

  Future<void> addToCart(
    Product product, 
    int quantity, {
    bool isRental = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_userId == null) return;

    // Check if the product is already in the cart
    final existingIndex = state.indexWhere((item) => 
      item.productId == product.id && item.isRental == isRental
    );

    try {
      if (existingIndex >= 0) {
        // Update existing item
        final item = state[existingIndex];
        final newQuantity = item.quantity + quantity;
        
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('cart')
            .doc(item.id)
            .update({'quantity': newQuantity});

        state = [
          ...state.sublist(0, existingIndex),
          item.copyWith(quantity: newQuantity),
          ...state.sublist(existingIndex + 1),
        ];
      } else {
        // Add new item
        final cartItem = CartItem(
          id: '', // Will be set after Firestore creates the document
          productId: product.id,
          productName: product.name,
          imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
          price: isRental ? (product.rentalPrice ?? product.price * 0.1) : product.price,
          quantity: quantity,
          isRental: isRental,
          rentalStartDate: startDate,
          rentalEndDate: endDate,
          artisanName: product.artisanName,
          sellerId: product.artisanId,
        );

        final docRef = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('cart')
            .add(cartItem.toMap());

        state = [...state, cartItem.copyWith(id: docRef.id)];
      }
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (_userId == null) return;
    
    final index = state.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .doc(itemId)
          .update({'quantity': quantity});

      state = [
        ...state.sublist(0, index),
        state[index].copyWith(quantity: quantity),
        ...state.sublist(index + 1),
      ];
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Future<void> removeFromCart(String itemId) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .doc(itemId)
          .delete();

      state = state.where((item) => item.id != itemId).toList();
    } catch (e) {
      print('Error removing from cart: $e');
    }
  }

  Future<void> clearCart() async {
    if (_userId == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      state = [];
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  Future<void> updateRentalDates(String itemId, DateTime startDate, DateTime endDate) async {
    if (_userId == null) return;
    
    final index = state.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .doc(itemId)
          .update({
            'rentalStartDate': Timestamp.fromDate(startDate),
            'rentalEndDate': Timestamp.fromDate(endDate),
          });

      state = [
        ...state.sublist(0, index),
        state[index].copyWith(
          rentalStartDate: startDate,
          rentalEndDate: endDate,
        ),
        ...state.sublist(index + 1),
      ];
    } catch (e) {
      print('Error updating rental dates: $e');
    }
  }
} 