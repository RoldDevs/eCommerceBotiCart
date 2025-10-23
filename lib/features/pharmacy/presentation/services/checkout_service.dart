import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/pharmacy_providers.dart';
import '../providers/location_provider.dart';
import 'order_message_service.dart';
import '../../data/services/stock_service.dart';

class CheckoutService {
  final OrderRepository _orderRepository;
  final Ref _ref;
  final StockService _stockService = StockService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CheckoutService(this._orderRepository, this._ref);

  Future<List<String>> checkoutSelectedItems({
    required String deliveryAddress,
    required bool isHomeDelivery,
    String? beneficiaryId,
  }) async {
    final userAsyncValue = _ref.read(currentUserProvider);
    final user = userAsyncValue.value;
    
    if (user == null) {
      throw Exception('User not logged in');
    }

    final cartNotifier = _ref.read(cartProvider.notifier);
    final cartItems = _ref.read(cartProvider);
    final selectedItems = cartItems.where((item) => item.isSelected).toList();

    if (selectedItems.isEmpty) {
      throw Exception('No items selected for checkout');
    }

    final List<String> orderIds = [];

    try {
      for (final item in selectedItems) {
        // Check stock availability before processing
        final hasStock = !await _stockService.hasInsufficientStock(item.medicine.id, item.quantity);
        if (!hasStock) {
          throw Exception('Insufficient stock for ${item.medicine.medicineName}. Please reduce quantity or remove from cart.');
        }

        // Decrease stock immediately during checkout
        await _stockService.decreaseStockForCheckout(item.medicine.id, item.quantity);

        // Calculate discount if beneficiary ID is provided
        double discountAmount = 0.0;
        if (beneficiaryId != null && beneficiaryId.isNotEmpty) {
          final basePrice = item.medicine.price * item.quantity;
          discountAmount = basePrice * 0.20; // 20% discount
        }

        final totalPrice = (item.medicine.price * item.quantity) - discountAmount;

        final order = OrderEntity(
          orderID: '', // Will be set by repository
          medicineID: item.medicine.id,
          userUID: user.id,
          storeID: item.medicine.storeID,
          quantity: item.quantity,
          totalPrice: totalPrice,
          status: OrderStatus.toProcess,
          idDiscount: beneficiaryId,
          createdAt: DateTime.now(),
          deliveryAddress: deliveryAddress,
          isHomeDelivery: isHomeDelivery,
          discountAmount: discountAmount,
        );

        final orderId = await _orderRepository.createOrder(order);
        orderIds.add(orderId);
        
        // Create initial order message
        await _createOrderMessage(
          orderId: orderId,
          medicine: item.medicine,
          quantity: item.quantity,
          totalPrice: totalPrice,
          userUID: user.id,
          storeID: item.medicine.storeID,
          messageType: 'order_placed',
          isHomeDelivery: isHomeDelivery,
          deliveryAddress: isHomeDelivery ? deliveryAddress : null,
        );
        
        if (isHomeDelivery) {
          final pharmacyData = await _getPharmacyData(item.medicine.storeID);
          final pharmacyAddress = pharmacyData['address'] as String;
          final pickupCoordinates = pharmacyData['coordinates'] as LatLng?;
          
          final deliveryCoordinates = await getLocationFromAddress(deliveryAddress);
          
          if (pickupCoordinates != null && deliveryCoordinates != null) {
            await _orderRepository.createLalamoveDelivery(
              orderId: orderId,
              customerName: user.firstName,
              pharmacyName: pharmacyData['name'] as String,
              pickupAddress: pharmacyAddress,
              deliveryAddress: deliveryAddress,
              customerPhone: user.contact,
              pharmacyPhone: pharmacyData['contact'] as String,
              pickupCoordinates: pickupCoordinates,
              deliveryCoordinates: deliveryCoordinates,
            );
          } else {
          }
        }
      }

      await cartNotifier.removeSelectedItems();

      return orderIds;
    } catch (e) {
      throw Exception('Checkout failed: $e');
    }
  }

