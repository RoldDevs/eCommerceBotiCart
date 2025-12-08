import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to send FCM notifications via Cloud Functions or HTTP
/// Note: In production, this should be done via Cloud Functions for security
class FCMNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification to a user
  /// This method should be called from Cloud Functions in production
  /// For now, we'll create a Firestore trigger document that Cloud Functions can listen to
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Create a notification request document in Firestore
      // Cloud Functions will listen to this and send the actual notification
      await _firestore.collection('notification_requests').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      print('Error creating notification request: $e');
    }
  }

  /// Send chat message notification
  Future<void> sendChatNotification({
    required String userId,
    required String conversationId,
    required String pharmacyName,
    required String message,
    required String pharmacyId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'New message from $pharmacyName',
      body: message,
      data: {
        'type': 'chat',
        'conversationId': conversationId,
        'pharmacyId': pharmacyId,
        'pharmacyName': pharmacyName,
      },
    );
  }

  /// Send order message notification
  Future<void> sendOrderNotification({
    required String userId,
    required String orderId,
    required String title,
    required String message,
    required String pharmacyId,
    required String messageType,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: message,
      data: {
        'type': 'order',
        'orderId': orderId,
        'pharmacyId': pharmacyId,
        'messageType': messageType,
      },
    );
  }
}
