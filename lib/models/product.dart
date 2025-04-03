import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? rentalPrice;
  final bool isAvailableForRent;
  final bool isAvailableForSale;
  final String categoryId;
  final List<String> imageUrls;
  final bool isFeatured;
  final double rating;
  final int ratingCount;
  final Map<String, dynamic> specifications;
  final Timestamp createdAt;
  final String artisanId;
  final String artisanName;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.rentalPrice,
    required this.isAvailableForRent,
    required this.isAvailableForSale,
    required this.categoryId,
    required this.imageUrls,
    required this.isFeatured,
    required this.rating,
    required this.ratingCount,
    required this.specifications,
    required this.createdAt,
    required this.artisanId,
    required this.artisanName,
    required this.stock,
  });

  // Create Product from Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      rentalPrice: data['rentalPrice']?.toDouble(),
      isAvailableForRent: data['isAvailableForRent'] ?? false,
      isAvailableForSale: data['isAvailableForSale'] ?? true,
      categoryId: data['categoryId'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isFeatured: data['isFeatured'] ?? false,
      rating: (data['rating'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      specifications: data['specifications'] ?? {},
      createdAt: data['createdAt'] ?? Timestamp.now(),
      artisanId: data['artisanId'] ?? '',
      artisanName: data['artisanName'] ?? '',
      stock: data['stock'] ?? 0,
    );
  }

  // Convert Product to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'rentalPrice': rentalPrice,
      'isAvailableForRent': isAvailableForRent,
      'isAvailableForSale': isAvailableForSale,
      'categoryId': categoryId,
      'imageUrls': imageUrls,
      'isFeatured': isFeatured,
      'rating': rating,
      'ratingCount': ratingCount,
      'specifications': specifications,
      'createdAt': createdAt,
      'artisanId': artisanId,
      'artisanName': artisanName,
      'stock': stock,
    };
  }
} 