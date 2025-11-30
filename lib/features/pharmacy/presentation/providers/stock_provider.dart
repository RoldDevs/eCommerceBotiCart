import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/services/stock_service.dart';
import '../../domain/entities/order.dart';

final stockServiceProvider = Provider<StockService>((ref) {
  return StockService();
});

final stockProvider =
    StateNotifierProvider.family<StockNotifier, AsyncValue<int>, String>((
      ref,
      medicineId,
    ) {
      return StockNotifier(ref.read(stockServiceProvider), medicineId);
    });

class StockNotifier extends StateNotifier<AsyncValue<int>> {
  final StockService _stockService;
  final String _medicineId;

  StockNotifier(this._stockService, this._medicineId)
    : super(const AsyncValue.loading()) {
    _loadStock();
  }

  Future<void> _loadStock() async {
    try {
      final stock = await _stockService.getMedicineStock(_medicineId);
      state = AsyncValue.data(stock);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateStock(int newStock) async {
    try {
      await _stockService.updateMedicineStock(_medicineId, newStock);
      state = AsyncValue.data(newStock);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> decreaseStockForOrder(OrderEntity order) async {
    try {
      await _stockService.decreaseStockForOrder(order);
      await _loadStock(); // Reload stock after decrease
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> checkSufficientStock(int requestedQuantity) async {
    try {
      return !await _stockService.hasInsufficientStock(
        _medicineId,
        requestedQuantity,
      );
    } catch (e) {
      return false;
    }
  }
}

// Provider for watching stock changes in real-time
final stockStreamProvider = StreamProvider.family<int, String>((
  ref,
  medicineId,
) {
  final stockService = ref.read(stockServiceProvider);
  return stockService.watchMedicineStock(medicineId);
});
