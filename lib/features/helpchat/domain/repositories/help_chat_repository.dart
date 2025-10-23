import '../entities/help_chat_message.dart';

abstract class HelpChatRepository {
  Stream<List<HelpChatMessage>> getUserChatMessages(String userUID);
  Future<void> sendMessage(HelpChatMessage message);
  Future<void> clearChatHistory(String userUID);
  Future<void> sendAdminReply({
    required String userUID,
    required String adminUID,
    required String adminName,
    required String content,
  });
  Future<void> addAdminReply({
    required String messageId,
    required String adminUID,
    required String adminName,
    required String replyContent,
  });
  Stream<List<Map<String, dynamic>>> getAllConversations();
  Future<HelpChatMessage?> getMessageById(String messageId);
}