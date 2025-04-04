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
  
  // Enhanced Seller/Artisan specific fields
  final String? businessName;
  final String? businessDescription;
  final List<String>? businessImages;
  final String? businessAddress;
  final bool isVerifiedSeller;
  
  // Payment details
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankIFSC;
  final String? upiId;
  final String? preferredPayoutMethod; // 'bank' or 'upi'
  
  // New Artisan Storytelling fields
  final String? artisanStory;           // Personal story of the artisan
  final List<String>? craftProcessImages; // Images showing the craft process
  final String? craftHistory;           // History/tradition of their craft
  final int? yearsOfExperience;         // Years of experience in the craft
  final List<String>? awards;           // Awards or recognitions received
  final List<String>? certifications;   // Certifications or qualifications
  final List<Map<String, dynamic>>? virtualEvents; // Upcoming or past virtual events
  final List<String>? skillsAndTechniques; // Specific skills and techniques
  final String? craftRegion;            // Region where the craft originates
  
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
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankIFSC,
    this.upiId,
    this.preferredPayoutMethod,
    this.artisanStory,
    this.craftProcessImages,
    this.craftHistory,
    this.yearsOfExperience,
    this.awards,
    this.certifications,
    this.virtualEvents,
    this.skillsAndTechniques,
    this.craftRegion,
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
      bankAccountName: data['bankAccountName'],
      bankAccountNumber: data['bankAccountNumber'],
      bankIFSC: data['bankIFSC'],
      upiId: data['upiId'],
      preferredPayoutMethod: data['preferredPayoutMethod'],
      artisanStory: data['artisanStory'],
      craftProcessImages: data['craftProcessImages'] != null 
          ? List<String>.from(data['craftProcessImages']) 
          : null,
      craftHistory: data['craftHistory'],
      yearsOfExperience: data['yearsOfExperience'],
      awards: data['awards'] != null 
          ? List<String>.from(data['awards']) 
          : null,
      certifications: data['certifications'] != null 
          ? List<String>.from(data['certifications']) 
          : null,
      virtualEvents: data['virtualEvents'] != null 
          ? List<Map<String, dynamic>>.from(data['virtualEvents']) 
          : null,
      skillsAndTechniques: data['skillsAndTechniques'] != null 
          ? List<String>.from(data['skillsAndTechniques']) 
          : null,
      craftRegion: data['craftRegion'],
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
      
      // Add the new artisan storytelling fields
      data['artisanStory'] = artisanStory;
      data['craftProcessImages'] = craftProcessImages;
      data['craftHistory'] = craftHistory;
      data['yearsOfExperience'] = yearsOfExperience;
      data['awards'] = awards;
      data['certifications'] = certifications;
      data['virtualEvents'] = virtualEvents;
      data['skillsAndTechniques'] = skillsAndTechniques;
      data['craftRegion'] = craftRegion;
      
      // Add payment details
      data['bankAccountName'] = bankAccountName;
      data['bankAccountNumber'] = bankAccountNumber;
      data['bankIFSC'] = bankIFSC;
      data['upiId'] = upiId;
      data['preferredPayoutMethod'] = preferredPayoutMethod;
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
    String? bankAccountName,
    String? bankAccountNumber,
    String? bankIFSC,
    String? upiId,
    String? preferredPayoutMethod,
    String? artisanStory,
    List<String>? craftProcessImages,
    String? craftHistory,
    int? yearsOfExperience,
    List<String>? awards,
    List<String>? certifications,
    List<Map<String, dynamic>>? virtualEvents,
    List<String>? skillsAndTechniques,
    String? craftRegion,
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
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIFSC: bankIFSC ?? this.bankIFSC,
      upiId: upiId ?? this.upiId,
      preferredPayoutMethod: preferredPayoutMethod ?? this.preferredPayoutMethod,
      artisanStory: artisanStory ?? this.artisanStory,
      craftProcessImages: craftProcessImages ?? this.craftProcessImages,
      craftHistory: craftHistory ?? this.craftHistory,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      awards: awards ?? this.awards,
      certifications: certifications ?? this.certifications,
      virtualEvents: virtualEvents ?? this.virtualEvents,
      skillsAndTechniques: skillsAndTechniques ?? this.skillsAndTechniques,
      craftRegion: craftRegion ?? this.craftRegion,
    );
  }
  
  bool get isSeller => role == UserRole.seller;
  bool get isBuyer => role == UserRole.buyer;
} 