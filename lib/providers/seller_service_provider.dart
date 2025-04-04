import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/services/seller_service.dart';
import 'package:kalakritiapp/models/order.dart';
import 'package:kalakritiapp/models/seller_product.dart';

/// Provider for seller service
final sellerServiceProvider = Provider<SellerService>((ref) {
  return SellerService();
});

/// Provider for inventory alerts (low stock products)
final inventoryAlertsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final sellerService = ref.watch(sellerServiceProvider);
  return await sellerService.getInventoryAlerts();
});

/// Provider for real-time order notifications
final recentOrdersProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  final sellerService = ref.watch(sellerServiceProvider);
  return sellerService.getRecentOrders();
});

/// Provider for all seller orders - updated to use stream
final sellerAllOrdersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final sellerService = ref.watch(sellerServiceProvider);
  return sellerService.getSellerOrdersStream().map(
    (orders) => orders.map((order) => order.toMap()).toList(),
  );
});

/// Provider for specific product access
final sellerProductProvider = FutureProvider.family<SellerProduct?, String>((ref, productId) async {
  final sellerService = ref.watch(sellerServiceProvider);
  return await sellerService.getProductById(productId);
});

/// Provider for specific order access
final sellerOrderProvider = FutureProvider.family<Order?, String>((ref, orderId) async {
  final sellerService = ref.watch(sellerServiceProvider);
  return await sellerService.getOrderById(orderId);
}); 