import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/pharmacy.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

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
            if (error is FirebaseException &&
                error.code == 'failed-precondition' &&
                error.message != null &&
                error.message!.contains('index')) {
              return [];
            }
            throw error;
          });
    } catch (e) {
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

            conversations.sort(
              (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
            );
            return conversations;
          });
    }
  }

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

  Future<void> sendMessage(String conversationId, ChatMessage message) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message.toFirestore());

      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp,
        'hasUnreadMessages': true,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<String> createConversation(String userId, Pharmacy pharmacy) async {
    try {
      final existingConversation = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .where('pharmacyId', isEqualTo: pharmacy.id)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        return existingConversation.docs.first.id;
      }

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

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'hasUnreadMessages': false,
      });
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

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

      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': replyContent,
        'lastMessageTime': DateTime.now(),
        'hasUnreadMessages': true,
      });
    } catch (e) {
      throw Exception('Failed to add reply: $e');
    }
  }
}
