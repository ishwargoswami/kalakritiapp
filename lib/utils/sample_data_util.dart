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
      
      // Sample product data
      final List<Map<String, dynamic>> sampleProducts = [
        {
          'name': 'Hand Embroidered Shawl',
          'description': 'Exquisite hand embroidered shawl made by skilled artisans from Kashmir.',
          'price': 2500.0,
          'quantity': 15,
          'imageUrls': [
            'https://images.pexels.com/photos/6193090/pexels-photo-6193090.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            'https://images.pexels.com/photos/7260549/pexels-photo-7260549.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'
          ],
          'categories': ['Handicrafts', 'Traditional'],
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
          'orderCount': 8,
          'averageRating': 4.7,
          'reviewCount': 6,
          'isApproved': true, // Auto-approve sample data
        },
        {
          'name': 'Blue Pottery Vase',
          'description': 'Traditional blue pottery vase handcrafted in Jaipur, featuring intricate floral designs.',
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
          'material': 'Ceramic',
          'discountPercentage': 0.0,
          'isFeatured': true,
          'viewCount': 28,
          'orderCount': 5,
          'averageRating': 4.9,
          'reviewCount': 4,
          'isApproved': true, // Auto-approve sample data
        },
        {
          'name': 'Wooden Elephant Sculpture',
          'description': 'Hand-carved wooden elephant sculpture, showcasing the rich woodworking traditions of India.',
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
          'orderCount': 2,
          'averageRating': 4.8,
          'reviewCount': 2,
          'isApproved': true, // Auto-approve sample data
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
          'totalSales': product['orderCount'],
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
} 