import 'package:boticart/features/pharmacy/presentation/providers/order_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/lalamove_service.dart';

final lalamoveServiceProvider = Provider<LalamoveService>((ref) {
  return LalamoveService();
});

// Provider to track delivery status updates
final deliveryStatusProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
      final orderRepository = ref.watch(orderRepositoryProvider);
      await orderRepository.updateLalamoveDeliveryStatus(orderId);
      final order = await orderRepository.getOrderById(orderId);

      return {
        'status': order?.lalamoveStatus ?? 'Unknown',
        'driverName': order?.lalamoveDriverName,
        'driverPhone': order?.lalamoveDriverPhone,
        'trackingUrl': order?.lalamoveTrackingUrl,
      };
    });
