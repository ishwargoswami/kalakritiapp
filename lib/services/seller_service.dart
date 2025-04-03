import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kalakritiapp/models/seller_product.dart';
import 'package:uuid/uuid.dart';

class SellerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get the current seller's ID
  String? get currentSellerId => _auth.currentUser?.uid;
  
  // Get a stream of seller products
  Stream<List<SellerProduct>> getSellerProducts() {
    final String? sellerId = currentSellerId;
    if (sellerId == null) return Stream.value([]);
    
    return _firestore
        .collection('sellerProducts')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SellerProduct.fromFirestore(doc))
            .toList());
  }
  
  // Add a new product
  Future<String> addProduct({
    required String name,
    required String description,
    required double price,
    required int quantity,
    required List<File> images,
    required List<String> categories,
    String? size,
    String? weight,
    String? material,
    Map<String, dynamic>? specifications,
    double discountPercentage = 0.0,
  }) async {
    try {
      final String? sellerId = currentSellerId;
      if (sellerId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get seller name from user document
      final userDoc = await _firestore.collection('users').doc(sellerId).get();
      final userData = userDoc.data();
      final String sellerName = userData?['name'] ?? 'Unknown Seller';
      
      // Upload images to storage
      List<String> imageUrls = [];
      for (final image in images) {
        final String imageName = '${const Uuid().v4()}.jpg';
        final ref = _storage.ref().child('seller_products/$sellerId/$imageName');
        
        await ref.putFile(image);
        final String downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
      
      // Create product document in Firestore for seller view
      final productData = {
        'sellerId': sellerId,
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'imageUrls': imageUrls,
        'categories': categories,
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'specifications': specifications,
        'size': size,
        'weight': weight,
        'material': material,
        'discountPercentage': discountPercentage,
        'isFeatured': false,
        'viewCount': 0,
        'orderCount': 0,
        'averageRating': 0.0,
        'reviewCount': 0,
        'sellerName': sellerName,
        'isApproved': false, // All new products need approval first
      };
      
      // Add to sellerProducts collection
      final docRef = await _firestore.collection('sellerProducts').add(productData);
      
      // Prepare data for products collection (buyer-visible)
      final buyerProductData = {
        ...productData,
        'productId': docRef.id, // Reference to the seller product
        'rentalPrice': price * 0.1, // 10% of sale price
        'isAvailableForRent': true,
        'isAvailableForSale': true,
        'categoryId': categories.isNotEmpty ? categories[0].toLowerCase() : 'other',
        'category': categories.isNotEmpty ? categories[0] : 'Other',
        'artisanId': sellerId,
        'artisanName': sellerName,
        'artisanLocation': userData?['businessAddress'] ?? 'India',
        'stock': quantity,
        'totalSales': 0,
      };
      
      // Add to products collection (visible to buyers)
      await _firestore.collection('products').add(buyerProductData);
      
      return docRef.id;
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }
  
  // Add a new product with image URLs instead of file uploads
  Future<String> addProductWithUrls({
    required String name,
    required String description,
    required double price,
    required int quantity,
    required List<String> imageUrls,
    required List<String> categories,
    String? size,
    String? weight,
    String? material,
    Map<String, dynamic>? specifications,
    double discountPercentage = 0.0,
  }) async {
    try {
      final String? sellerId = currentSellerId;
      if (sellerId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get seller name from user document
      final userDoc = await _firestore.collection('users').doc(sellerId).get();
      final userData = userDoc.data();
      final String sellerName = userData?['name'] ?? 'Unknown Seller';
      
      // Create product document in Firestore for seller view
      final productData = {
        'sellerId': sellerId,
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'imageUrls': imageUrls,
        'categories': categories,
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'specifications': specifications,
        'size': size,
        'weight': weight,
        'material': material,
        'discountPercentage': discountPercentage,
        'isFeatured': false,
        'viewCount': 0,
        'orderCount': 0,
        'averageRating': 0.0,
        'reviewCount': 0,
        'sellerName': sellerName,
        'isApproved': false, // All new products need approval first
      };
      
      // Add to sellerProducts collection
      final docRef = await _firestore.collection('sellerProducts').add(productData);
      
      // Prepare data for products collection (buyer-visible)
      final buyerProductData = {
        ...productData,
        'productId': docRef.id, // Reference to the seller product
        'rentalPrice': price * 0.1, // 10% of sale price
        'isAvailableForRent': true,
        'isAvailableForSale': true,
        'categoryId': categories.isNotEmpty ? categories[0].toLowerCase() : 'other',
        'category': categories.isNotEmpty ? categories[0] : 'Other',
        'artisanId': sellerId,
        'artisanName': sellerName,
        'artisanLocation': userData?['businessAddress'] ?? 'India',
        'stock': quantity,
        'totalSales': 0,
      };
      
      // Add to products collection (visible to buyers)
      await _firestore.collection('products').add(buyerProductData);
      
      return docRef.id;
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }
  
  // Update an existing product
  Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    int? quantity,
    List<File>? newImages,
    List<String>? imagesToKeep,
    List<String>? categories,
    bool? isAvailable,
    String? size,
    String? weight,
    String? material,
    Map<String, dynamic>? specifications,
    double? discountPercentage,
  }) async {
    try {
      final String? sellerId = currentSellerId;
      if (sellerId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get current product data
      final docSnapshot = await _firestore.collection('sellerProducts').doc(productId).get();
      if (!docSnapshot.exists) {
        throw Exception('Product not found');
      }
      
      final productData = docSnapshot.data()!;
      
      // Verify seller owns this product
      if (productData['sellerId'] != sellerId) {
        throw Exception('You do not have permission to update this product');
      }
      
      // Handle image updates
      List<String> updatedImageUrls = [];
      
      // Keep existing images that are marked to keep
      if (imagesToKeep != null && imagesToKeep.isNotEmpty) {
        updatedImageUrls.addAll(imagesToKeep);
      }
      
      // Upload new images if any
      if (newImages != null && newImages.isNotEmpty) {
        for (final image in newImages) {
          final String imageName = '${const Uuid().v4()}.jpg';
          final ref = _storage.ref().child('seller_products/$sellerId/$imageName');
          
          await ref.putFile(image);
          final String downloadUrl = await ref.getDownloadURL();
          updatedImageUrls.add(downloadUrl);
        }
      }
      
      // Prepare update data
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (quantity != null) updateData['quantity'] = quantity;
      if (updatedImageUrls.isNotEmpty) updateData['imageUrls'] = updatedImageUrls;
      if (categories != null) updateData['categories'] = categories;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;
      if (size != null) updateData['size'] = size;
      if (weight != null) updateData['weight'] = weight;
      if (material != null) updateData['material'] = material;
      if (specifications != null) updateData['specifications'] = specifications;
      if (discountPercentage != null) updateData['discountPercentage'] = discountPercentage;
      
      // Update in firestore
      await _firestore.collection('sellerProducts').doc(productId).update(updateData);
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }
  
  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      final String? sellerId = currentSellerId;
      if (sellerId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get current product data
      final docSnapshot = await _firestore.collection('sellerProducts').doc(productId).get();
      if (!docSnapshot.exists) {
        throw Exception('Product not found');
      }
      
      final productData = docSnapshot.data()!;
      
      // Verify seller owns this product
      if (productData['sellerId'] != sellerId) {
        throw Exception('You do not have permission to delete this product');
      }
      
      // Delete the product
      await _firestore.collection('sellerProducts').doc(productId).delete();
      
      // Delete images from storage if needed
      // Note: We're keeping this commented to prevent orphaned data,
      // but in a real production app you might want to clean up storage
      
      // final List<String> imageUrls = List<String>.from(productData['imageUrls'] ?? []);
      // for (final imageUrl in imageUrls) {
      //   if (imageUrl.contains('seller_products/$sellerId')) {
      //     try {
      //       final ref = _storage.refFromURL(imageUrl);
      //       await ref.delete();
      //     } catch (e) {
      //       print('Error deleting image: $e');
      //     }
      //   }
      // }
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }
  
  // Get seller's orders
  Stream<List<Map<String, dynamic>>> getSellerOrders() {
    final String? sellerId = currentSellerId;
    if (sellerId == null) return Stream.value([]);
    
    return _firestore
        .collection('orders')
        .where('sellerIds', arrayContains: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }
  
  // Update order status for a specific item in an order
  Future<void> updateOrderItemStatus({
    required String orderId,
    required String orderItemId,
    required String status,
  }) async {
    try {
      final String? sellerId = currentSellerId;
      if (sellerId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get the order
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }
      
      final orderData = orderDoc.data()!;
      
      // Check if the seller is associated with this order
      final List<dynamic> sellerIds = orderData['sellerIds'] ?? [];
      if (!sellerIds.contains(sellerId)) {
        throw Exception('You do not have permission to update this order');
      }
      
      // Update the item status
      final List<dynamic> items = orderData['items'] ?? [];
      bool found = false;
      
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item['id'] == orderItemId && item['sellerId'] == sellerId) {
          // Update in Firestore using array update
          await _firestore.collection('orders').doc(orderId).update({
            'items.$i.status': status,
            'items.$i.updatedAt': FieldValue.serverTimestamp(),
          });
          found = true;
          break;
        }
      }
      
      if (!found) {
        throw Exception('Order item not found or does not belong to you');
      }
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }
  
  // Get seller statistics
  Future<Map<String, dynamic>> getSellerStats() async {
    try {
      final String? sellerId = currentSellerId;
      if (sellerId == null) {
        return {
          'totalProducts': 0,
          'totalOrders': 0,
          'totalRevenue': 0.0,
          'pendingOrders': 0,
        };
      }
      
      // Get total products count
      final productsSnapshot = await _firestore
          .collection('sellerProducts')
          .where('sellerId', isEqualTo: sellerId)
          .get();
      
      // Get orders data
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('sellerIds', arrayContains: sellerId)
          .get();
      
      // Get pending orders count
      final pendingOrdersSnapshot = await _firestore
          .collection('orders')
          .where('sellerIds', arrayContains: sellerId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      // Calculate total revenue from orders
      double totalRevenue = 0.0;
      for (final doc in ordersSnapshot.docs) {
        final orderData = doc.data();
        final List<dynamic> items = orderData['items'] ?? [];
        
        for (final item in items) {
          if (item['sellerId'] == sellerId) {
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
    } catch (e) {
      print('Error getting seller stats: $e');
      return {
        'totalProducts': 0,
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'pendingOrders': 0,
      };
    }
  }
} 