import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/services/seller_service.dart';

// Provider for SellerService
final sellerServiceProvider = Provider<SellerService>((ref) {
  return SellerService();
}); 