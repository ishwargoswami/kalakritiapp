import 'package:cloud_firestore/cloud_firestore.dart';

class SellerProduct {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final List<String> imageUrls;
  final List<String> categories;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? specifications;
  final String? size;
  final String? weight;
  final String? material;
  final double discountPercentage;
  final bool isFeatured;
  final int viewCount;
  final int salesCount;
  final double rating;
  final int reviewCount;
  final bool isApproved;
  
  SellerProduct({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.imageUrls,
    required this.categories,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
    this.specifications,
    this.size,
    this.weight,
    this.material,
    this.discountPercentage = 0.0,
    this.isFeatured = false,
    this.viewCount = 0,
    this.salesCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isApproved = false,
  });
  
  // Create SellerProduct from Firestore document
  factory SellerProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellerProduct.fromMap({...data, 'id': doc.id});
  }
  
  // Create from Map
  factory SellerProduct.fromMap(Map<String, dynamic> data) {
    return SellerProduct(
      id: data['id'] ?? '',
      sellerId: data['sellerId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      imageUrls: data['imageUrls'] != null 
          ? List<String>.from(data['imageUrls']) 
          : [],
      categories: data['categories'] != null 
          ? List<String>.from(data['categories']) 
          : [],
      isAvailable: data['isAvailable'] ?? true,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt']))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(data['updatedAt']))
          : DateTime.now(),
      specifications: data['specifications'],
      size: data['size'],
      weight: data['weight'],
      material: data['material'],
      discountPercentage: (data['discountPercentage'] ?? 0).toDouble(),
      isFeatured: data['isFeatured'] ?? false,
      viewCount: data['viewCount'] ?? 0,
      salesCount: data['salesCount'] ?? data['orderCount'] ?? 0,
      rating: (data['rating'] ?? data['averageRating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isApproved: data['isApproved'] ?? false,
    );
  }
  
  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'imageUrls': imageUrls,
      'categories': categories,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'specifications': specifications ?? {},
      'size': size,
      'weight': weight,
      'material': material,
      'discountPercentage': discountPercentage,
      'isFeatured': isFeatured,
      'viewCount': viewCount,
      'salesCount': salesCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'isApproved': isApproved,
    };
  }
  
  // Calculate discounted price
  double get discountedPrice {
    if (discountPercentage <= 0) return price;
    return price - (price * discountPercentage / 100);
  }
  
  // Check if product is in stock
  bool get inStock => quantity > 0 && isAvailable;
  
  // Formatted rating display (e.g., "4.5 (10 reviews)")
  String get ratingDisplay {
    return "$rating${reviewCount > 0 ? ' (${reviewCount} reviews)' : ''}";
  }
  
  // Get inventory status
  String get inventoryStatus {
    if (quantity <= 0) return 'Out of Stock';
    if (quantity < 5) return 'Low Stock';
    return 'In Stock';
  }
  
  // Create a copy with updated properties
  SellerProduct copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    double? price,
    int? quantity,
    List<String>? imageUrls,
    List<String>? categories,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? specifications,
    String? size,
    String? weight,
    String? material,
    double? discountPercentage,
    bool? isFeatured,
    int? viewCount,
    int? salesCount,
    double? rating,
    int? reviewCount,
    bool? isApproved,
  }) {
    return SellerProduct(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrls: imageUrls ?? this.imageUrls,
      categories: categories ?? this.categories,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      specifications: specifications ?? this.specifications,
      size: size ?? this.size,
      weight: weight ?? this.weight,
      material: material ?? this.material,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      isFeatured: isFeatured ?? this.isFeatured,
      viewCount: viewCount ?? this.viewCount,
      salesCount: salesCount ?? this.salesCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isApproved: isApproved ?? this.isApproved,
    );
  }
} 