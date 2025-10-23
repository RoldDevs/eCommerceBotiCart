import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/stock_service.dart';
import '../../domain/entities/order.dart';
import '../providers/order_provider.dart';

final orderStockHandlerProvider = Provider<OrderStockHandler>((ref) {
  return OrderStockHandler(ref);
});

class OrderStockHandler {
  final Ref _ref;
  final StockService _stockService = StockService();

  OrderStockHandler(this._ref);

  /// Initialize order status listener to handle stock decreases
  void initializeOrderListener() {
    _ref.listen<AsyncValue<List<OrderEntity>>>(
      userOrdersProvider,
      (previous, next) {
        next.whenData((orders) {
          if (previous != null) {
            previous.whenData((previousOrders) {
              _handleOrderStatusChanges(previousOrders, orders);
            });
          }
        });
      },
    );
  }

  /// Handle order status changes and decrease stock when appropriate
  void _handleOrderStatusChanges(List<OrderEntity> previousOrders, List<OrderEntity> currentOrders) {
    for (final currentOrder in currentOrders) {
      final previousOrder = previousOrders.firstWhere(
        (order) => order.orderID == currentOrder.orderID,
        orElse: () => currentOrder,
      );

      // Check if order became "In Transit" (which means it's ready for delivery and stock should be decreased)
      final wasNotInTransit = previousOrder.status != OrderStatus.inTransit;
      final isNowInTransit = currentOrder.status == OrderStatus.inTransit;

      if (wasNotInTransit && isNowInTransit) {
        _decreaseStockForOrder(currentOrder);
      }
    }
  }

  /// Decrease stock for a specific order
  Future<void> _decreaseStockForOrder(OrderEntity order) async {
    try {
      await _stockService.decreaseStockForOrder(order);
    } catch (e) {
      // Log error or handle appropriately
      print('Failed to decrease stock for order ${order.orderID}: $e');
    }
  }

  /// Manually decrease stock for an order (can be called from UI)
  Future<void> decreaseStockForOrder(OrderEntity order) async {
    await _decreaseStockForOrder(order);
  }
}