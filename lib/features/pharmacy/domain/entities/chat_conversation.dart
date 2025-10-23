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
  });

  factory ChatConversation.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatConversation(
      id: id,
      userId: data['userId'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime']?.toDate() ?? DateTime.now(),
      hasUnreadMessages: data['hasUnreadMessages'] ?? false,
      unreadCount: data['unreadCount'] ?? 0,
      pharmacyName: data['pharmacyName'] ?? '',
      pharmacyImageUrl: data['pharmacyImageUrl'] ?? '',
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
    };
  }
}