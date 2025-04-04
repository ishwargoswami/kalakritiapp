import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String sellerId;
  final String? size;
  final String? color;
  final String? status;
  final bool isRental;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;
  
  OrderItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.sellerId,
    this.size,
    this.color,
    this.status,
    this.isRental = false,
    this.rentalStartDate,
    this.rentalEndDate,
  });
  
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      sellerId: map['sellerId'] ?? '',
      size: map['size'],
      color: map['color'],
      status: map['status'],
      isRental: map['isRental'] ?? false,
      rentalStartDate: map['rentalStartDate'] != null
          ? (map['rentalStartDate'] is Timestamp 
              ? (map['rentalStartDate'] as Timestamp).toDate()
              : DateTime.parse(map['rentalStartDate'].toString()))
          : null,
      rentalEndDate: map['rentalEndDate'] != null
          ? (map['rentalEndDate'] is Timestamp 
              ? (map['rentalEndDate'] as Timestamp).toDate()
              : DateTime.parse(map['rentalEndDate'].toString()))
          : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'sellerId': sellerId,
      'size': size,
      'color': color,
      'status': status,
      'isRental': isRental,
      'rentalStartDate': rentalStartDate != null
          ? Timestamp.fromDate(rentalStartDate!)
          : null,
      'rentalEndDate': rentalEndDate != null
          ? Timestamp.fromDate(rentalEndDate!)
          : null,
    };
  }
}

class ShippingAddress {
  final String name;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String phoneNumber;
  
  ShippingAddress({
    required this.name,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.phoneNumber,
  });
  
  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      name: map['name'] ?? '',
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'],
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'phoneNumber': phoneNumber,
    };
  }
  
  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final String customerName;
  final String customerEmail;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingCost;
  final double tax;
  final double total;
  final DateTime? orderDate;
  final String status;
  final ShippingAddress shippingAddress;
  final String paymentMethod;
  final String? paymentId;
  final bool isPaid;
  final String? trackingNumber;
  final String? shippingCarrier;
  final List<String> sellerIds; // List of seller IDs involved in this order
  final DateTime? shippedDate;
  final DateTime? deliveredDate;
  
  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.tax,
    required this.total,
    this.orderDate,
    required this.status,
    required this.shippingAddress,
    required this.paymentMethod,
    this.paymentId,
    required this.isPaid,
    this.trackingNumber,
    this.shippingCarrier,
    required this.sellerIds,
    this.shippedDate,
    this.deliveredDate,
  });
  
  factory Order.fromMap(Map<String, dynamic> map) {
    // Parse items
    final List<OrderItem> orderItems = [];
    if (map['items'] != null) {
      for (var item in map['items']) {
        orderItems.add(OrderItem.fromMap(item));
      }
    }
    
    // Parse shipping address
    ShippingAddress address;
    if (map['shippingAddress'] != null) {
      address = ShippingAddress.fromMap(map['shippingAddress']);
    } else {
      address = ShippingAddress(
        name: '',
        addressLine1: '',
        city: '',
        state: '',
        postalCode: '',
        country: '',
        phoneNumber: '',
      );
    }
    
    // Parse seller IDs
    List<String> sellers = [];
    if (map['sellerIds'] != null) {
      sellers = List<String>.from(map['sellerIds']);
    }
    
    return Order(
      id: map['id'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      items: orderItems,
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      shippingCost: (map['shippingCost'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      orderDate: map['orderDate'] != null
          ? (map['orderDate'] is Timestamp 
              ? (map['orderDate'] as Timestamp).toDate()
              : DateTime.parse(map['orderDate'].toString()))
          : null,
      status: map['status'] ?? 'pending',
      shippingAddress: address,
      paymentMethod: map['paymentMethod'] ?? '',
      paymentId: map['paymentId'],
      isPaid: map['isPaid'] ?? false,
      trackingNumber: map['trackingNumber'],
      shippingCarrier: map['shippingCarrier'],
      sellerIds: sellers,
      shippedDate: map['shippedDate'] != null
          ? (map['shippedDate'] is Timestamp 
              ? (map['shippedDate'] as Timestamp).toDate()
              : DateTime.parse(map['shippedDate'].toString()))
          : null,
      deliveredDate: map['deliveredDate'] != null
          ? (map['deliveredDate'] is Timestamp 
              ? (map['deliveredDate'] as Timestamp).toDate()
              : DateTime.parse(map['deliveredDate'].toString()))
          : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'tax': tax,
      'total': total,
      'orderDate': orderDate != null ? Timestamp.fromDate(orderDate!) : null,
      'status': status,
      'shippingAddress': shippingAddress.toMap(),
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'isPaid': isPaid,
      'trackingNumber': trackingNumber,
      'shippingCarrier': shippingCarrier,
      'sellerIds': sellerIds,
      'shippedDate': shippedDate != null ? Timestamp.fromDate(shippedDate!) : null,
      'deliveredDate': deliveredDate != null ? Timestamp.fromDate(deliveredDate!) : null,
    };
  }
} 