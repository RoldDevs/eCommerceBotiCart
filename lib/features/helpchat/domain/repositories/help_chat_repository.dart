import '../entities/help_chat_message.dart';

abstract class HelpChatRepository {
  Stream<List<HelpChatMessage>> getUserChatMessages(String userUID);
  Future<void> sendMessage(HelpChatMessage message);
  Future<void> clearChatHistory(String userUID);
}