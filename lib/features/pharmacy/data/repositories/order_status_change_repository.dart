import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for managing order status change tracking
class OrderStatusChangeRepository {
  final FirebaseFirestore _firestore;

  OrderStatusChangeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get unread status changes count for a user
  Stream<int> getUnreadStatusChangesCount(String userId) {
    return _firestore
        .collection('orderStatusChanges')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Check if an order has unread status changes
  Future<bool> hasUnreadStatusChanges(String orderId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orderStatusChanges')
          .where('orderId', isEqualTo: orderId)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Mark order status changes as read for a specific order
  Future<void> markOrderStatusChangesAsRead(
    String orderId,
    String userId,
  ) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('orderStatusChanges')
          .where('orderId', isEqualTo: orderId)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark order status changes as read: $e');
    }
  }

  /// Mark all order status changes as read for a user
  Future<void> markAllStatusChangesAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('orderStatusChanges')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all status changes as read: $e');
    }
  }

  /// Create a status change record (called when order status changes)
  Future<void> createStatusChange({
    required String orderId,
    required String userId,
    required String oldStatus,
    required String newStatus,
    required DateTime timestamp,
  }) async {
    try {
      await _firestore.collection('orderStatusChanges').add({
        'orderId': orderId,
        'userId': userId,
        'oldStatus': oldStatus,
        'newStatus': newStatus,
        'timestamp': timestamp,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create status change record: $e');
    }
  }
}
