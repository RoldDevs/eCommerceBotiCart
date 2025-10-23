class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String senderName;
  final String senderType; 
  final List<Map<String, dynamic>> replies;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.senderName = '',
    this.senderType = 'customer',
    this.replies = const [],
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    List<Map<String, dynamic>> repliesList = [];
    if (data['replies'] != null) {
      final repliesData = data['replies'] as List;
      repliesList = repliesData.map((reply) {
        if (reply is Map<String, dynamic>) {
          return reply;
        } else if (reply is Map) {
          return Map<String, dynamic>.from(reply);
        } else if (reply is String) {
          return <String, dynamic>{
            'content': reply,
            'senderType': 'admin',
            'senderName': 'Admin',
            'timestamp': DateTime.now(),
          };
        } else {
          return <String, dynamic>{
            'content': reply.toString(),
            'senderType': 'admin',
            'senderName': 'Admin',
            'timestamp': DateTime.now(),
          };
        }
      }).toList();
    }

    return ChatMessage(
      id: id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      senderName: data['senderName'] ?? '',
      senderType: data['senderType'] ?? 'customer',
      replies: repliesList,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
      'isRead': isRead,
      'senderName': senderName,
      'senderType': senderType,
      'replies': replies,
    };
  }
}