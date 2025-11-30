import '../repositories/help_chat_repository.dart';

class ClearChatHistoryUseCase {
  final HelpChatRepository repository;

  ClearChatHistoryUseCase(this.repository);

  Future<void> call(String userUID) {
    return repository.clearChatHistory(userUID);
  }
}
