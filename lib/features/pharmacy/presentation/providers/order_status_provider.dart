import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_status_listener.dart';
import '../services/order_stock_handler.dart';

// Provider to initialize and manage the order status listener
final orderStatusInitializerProvider = Provider<void>((ref) {
  final listener = ref.watch(orderStatusListenerProvider);
  listener.startListening();
  
  // Initialize the order stock handler to listen for stock decreases
  final stockHandler = ref.watch(orderStockHandlerProvider);
  stockHandler.initializeOrderListener();
  
  return;
});