import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order_message.dart';

class OrderMessageRepository {
  final FirebaseFirestore _firestore;

  OrderMessageRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

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

  Stream<int> getUnreadMessageCount(String userId) {
    return _firestore
        .collection('order_messages')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> deleteOrderMessage(String messageId) async {
    try {
      await _firestore.collection('order_messages').doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete order message: $e');
    }
  }
}