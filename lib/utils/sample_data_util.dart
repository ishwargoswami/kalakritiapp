import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SampleDataUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add sample products to Firestore
  static Future<void> addSampleProducts() async {
    try {
      // Sample product data
      final List<Map<String, dynamic>> sampleProducts = [
        {
          'name': 'Hand Embroidered Shawl',
          'description': 'Exquisite hand embroidered shawl made by skilled artisans from Kashmir.',
          'price': 2500.0,
          'rentalPrice': 250.0,
          'isAvailableForRent': true,
          'isAvailableForSale': true,
          'categoryId': 'handicrafts',
          'category': 'Handicrafts',
          'imageUrls': [
            'https://images.pexels.com/photos/6193090/pexels-photo-6193090.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            'https://images.pexels.com/photos/7260549/pexels-photo-7260549.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'
          ],
          'isFeatured': true,
          'rating': 4.7,
          'ratingCount': 42,
          'specifications': {
            'material': 'Pashmina Wool',
            'dimensions': '2m x 1m',
            'care': 'Dry clean only'
          },
          'createdAt': Timestamp.now(),
          'artisanId': 'artisan123',
          'artisanName': 'Aisha Khan',
          'artisanLocation': 'Srinagar, Kashmir',
          'stock': 15,
          'totalSales': 37
        },
        {
          'name': 'Blue Pottery Vase',
          'description': 'Traditional blue pottery vase handcrafted in Jaipur, featuring intricate floral designs.',
          'price': 1800.0,
          'rentalPrice': 200.0,
          'isAvailableForRent': true,
          'isAvailableForSale': true,
          'categoryId': 'traditional',
          'category': 'Traditional',
          'imageUrls': [
            'https://images.pexels.com/photos/6258031/pexels-photo-6258031.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            'https://images.pexels.com/photos/5705508/pexels-photo-5705508.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'
          ],
          'isFeatured': true,
          'rating': 4.9,
          'ratingCount': 28,
          'specifications': {
            'material': 'Ceramic',
            'height': '30cm',
            'care': 'Handle with care, clean with soft cloth'
          },
          'createdAt': Timestamp.now(),
          'artisanId': 'artisan456',
          'artisanName': 'Rajesh Sharma',
          'artisanLocation': 'Jaipur, Rajasthan',
          'stock': 8,
          'totalSales': 45
        },
        {
          'name': 'Madhubani Wall Art',
          'description': 'Vibrant Madhubani painting on handmade paper, depicting traditional village scenes.',
          'price': 3200.0,
          'rentalPrice': 350.0,
          'isAvailableForRent': true,
          'isAvailableForSale': true,
          'categoryId': 'handicrafts',
          'category': 'Handicrafts',
          'imageUrls': [
            'https://images.pexels.com/photos/12029653/pexels-photo-12029653.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            'https://images.pexels.com/photos/15913452/pexels-photo-15913452/free-photo-of-woman-creating-traditional-paintings.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'
          ],
          'isFeatured': false,
          'rating': 4.8,
          'ratingCount': 19,
          'specifications': {
            'material': 'Natural pigments on handmade paper',
            'dimensions': '45cm x 60cm',
            'framed': 'Yes, wooden frame'
          },
          'createdAt': Timestamp.now(),
          'artisanId': 'artisan789',
          'artisanName': 'Meena Devi',
          'artisanLocation': 'Madhubani, Bihar',
          'stock': 5,
          'totalSales': 22
        },
        {
          'name': 'Brass Diya Set',
          'description': 'Set of 5 intricately designed brass diyas (oil lamps) for festive occasions.',
          'price': 1200.0,
          'rentalPrice': 150.0,
          'isAvailableForRent': true,
          'isAvailableForSale': true,
          'categoryId': 'traditional',
          'category': 'Traditional',
          'imageUrls': [
            'https://images.pexels.com/photos/7175443/pexels-photo-7175443.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            'https://images.pexels.com/photos/15874258/pexels-photo-15874258/free-photo-of-traditional-decorative-lamps.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'
          ],
          'isFeatured': true,
          'rating': 4.5,
          'ratingCount': 52,
          'specifications': {
            'material': 'Pure brass',
            'size': 'Assorted sizes (8cm - 15cm)',
            'care': 'Clean with lemon and salt paste for shine'
          },
          'createdAt': Timestamp.now(),
          'artisanId': 'artisan101',
          'artisanName': 'Ravi Kumar',
          'artisanLocation': 'Moradabad, Uttar Pradesh',
          'stock': 25,
          'totalSales': 78
        },
        {
          'name': 'Wooden Elephant Sculpture',
          'description': 'Hand-carved wooden elephant sculpture, showcasing the rich woodworking traditions of India.',
          'price': 4500.0,
          'rentalPrice': 500.0,
          'isAvailableForRent': true,
          'isAvailableForSale': true,
          'categoryId': 'handicrafts',
          'category': 'Handicrafts',
          'imageUrls': [
            'https://images.pexels.com/photos/12068871/pexels-photo-12068871.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            'https://images.pexels.com/photos/6758292/pexels-photo-6758292.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'
          ],
          'isFeatured': false,
          'rating': 4.9,
          'ratingCount': 31,
          'specifications': {
            'material': 'Rosewood',
            'dimensions': '25cm x 20cm x 15cm',
            'weight': '2.5kg'
          },
          'createdAt': Timestamp.now(),
          'artisanId': 'artisan202',
          'artisanName': 'Gopal Vishwakarma',
          'artisanLocation': 'Saharanpur, Uttar Pradesh',
          'stock': 3,
          'totalSales': 18
        },
      ];

      // Add each product to Firestore
      for (final product in sampleProducts) {
        await _firestore.collection('products').add(product);
      }

      print('Sample products added successfully!');
    } catch (e) {
      print('Error adding sample products: $e');
    }
  }

  // Add sample categories to Firestore
  static Future<void> addSampleCategories() async {
    try {
      // Sample category data
      final List<Map<String, dynamic>> sampleCategories = [
        {
          'name': 'Handicrafts',
          'description': 'Beautiful handcrafted items from skilled artisans',
          'imageUrl': 'https://images.pexels.com/photos/12029653/pexels-photo-12029653.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
          'productCount': 0,
          'displayOrder': 1,
        },
        {
          'name': 'Traditional',
          'description': 'Timeless traditional pieces celebrating Indian heritage',
          'imageUrl': 'https://images.pexels.com/photos/6192401/pexels-photo-6192401.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
          'productCount': 0,
          'displayOrder': 2,
        },
        {
          'name': 'Handloom Textiles',
          'description': 'Exquisite handwoven textiles from across India',
          'imageUrl': 'https://images.pexels.com/photos/6193101/pexels-photo-6193101.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
          'productCount': 0,
          'displayOrder': 3,
        },
        {
          'name': 'Home Decor',
          'description': 'Beautiful handcrafted items for your home',
          'imageUrl': 'https://images.pexels.com/photos/6194021/pexels-photo-6194021.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
          'productCount': 0,
          'displayOrder': 4,
        },
        {
          'name': 'Pottery & Ceramics',
          'description': 'Handcrafted pottery and ceramic artifacts',
          'imageUrl': 'https://images.pexels.com/photos/6258031/pexels-photo-6258031.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
          'productCount': 0,
          'displayOrder': 5,
        },
      ];

      // Add each category to Firestore
      for (final category in sampleCategories) {
        await _firestore.collection('categories').add(category);
      }

      print('Sample categories added successfully!');
    } catch (e) {
      print('Error adding sample categories: $e');
    }
  }

  // Add sample seller products - these will be visible to both sellers and buyers
  static Future<void> addSellerProducts() async {
    try {
      final String? sellerId = _auth.currentUser?.uid;
      if (sellerId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get seller name from user document
      final userDoc = await _firestore.collection('users').doc(sellerId).get();
      final userData = userDoc.data();
      final String sellerName = userData?['name'] ?? 'Sample Seller';
      
      // Sample product data with updated handicraft related products
      final List<Map<String, dynamic>> sampleProducts = [
        {
          'name': 'Hand Embroidered Kashmiri Shawl',
          'description': 'Exquisite hand embroidered shawl made by skilled artisans from Kashmir. Each piece features unique floral patterns representing traditional Kashmiri craftsmanship.',
          'price': 2500.0,
          'quantity': 15,
          'imageUrls': [
            'https://images.pexels.com/photos/6193090/pexels-photo-6193090.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            'https://images.pexels.com/photos/7260549/pexels-photo-7260549.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'
          ],
          'categories': ['Handicrafts', 'Handloom Textiles'],
          'sellerId': sellerId,
          'sellerName': sellerName,
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'size': '2m x 1m',
          'weight': '250g',
          'material': 'Pashmina Wool',
          'discountPercentage': 10.0,
          'isFeatured': true,
          'viewCount': 42,
          'salesCount': 8, // Changed from orderCount to salesCount
          'rating': 4.7,
          'reviewCount': 6,
          'isApproved': true, // Auto-approve sample data
        },
        {
          'name': 'Jaipur Blue Pottery Decorative Vase',
          'description': 'Traditional blue pottery vase handcrafted in Jaipur, featuring intricate floral designs in vibrant blue and turquoise colors. Made with a special dough of quartz stone powder, glass, and gum.',
          'price': 1800.0,
          'quantity': 8,
          'imageUrls': [
            'https://images.pexels.com/photos/6258031/pexels-photo-6258031.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            'https://images.pexels.com/photos/5705508/pexels-photo-5705508.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'
          ],
          'categories': ['Pottery & Ceramics', 'Home Decor'],
          'sellerId': sellerId,
          'sellerName': sellerName,
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'size': '30cm x 15cm',
          'weight': '1.2kg',
          'material': 'Ceramic with quartz powder',
          'discountPercentage': 0.0,
          'isFeatured': true,
          'viewCount': 28,
          'salesCount': 5, // Changed from orderCount to salesCount
          'rating': 4.9,
          'reviewCount': 4,
          'isApproved': true,
        },
        {
          'name': 'Banarasi Silk Handloom Saree',
          'description': 'Authentic Banarasi silk handloom saree with intricate gold zari work. Each saree takes up to 15 days to weave by master artisans from Varanasi.',
          'price': 8500.0,
          'quantity': 7,
          'imageUrls': [
            'https://images.pexels.com/photos/12211960/pexels-photo-12211960.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            'https://images.pexels.com/photos/1108638/pexels-photo-1108638.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'
          ],
          'categories': ['Handloom Textiles', 'Traditional'],
          'sellerId': sellerId,
          'sellerName': sellerName,
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'size': '5.5m x 1.1m',
          'weight': '500g',
          'material': 'Pure silk with gold zari work',
          'discountPercentage': 5.0,
          'isFeatured': true,
          'viewCount': 65,
          'salesCount': 12, // Changed from orderCount to salesCount
          'rating': 4.8,
          'reviewCount': 9,
          'isApproved': true,
        },
        {
          'name': 'Bidri Art Decorative Plate',
          'description': 'Handcrafted Bidri art decorative plate, showcasing the ancient metal craft from Bidar, Karnataka. Made with an alloy of zinc and copper with intricate silver inlay work.',
          'price': 3800.0,
          'quantity': 4,
          'imageUrls': [
            'https://images.pexels.com/photos/6044993/pexels-photo-6044993.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            'https://images.pexels.com/photos/6045001/pexels-photo-6045001.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'
          ],
          'categories': ['Handicrafts', 'Home Decor'],
          'sellerId': sellerId,
          'sellerName': sellerName,
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'size': '30cm diameter',
          'weight': '1.5kg',
          'material': 'Zinc-copper alloy with silver inlay',
          'discountPercentage': 0.0,
          'isFeatured': true,
          'viewCount': 22,
          'salesCount': 3, // Changed from orderCount to salesCount
          'rating': 5.0,
          'reviewCount': 3,
          'isApproved': true,
        },
        {
          'name': 'Rosewood Elephant Sculpture',
          'description': 'Hand-carved rosewood elephant sculpture from Saharanpur, showcasing the rich woodworking traditions of India. Each piece is unique with intricate detailing.',
          'price': 4500.0,
          'quantity': 3,
          'imageUrls': [
            'https://images.pexels.com/photos/12068871/pexels-photo-12068871.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            'https://images.pexels.com/photos/6758292/pexels-photo-6758292.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'
          ],
          'categories': ['Handicrafts', 'Home Decor'],
          'sellerId': sellerId,
          'sellerName': sellerName,
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'size': '25cm x 20cm x 15cm',
          'weight': '2.5kg',
          'material': 'Rosewood',
          'discountPercentage': 5.0,
          'isFeatured': false,
          'viewCount': 15,
          'salesCount': 2, // Changed from orderCount to salesCount
          'rating': 4.8,
          'reviewCount': 2,
          'isApproved': true,
        },
      ];

      // Add each product to both sellerProducts and products collections
      for (final product in sampleProducts) {
        // Add to sellerProducts collection
        final docRef = await _firestore.collection('sellerProducts').add(product);
        
        // Prepare data for products collection (buyer-visible)
        final productData = {
          ...product,
          'productId': docRef.id, // Reference to the seller product
          'rentalPrice': (product['price'] as double) * 0.1, // 10% of sale price
          'isAvailableForRent': true,
          'isAvailableForSale': true,
          'categoryId': product['categories'][0].toString().toLowerCase(),
          'category': product['categories'][0],
          'artisanId': sellerId,
          'artisanName': sellerName,
          'artisanLocation': userData?['businessAddress'] ?? 'India',
          'stock': product['quantity'],
          'totalSales': product['salesCount'],
        };
        
        // Add to products collection (visible to buyers)
        await _firestore.collection('products').add(productData);
      }

      print('Sample seller products added successfully!');
    } catch (e) {
      print('Error adding sample seller products: $e');
      rethrow;
    }
  }
  
  // Create a sample order to fix synchronization between buyer and seller
  static Future<void> createSampleOrder() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get user information
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      // Get a random product from sellerProducts collection
      final productsSnapshot = await _firestore.collection('sellerProducts').limit(3).get();
      
      if (productsSnapshot.docs.isEmpty) {
        throw Exception('No products found to create sample order');
      }
      
      final List<Map<String, dynamic>> orderItems = [];
      final Set<String> sellerIds = {};
      double subtotal = 0;
      
      // Create order items from products
      for (final doc in productsSnapshot.docs) {
        final product = doc.data();
        final sellerId = product['sellerId'] as String;
        sellerIds.add(sellerId);
        
        final price = (product['price'] as double);
        final quantity = 1;
        subtotal += price * quantity;
        
        orderItems.add({
          'id': doc.id,
          'productId': doc.id,
          'name': product['name'],
          'imageUrl': product['imageUrls'][0],
          'price': price,
          'quantity': quantity,
          'sellerId': sellerId,
          'isRental': false,
        });
      }
      
      // Create shipping address
      final Map<String, dynamic> shippingAddress = {
        'name': userData?['name'] ?? 'Sample Customer',
        'addressLine1': userData?['address'] ?? '123 Sample Street',
        'city': userData?['city'] ?? 'Mumbai',
        'state': userData?['state'] ?? 'Maharashtra',
        'postalCode': userData?['postalCode'] ?? '400001',
        'country': 'India',
        'phoneNumber': userData?['phoneNumber'] ?? '9876543210',
      };
      
      // Calculate order totals
      final shippingCost = 150.0;
      final tax = subtotal * 0.18; // 18% GST
      final total = subtotal + shippingCost + tax;
      
      // Generate order number
      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)}';
      
      // Create order document
      final orderData = {
        'orderNumber': orderNumber,
        'userId': userId,
        'customerName': userData?['name'] ?? 'Sample Customer',
        'customerEmail': userData?['email'] ?? 'sample@kalakriti.com',
        'items': orderItems,
        'subtotal': subtotal,
        'shippingCost': shippingCost,
        'tax': tax,
        'total': total,
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'confirmed', // Important: Setting as confirmed so it shows up in seller dashboard
        'shippingAddress': shippingAddress,
        'paymentMethod': 'Cash on Delivery',
        'isPaid': false,
        'sellerIds': sellerIds.toList(), // This is crucial for seller to see the order
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add to orders collection
      await _firestore.collection('orders').add(orderData);
      
      print('Sample order created successfully!');
    } catch (e) {
      print('Error creating sample order: $e');
    }
  }

  // Create a test order that immediately shows up for the seller
  static Future<void> createTestOrder() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get user information
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final customerName = userData['name'] ?? _auth.currentUser?.displayName ?? 'Test Customer';
      final customerEmail = userData['email'] ?? _auth.currentUser?.email ?? 'test@example.com';
      
      // Get a seller product to create an order for
      final productsSnapshot = await _firestore.collection('sellerProducts').limit(1).get();
      
      if (productsSnapshot.docs.isEmpty) {
        throw Exception('No seller products found. Please add sample products first.');
      }
      
      // Get the first product
      final product = productsSnapshot.docs.first.data();
      final productId = productsSnapshot.docs.first.id;
      final sellerId = product['sellerId'] as String;
      
      // Create order items
      final List<Map<String, dynamic>> orderItems = [
        {
          'id': productId,
          'productId': productId,
          'name': product['name'],
          'price': (product['price'] as num).toDouble(),
          'quantity': 1,
          'imageUrl': (product['imageUrls'] as List)[0],
          'sellerId': sellerId,
          'isRental': false,
          'totalPrice': (product['price'] as num).toDouble(),
        }
      ];
      
      // Generate a unique order number
      final orderNumber = 'TST${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      // Calculate order totals
      final double subtotal = (product['price'] as num).toDouble();
      final double shipping = 50.0;
      final double tax = subtotal * 0.18; // 18% GST
      final double total = subtotal + shipping + tax;
      
      // Order data
      final Map<String, dynamic> orderData = {
        'orderNumber': orderNumber,
        'userId': userId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'items': orderItems,
        'shippingAddress': {
          'name': customerName,
          'addressLine1': userData['address'] ?? '123 Test Street',
          'addressLine2': '',
          'city': userData['city'] ?? 'Mumbai',
          'state': userData['state'] ?? 'Maharashtra',
          'postalCode': userData['postalCode'] ?? '400001',
          'phoneNumber': userData['phoneNumber'] ?? '9876543210',
          'country': 'India',
        },
        'paymentMethod': 'Cash on Delivery',
        'subtotal': subtotal,
        'shippingCost': shipping,
        'tax': tax,
        'total': total,
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'pending', // Critical field for seller visibility
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'sellerIds': [sellerId], // Critical field for seller visibility
        'isPaid': false,
      };
      
      // Add to orders collection
      final orderRef = await _firestore.collection('orders').add(orderData);
      
      print('Test order created successfully! Order ID: ${orderRef.id}');
    } catch (e) {
      print('Error creating test order: $e');
      rethrow;
    }
  }
} 