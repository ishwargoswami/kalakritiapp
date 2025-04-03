import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kalakritiapp/models/category.dart';
import 'package:kalakritiapp/models/product.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _productsCollection => _firestore.collection('products');
  CollectionReference get _categoriesCollection => _firestore.collection('categories');
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _ordersCollection => _firestore.collection('orders');
  CollectionReference get _rentalsCollection => _firestore.collection('rentals');
  CollectionReference get _cartCollection => _firestore.collection('carts');

  // PRODUCTS

  // Get all products
  Future<List<Product>> getProducts() async {
    final QuerySnapshot snapshot = await _productsCollection.get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  // Get featured products
  Future<List<Product>> getFeaturedProducts() async {
    final QuerySnapshot snapshot = await _productsCollection
        .where('isFeatured', isEqualTo: true)
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  // Get new arrivals
  Future<List<Product>> getNewArrivals() async {
    final QuerySnapshot snapshot = await _productsCollection
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final QuerySnapshot snapshot = await _productsCollection
        .where('categoryId', isEqualTo: categoryId)
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    final DocumentSnapshot doc = await _productsCollection.doc(productId).get();
    if (doc.exists) {
      return Product.fromFirestore(doc);
    }
    return null;
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      // For basic search, we'll fetch products and filter client-side
      final querySnapshot = await _firestore
          .collection('products')
          .get();
      
      final allProducts = querySnapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
      
      // Filter products that contain the query in name, description, or artisan name
      final lowercaseQuery = query.toLowerCase();
      return allProducts.where((product) {
        return product.name.toLowerCase().contains(lowercaseQuery) ||
                product.description.toLowerCase().contains(lowercaseQuery) ||
                product.artisanName.toLowerCase().contains(lowercaseQuery) ||
                product.category.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // CATEGORIES

  // Get all categories
  Future<List<Category>> getCategories() async {
    final QuerySnapshot snapshot = await _categoriesCollection
        .orderBy('displayOrder')
        .get();
    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  // Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    final DocumentSnapshot doc = await _categoriesCollection.doc(categoryId).get();
    if (doc.exists) {
      return Category.fromFirestore(doc);
    }
    return null;
  }

  // CART

  // Get user cart
  Future<DocumentSnapshot> getUserCart(String userId) async {
    return await _cartCollection.doc(userId).get();
  }

  // Add item to cart
  Future<void> addToCart(String userId, String productId, int quantity) async {
    final cartRef = _cartCollection.doc(userId);
    final cartDoc = await cartRef.get();
    
    if (cartDoc.exists) {
      // Cart exists, update it
      await cartRef.update({
        'items.$productId': FieldValue.increment(quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new cart
      await cartRef.set({
        'userId': userId,
        'items': {productId: quantity},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update cart item with rental info
  Future<void> updateCartItem(
    String userId,
    String productId, {
    required int quantity,
    bool isRental = false,
    DateTime? rentalStartDate,
    DateTime? rentalEndDate,
  }) async {
    final cartRef = _cartCollection.doc(userId);
    final cartDoc = await cartRef.get();
    
    Map<String, dynamic> itemData = {
      'quantity': quantity,
      'isRental': isRental,
    };
    
    if (isRental) {
      if (rentalStartDate != null) {
        itemData['rentalStartDate'] = Timestamp.fromDate(rentalStartDate);
      }
      if (rentalEndDate != null) {
        itemData['rentalEndDate'] = Timestamp.fromDate(rentalEndDate);
      }
    }
    
    if (cartDoc.exists) {
      // Cart exists, update it
      await cartRef.update({
        'items.$productId': itemData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new cart
      await cartRef.set({
        'userId': userId,
        'items': {productId: itemData},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String userId, String productId) async {
    final cartRef = _cartCollection.doc(userId);
    
    await cartRef.update({
      'items.$productId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(String userId, String productId, int quantity) async {
    final cartRef = _cartCollection.doc(userId);
    
    await cartRef.update({
      'items.$productId.quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Clear cart
  Future<void> clearCart(String userId) async {
    await _cartCollection.doc(userId).update({
      'items': {},
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ORDERS

  // Create order
  Future<DocumentReference> createOrder(Map<String, dynamic> orderData) async {
    return await _ordersCollection.add(orderData);
  }

  // Get user orders
  Future<QuerySnapshot> getUserOrders(String userId) async {
    return await _ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
  }

  // RENTALS

  // Create rental
  Future<DocumentReference> createRental(Map<String, dynamic> rentalData) async {
    return await _rentalsCollection.add(rentalData);
  }

  // Get user rentals
  Future<QuerySnapshot> getUserRentals(String userId) async {
    return await _rentalsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('rentDate', descending: true)
        .get();
  }

  // Get best selling products
  Future<List<Product>> getBestSellingProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .orderBy('totalSales', descending: true)
          .limit(10)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting best selling products: $e');
      return [];
    }
  }

  // Get products by category name
  Future<List<Product>> getProductsByCategoryName(String categoryName) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: categoryName)
          .limit(10)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting products by category name: $e');
      return [];
    }
  }
} 