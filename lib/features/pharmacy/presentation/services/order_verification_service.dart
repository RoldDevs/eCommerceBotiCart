import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/pharmacy.dart';

final orderVerificationServiceProvider = Provider<OrderVerificationService>((
  ref,
) {
  return OrderVerificationService();
});

class OrderVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get order by ID
  Future<OrderEntity?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderEntity.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Get pharmacy by store ID
  Future<Pharmacy?> getPharmacyByStoreId(int storeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('pharmacy')
          .where('storeID', isEqualTo: storeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Pharmacy.fromFirestore(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get pharmacy: $e');
    }
  }

  // Upload payment receipt to Firebase Storage
  Future<String> uploadPaymentReceipt({
    required File receiptFile,
    required String pharmacyName,
    required String userUID,
    required String orderId,
  }) async {
    try {
      // Clean pharmacy name for folder structure
      final cleanPharmacyName = pharmacyName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim();

      // Create storage path
      final storageRef = _storage.ref().child(
        '$cleanPharmacyName-receipts/$userUID/${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Upload file
      final uploadTask = await storageRef.putFile(receiptFile);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload receipt: $e');
    }
  }

  // Update order payment status
  Future<void> updateOrderPaymentStatus({
    required String orderId,
    required String receiptUrl,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'isPaid': true,
        'paymentReceiptUrl': receiptUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order payment status: $e');
    }
  }

  // Listen to order verification status changes
  Stream<OrderEntity> listenToOrderVerification(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => OrderEntity.fromFirestore(doc));
  }

  // Check if order should show in orders list (only completely verified orders)
  bool shouldShowInOrdersList(OrderEntity order) {
    if (!order.isHomeDelivery) {
      return true; // Show pickup orders immediately
    }
    return order
        .isCompletelyVerified; // Only show verified home delivery orders
  }
}
