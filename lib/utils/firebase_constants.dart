/// Constants for Firebase collections and other Firebase-related values
class FirebaseConstants {
  // Collection names
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';
  static const String cartsCollection = 'carts';
  static const String wishlistsCollection = 'wishlists';
  static const String reviewsCollection = 'reviews';
  static const String chatsCollection = 'chats';
  static const String paymentsCollection = 'payments';
  static const String notificationsCollection = 'notifications';
  static const String sellerActivitiesCollection = 'sellerActivities';
  
  // Storage paths
  static const String productsStoragePath = 'products';
  static const String userProfilesStoragePath = 'user_profiles';
  
  // Document fields
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';
  
  // Order status values
  static const String orderStatusPending = 'pending';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusShipped = 'shipped';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';
  
  // Payment status values
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';
} 