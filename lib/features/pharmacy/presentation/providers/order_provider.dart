import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import 'delivery_provider.dart';

// Provider for OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final lalamoveService = ref.watch(lalamoveServiceProvider);
  return OrderRepository(
    firestore: firestore,
    lalamoveService: lalamoveService,
  );
});

// Provider for a single order by ID
final orderByIdProvider = FutureProvider.family<OrderEntity?, String>((ref, orderId) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository.getOrderById(orderId);
});

class OrderState {
  final Medicine? medicine;
  final int quantity;
  final bool isHomeDelivery;
  final String? address;
  final bool applyBeneficiaryDiscount;
  final String? selectedBeneficiaryId;
  final double? discountAmount;
  final bool isLoading;
  final String? error;

  OrderState({
    this.medicine,
    this.quantity = 1,
    this.isHomeDelivery = true,
    this.address,
    this.applyBeneficiaryDiscount = false,
    this.selectedBeneficiaryId,
    this.discountAmount,
    this.isLoading = false,
    this.error,
  });

  OrderState copyWith({
    Medicine? medicine,
    int? quantity,
    bool? isHomeDelivery,
    String? address,
    bool? applyBeneficiaryDiscount,
    String? selectedBeneficiaryId,
    double? discountAmount,
    bool? isLoading,
    String? error,
  }) {
    return OrderState(
      medicine: medicine ?? this.medicine,
      quantity: quantity ?? this.quantity,
      isHomeDelivery: isHomeDelivery ?? this.isHomeDelivery,
      address: address ?? this.address,
      applyBeneficiaryDiscount: applyBeneficiaryDiscount ?? this.applyBeneficiaryDiscount,
      selectedBeneficiaryId: selectedBeneficiaryId ?? this.selectedBeneficiaryId,
      discountAmount: discountAmount ?? this.discountAmount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  double get totalPrice {
    if (medicine == null) return 0.0;
    final basePrice = medicine!.price * quantity;
    return basePrice - (discountAmount ?? 0.0);
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderRepository _orderRepository;
  final Ref _ref;

  OrderNotifier(this._orderRepository, this._ref) : super(OrderState());

  void setMedicine(Medicine medicine) {
    state = state.copyWith(medicine: medicine);
  }

  void setQuantity(int quantity) {
    if (quantity > 0) {
      state = state.copyWith(quantity: quantity);
      _calculateDiscount();
    }
  }

  void setDeliveryMethod(bool isHomeDelivery) {
    state = state.copyWith(isHomeDelivery: isHomeDelivery);
  }

  void setAddress(String address) {
    state = state.copyWith(address: address);
  }

  void setBeneficiaryDiscount(bool apply, String? beneficiaryId) {
    state = state.copyWith(
      applyBeneficiaryDiscount: apply,
      selectedBeneficiaryId: beneficiaryId,
    );
    _calculateDiscount();
  }

  void _calculateDiscount() {
    if (state.applyBeneficiaryDiscount && state.medicine != null) {
      final basePrice = state.medicine!.price * state.quantity;
      final discount = basePrice * 0.20; // 20% discount
      state = state.copyWith(discountAmount: discount);
    } else {
      state = state.copyWith(discountAmount: 0.0);
    }
  }

  Future<String?> createOrder() async {
    if (state.medicine == null || state.address == null) {
      state = state.copyWith(error: 'Missing required information');
      return null;
    }

    final userAsyncValue = _ref.read(currentUserProvider);
    final user = userAsyncValue.value;
    
    if (user == null) {
      state = state.copyWith(error: 'User not logged in');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final order = OrderEntity(
        orderID: '', // Will be set by repository
        medicineID: state.medicine!.id,
        userUID: user.id,
        storeID: state.medicine!.storeID,
        quantity: state.quantity,
        totalPrice: state.totalPrice,
        status: OrderStatus.toProcess,
        idDiscount: state.selectedBeneficiaryId,
        createdAt: DateTime.now(),
        deliveryAddress: state.address,
        isHomeDelivery: state.isHomeDelivery,
        discountAmount: state.discountAmount,
      );

      final orderId = await _orderRepository.createOrder(order);
      state = state.copyWith(isLoading: false);
      return orderId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create order: $e',
      );
      return null;
    }
  }

  void resetOrder() {
    state = OrderState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return OrderNotifier(orderRepository, ref);
});

// Provider for user's orders
final userOrdersProvider = StreamProvider<List<OrderEntity>>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  final userAsyncValue = ref.watch(currentUserProvider);
  
  return userAsyncValue.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return orderRepository.getUserOrders(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Provider for orders by status
final ordersByStatusProvider = StreamProvider.family<List<OrderEntity>, OrderStatus>((ref, status) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  final userAsyncValue = ref.watch(currentUserProvider);
  
  return userAsyncValue.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return orderRepository.getUserOrdersByStatus(user.id, status);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Provider for order status filter
final selectedOrderStatusProvider = StateProvider<OrderStatus?>((ref) => null);

// Provider for filtered orders
final filteredOrdersProvider = Provider<AsyncValue<List<OrderEntity>>>((ref) {
  final selectedStatus = ref.watch(selectedOrderStatusProvider);
  final allOrders = ref.watch(userOrdersProvider);
  
  if (selectedStatus == null) {
    return allOrders;
  }
  
  return allOrders.when(
    data: (orders) => AsyncValue.data(
      orders.where((order) => order.status == selectedStatus).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});