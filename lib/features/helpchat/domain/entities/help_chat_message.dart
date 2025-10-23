import 'package:cloud_firestore/cloud_firestore.dart';

class HelpChatMessage {
  final String id;
  final String content;
  final String senderUID;
  final String senderName;
  final String senderType; // 'user' or 'admin'
  final DateTime timestamp;
  final bool isRead;
  final List<Map<String, dynamic>> replies;

  HelpChatMessage({
    required this.id,
    required this.content,
    required this.senderUID,
    required this.senderName,
    required this.senderType,
    required this.timestamp,
    this.isRead = false,
    this.replies = const [],
  });

  factory HelpChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    // Safely handle replies conversion
    List<Map<String, dynamic>> repliesList = [];
    if (data['replies'] != null) {
      final repliesData = data['replies'] as List;
      repliesList = repliesData.map((reply) {
        if (reply is Map<String, dynamic>) {
          // Convert timestamp if it's a Timestamp object
          final replyMap = Map<String, dynamic>.from(reply);
          if (replyMap['timestamp'] is Timestamp) {
            replyMap['timestamp'] = (replyMap['timestamp'] as Timestamp).toDate();
          }
          return replyMap;
        } else if (reply is Map) {
          // Convert Map<String, Object?> to Map<String, dynamic>
          final replyMap = Map<String, dynamic>.from(reply);
          if (replyMap['timestamp'] is Timestamp) {
            replyMap['timestamp'] = (replyMap['timestamp'] as Timestamp).toDate();
          }
          return replyMap;
        } else if (reply is String) {
          // Handle incorrect format where reply is just a string
          return <String, dynamic>{
            'content': reply,
            'senderType': 'admin',
            'senderName': 'Support Admin',
            'timestamp': DateTime.now(),
          };
        } else {
          // Handle unexpected data types
          return <String, dynamic>{
            'content': reply.toString(),
            'senderType': 'admin',
            'senderName': 'Support Admin',
            'timestamp': DateTime.now(),
          };
        }
      }).toList();
    }

    return HelpChatMessage(
      id: id,
      content: data['content'] ?? '',
      senderUID: data['senderUID'] ?? '',
      senderName: data['senderName'] ?? '',
      senderType: data['senderType'] ?? 'user',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      replies: repliesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'senderUID': senderUID,
      'senderName': senderName,
      'senderType': senderType,
      'timestamp': timestamp,
      'isRead': isRead,
      'replies': replies,
    };
  }

  HelpChatMessage copyWith({
    String? id,
    String? content,
    String? senderUID,
    String? senderName,
    String? senderType,
    DateTime? timestamp,
    bool? isRead,
    List<Map<String, dynamic>>? replies,
  }) {
    return HelpChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderUID: senderUID ?? this.senderUID,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      replies: replies ?? this.replies,
    );
  }

  bool get isFromUser => senderType == 'user';
  bool get isFromAdmin => senderType == 'admin';
  bool get hasReplies => replies.isNotEmpty;
}