  Future<String> checkoutSingleItem({
    required Medicine medicine,
    required int quantity,
    required String deliveryAddress,
    required bool isHomeDelivery,
    String? beneficiaryId,
  }) async {
    final userAsyncValue = _ref.read(currentUserProvider);
    final user = userAsyncValue.value;
    
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Check stock availability before processing
      final hasStock = !await _stockService.hasInsufficientStock(medicine.id, quantity);
      if (!hasStock) {
        throw Exception('Insufficient stock for ${medicine.medicineName}. Available stock may have changed.');
      }

      // Decrease stock immediately during checkout
      await _stockService.decreaseStockForCheckout(medicine.id, quantity);

      double discountAmount = 0.0;
      if (beneficiaryId != null && beneficiaryId.isNotEmpty) {
        final basePrice = medicine.price * quantity;
        discountAmount = basePrice * 0.20; 
      }

      final totalPrice = (medicine.price * quantity) - discountAmount;

      final order = OrderEntity(
        orderID: '', 
        medicineID: medicine.id,
        userUID: user.id,
        storeID: medicine.storeID,
        quantity: quantity,
        totalPrice: totalPrice,
        status: OrderStatus.toProcess,
        idDiscount: beneficiaryId,
        createdAt: DateTime.now(),
        deliveryAddress: deliveryAddress,
        isHomeDelivery: isHomeDelivery,
        discountAmount: discountAmount,
      );

      final orderId = await _orderRepository.createOrder(order);
      
      await _createOrderMessage(
        orderId: orderId,
        medicine: medicine,
        quantity: quantity,
        totalPrice: totalPrice,
        userUID: user.id,
        storeID: medicine.storeID,
        messageType: 'order_placed',
        isHomeDelivery: isHomeDelivery,
        deliveryAddress: isHomeDelivery ? deliveryAddress : null,
      );
      
      if (isHomeDelivery) {
        final pharmacyData = await _getPharmacyData(medicine.storeID);
        final pharmacyAddress = pharmacyData['address'] as String;
        final pickupCoordinates = pharmacyData['coordinates'] as LatLng?;
        
        final deliveryCoordinates = await getLocationFromAddress(deliveryAddress);
        
        if (pickupCoordinates != null && deliveryCoordinates != null) {
          await _orderRepository.createLalamoveDelivery(
            orderId: orderId,
            pickupAddress: pharmacyAddress,
            deliveryAddress: deliveryAddress,
            customerPhone: user.contact,
            customerName: user.firstName,
            pharmacyName: pharmacyData['name'] as String,
            pharmacyPhone: pharmacyData['contact'] as String,
            pickupCoordinates: pickupCoordinates,
            deliveryCoordinates: deliveryCoordinates,
          );
        } else {
        }
      }

      return orderId;
    } catch (e) {
      throw Exception('Checkout failed: $e');
    }
  }

  Future<void> _createOrderMessage({
    required String orderId,
    required Medicine medicine,
    required int quantity,
    required double totalPrice,
    required String userUID,
    required int storeID,
    required String messageType,
    bool isHomeDelivery = false,
    String? deliveryAddress,
  }) async {
    try {
      final orderMessageService = _ref.read(orderMessageServiceProvider);
      
      final pharmacies = _ref.read(pharmaciesStreamProvider).value ?? [];
      final pharmacy = pharmacies.firstWhere(
        (p) => p.storeID == storeID,
        orElse: () => throw Exception('Pharmacy not found'),
      );
      
      final order = OrderEntity(
        orderID: orderId,
        medicineID: medicine.id,
        userUID: userUID,
        storeID: storeID,
        quantity: quantity,
        totalPrice: totalPrice,
        status: OrderStatus.toProcess,
        createdAt: DateTime.now(),
        isHomeDelivery: isHomeDelivery,
        deliveryAddress: deliveryAddress,
      );
      
      if (messageType == 'order_placed') {
        await orderMessageService.createOrderConfirmationMessage(
          order: order,
          medicine: medicine,
          pharmacy: pharmacy,
        );
      } else if (messageType == 'in_transit') {
        await orderMessageService.createInTransitMessage(
          order: order,
          medicine: medicine,
          pharmacy: pharmacy,
        );
      }
    // ignore: empty_catches
    } catch (e) {

    }
  }

  Future<void> createInTransitMessage({
    required String orderId,
    required String medicineId,
    required int quantity,
    required double totalPrice,
    required String userUID,
    required int storeID,
  }) async {
    try {
      final medicineDoc = await _firestore.collection('medicines').doc(medicineId).get();
      if (!medicineDoc.exists) return;
      
      final medicineData = medicineDoc.data()!;
      final medicine = Medicine(
        id: medicineDoc.id,
        medicineName: medicineData['medicineName'] ?? '',
        price: (medicineData['price'] ?? 0.0).toDouble(),
        imageURL: medicineData['imageURL'] ?? '',
        productDescription: medicineData['productDescription'] ?? '',
        productOffering: List<String>.from(medicineData['productOffering'] ?? []),
        storeID: medicineData['storeID'] ?? 0,
        createdAt: (medicineData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (medicineData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        majorType: MedicineMajorType.values.firstWhere(
          (e) => e.toString().split('.').last == (medicineData['majorType'] ?? 'generic'),
          orElse: () => MedicineMajorType.generic,
        ),
        productType: MedicineProductType.values.firstWhere(
          (e) => e.toString().split('.').last == (medicineData['productType'] ?? 'overTheCounter'),
          orElse: () => MedicineProductType.overTheCounter,
        ),
        conditionType: MedicineConditionType.values.firstWhere(
          (e) => e.toString().split('.').last == (medicineData['conditionType'] ?? 'other'),
          orElse: () => MedicineConditionType.other,
        ),
        stock: medicineData['stock'] ?? 0,
      );

      await _createOrderMessage(
        orderId: orderId,
        medicine: medicine,
        quantity: quantity,
        totalPrice: totalPrice,
        userUID: userUID,
        storeID: storeID,
        messageType: 'in_transit',
      );
    // ignore: empty_catches
    } catch (e) {
    }
  }
  
  Future<Map<String, dynamic>> _getPharmacyData(int storeId) async {
    try {
      final pharmaciesAsyncValue = _ref.read(pharmaciesStreamProvider);
      
      final pharmacies = pharmaciesAsyncValue.value ?? [];
      final pharmacy = pharmacies.firstWhere(
        (p) => p.storeID == storeId,
        orElse: () => throw Exception('Pharmacy not found for storeID: $storeId'),
      );
      
      LatLng? coordinates;
      try {
        coordinates = await getLocationFromAddress(pharmacy.location);
      } catch (e) {
        coordinates = null;
      }
      
      return {
        'address': pharmacy.location,
        'name': pharmacy.name,
        'contact': pharmacy.contact,
        'coordinates': coordinates,
      };
    } catch (e) {
      return {
        'address': '',
        'name': '',
        'contact': '',
        'coordinates': null,
      };
    }
  }
}

final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return CheckoutService(orderRepository, ref);
});