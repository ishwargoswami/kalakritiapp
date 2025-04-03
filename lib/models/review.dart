import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final bool isVerifiedPurchase;
  final Map<String, int> helpfulCount; // UserId -> 1 (helpful) or 0 (not helpful)
  
  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    this.imageUrls,
    required this.createdAt,
    required this.isVerifiedPurchase,
    required this.helpfulCount,
  });
  
  // Create Review from Firestore document
  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Review(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userPhotoUrl: data['userPhotoUrl'],
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : null,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isVerifiedPurchase: data['isVerifiedPurchase'] ?? false,
      helpfulCount: data['helpfulCount'] != null 
          ? Map<String, int>.from(data['helpfulCount']) 
          : {},
    );
  }
  
  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerifiedPurchase': isVerifiedPurchase,
      'helpfulCount': helpfulCount,
    };
  }
  
  // Get total helpful count
  int get totalHelpfulCount {
    return helpfulCount.values.fold(0, (sum, value) => sum + value);
  }
  
  // Get count of people who marked this review
  int get totalVotes {
    return helpfulCount.length;
  }
  
  // Check if a user has marked this review as helpful
  bool isMarkedHelpfulBy(String userId) {
    return helpfulCount.containsKey(userId) && helpfulCount[userId] == 1;
  }
  
  // Create a copy with updated properties
  Review copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    double? rating,
    String? comment,
    List<String>? imageUrls,
    DateTime? createdAt,
    bool? isVerifiedPurchase,
    Map<String, int>? helpfulCount,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      helpfulCount: helpfulCount ?? this.helpfulCount,
    );
  }
} 