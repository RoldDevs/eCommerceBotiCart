import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementType { general, maintenance, promotion, update, emergency }

class Announcement {
  final String id;
  final String title;
  final String message;
  final AnnouncementType type;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final int? storeID;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.imageUrl,
    this.metadata,
    this.storeID,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: AnnouncementType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => AnnouncementType.general,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl'],
      metadata: data['metadata'],
      storeID: data['storeID'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'storeID': storeID,
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? message,
    AnnouncementType? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    int? storeID,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      storeID: storeID ?? this.storeID,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isVisible {
    return isActive && !isExpired;
  }
}
