import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order_message.dart';

class OrderMessageRepository {
  final FirebaseFirestore _firestore;

  OrderMessageRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // Create a new order message
  Future<String> createOrderMessage(OrderMessage message) async {
    try {
      final docRef = _firestore.collection('order_messages').doc();
      final messageWithId = message.copyWith(id: docRef.id);
      
      await docRef.set(messageWithId.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order message: $e');
    }
  }

  // Get order messages for a specific user
  Stream<List<OrderMessage>> getUserOrderMessages(String userId) {
    return _firestore
        .collection('order_messages')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderMessage.fromFirestore(doc))
            .toList());
  }

  // Get order messages for a specific order
  Stream<List<OrderMessage>> getOrderMessages(String orderId) {
    return _firestore
        .collection('order_messages')
        .where('orderId', isEqualTo: orderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderMessage.fromFirestore(doc))
            .toList());
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore
          .collection('order_messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Get unread message count for user
  Stream<int> getUnreadMessageCount(String userId) {
    return _firestore
        .collection('order_messages')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete order message
  Future<void> deleteOrderMessage(String messageId) async {
    try {
      await _firestore.collection('order_messages').doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete order message: $e');
    }
  }
}