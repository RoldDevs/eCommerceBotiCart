class HelpChatMessage {
  final String id;
  final String message;
  final String? reply;
  final String userUID;
  final String? adminUID;
  final DateTime createdAt;

  HelpChatMessage({
    required this.id,
    required this.message,
    this.reply,
    required this.userUID,
    this.adminUID,
    required this.createdAt,
  });

  factory HelpChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return HelpChatMessage(
      id: id,
      message: data['message'] ?? '',
      reply: data['reply'],
      userUID: data['userUID'] ?? '',
      adminUID: data['adminUID'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'reply': reply,
      'userUID': userUID,
      'adminUID': adminUID,
      'createdAt': createdAt,
    };
  }
}