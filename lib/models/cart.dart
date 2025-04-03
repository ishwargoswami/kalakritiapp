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
    if (isRental && product.rentalPrice != null) {
      final int days = rentalEndDate!.difference(rentalStartDate!).inDays + 1;
      return product.rentalPrice! * quantity * days;
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
}

class Cart {
  final String userId;
  final Map<String, CartItem> items;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Cart({
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  int get itemCount {
    return items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    return items.values.fold(0, (sum, item) => sum + item.totalPrice);
  }

  factory Cart.empty(String userId) {
    return Cart(
      userId: userId,
      items: {},
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
  }

  factory Cart.fromFirestore(DocumentSnapshot doc, Map<String, Product> products) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsData = data['items'] as Map<String, dynamic>;
    
    Map<String, CartItem> cartItems = {};
    
    itemsData.forEach((productId, quantity) {
      if (products.containsKey(productId)) {
        cartItems[productId] = CartItem(
          product: products[productId]!,
          quantity: quantity,
          isRental: data['isRental']?[productId] ?? false,
          rentalStartDate: data['rentalStartDate']?[productId] != null 
              ? (data['rentalStartDate'][productId] as Timestamp).toDate() 
              : null,
          rentalEndDate: data['rentalEndDate']?[productId] != null 
              ? (data['rentalEndDate'][productId] as Timestamp).toDate() 
              : null,
        );
      }
    });
    
    return Cart(
      userId: data['userId'] ?? '',
      items: cartItems,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> itemQuantities = {};
    Map<String, dynamic> itemRentalFlags = {};
    Map<String, dynamic> startDates = {};
    Map<String, dynamic> endDates = {};
    
    items.forEach((productId, cartItem) {
      itemQuantities[productId] = cartItem.quantity;
      
      if (cartItem.isRental) {
        itemRentalFlags[productId] = true;
        if (cartItem.rentalStartDate != null) {
          startDates[productId] = Timestamp.fromDate(cartItem.rentalStartDate!);
        }
        if (cartItem.rentalEndDate != null) {
          endDates[productId] = Timestamp.fromDate(cartItem.rentalEndDate!);
        }
      }
    });
    
    return {
      'userId': userId,
      'items': itemQuantities,
      'isRental': itemRentalFlags,
      'rentalStartDate': startDates,
      'rentalEndDate': endDates,
      'createdAt': createdAt,
      'updatedAt': Timestamp.now(),
    };
  }
} 