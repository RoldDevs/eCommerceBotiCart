import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/order_message.dart';
import '../services/order_message_service.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import 'pharmacy_providers.dart';

// Provider for user's order messages
final userOrderMessagesProvider = StreamProvider<List<OrderMessage>>((ref) {
  final orderMessageService = ref.watch(orderMessageServiceProvider);
  final userAsyncValue = ref.watch(currentUserProvider);
  
  return userAsyncValue.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return orderMessageService.getUserOrderMessages(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Provider for user's order messages filtered by selected pharmacy
final filteredUserOrderMessagesProvider = StreamProvider.autoDispose<List<OrderMessage>>((ref) {
  final orderMessagesAsyncValue = ref.watch(userOrderMessagesProvider);
  final selectedStoreId = ref.watch(selectedPharmacyStoreIdProvider);
  final pharmaciesAsyncValue = ref.watch(pharmaciesStreamProvider);
  
  return orderMessagesAsyncValue.when(
    data: (orderMessages) {
      if (selectedStoreId == null) return Stream.value([]);
      
      return pharmaciesAsyncValue.when(
        data: (pharmacies) {
          // Find the selected pharmacy
          final selectedPharmacy = pharmacies.firstWhere(
            (p) => p.storeID == selectedStoreId,
            orElse: () => throw Exception('Pharmacy not found'),
          );
          
          // Filter order messages by pharmacy ID
          final filteredMessages = orderMessages.where((message) => 
            message.pharmacyId == selectedPharmacy.id
          ).toList();
          
          return Stream.value(filteredMessages);
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Provider for order messages of a specific order
final orderMessagesProvider = StreamProvider.family<List<OrderMessage>, String>((ref, orderId) {
  final orderMessageService = ref.watch(orderMessageServiceProvider);
  return orderMessageService.getOrderMessages(orderId);
});

// Provider for unread message count
final unreadOrderMessageCountProvider = StreamProvider<int>((ref) {
  final orderMessageService = ref.watch(orderMessageServiceProvider);
  final userAsyncValue = ref.watch(currentUserProvider);
  
  return userAsyncValue.when(
    data: (user) {
      if (user == null) return Stream.value(0);
      return orderMessageService.getUnreadMessageCount(user.id);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

// Provider for selected message filter
final selectedMessageFilterProvider = StateProvider<String>((ref) => 'All');