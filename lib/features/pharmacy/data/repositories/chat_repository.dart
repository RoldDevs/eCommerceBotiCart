import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/pharmacy.dart';
import '../../../../core/services/fcm_notification_service.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FCMNotificationService _notificationService = FCMNotificationService();

  ChatRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  // Get all conversations for a user
  Stream<List<ChatConversation>> getUserConversations(String userId) {
    try {
      return _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) => ChatConversation.fromFirestore(doc.data(), doc.id),
                )
                .toList();
          })
          .handleError((error) {
            // Check if the error is due to missing index
            if (error is FirebaseException &&
                error.code == 'failed-precondition' &&
                error.message != null &&
                error.message!.contains('index')) {
              // Return empty list instead of throwing error
              return [];
            }
            throw error;
          });
    } catch (e) {
      // Fallback to a simpler query without ordering if there's an issue
      return _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final conversations = snapshot.docs
                .map(
                  (doc) => ChatConversation.fromFirestore(doc.data(), doc.id),
                )
                .toList();

            // Sort locally instead of in the query
            conversations.sort(
              (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
            );
            return conversations;
          });
    }
  }

  // Get messages for a specific conversation
  Stream<List<ChatMessage>> getConversationMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  // Send a new message
  Future<void> sendMessage(String conversationId, ChatMessage message) async {
    try {
      // Validate conversationId
      if (conversationId.isEmpty) {
        throw Exception(
          'Invalid conversation ID: A document path must be a non-empty string',
        );
      }

      // Add message to the conversation's messages subcollection
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message.toFirestore());

      // Update the conversation with the last message info
      final updateData = <String, dynamic>{
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp,
        'lastMessageSenderType': message.senderType,
      };

      // Only mark as unread if pharmacy/admin sent it
      if (message.senderType != 'customer') {
        updateData['hasUnreadMessages'] = true;
        updateData['unreadCount'] = FieldValue.increment(1);
      } else {
        // User sent message - don't mark as unread
        updateData['hasUnreadMessages'] = false;
        // Don't change unreadCount for user messages
      }

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update(updateData);

      // Send notification if message is from pharmacy/admin
      if (message.senderType != 'customer') {
        try {
          // Get conversation to find userId
          final conversationDoc = await _firestore
              .collection('conversations')
              .doc(conversationId)
              .get();
          
          if (conversationDoc.exists) {
            final conversationData = conversationDoc.data()!;
            final userId = conversationData['userId'] as String;
            final pharmacyName = conversationData['pharmacyName'] as String? ?? 'Pharmacy';
            final pharmacyId = conversationData['pharmacyId'] as String? ?? '';

            await _notificationService.sendChatNotification(
              userId: userId,
              conversationId: conversationId,
              pharmacyName: pharmacyName,
              message: message.content,
              pharmacyId: pharmacyId,
            );
          }
        } catch (e) {
          // Don't fail message sending if notification fails
          print('Error sending notification: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Create a new conversation
  Future<String> createConversation(String userId, Pharmacy pharmacy) async {
    try {
      // Check if conversation already exists
      final existingConversation = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .where('pharmacyId', isEqualTo: pharmacy.id)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        return existingConversation.docs.first.id;
      }

      // Create new conversation
      final conversationData = ChatConversation(
        id: '',
        userId: userId,
        pharmacyId: pharmacy.id,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        hasUnreadMessages: false,
        pharmacyName: pharmacy.name,
        pharmacyImageUrl: pharmacy.imageUrl,
      ).toFirestore();

      final docRef = await _firestore
          .collection('conversations')
          .add(conversationData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Mark conversation messages as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'hasUnreadMessages': false,
        'unreadCount': 0,
      });
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  // Add this method after the existing sendMessage method
  Future<void> addReplyToMessage({
    required String conversationId,
    required String messageId,
    required String replyContent,
    required String replySenderId,
    required String replySenderName,
    required String replySenderType,
  }) async {
    try {
      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);

      final reply = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': replySenderId,
        'senderName': replySenderName,
        'senderType': replySenderType,
        'content': replyContent,
        'timestamp': DateTime.now(),
      };

      await messageRef.update({
        'replies': FieldValue.arrayUnion([reply]),
      });

      // Update conversation with latest reply
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': replyContent,
        'lastMessageTime': DateTime.now(),
        'lastMessageSenderType': replySenderType,
        'hasUnreadMessages': true,
        'unreadCount': FieldValue.increment(1),
      });

      // Send notification if reply is from pharmacy/admin
      if (replySenderType != 'customer') {
        try {
          final conversationDoc = await _firestore
              .collection('conversations')
              .doc(conversationId)
              .get();
          
          if (conversationDoc.exists) {
            final conversationData = conversationDoc.data()!;
            final userId = conversationData['userId'] as String;
            final pharmacyName = conversationData['pharmacyName'] as String? ?? 'Pharmacy';
            final pharmacyId = conversationData['pharmacyId'] as String? ?? '';

            await _notificationService.sendChatNotification(
              userId: userId,
              conversationId: conversationId,
              pharmacyName: pharmacyName,
              message: replyContent,
              pharmacyId: pharmacyId,
            );
          }
        } catch (e) {
          print('Error sending notification: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to add reply: $e');
    }
  }
}
