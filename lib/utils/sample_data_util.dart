import 'package:cloud_firestore/cloud_firestore.dart';

class SampleDataUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
            'https://images.unsplash.com/photo-1584499270550-e486d016239e?q=80&w=2070',
            'https://images.unsplash.com/photo-1494057905450-753aa3bd6631?q=80&w=2069'
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
            'https://images.unsplash.com/photo-1610701596007-11502861dcfa?q=80&w=2070',
            'https://images.unsplash.com/photo-1555196301-9acc011dfde4?q=80&w=1974'
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
            'https://images.unsplash.com/photo-1582547721161-f2a51e9f6f3f?q=80&w=2067',
            'https://images.unsplash.com/photo-1598532213932-98064d2c7956?q=80&w=2071'
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
            'https://images.unsplash.com/photo-1605365070248-299a257e911b?q=80&w=2070',
            'https://images.unsplash.com/photo-1604232749999-0b1681c1a1a9?q=80&w=2070'
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
            'https://images.unsplash.com/photo-1569172131546-0df55a7d7566?q=80&w=2070',
            'https://images.unsplash.com/photo-1599098615666-53cc8e7f67c9?q=80&w=2071'
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
          'imageUrl': 'https://images.unsplash.com/photo-1582550740000-5e4f70e6e87d?q=80&w=2070',
          'productCount': 0,
          'displayOrder': 1,
        },
        {
          'name': 'Traditional',
          'description': 'Timeless traditional pieces celebrating Indian heritage',
          'imageUrl': 'https://images.unsplash.com/photo-1590736969955-71cc94c4dd66?q=80&w=2070',
          'productCount': 0,
          'displayOrder': 2,
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
} 