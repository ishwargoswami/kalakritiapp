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
  final int orderCount;
  final double averageRating;
  final int reviewCount;
  final String sellerName;
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
    this.orderCount = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    required this.sellerName,
    this.isApproved = false,
  });
  
  // Create SellerProduct from Firestore document
  factory SellerProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SellerProduct(
      id: doc.id,
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
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      specifications: data['specifications'],
      size: data['size'],
      weight: data['weight'],
      material: data['material'],
      discountPercentage: (data['discountPercentage'] ?? 0).toDouble(),
      isFeatured: data['isFeatured'] ?? false,
      viewCount: data['viewCount'] ?? 0,
      orderCount: data['orderCount'] ?? 0,
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      sellerName: data['sellerName'] ?? '',
      isApproved: data['isApproved'] ?? false,
    );
  }
  
  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
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
      'specifications': specifications,
      'size': size,
      'weight': weight,
      'material': material,
      'discountPercentage': discountPercentage,
      'isFeatured': isFeatured,
      'viewCount': viewCount,
      'orderCount': orderCount,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'sellerName': sellerName,
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
    int? orderCount,
    double? averageRating,
    int? reviewCount,
    String? sellerName,
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
      orderCount: orderCount ?? this.orderCount,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      sellerName: sellerName ?? this.sellerName,
      isApproved: isApproved ?? this.isApproved,
    );
  }
} 