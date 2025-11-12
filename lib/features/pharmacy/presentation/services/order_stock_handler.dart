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

  void _handleOrderStatusChanges(List<OrderEntity> previousOrders, List<OrderEntity> currentOrders) {
    for (final currentOrder in currentOrders) {
      final previousOrder = previousOrders.firstWhere(
        (order) => order.orderID == currentOrder.orderID,
        orElse: () => currentOrder,
      );

      final wasNotInTransit = previousOrder.status != OrderStatus.inTransit;
      final isNowInTransit = currentOrder.status == OrderStatus.inTransit;

      if (wasNotInTransit && isNowInTransit) {
        _decreaseStockForOrder(currentOrder);
      }
    }
  }

  Future<void> _decreaseStockForOrder(OrderEntity order) async {
    try {
      await _stockService.decreaseStockForOrder(order);
    } catch (e) {
      // Log error or handle appropriately
    }
  }

  Future<void> decreaseStockForOrder(OrderEntity order) async {
    await _decreaseStockForOrder(order);
  }
}