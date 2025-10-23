import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order.dart';

class StockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateMedicineStock(String medicineId, int newStock) async {
    try {
      await _firestore
          .collection('medicines')
          .doc(medicineId)
          .update({'stock': newStock});
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  Future<void> decreaseStockForOrder(OrderEntity order) async {
    if (!order.isPaid || !order.isCompletelyVerified) {
      return; 
    }

    try {
      final medicineDoc = await _firestore
          .collection('medicines')
          .doc(order.medicineID)
          .get();

      if (!medicineDoc.exists) {
        throw Exception('Medicine not found');
      }

      final currentStock = medicineDoc.data()?['stock'] ?? 0;
      final newStock = currentStock - order.quantity;

      if (newStock < 0) {
        throw Exception('Insufficient stock');
      }

      await _firestore
          .collection('medicines')
          .doc(order.medicineID)
          .update({'stock': newStock});
    } catch (e) {
      throw Exception('Failed to decrease stock: $e');
    }
  }

  Future<void> decreaseStockForCheckout(String medicineId, int quantity) async {
    try {
      final medicineDoc = await _firestore
          .collection('medicines')
          .doc(medicineId)
          .get();

      if (!medicineDoc.exists) {
        throw Exception('Medicine not found');
      }

      final currentStock = medicineDoc.data()?['stock'] ?? 0;
      final newStock = currentStock - quantity;

      if (newStock < 0) {
        throw Exception('Insufficient stock. Available: $currentStock, Requested: $quantity');
      }

      await _firestore
          .collection('medicines')
          .doc(medicineId)
          .update({
            'stock': newStock,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to decrease stock during checkout: $e');
    }
  }

  Future<bool> hasInsufficientStock(String medicineId, int requestedQuantity) async {
    try {
      final medicineDoc = await _firestore
          .collection('medicines')
          .doc(medicineId)
          .get();

      if (!medicineDoc.exists) {
        return true; 
      }

      final currentStock = medicineDoc.data()?['stock'] ?? 0;
      return currentStock < requestedQuantity;
    } catch (e) {
      return true; 
    }
  }

  Future<int> getMedicineStock(String medicineId) async {
    try {
      final medicineDoc = await _firestore
          .collection('medicines')
          .doc(medicineId)
          .get();

      if (!medicineDoc.exists) {
        return 0;
      }

      return medicineDoc.data()?['stock'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Stream<int> watchMedicineStock(String medicineId) {
    return _firestore
        .collection('medicines')
        .doc(medicineId)
        .snapshots()
        .map((doc) => doc.data()?['stock'] ?? 0);
  }
}