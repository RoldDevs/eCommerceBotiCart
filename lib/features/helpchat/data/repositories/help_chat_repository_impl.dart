import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/help_chat_message.dart';
import '../../domain/repositories/help_chat_repository.dart';

class HelpChatRepositoryImpl implements HelpChatRepository {
  final FirebaseFirestore _firestore;

  HelpChatRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<HelpChatMessage>> getUserChatMessages(String userUID) {
    try {
      return _firestore
          .collection('helpchat')
          .where('participants', arrayContains: userUID)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return HelpChatMessage.fromFirestore(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      // Fallback query without orderBy if index doesn't exist
      return _firestore
          .collection('helpchat')
          .where('participants', arrayContains: userUID)
          .snapshots()
          .map((snapshot) {
        final messages = snapshot.docs.map((doc) {
          return HelpChatMessage.fromFirestore(doc.data(), doc.id);
        }).toList();
        
        // Sort locally
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return messages;
      });
    }
  }

  @override
  Future<void> sendMessage(HelpChatMessage message) async {
    // Create a conversation document that includes both user and admin
    final conversationData = {
      ...message.toMap(),
      'participants': [message.senderUID, 'admin'], // Include admin for queries
      'conversationId': message.senderUID, // Use userUID as conversation identifier
      'lastMessage': message.content,
      'lastMessageTime': message.timestamp,
      'hasUnreadMessages': message.senderType == 'user', // Mark as unread if from user
    };

    await _firestore.collection('helpchat').add(conversationData);
  }

  @override
  Future<void> clearChatHistory(String userUID) async {
    final batch = _firestore.batch();
    final messages = await _firestore
        .collection('helpchat')
        .where('participants', arrayContains: userUID)
        .get();
    
    for (var message in messages.docs) {
      batch.delete(message.reference);
    }
    
    await batch.commit();
  }

  @override
  Future<void> addAdminReply({
    required String messageId,
    required String adminUID,
    required String adminName,
    required String replyContent,
  }) async {
    final messageRef = _firestore.collection('helpchat').doc(messageId);
    
    final replyData = {
      'content': replyContent,
      'senderType': 'admin',
      'senderName': adminName,
      'senderUID': adminUID,
      'timestamp': DateTime.now(),
    };

    await messageRef.update({
      'replies': FieldValue.arrayUnion([replyData]),
      'lastMessage': replyContent,
      'lastMessageTime': DateTime.now(),
      'hasUnreadMessages': true, // Mark as unread for user
    });
  }

  // New method for admin to reply (alternative approach - creates new message)
  @override
  Future<void> sendAdminReply({
    required String userUID,
    required String adminUID,
    required String adminName,
    required String content,
  }) async {
    final adminMessage = HelpChatMessage(
      id: '',
      content: content,
      senderUID: adminUID,
      senderName: adminName,
      senderType: 'admin',
      timestamp: DateTime.now(),
    );

    final messageData = {
      ...adminMessage.toMap(),
      'participants': [userUID, adminUID],
      'conversationId': userUID,
      'lastMessage': content,
      'lastMessageTime': DateTime.now(),
      'hasUnreadMessages': true, // Mark as unread for user
    };

    await _firestore.collection('helpchat').add(messageData);
  }

  // Get all conversations for admin panel
  @override
  Stream<List<Map<String, dynamic>>> getAllConversations() {
    return _firestore
        .collection('helpchat')
        .where('senderType', isEqualTo: 'user')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      // Group messages by conversationId (userUID)
      Map<String, Map<String, dynamic>> conversations = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final conversationId = data['conversationId'] ?? data['senderUID'];
        
        if (!conversations.containsKey(conversationId) || 
            (data['timestamp'] as Timestamp).toDate().isAfter(
              (conversations[conversationId]!['timestamp'] as Timestamp).toDate()
            )) {
          conversations[conversationId] = {
            ...data,
            'id': doc.id,
          };
        }
      }
      
      return conversations.values.toList();
    });
  }

  // Get specific message by ID for admin to reply to
  @override
  Future<HelpChatMessage?> getMessageById(String messageId) async {
    try {
      final doc = await _firestore.collection('helpchat').doc(messageId).get();
      if (doc.exists) {
        return HelpChatMessage.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}