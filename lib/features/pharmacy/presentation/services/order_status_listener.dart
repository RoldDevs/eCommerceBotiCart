import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/medicine.dart';
import '../../data/repositories/order_status_change_repository.dart';
import 'order_message_service.dart';
import '../providers/pharmacy_providers.dart';

final orderStatusListenerProvider = Provider<OrderStatusListener>((ref) {
  return OrderStatusListener(ref);
});

class OrderStatusListener {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  OrderStatusListener(this._ref);

  // Start listening to order status changes
  void startListening() {
    _firestore.collection('orders').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          _handleOrderUpdate(change.doc);
        }
      }
    });
  }

  // Handle order updates
  Future<void> _handleOrderUpdate(DocumentSnapshot doc) async {
    try {
      final currentData = doc.data() as Map<String, dynamic>;
      final order = OrderEntity.fromFirestore(doc);

      // Get previous state from document metadata or cache
      // For now, we'll check the current state and create status change if needed
      await _trackVerificationFieldChanges(order, currentData);
      await _trackPickupStatusChanges(order, currentData);

      // Check if order just became completely verified
      if (order.isCompletelyVerified && order.isPaid) {
        await _createInTransitMessage(order);
      }
    // ignore: empty_catches
    } catch (e) {
    }
  }

  // Track verification field changes and create status change records
  Future<void> _trackVerificationFieldChanges(
    OrderEntity order,
    Map<String, dynamic> currentData,
  ) async {
    try {
      final statusChangeRepo = OrderStatusChangeRepository();

      // Check if verification fields indicate a status change that needs notification
      // Indicator should show when: isInitiallyVerified: True, isPaid: False, isCompletelyVerified: False
      if (order.isHomeDelivery &&
          order.isInitiallyVerified &&
          !order.isPaid &&
          !order.isCompletelyVerified) {
        // Check if status change record already exists for this state
        final existingChanges = await _firestore
            .collection('orderStatusChanges')
            .where('orderId', isEqualTo: order.orderID)
            .where('userId', isEqualTo: order.userUID)
            .where('newStatus', isEqualTo: 'Initial Verification')
            .get();

        if (existingChanges.docs.isEmpty) {
          await statusChangeRepo.createStatusChange(
            orderId: order.orderID,
            userId: order.userUID,
            oldStatus: 'Pending Verification',
            newStatus: 'Initial Verification',
            timestamp: DateTime.now(),
          );
        }
      }

      // Track payment status change
      if (order.isPaid &&
          order.isInitiallyVerified &&
          !order.isCompletelyVerified) {
        final existingChanges = await _firestore
            .collection('orderStatusChanges')
            .where('orderId', isEqualTo: order.orderID)
            .where('userId', isEqualTo: order.userUID)
            .where('newStatus', isEqualTo: 'Payment Submitted')
            .get();

        if (existingChanges.docs.isEmpty) {
          await statusChangeRepo.createStatusChange(
            orderId: order.orderID,
            userId: order.userUID,
            oldStatus: 'Initial Verification',
            newStatus: 'Payment Submitted',
            timestamp: DateTime.now(),
          );
        }
      }

      // Track final verification
      if (order.isCompletelyVerified && order.isPaid) {
        final existingChanges = await _firestore
            .collection('orderStatusChanges')
            .where('orderId', isEqualTo: order.orderID)
            .where('userId', isEqualTo: order.userUID)
            .where('newStatus', isEqualTo: 'Final Verification')
            .get();

        if (existingChanges.docs.isEmpty) {
          await statusChangeRepo.createStatusChange(
            orderId: order.orderID,
            userId: order.userUID,
            oldStatus: 'Payment Submitted',
            newStatus: 'Final Verification',
            timestamp: DateTime.now(),
          );
        }
      }
    // ignore: empty_catches
    } catch (e) {
      }
  }

  // Track pickup status changes and create status change records
  Future<void> _trackPickupStatusChanges(
    OrderEntity order,
    Map<String, dynamic> currentData,
  ) async {
    try {
      // Only track for pickup orders
      if (order.isHomeDelivery) return;

      final statusChangeRepo = OrderStatusChangeRepository();
      final pickupStatus = order.pickupStatus;

      // Track when order becomes ready for pickup
      if (pickupStatus == 'ready') {
        final existingChanges = await _firestore
            .collection('orderStatusChanges')
            .where('orderId', isEqualTo: order.orderID)
            .where('userId', isEqualTo: order.userUID)
            .where('newStatus', isEqualTo: 'Ready for Pickup')
            .get();

        if (existingChanges.docs.isEmpty) {
          await statusChangeRepo.createStatusChange(
            orderId: order.orderID,
            userId: order.userUID,
            oldStatus: 'Preparing',
            newStatus: 'Ready for Pickup',
            timestamp: DateTime.now(),
          );
        }
      }

      // Track when order is picked up
      if (pickupStatus == 'picked_up') {
        final existingChanges = await _firestore
            .collection('orderStatusChanges')
            .where('orderId', isEqualTo: order.orderID)
            .where('userId', isEqualTo: order.userUID)
            .where('newStatus', isEqualTo: 'Picked Up')
            .get();

        if (existingChanges.docs.isEmpty) {
          await statusChangeRepo.createStatusChange(
            orderId: order.orderID,
            userId: order.userUID,
            oldStatus: 'Ready for Pickup',
            newStatus: 'Picked Up',
            timestamp: DateTime.now(),
          );
        }
      }
    // ignore: empty_catches
    } catch (e) {
    }
  }

  // Create in-transit message when order is completely verified
  Future<void> _createInTransitMessage(OrderEntity order) async {
    try {
      final orderMessageService = _ref.read(orderMessageServiceProvider);

      // Get medicine details
      final medicineDoc = await _firestore
          .collection('medicines')
          .doc(order.medicineID)
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

      // Get pharmacy details
      final pharmacies = _ref.read(pharmaciesStreamProvider).value ?? [];
      final pharmacy = pharmacies.firstWhere(
        (p) => p.storeID == order.storeID,
        orElse: () => throw Exception('Pharmacy not found'),
      );

      // Check if in-transit message already exists for this order
      final existingMessages = await _firestore
          .collection('order_messages')
          .where('orderId', isEqualTo: order.orderID)
          .where('type', isEqualTo: 'inTransit')
          .get();

      if (existingMessages.docs.isEmpty) {
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
}
