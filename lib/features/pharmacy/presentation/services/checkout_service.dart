import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:boticart/core/config/app_config.dart';
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
import '../services/pickup_service.dart';
import '../models/pickup_time_slot.dart';
import '../models/pickup_promotion.dart';

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
    PickupTimeSlot? pickupTimeSlot,
    bool isCurbsidePickup = false,
    String? pickupInstructions,
    PickupPromotion? pickupPromotion,
  }) async {
    // Block delivery orders if feature is disabled
    if (isHomeDelivery && !AppConfig.isDeliveryEnabled) {
      throw Exception('Delivery are not yet available at this moment');
    }

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

    // Group items by storeID
    final Map<int, List<dynamic>> itemsByStore = {};
    for (final item in selectedItems) {
      if (!itemsByStore.containsKey(item.medicine.storeID)) {
        itemsByStore[item.medicine.storeID] = [];
      }
      itemsByStore[item.medicine.storeID]!.add(item);
    }

    final List<String> orderIds = [];
    final DateTime orderTime = DateTime.now();

    try {
      // Process each store separately
      for (final storeEntry in itemsByStore.entries) {
        final storeID = storeEntry.key;
        final storeItems = storeEntry.value;

        // Check stock availability for all items in this store
        for (final item in storeItems) {
          final hasStock = !await _stockService.hasInsufficientStock(
            item.medicine.id,
            item.quantity,
          );
          if (!hasStock) {
            throw Exception(
              'Insufficient stock for ${item.medicine.medicineName}. Please reduce quantity or remove from cart.',
            );
          }
        }

        // Calculate totals for the entire order
        double orderSubtotal = 0.0;
        int totalQuantity = 0;
        final List<Map<String, dynamic>> orderItemsData = [];

        for (final item in storeItems) {
          // Decrease stock immediately during checkout
          await _stockService.decreaseStockForCheckout(
            item.medicine.id,
            item.quantity,
          );

          final itemPrice = item.medicine.price * item.quantity;
          orderSubtotal += itemPrice;
          totalQuantity += item.quantity as int;

          orderItemsData.add({
            'medicineID': item.medicine.id,
            'medicineName': item.medicine.medicineName,
            'quantity': item.quantity,
            'price': item.medicine.price,
            'totalPrice': itemPrice,
            'imageURL': item.medicine.imageURL,
          });
        }

        // Calculate discount for the entire order if beneficiary ID is provided
        double discountAmount = 0.0;
        if (beneficiaryId != null && beneficiaryId.isNotEmpty) {
          discountAmount = orderSubtotal * 0.20; // 20% discount
        }

        // Apply pickup promotion discount if applicable
        double pickupDiscountAmount = 0.0;
        if (!isHomeDelivery && pickupPromotion != null) {
          pickupDiscountAmount = pickupPromotion.calculateDiscount(
            orderSubtotal - discountAmount,
          );
        }

        final orderTotalPrice =
            orderSubtotal - discountAmount - pickupDiscountAmount;

        // Use the first item's medicineID for backward compatibility
        final firstItem = storeItems.first;

        // Calculate ready-by time for pickup orders
        DateTime? readyByTime;
        String? expressPickupLane;
        if (!isHomeDelivery) {
          final pickupService = PickupService();
          readyByTime = await pickupService.calculateReadyByTime(
            itemCount: storeItems.length,
            totalQuantity: totalQuantity,
            scheduledPickupTime: pickupTimeSlot?.startTime,
          );
          expressPickupLane = pickupTimeSlot?.expressLane;

          // Reserve items for pickup
          await pickupService.reserveItemsForPickup(
            orderId: '', // Will be set after order creation
            items: orderItemsData,
          );
        }

        final order = OrderEntity(
          orderID: '', // Will be set by repository
          medicineID: firstItem.medicine.id,
          userUID: user.id,
          storeID: storeID,
          quantity: totalQuantity,
          totalPrice: orderTotalPrice,
          status: isHomeDelivery ? OrderStatus.toProcess : OrderStatus.toPickup,
          idDiscount: beneficiaryId,
          createdAt: orderTime,
          deliveryAddress: deliveryAddress,
          isHomeDelivery: isHomeDelivery,
          discountAmount: discountAmount,
          scheduledPickupTime: pickupTimeSlot?.startTime,
          readyByTime: readyByTime,
          isCurbsidePickup: isCurbsidePickup,
          pickupInstructions: pickupInstructions,
          pickupStatus: !isHomeDelivery ? 'preparing' : null,
          pickupDiscountAmount: pickupDiscountAmount > 0
              ? pickupDiscountAmount
              : null,
          expressPickupLane: expressPickupLane,
        );

        final orderId = await _orderRepository.createOrder(order);

        // Create order items subcollection
        await _orderRepository.createOrderItems(orderId, orderItemsData);

        // Update reserved items with actual order ID for pickup orders
        if (!isHomeDelivery) {
          final pickupService = PickupService();
          // Release the temporary reservation and create proper one
          await pickupService.releaseReservedItems(
            orderId: '',
            items: orderItemsData,
          );
          await pickupService.reserveItemsForPickup(
            orderId: orderId,
            items: orderItemsData,
          );
        }

        orderIds.add(orderId);

        // Create initial order message with all items
        await _createOrderMessageForMultipleItems(
          orderId: orderId,
          orderItems: storeItems,
          totalPrice: orderTotalPrice,
          userUID: user.id,
          storeID: storeID,
          messageType: 'order_placed',
          isHomeDelivery: isHomeDelivery,
          deliveryAddress: isHomeDelivery ? deliveryAddress : null,
        );

        if (isHomeDelivery) {
          final pharmacyData = await _getPharmacyData(storeID);
          final pharmacyAddress = pharmacyData['address'] as String;
          final pickupCoordinates = pharmacyData['coordinates'] as LatLng?;

          final deliveryCoordinates = await getLocationFromAddress(
            deliveryAddress,
          );

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
    PickupTimeSlot? pickupTimeSlot,
    bool isCurbsidePickup = false,
    String? pickupInstructions,
    PickupPromotion? pickupPromotion,
  }) async {
    // Block delivery orders if feature is disabled
    if (isHomeDelivery && !AppConfig.isDeliveryEnabled) {
      throw Exception('Delivery are not yet available at this moment');
    }

    final userAsyncValue = _ref.read(currentUserProvider);
    final user = userAsyncValue.value;

    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Check stock availability before processing
      final hasStock = !await _stockService.hasInsufficientStock(
        medicine.id,
        quantity,
      );
      if (!hasStock) {
        throw Exception(
          'Insufficient stock for ${medicine.medicineName}. Available stock may have changed.',
        );
      }

      // Decrease stock immediately during checkout
      await _stockService.decreaseStockForCheckout(medicine.id, quantity);

      double discountAmount = 0.0;
      if (beneficiaryId != null && beneficiaryId.isNotEmpty) {
        final basePrice = medicine.price * quantity;
        discountAmount = basePrice * 0.20;
      }

      // Apply pickup promotion discount if applicable
      double pickupDiscountAmount = 0.0;
      final basePrice = (medicine.price * quantity) - discountAmount;
      if (!isHomeDelivery && pickupPromotion != null) {
        pickupDiscountAmount = pickupPromotion.calculateDiscount(basePrice);
      }

      final totalPrice = basePrice - pickupDiscountAmount;

      // Calculate ready-by time for pickup orders
      DateTime? readyByTime;
      String? expressPickupLane;
      if (!isHomeDelivery) {
        final pickupService = PickupService();
        readyByTime = await pickupService.calculateReadyByTime(
          itemCount: 1,
          totalQuantity: quantity,
          scheduledPickupTime: pickupTimeSlot?.startTime,
        );
        expressPickupLane = pickupTimeSlot?.expressLane;

        // Reserve item for pickup
        await pickupService.reserveItemsForPickup(
          orderId: '', // Will be set after order creation
          items: [
            {'medicineID': medicine.id, 'quantity': quantity},
          ],
        );
      }

      final order = OrderEntity(
        orderID: '',
        medicineID: medicine.id,
        userUID: user.id,
        storeID: medicine.storeID,
        quantity: quantity,
        totalPrice: totalPrice,
        status: isHomeDelivery ? OrderStatus.toProcess : OrderStatus.toPickup,
        idDiscount: beneficiaryId,
        createdAt: DateTime.now(),
        deliveryAddress: deliveryAddress,
        isHomeDelivery: isHomeDelivery,
        discountAmount: discountAmount,
        scheduledPickupTime: pickupTimeSlot?.startTime,
        readyByTime: readyByTime,
        isCurbsidePickup: isCurbsidePickup,
        pickupInstructions: pickupInstructions,
        pickupStatus: !isHomeDelivery ? 'preparing' : null,
        pickupDiscountAmount: pickupDiscountAmount > 0
            ? pickupDiscountAmount
            : null,
        expressPickupLane: expressPickupLane,
      );

      final orderId = await _orderRepository.createOrder(order);

      // Update reserved items with actual order ID for pickup orders
      if (!isHomeDelivery) {
        final pickupService = PickupService();
        // Release the temporary reservation and create proper one
        await pickupService.releaseReservedItems(
          orderId: '',
          items: [
            {'medicineID': medicine.id, 'quantity': quantity},
          ],
        );
        await pickupService.reserveItemsForPickup(
          orderId: orderId,
          items: [
            {'medicineID': medicine.id, 'quantity': quantity},
          ],
        );
      }

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

        final deliveryCoordinates = await getLocationFromAddress(
          deliveryAddress,
        );

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
        } else {}
      }

      return orderId;
    } catch (e) {
      throw Exception('Checkout failed: $e');
    }
  }

  Future<void> _createOrderMessageForMultipleItems({
    required String orderId,
    required List<dynamic> orderItems,
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

      // Get the first item for the order entity (for backward compatibility)
      final firstItem = orderItems.first;

      final order = OrderEntity(
        orderID: orderId,
        medicineID: firstItem.medicine.id,
        userUID: userUID,
        storeID: storeID,
        quantity: orderItems.fold(
          0,
          (sum, item) => sum + (item.quantity as int),
        ),
        totalPrice: totalPrice,
        status: OrderStatus.toProcess,
        createdAt: DateTime.now(),
        isHomeDelivery: isHomeDelivery,
        deliveryAddress: deliveryAddress,
      );

      if (messageType == 'order_placed') {
        await orderMessageService
            .createOrderConfirmationMessageForMultipleItems(
              order: order,
              orderItems: orderItems,
              pharmacy: pharmacy,
            );
      } else if (messageType == 'in_transit') {
        await orderMessageService.createInTransitMessageForMultipleItems(
          order: order,
          orderItems: orderItems,
          pharmacy: pharmacy,
        );
      }
      // ignore: empty_catches
    } catch (e) {}
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
    } catch (e) {}
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
      final medicineDoc = await _firestore
          .collection('medicines')
          .doc(medicineId)
          .get();
      if (!medicineDoc.exists) return;

      final medicineData = medicineDoc.data()!;
      final medicine = Medicine(
        id: medicineDoc.id,
        medicineName: medicineData['medicineName'] ?? '',
        price: (medicineData['price'] ?? 0.0).toDouble(),
        imageURL: medicineData['imageURL'] ?? '',
        productDescription: medicineData['productDescription'] ?? '',
        productOffering: List<String>.from(
          medicineData['productOffering'] ?? [],
        ),
        storeID: medicineData['storeID'] ?? 0,
        createdAt:
            (medicineData['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        updatedAt:
            (medicineData['updatedAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        majorType: MedicineMajorType.values.firstWhere(
          (e) =>
              e.toString().split('.').last ==
              (medicineData['majorType'] ?? 'generic'),
          orElse: () => MedicineMajorType.generic,
        ),
        productType: MedicineProductType.values.firstWhere(
          (e) =>
              e.toString().split('.').last ==
              (medicineData['productType'] ?? 'overTheCounter'),
          orElse: () => MedicineProductType.overTheCounter,
        ),
        conditionType: MedicineConditionType.values.firstWhere(
          (e) =>
              e.toString().split('.').last ==
              (medicineData['conditionType'] ?? 'other'),
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
    } catch (e) {}
  }

  Future<Map<String, dynamic>> _getPharmacyData(int storeId) async {
    try {
      final pharmaciesAsyncValue = _ref.read(pharmaciesStreamProvider);

      final pharmacies = pharmaciesAsyncValue.value ?? [];
      final pharmacy = pharmacies.firstWhere(
        (p) => p.storeID == storeId,
        orElse: () =>
            throw Exception('Pharmacy not found for storeID: $storeId'),
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
      return {'address': '', 'name': '', 'contact': '', 'coordinates': null};
    }
  }
}

final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return CheckoutService(orderRepository, ref);
});
