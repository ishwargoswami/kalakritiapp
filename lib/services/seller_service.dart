import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kalakritiapp/models/seller_product.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:kalakritiapp/models/order.dart' as app_model;
import 'package:kalakritiapp/utils/firebase_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class SellerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get the current seller's ID
  String? get currentSellerId => _auth.currentUser?.uid;
  
  // Check if user is authenticated as a seller
  bool get isSellerAuthenticated => 
      _auth.currentUser != null;
  
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
    required List<XFile> images,
    required List<String> categories,
    String? size,
    String? weight,
    String? material,
    Map<String, dynamic>? specifications,
    double discountPercentage = 0.0,
    bool isFeatured = false,
  }) async {
    try {
      if (!isSellerAuthenticated) {
        throw 'User not authenticated as a seller';
      }
      
      // Upload images first
      List<String> imageUrls = [];
      for (var image in images) {
        final imageUrl = await _uploadProductImage(image);
        imageUrls.add(imageUrl);
      }
      
      // Create product data
      final productId = const Uuid().v4();
      final productData = {
        'id': productId,
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'imageUrls': imageUrls,
        'categories': categories,
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'specifications': specifications ?? {},
        'size': size,
        'weight': weight,
        'material': material,
        'discountPercentage': discountPercentage,
        'isFeatured': isFeatured,
        'rating': 0.0,
        'reviewCount': 0,
        'sellerId': currentSellerId,
        'isApproved': false,
      };
      
      // Add to Firestore
      await _firestore
          .collection(FirebaseConstants.productsCollection)
          .doc(productId)
          .set(productData);
          
      // Add to seller recent activities
      await _addRecentActivity(
        type: 'product',
        title: 'Product Added',
        description: 'You added a new product: $name',
      );
      
      return productId;
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }
  
  // Upload product image to Firebase Storage
  Future<String> _uploadProductImage(XFile image) async {
    try {
      final path = 'products/${currentSellerId}/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final ref = _storage.ref().child(path);
      
      final file = File(image.path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      // Get download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
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
    List<XFile>? newImages,
    List<String>? existingImageUrls,
    List<String>? categories,
    bool? isAvailable,
    String? size,
    String? weight,
    String? material,
    Map<String, dynamic>? specifications,
    double? discountPercentage,
    bool? isFeatured,
  }) async {
    try {
      if (!isSellerAuthenticated) {
        throw 'User not authenticated as a seller';
      }
      
      // Get product to update
      final productDoc = await _firestore
          .collection(FirebaseConstants.productsCollection)
          .doc(productId)
          .get();
      
      if (!productDoc.exists) {
        throw 'Product not found';
      }
      
      // Verify seller owns this product
      final product = SellerProduct.fromMap(productDoc.data()!);
      if (product.sellerId != currentSellerId) {
        throw 'You do not have permission to update this product';
      }
      
      // Handle image uploads if new images provided
      List<String> updatedImageUrls = existingImageUrls ?? product.imageUrls;
      if (newImages != null && newImages.isNotEmpty) {
        for (var image in newImages) {
          final imageUrl = await _uploadProductImage(image);
          updatedImageUrls.add(imageUrl);
        }
      }
      
      // Create update data
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Only include fields that should be updated
      if (name != null) updateData['name'] = name;
      if (price != null) updateData['price'] = price;
      if (quantity != null) updateData['quantity'] = quantity;
      if (description != null) updateData['description'] = description;
      if (categories != null) updateData['categories'] = categories;
      if (updatedImageUrls.isNotEmpty) updateData['imageUrls'] = updatedImageUrls;
      if (discountPercentage != null) updateData['discountPercentage'] = discountPercentage;
      if (specifications != null) updateData['specifications'] = specifications;
      if (size != null) updateData['size'] = size;
      if (weight != null) updateData['weight'] = weight;
      if (material != null) updateData['material'] = material;
      if (isFeatured != null) updateData['isFeatured'] = isFeatured;
      
      // Update in Firestore
      await _firestore
          .collection(FirebaseConstants.productsCollection)
          .doc(productId)
          .update(updateData);
          
      // Add to seller recent activities
      await _addRecentActivity(
        type: 'product',
        title: 'Product Updated',
        description: 'You updated product: ${name ?? product.name}',
      );
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }
  
  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      if (!isSellerAuthenticated) {
        throw 'User not authenticated as a seller';
      }
      
      // Get product to delete
      final productDoc = await _firestore
          .collection(FirebaseConstants.productsCollection)
          .doc(productId)
          .get();
      
      if (!productDoc.exists) {
        throw 'Product not found';
      }
      
      // Verify seller owns this product
      final product = SellerProduct.fromMap(productDoc.data()!);
      if (product.sellerId != currentSellerId) {
        throw 'You do not have permission to delete this product';
      }
      
      // Delete from Firestore
      await _firestore
          .collection(FirebaseConstants.productsCollection)
          .doc(productId)
          .delete();
          
      // Add to seller recent activities
      await _addRecentActivity(
        type: 'product',
        title: 'Product Deleted',
        description: 'You deleted product: ${product.name}',
      );
      
      // TODO: Optionally delete images from storage
      // This is left as a future improvement since Firebase Storage doesn't
      // automatically delete files when documents are deleted
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }
  
  // Get product by ID
  Future<SellerProduct?> getProductById(String productId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.productsCollection)
          .doc(productId)
          .get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id; // Add document ID
      
      return SellerProduct.fromMap(data);
    } catch (e) {
      debugPrint('Error fetching product by ID: $e');
      return null;
    }
  }
  
  // Get seller orders - Modified to use stream for real-time updates
  Stream<List<app_model.Order>> getSellerOrdersStream() {
    if (!isSellerAuthenticated) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection(FirebaseConstants.ordersCollection)
        .where('sellerIds', arrayContains: currentSellerId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID
            return app_model.Order.fromMap(data);
          }).toList();
        });
  }
  
  // Get seller order by ID
  Future<app_model.Order?> getOrderById(String orderId) async {
    try {
      final orderDoc = await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .get();
      
      if (!orderDoc.exists) return null;
      
      final data = orderDoc.data()!;
      data['id'] = orderDoc.id;
      
      final order = app_model.Order.fromMap(data);
      
      // Verify this order belongs to this seller
      if (!order.sellerIds.contains(currentSellerId)) {
        return null;
      }
      
      return order;
    } catch (e) {
      debugPrint('Error fetching order by ID: $e');
      return null;
    }
  }
  
  // Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? trackingNumber,
    String? shippingCarrier,
  }) async {
    try {
      if (!isSellerAuthenticated) {
        throw 'User not authenticated as a seller';
      }
      
      final orderDoc = await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .get();
      
      if (!orderDoc.exists) {
        throw 'Order not found';
      }
      
      final orderData = orderDoc.data()!;
      final order = app_model.Order.fromMap({...orderData, 'id': orderId});
      
      // Verify this order belongs to this seller
      if (!order.sellerIds.contains(currentSellerId)) {
        throw 'You do not have permission to update this order';
      }
      
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (trackingNumber != null) {
        updateData['trackingNumber'] = trackingNumber;
      }
      
      if (shippingCarrier != null) {
        updateData['shippingCarrier'] = shippingCarrier;
      }
      
      // Update order
      await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .update(updateData);
          
      // Add to seller recent activities
      await _addRecentActivity(
        type: 'order',
        title: 'Order Status Updated',
        description: 'You updated order #${order.orderNumber} to: $status',
      );
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }
  
  // Get real-time seller statistics
  Stream<Map<String, dynamic>> getSellerStatsStream() {
    if (!isSellerAuthenticated) {
      return Stream.value({});
    }
    
    // Combine multiple streams for complete stats
    final productsStream = _firestore
        .collection(FirebaseConstants.productsCollection)
        .where('sellerId', isEqualTo: currentSellerId)
        .snapshots();
        
    final ordersStream = _firestore
        .collection(FirebaseConstants.ordersCollection)
        .where('sellerIds', arrayContains: currentSellerId)
        .snapshots();
    
    // Combine the streams and transform the data using rxdart's CombineLatestStream
    return CombineLatestStream.combine2<QuerySnapshot, QuerySnapshot, Map<String, dynamic>>(
      productsStream, 
      ordersStream,
      (productsSnapshot, ordersSnapshot) {
        // Process products
        final products = productsSnapshot.docs
            .map((doc) => SellerProduct.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
            
        final totalProducts = products.length;
        
        // Calculate average rating
        double totalRating = 0;
        int ratedProductsCount = 0;
        
        for (var product in products) {
          if (product.reviewCount > 0) {
            totalRating += product.rating;
            ratedProductsCount++;
          }
        }
        
        final averageRating = ratedProductsCount > 0 
            ? totalRating / ratedProductsCount 
            : 0.0;
        
        // Process orders
        final orders = ordersSnapshot.docs
            .map((doc) => app_model.Order.fromMap({...(doc.data() as Map<String, dynamic>), 'id': doc.id}))
            .toList();
            
        final totalOrders = orders.length;
        
        // Count pending orders
        int pendingOrders = 0;
        double totalRevenue = 0;
        Set<String> customers = {};
        
        for (var order in orders) {
          if (order.status == 'pending' || order.status == 'processing' || order.status == 'confirmed') {
            pendingOrders++;
          }
          
          // Add to total revenue (only count this seller's items)
          for (var item in order.items) {
            if (item.sellerId == currentSellerId) {
              totalRevenue += item.price * item.quantity;
            }
          }
          
          // Add to unique customers
          customers.add(order.userId);
        }
        
        return {
          'totalProducts': totalProducts,
          'totalOrders': totalOrders,
          'pendingOrders': pendingOrders,
          'totalRevenue': totalRevenue,
          'averageRating': averageRating,
          'totalCustomers': customers.length,
        };
      }
    );
  }
  
  // New methods for real-time data and analytics
  
  // Get revenue analytics
  Future<Map<String, dynamic>> getRevenueAnalytics() async {
    try {
      if (!isSellerAuthenticated) {
        throw 'User not authenticated as a seller';
      }
      
      // Get all orders for this seller
      final ordersQuery = await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .where('sellerIds', arrayContains: currentSellerId)
          .orderBy('orderDate', descending: true)
          .get();
      
      // Calculate time periods
      final now = DateTime.now();
      final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = (now.month == 1)
          ? DateTime(now.year - 1, 12, 1)
          : DateTime(now.year, now.month - 1, 1);
      
      double thisWeekRevenue = 0;
      double lastWeekRevenue = 0;
      double thisMonthRevenue = 0;
      double lastMonthRevenue = 0;
      double totalRevenue = 0;
      
      // Process each order
      for (var doc in ordersQuery.docs) {
        final order = app_model.Order.fromMap({...doc.data(), 'id': doc.id});
        final orderDate = order.orderDate;
        
        if (orderDate == null) continue;
        
        // Calculate revenue for this seller from this order
        double orderRevenue = 0;
        for (var item in order.items) {
          if (item.sellerId == currentSellerId) {
            orderRevenue += item.price * item.quantity;
          }
        }
        
        totalRevenue += orderRevenue;
        
        // Add to specific time periods
        if (orderDate.isAfter(thisWeekStart)) {
          thisWeekRevenue += orderRevenue;
        } else if (orderDate.isAfter(lastWeekStart)) {
          lastWeekRevenue += orderRevenue;
        }
        
        if (orderDate.isAfter(thisMonthStart)) {
          thisMonthRevenue += orderRevenue;
        } else if (orderDate.isAfter(lastMonthStart)) {
          lastMonthRevenue += orderRevenue;
        }
      }
      
      // Calculate growth percentages
      double weeklyGrowth = lastWeekRevenue > 0
          ? ((thisWeekRevenue - lastWeekRevenue) / lastWeekRevenue) * 100
          : 0;
      
      double monthlyGrowth = lastMonthRevenue > 0
          ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100
          : 0;
      
      // Calculate annualized growth rate
      // Simplified calculation - would need more data for accuracy
      double growthRate = 0;
      if (ordersQuery.docs.isNotEmpty) {
        // Get earliest order date
        final orderedDates = ordersQuery.docs
            .map((doc) => (doc.data()['orderDate'] as Timestamp?)?.toDate())
            .where((date) => date != null)
            .cast<DateTime>()
            .toList();
        
        if (orderedDates.isNotEmpty) {
          orderedDates.sort();
          final firstOrderDate = orderedDates.first;
          final daysSinceFirst = now.difference(firstOrderDate).inDays;
          
          if (daysSinceFirst > 0) {
            // Annualized growth rate calculation
            growthRate = (totalRevenue / daysSinceFirst) * 365 / 100;
          }
        }
      }
      
      return {
        'thisWeekRevenue': thisWeekRevenue,
        'lastWeekRevenue': lastWeekRevenue,
        'thisMonthRevenue': thisMonthRevenue,
        'lastMonthRevenue': lastMonthRevenue,
        'totalRevenue': totalRevenue,
        'weeklyGrowth': weeklyGrowth,
        'monthlyGrowth': monthlyGrowth,
        'growthRate': growthRate,
      };
    } catch (e) {
      debugPrint('Error getting revenue analytics: $e');
      return {};
    }
  }
  
  // Get monthly revenue data for charts
  Future<List<Map<String, dynamic>>> getMonthlyRevenue() async {
    try {
      if (!isSellerAuthenticated) {
        throw 'User not authenticated as a seller';
      }
      
      // Get orders for the last 6 months
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      
      final ordersQuery = await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .where('sellerIds', arrayContains: currentSellerId)
          .where('orderDate', isGreaterThan: sixMonthsAgo)
          .orderBy('orderDate', descending: true)
          .get();
      
      // Group by month
      Map<String, double> monthlyData = {};
      
      for (var doc in ordersQuery.docs) {
        final order = app_model.Order.fromMap({...doc.data(), 'id': doc.id});
        final orderDate = order.orderDate;
        
        if (orderDate == null) continue;
        
        // Calculate revenue for this seller from this order
        double orderRevenue = 0;
        for (var item in order.items) {
          if (item.sellerId == currentSellerId) {
            orderRevenue += item.price * item.quantity;
          }
        }
        
        // Get month key (e.g., "2023-01")
        final monthKey = DateFormat('MMM').format(orderDate);
        
        // Add to monthly totals
        monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + orderRevenue;
      }
      
      // Convert to list format for chart
      final result = monthlyData.entries.map((entry) {
        return {
          'month': entry.key,
          'amount': entry.value,
        };
      }).toList();
      
      // Sort data by month
      result.sort((a, b) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final aIndex = months.indexOf(a['month'] as String);
        final bIndex = months.indexOf(b['month'] as String);
        return aIndex.compareTo(bIndex);
      });
      
      return result;
    } catch (e) {
      debugPrint('Error getting monthly revenue: $e');
      return [];
    }
  }
  
  // Get top performing products
  Future<List<Map<String, dynamic>>> getTopProducts() async {
    try {
      if (!isSellerAuthenticated) {
        throw 'User not authenticated as a seller';
      }
      
      // Get all products for this seller
      final productsQuery = await _firestore
          .collection(FirebaseConstants.productsCollection)
          .where('sellerId', isEqualTo: currentSellerId)
          .get();
      
      // Get all orders containing products from this seller
      final ordersQuery = await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .where('sellerIds', arrayContains: currentSellerId)
          .get();
      
      // Process sales data
      Map<String, Map<String, dynamic>> productData = {};
      
      // Initialize with basic product data
      for (var doc in productsQuery.docs) {
        final product = SellerProduct.fromMap({...doc.data(), 'id': doc.id});
        productData[product.id] = {
          'id': product.id,
          'name': product.name,
          'imageUrl': product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
          'price': product.price,
          'rating': product.rating,
          'sales': 0,
          'revenue': 0.0,
        };
      }
      
      // Add sales data from orders
      for (var doc in ordersQuery.docs) {
        final order = app_model.Order.fromMap({...doc.data(), 'id': doc.id});
        
        for (var item in order.items) {
          if (item.sellerId == currentSellerId && productData.containsKey(item.productId)) {
            final data = productData[item.productId]!;
            data['sales'] = (data['sales'] as int) + item.quantity;
            data['revenue'] = (data['revenue'] as double) + (item.price * item.quantity);
          }
        }
      }
      
      // Convert to list and sort by revenue
      final result = productData.values.toList();
      result.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
      
      // Return top 5 products
      return result.take(5).toList();
    } catch (e) {
      debugPrint('Error getting top products: $e');
      return [];
    }
  }
  
  // Stream of recent activities for the seller
  Stream<List<Map<String, dynamic>>> getRecentActivities() {
    try {
      if (!isSellerAuthenticated) {
        throw 'User not authenticated as a seller';
      }
      
      return _firestore
          .collection(FirebaseConstants.sellerActivitiesCollection)
          .doc(currentSellerId)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              // Convert Timestamp to DateTime
              if (data['timestamp'] is Timestamp) {
                data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
              }
              return data;
            }).toList();
          });
    } catch (e) {
      debugPrint('Error getting recent activities: $e');
      return Stream.value([]);
    }
  }
  
  // Add a recent activity
  Future<void> _addRecentActivity({
    required String type,
    required String title,
    required String description,
  }) async {
    try {
      if (!isSellerAuthenticated) return;
      
      await _firestore
          .collection(FirebaseConstants.sellerActivitiesCollection)
          .doc(currentSellerId)
          .collection('activities')
          .add({
            'type': type,
            'title': title,
            'description': description,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error adding recent activity: $e');
    }
  }
  
  // Get inventory alerts (low stock products)
  Future<List<Map<String, dynamic>>> getInventoryAlerts() async {
    try {
      if (!isSellerAuthenticated) {
        return [];
      }
      
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.productsCollection)
          .where('sellerId', isEqualTo: currentSellerId)
          .where('quantity', isLessThanOrEqualTo: 5)
          .where('isAvailable', isEqualTo: true)
          .orderBy('quantity')
          .limit(10)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting inventory alerts: $e');
      return [];
    }
  }
  
  // Get real-time order notifications
  Stream<List<app_model.Order>> getRecentOrders() {
    try {
      if (!isSellerAuthenticated) {
        return Stream.value([]);
      }
      
      return _firestore
          .collection(FirebaseConstants.ordersCollection)
          .where('sellerIds', arrayContains: currentSellerId)
          .orderBy('orderDate', descending: true)
          .limit(10)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return app_model.Order.fromMap({...doc.data(), 'id': doc.id});
            }).toList();
          });
    } catch (e) {
      debugPrint('Error getting recent orders: $e');
      return Stream.value([]);
    }
  }
  
  // Add a product with pre-uploaded image URLs
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
    bool isFeatured = false,
  }) async {
    try {
      if (!isSellerAuthenticated) {
        throw 'User not authenticated as a seller';
      }
      
      // Get seller information for buyer product view
      final userDoc = await _firestore.collection('users').doc(currentSellerId).get();
      final userData = userDoc.data();
      final String sellerName = userData?['name'] ?? 'Store Seller';
      
      // Create product data for seller products collection
      final productId = const Uuid().v4();
      final sellerProductData = {
        'id': productId,
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'imageUrls': imageUrls,
        'categories': categories,
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'specifications': specifications ?? {},
        'size': size,
        'weight': weight,
        'material': material,
        'discountPercentage': discountPercentage,
        'isFeatured': isFeatured,
        'rating': 0.0,
        'reviewCount': 0,
        'sellerId': currentSellerId,
        'sellerName': sellerName,
        'isApproved': true, // Auto-approve now for testing
        'salesCount': 0,
        'viewCount': 0,
      };
      
      // Add to sellerProducts collection
      final docRef = await _firestore
          .collection('sellerProducts')
          .add(sellerProductData);
      
      // Create product data for buyers collection
      final buyerProductData = {
        ...sellerProductData,
        'productId': docRef.id, // Reference to the seller product
        'rentalPrice': price * 0.1, // 10% of sale price
        'isAvailableForRent': true,
        'isAvailableForSale': true,
        'categoryId': categories[0].toString().toLowerCase(),
        'category': categories[0],
        'artisanId': currentSellerId,
        'artisanName': sellerName,
        'artisanLocation': userData?['businessAddress'] ?? 'India',
        'stock': quantity,
        'totalSales': 0,
      };
      
      // Add to products collection (visible to buyers)
      await _firestore
          .collection('products')
          .add(buyerProductData);
          
      // Add to seller recent activities
      await _addRecentActivity(
        type: 'product',
        title: 'Product Added',
        description: 'You added a new product: $name',
      );
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }
} 