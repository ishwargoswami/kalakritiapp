import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final int productCount;
  final int displayOrder;

  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.productCount,
    required this.displayOrder,
  });

  // Create Category from Firestore document
  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      productCount: data['productCount'] ?? 0,
      displayOrder: data['displayOrder'] ?? 0,
    );
  }

  // Convert Category to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'productCount': productCount,
      'displayOrder': displayOrder,
    };
  }
} 