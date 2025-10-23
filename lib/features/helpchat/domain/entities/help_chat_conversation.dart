class HelpChatConversation {
  final String id;
  final String userId;
  final String userName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool hasUnreadMessages;
  final int unreadCount;

  HelpChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
  });

  factory HelpChatConversation.fromFirestore(Map<String, dynamic> data, String id) {
    return HelpChatConversation(
      id: id,
      userId: data['userId'] ?? data['senderUID'] ?? '',
      userName: data['userName'] ?? data['senderName'] ?? 'User',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime']?.toDate() ?? DateTime.now(),
      hasUnreadMessages: data['hasUnreadMessages'] ?? false,
      unreadCount: data['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'hasUnreadMessages': hasUnreadMessages,
      'unreadCount': unreadCount,
    };
  }
}