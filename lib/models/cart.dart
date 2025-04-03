import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kalakritiapp/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final bool isRental;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;
  
  CartItem({
    required this.product,
    required this.quantity,
    this.isRental = false,
    this.rentalStartDate,
    this.rentalEndDate,
  });
  
  double get totalPrice {
    if (isRental && rentalStartDate != null && rentalEndDate != null && product.rentalPrice != null) {
      final days = rentalEndDate!.difference(rentalStartDate!).inDays + 1;
      return product.rentalPrice! * days * quantity;
    } else {
      return product.price * quantity;
    }
  }
  
  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'quantity': quantity,
      'isRental': isRental,
      'rentalStartDate': rentalStartDate,
      'rentalEndDate': rentalEndDate,
    };
  }
  
  factory CartItem.fromMap(Map<String, dynamic> map, Product product) {
    return CartItem(
      product: product,
      quantity: map['quantity'] ?? 1,
      isRental: map['isRental'] ?? false,
      rentalStartDate: map['rentalStartDate'] != null ? (map['rentalStartDate'] as Timestamp).toDate() : null,
      rentalEndDate: map['rentalEndDate'] != null ? (map['rentalEndDate'] as Timestamp).toDate() : null,
    );
  }
}

class Cart {
  final String userId;
  final Map<String, CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Cart({
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });
  
  double get totalAmount {
    double total = 0;
    items.forEach((key, item) {
      total += item.totalPrice;
    });
    return total;
  }
  
  int get itemCount {
    int count = 0;
    items.forEach((key, item) {
      count += item.quantity;
    });
    return count;
  }
  
  factory Cart.empty(String userId) {
    return Cart(
      userId: userId,
      items: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> itemsMap = {};
    items.forEach((key, value) {
      itemsMap[key] = value.toMap();
    });
    
    return {
      'userId': userId,
      'items': itemsMap,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
} 