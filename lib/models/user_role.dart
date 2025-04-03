enum UserRole {
  buyer,
  seller,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.seller:
        return 'Seller';
    }
  }
  
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.toString().split('.').last == value,
      orElse: () => UserRole.buyer,
    );
  }
} 