import 'package:flutter/material.dart';
import 'package:boticart/features/pharmacy/presentation/screens/messages_screen.dart';
import 'package:boticart/features/pharmacy/presentation/screens/chat_detail_screen.dart';
import 'package:boticart/features/pharmacy/presentation/screens/order_message_detail_screen.dart';
import 'package:boticart/features/pharmacy/domain/entities/order_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle navigation from notifications
class NotificationNavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Navigate based on notification data
  static void navigateFromNotification(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type'] as String?;

    switch (type) {
      case 'chat':
        _navigateToChat(data, navigator);
        break;
      case 'order':
        _navigateToOrderMessage(data, navigator);
        break;
      default:
        // Default to messages screen
        navigator.push(
          MaterialPageRoute(builder: (context) => const MessagesScreen()),
        );
    }
  }

  /// Navigate to chat detail screen
  static void _navigateToChat(
    Map<String, dynamic> data,
    NavigatorState navigator,
  ) {
    final conversationId = data['conversationId'] as String?;
    final pharmacyId = data['pharmacyId'] as String?;
    final pharmacyName = data['pharmacyName'] as String? ?? 'Pharmacy';

    if (conversationId != null && pharmacyId != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            conversationId: conversationId,
            pharmacyName: pharmacyName,
            pharmacyImageUrl: '',
            pharmacyId: pharmacyId,
          ),
        ),
      );
    } else {
      // Fallback to messages screen
      navigator.push(
        MaterialPageRoute(builder: (context) => const MessagesScreen()),
      );
    }
  }

  /// Navigate to order message detail screen
  static void _navigateToOrderMessage(
    Map<String, dynamic> data,
    NavigatorState navigator,
  ) async {
    final orderId = data['orderId'] as String?;

    if (orderId != null) {
      try {
        // Fetch the order message from Firestore
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('order_messages')
            .where('orderId', isEqualTo: orderId)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (messagesSnapshot.docs.isNotEmpty) {
          final messageDoc = messagesSnapshot.docs.first;
          final message = OrderMessage.fromFirestore(messageDoc);

          navigator.push(
            MaterialPageRoute(
              builder: (context) => OrderMessageDetailScreen(message: message),
            ),
          );
        } else {
          // Fallback to messages screen
          navigator.push(
            MaterialPageRoute(builder: (context) => const MessagesScreen()),
          );
        }
      } catch (e) {
        print('Error navigating to order message: $e');
        // Fallback to messages screen
        navigator.push(
          MaterialPageRoute(builder: (context) => const MessagesScreen()),
        );
      }
    } else {
      // Fallback to messages screen
      navigator.push(
        MaterialPageRoute(builder: (context) => const MessagesScreen()),
      );
    }
  }
}
