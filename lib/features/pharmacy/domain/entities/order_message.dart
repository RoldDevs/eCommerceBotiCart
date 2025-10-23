import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderMessageType {
  orderConfirmation,
  inTransit,
  delivered,
  cancelled,
  paymentReceived,
  verificationComplete
}

class OrderMessage {
  final String id;
  final String orderId;
  final String userId;
  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyImageUrl;
  final String title;
  final String message;
  final OrderMessageType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata; 

  OrderMessage({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyImageUrl,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
  });

  factory OrderMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderMessage(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      pharmacyImageUrl: data['pharmacyImageUrl'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: OrderMessageType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => OrderMessageType.orderConfirmation,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'userId': userId,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'pharmacyImageUrl': pharmacyImageUrl,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  OrderMessage copyWith({
    String? id,
    String? orderId,
    String? userId,
    String? pharmacyId,
    String? pharmacyName,
    String? pharmacyImageUrl,
    String? title,
    String? message,
    OrderMessageType? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return OrderMessage(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyImageUrl: pharmacyImageUrl ?? this.pharmacyImageUrl,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}