import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/cart.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/providers/product_provider.dart';
import 'package:kalakritiapp/services/firestore_service.dart';

// Cart state notifier to manage cart operations
class CartNotifier extends StateNotifier<AsyncValue<Cart>> {
  final FirestoreService _firestoreService;
  final String _userId;
  final Reader _read;

  CartNotifier(this._firestoreService, this._userId, this._read) 
      : super(const AsyncValue.loading()) {
    if (_userId.isNotEmpty) {
      loadCart();
    } else {
      state = AsyncValue.data(Cart.empty(''));
    }
  }

  // Load cart from Firestore
  Future<void> loadCart() async {
    try {
      state = const AsyncValue.loading();
      
      // Get cart document
      final cartDoc = await _firestoreService.getUserCart(_userId);
      
      if (!cartDoc.exists) {
        state = AsyncValue.data(Cart.empty(_userId));
        return;
      }
      
      // Get product IDs from cart
      final data = cartDoc.data() as Map<String, dynamic>;
      final itemsData = data['items'] as Map<String, dynamic>;
      final productIds = itemsData.keys.toList();
      
      // Fetch all products in cart
      Map<String, Product> productsMap = {};
      for (final productId in productIds) {
        final product = await _firestoreService.getProductById(productId);
        if (product != null) {
          productsMap[productId] = product;
        }
      }
      
      // Create cart with products
      final cart = Cart.fromFirestore(cartDoc, productsMap);
      state = AsyncValue.data(cart);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Add item to cart
  Future<void> addToCart(Product product, int quantity, {
    bool isRental = false,
    DateTime? rentalStartDate,
    DateTime? rentalEndDate,
  }) async {
    if (_userId.isEmpty) return;
    
    try {
      final currentState = state;
      if (!currentState.hasValue) return;
      
      final cart = currentState.value!;
      final items = Map<String, CartItem>.from(cart.items);
      
      // Update or add item
      if (items.containsKey(product.id)) {
        final existingItem = items[product.id]!;
        final newQuantity = existingItem.quantity + quantity;
        
        items[product.id] = CartItem(
          product: product,
          quantity: newQuantity,
          isRental: isRental,
          rentalStartDate: isRental ? rentalStartDate : null,
          rentalEndDate: isRental ? rentalEndDate : null,
        );
      } else {
        items[product.id] = CartItem(
          product: product,
          quantity: quantity,
          isRental: isRental,
          rentalStartDate: isRental ? rentalStartDate : null,
          rentalEndDate: isRental ? rentalEndDate : null,
        );
      }
      
      // Update state
      state = AsyncValue.data(Cart(
        userId: _userId,
        items: items,
        createdAt: cart.createdAt,
        updatedAt: Timestamp.now(),
      ));
      
      // Save to Firestore
      await _firestoreService.addToCart(_userId, product.id, quantity);
      
      // Update rental info if needed
      if (isRental && rentalStartDate != null && rentalEndDate != null) {
        await FirebaseFirestore.instance.collection('carts').doc(_userId).update({
          'isRental.${'product.id'}': true,
          'rentalStartDate.${'product.id'}': Timestamp.fromDate(rentalStartDate),
          'rentalEndDate.${'product.id'}': Timestamp.fromDate(rentalEndDate),
        });
      }
    } catch (e) {
      // Revert to previous state
      await loadCart();
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    if (_userId.isEmpty) return;
    
    try {
      final currentState = state;
      if (!currentState.hasValue) return;
      
      final cart = currentState.value!;
      final items = Map<String, CartItem>.from(cart.items);
      
      if (items.containsKey(productId)) {
        items.remove(productId);
        
        // Update state
        state = AsyncValue.data(Cart(
          userId: _userId,
          items: items,
          createdAt: cart.createdAt,
          updatedAt: Timestamp.now(),
        ));
        
        // Save to Firestore
        await _firestoreService.removeFromCart(_userId, productId);
      }
    } catch (e) {
      // Revert to previous state
      await loadCart();
    }
  }

  // Update item quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    if (_userId.isEmpty) return;
    
    try {
      final currentState = state;
      if (!currentState.hasValue) return;
      
      final cart = currentState.value!;
      final items = Map<String, CartItem>.from(cart.items);
      
      if (items.containsKey(productId)) {
        final item = items[productId]!;
        
        if (quantity <= 0) {
          await removeFromCart(productId);
          return;
        }
        
        items[productId] = CartItem(
          product: item.product,
          quantity: quantity,
          isRental: item.isRental,
          rentalStartDate: item.rentalStartDate,
          rentalEndDate: item.rentalEndDate,
        );
        
        // Update state
        state = AsyncValue.data(Cart(
          userId: _userId,
          items: items,
          createdAt: cart.createdAt,
          updatedAt: Timestamp.now(),
        ));
        
        // Save to Firestore
        await _firestoreService.updateCartItemQuantity(_userId, productId, quantity);
      }
    } catch (e) {
      // Revert to previous state
      await loadCart();
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    if (_userId.isEmpty) return;
    
    try {
      final currentState = state;
      if (!currentState.hasValue) return;
      
      final cart = currentState.value!;
      
      // Update state
      state = AsyncValue.data(Cart(
        userId: _userId,
        items: {},
        createdAt: cart.createdAt,
        updatedAt: Timestamp.now(),
      ));
      
      // Save to Firestore
      await _firestoreService.clearCart(_userId);
    } catch (e) {
      // Revert to previous state
      await loadCart();
    }
  }
}

// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<Cart>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authState = ref.watch(authStateProvider);
  
  final userId = authState.maybeWhen(
    data: (user) => user?.uid ?? '',
    orElse: () => '',
  );
  
  return CartNotifier(firestoreService, userId, ref.read);
}); 