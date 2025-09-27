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
          .where('userUID', isEqualTo: userUID)
          .snapshots()
          .map((snapshot) {
        final messages = snapshot.docs.map((doc) {
          return HelpChatMessage.fromFirestore(doc.data(), doc.id);
        }).toList();
        
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return messages;
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendMessage(HelpChatMessage message) async {
    await _firestore.collection('helpchat').add(message.toMap());
  }

  @override
  Future<void> clearChatHistory(String userUID) async {
    final batch = _firestore.batch();
    final messages = await _firestore
        .collection('helpchat')
        .where('userUID', isEqualTo: userUID)
        .get();
    
    for (var message in messages.docs) {
      batch.delete(message.reference);
    }
    
    await batch.commit();
  }
}