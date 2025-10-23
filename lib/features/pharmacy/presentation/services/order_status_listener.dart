import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/medicine.dart';
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
      final order = OrderEntity.fromFirestore(doc);
      
      // Check if order just became completely verified
      if (order.isCompletelyVerified && order.isPaid) {
        await _createInTransitMessage(order);
      }
    } catch (e) {
      print('Error handling order update: $e');
    }
  }

  // Create in-transit message when order is completely verified
  Future<void> _createInTransitMessage(OrderEntity order) async {
    try {
      final orderMessageService = _ref.read(orderMessageServiceProvider);
      
      // Get medicine details
      final medicineDoc = await _firestore.collection('medicines').doc(order.medicineID).get();
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
    } catch (e) {
      print('Error creating in-transit message: $e');
    }
  }
}