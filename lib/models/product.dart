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
  final String category;
  final List<String> imageUrls;
  final bool isFeatured;
  final double rating;
  final int ratingCount;
  final Map<String, dynamic> specifications;
  final DateTime createdAt;
  final String artisanId;
  final String artisanName;
  final String artisanLocation;
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
    this.category = '',
    required this.imageUrls,
    required this.isFeatured,
    required this.rating,
    required this.ratingCount,
    required this.specifications,
    required this.createdAt,
    required this.artisanId,
    required this.artisanName,
    this.artisanLocation = '',
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
      category: data['category'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isFeatured: data['isFeatured'] ?? false,
      rating: (data['rating'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      specifications: data['specifications'] ?? {},
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      artisanId: data['artisanId'] ?? '',
      artisanName: data['artisanName'] ?? '',
      artisanLocation: data['artisanLocation'] ?? '',
      stock: data['stock'] ?? 0,
    );
  }

  // Create Product from Map
  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      rentalPrice: data['rentalPrice']?.toDouble(),
      isAvailableForRent: data['isAvailableForRent'] ?? false,
      isAvailableForSale: data['isAvailableForSale'] ?? true,
      categoryId: data['categoryId'] ?? '',
      category: data['category'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isFeatured: data['isFeatured'] ?? false,
      rating: (data['rating'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      specifications: data['specifications'] ?? {},
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      artisanId: data['artisanId'] ?? '',
      artisanName: data['artisanName'] ?? '',
      artisanLocation: data['artisanLocation'] ?? '',
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
      'category': category,
      'imageUrls': imageUrls,
      'isFeatured': isFeatured,
      'rating': rating,
      'ratingCount': ratingCount,
      'specifications': specifications,
      'createdAt': Timestamp.fromDate(createdAt),
      'artisanId': artisanId,
      'artisanName': artisanName,
      'artisanLocation': artisanLocation,
      'stock': stock,
    };
  }

  // Copy Product with some changes
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? rentalPrice,
    bool? isAvailableForRent,
    bool? isAvailableForSale,
    String? categoryId,
    String? category,
    List<String>? imageUrls,
    bool? isFeatured,
    double? rating,
    int? ratingCount,
    Map<String, dynamic>? specifications,
    DateTime? createdAt,
    String? artisanId,
    String? artisanName,
    String? artisanLocation,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      rentalPrice: rentalPrice ?? this.rentalPrice,
      isAvailableForRent: isAvailableForRent ?? this.isAvailableForRent,
      isAvailableForSale: isAvailableForSale ?? this.isAvailableForSale,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      specifications: specifications ?? this.specifications,
      createdAt: createdAt ?? this.createdAt,
      artisanId: artisanId ?? this.artisanId,
      artisanName: artisanName ?? this.artisanName,
      artisanLocation: artisanLocation ?? this.artisanLocation,
      stock: stock ?? this.stock,
    );
  }
} 