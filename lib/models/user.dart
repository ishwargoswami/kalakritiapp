import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kalakritiapp/models/user_role.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? photoURL;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastLogin;
  final List<String> favoriteProducts;
  final List<Map<String, dynamic>> shippingAddresses;
  
  // Seller specific fields
  final String? businessName;
  final String? businessDescription;
  final List<String>? businessImages;
  final String? businessAddress;
  final bool isVerifiedSeller;
  
  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.photoURL,
    required this.role,
    required this.createdAt,
    required this.lastLogin,
    required this.favoriteProducts,
    required this.shippingAddresses,
    this.businessName,
    this.businessDescription,
    this.businessImages,
    this.businessAddress,
    this.isVerifiedSeller = false,
  });
  
  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Anonymous',
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      role: UserRoleExtension.fromString(data['role'] ?? 'buyer'),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      lastLogin: data['lastLogin'] != null 
          ? (data['lastLogin'] as Timestamp).toDate() 
          : DateTime.now(),
      favoriteProducts: data['favoriteProducts'] != null 
          ? List<String>.from(data['favoriteProducts']) 
          : [],
      shippingAddresses: data['shippingAddresses'] != null 
          ? List<Map<String, dynamic>>.from(data['shippingAddresses']) 
          : [],
      businessName: data['businessName'],
      businessDescription: data['businessDescription'],
      businessImages: data['businessImages'] != null 
          ? List<String>.from(data['businessImages']) 
          : null,
      businessAddress: data['businessAddress'],
      isVerifiedSeller: data['isVerifiedSeller'] ?? false,
    );
  }
  
  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'favoriteProducts': favoriteProducts,
      'shippingAddresses': shippingAddresses,
    };
    
    // Add seller-specific fields only if the user is a seller
    if (role == UserRole.seller) {
      data['businessName'] = businessName;
      data['businessDescription'] = businessDescription;
      data['businessImages'] = businessImages;
      data['businessAddress'] = businessAddress;
      data['isVerifiedSeller'] = isVerifiedSeller;
    }
    
    return data;
  }
  
  // Create a copy with updated properties
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoURL,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    List<String>? favoriteProducts,
    List<Map<String, dynamic>>? shippingAddresses,
    String? businessName,
    String? businessDescription,
    List<String>? businessImages,
    String? businessAddress,
    bool? isVerifiedSeller,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      shippingAddresses: shippingAddresses ?? this.shippingAddresses,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      businessImages: businessImages ?? this.businessImages,
      businessAddress: businessAddress ?? this.businessAddress,
      isVerifiedSeller: isVerifiedSeller ?? this.isVerifiedSeller,
    );
  }
  
  bool get isSeller => role == UserRole.seller;
  bool get isBuyer => role == UserRole.buyer;
} 