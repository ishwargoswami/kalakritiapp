import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final int quantity;
  final bool isRental;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;
  final String artisanName;
  final String? sellerId;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.isRental,
    this.rentalStartDate,
    this.rentalEndDate,
    required this.artisanName,
    this.sellerId,
  });

  // Get total price for this item
  double get totalPrice => price * quantity;

  // Get rental duration in days
  int get rentalDuration {
    if (!isRental || rentalStartDate == null || rentalEndDate == null) return 0;
    return rentalEndDate!.difference(rentalStartDate!).inDays + 1; // Include both start and end days
  }

  // Get total rental price
  double get totalRentalPrice {
    if (!isRental || rentalStartDate == null || rentalEndDate == null) return 0;
    return price * rentalDuration;
  }

  // Factory method to create CartItem from Firestore document
  factory CartItem.fromMap(String id, Map<String, dynamic> map) {
    return CartItem(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      isRental: map['isRental'] ?? false,
      rentalStartDate: map['rentalStartDate'] != null 
          ? (map['rentalStartDate'] as Timestamp).toDate() 
          : null,
      rentalEndDate: map['rentalEndDate'] != null 
          ? (map['rentalEndDate'] as Timestamp).toDate() 
          : null,
      artisanName: map['artisanName'] ?? '',
      sellerId: map['sellerId'],
    );
  }

  // Convert CartItem to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'isRental': isRental,
      'rentalStartDate': rentalStartDate != null ? Timestamp.fromDate(rentalStartDate!) : null,
      'rentalEndDate': rentalEndDate != null ? Timestamp.fromDate(rentalEndDate!) : null,
      'artisanName': artisanName,
      'sellerId': sellerId,
      'updatedAt': Timestamp.now(),
    };
  }

  // Create a copy with modified fields
  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? imageUrl,
    double? price,
    int? quantity,
    bool? isRental,
    DateTime? rentalStartDate,
    DateTime? rentalEndDate,
    String? artisanName,
    String? sellerId,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isRental: isRental ?? this.isRental,
      rentalStartDate: rentalStartDate ?? this.rentalStartDate,
      rentalEndDate: rentalEndDate ?? this.rentalEndDate,
      artisanName: artisanName ?? this.artisanName,
      sellerId: sellerId ?? this.sellerId,
    );
  }
} 