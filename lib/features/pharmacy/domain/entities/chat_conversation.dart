class ChatConversation {
  final String id;
  final String userId;
  final String pharmacyId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool hasUnreadMessages;
  final int unreadCount;
  final String pharmacyName;
  final String pharmacyImageUrl;
  final String lastMessageSenderType;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.pharmacyId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
    required this.pharmacyName,
    required this.pharmacyImageUrl,
    this.lastMessageSenderType = 'customer',
  });

  factory ChatConversation.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatConversation(
      id: id,
      userId: (data['userId'] as String?) ?? '',
      pharmacyId: (data['pharmacyId'] as String?) ?? '',
      lastMessage: (data['lastMessage'] as String?) ?? '',
      lastMessageTime: data['lastMessageTime']?.toDate() ?? DateTime.now(),
      hasUnreadMessages: (data['hasUnreadMessages'] as bool?) ?? false,
      unreadCount: (data['unreadCount'] as int?) ?? 0,
      pharmacyName: (data['pharmacyName'] as String?) ?? '',
      pharmacyImageUrl: (data['pharmacyImageUrl'] as String?) ?? '',
      lastMessageSenderType:
          (data['lastMessageSenderType'] as String?) ?? 'customer',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pharmacyId': pharmacyId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'hasUnreadMessages': hasUnreadMessages,
      'unreadCount': unreadCount,
      'pharmacyName': pharmacyName,
      'pharmacyImageUrl': pharmacyImageUrl,
      'lastMessageSenderType': lastMessageSenderType,
    };
  }
}
