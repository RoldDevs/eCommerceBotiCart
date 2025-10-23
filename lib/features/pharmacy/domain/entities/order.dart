import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  toProcess,
  toReceive,
  toShip,
  toPickup,
  inTransit,
  delivered,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.toProcess:
        return 'To Process';
      case OrderStatus.toReceive:
        return 'To Receive';
      case OrderStatus.toShip:
        return 'To Ship';
      case OrderStatus.toPickup:
        return 'To Pickup';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'to process':
      case 'toprocess':
        return OrderStatus.toProcess;
      case 'to receive':
      case 'toreceive':
        return OrderStatus.toReceive;
      case 'to ship':
      case 'toship':
        return OrderStatus.toShip;
      case 'to pickup':
      case 'topickup':
        return OrderStatus.toPickup;
      case 'in transit':
      case 'intransit':
        return OrderStatus.inTransit;
      case 'delivered':
        return OrderStatus.delivered;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.toProcess;
    }
  }
}

class OrderEntity {
  final String orderID;
  final String medicineID;
  final String userUID;
  final int storeID;
  final int quantity;
  final double totalPrice;
  final OrderStatus status;
  final String? idDiscount;
  final DateTime createdAt;
  final String? deliveryAddress;
  final bool isHomeDelivery;
  final double? discountAmount;
  final String? lalamoveOrderId;
  final String? lalamoveTrackingUrl;
  final String? lalamoveDriverName;
  final String? lalamoveDriverPhone;
  final String? lalamoveStatus;
  final bool isInitiallyVerified;
  final bool isPaid;
  final bool isCompletelyVerified;
  final String? paymentReceiptUrl;

  OrderEntity({
    required this.orderID,
    required this.medicineID,
    required this.userUID,
    required this.storeID,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    this.idDiscount,
    required this.createdAt,
    this.deliveryAddress,
    required this.isHomeDelivery,
    this.discountAmount,
    this.lalamoveOrderId,
    this.lalamoveTrackingUrl,
    this.lalamoveDriverName,
    this.lalamoveDriverPhone,
    this.lalamoveStatus,
    this.isInitiallyVerified = false,
    this.isPaid = false,
    this.isCompletelyVerified = false,
    this.paymentReceiptUrl,
  });

  // Convert OrderEntity to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'orderID': orderID,
      'medicineID': medicineID,
      'userUID': userUID,
      'storeID': storeID,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'status': status.displayName,
      'idDiscount': idDiscount,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveryAddress': deliveryAddress,
      'isHomeDelivery': isHomeDelivery,
      'discountAmount': discountAmount,
      'lalamoveOrderId': lalamoveOrderId,
      'lalamoveTrackingUrl': lalamoveTrackingUrl,
      'lalamoveDriverName': lalamoveDriverName,
      'lalamoveDriverPhone': lalamoveDriverPhone,
      'lalamoveStatus': lalamoveStatus,
      'isInitiallyVerified': isInitiallyVerified,
      'isPaid': isPaid,
      'isCompletelyVerified': isCompletelyVerified,
      'paymentReceiptUrl': paymentReceiptUrl,
    };
  }

  // Create OrderEntity from Firestore document
  factory OrderEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderEntity(
      orderID: data['orderID'] ?? '',
      medicineID: data['medicineID'] ?? '',
      userUID: data['userUID'] ?? '',
      storeID: data['storeID'] ?? 0,
      quantity: data['quantity'] ?? 0,
      totalPrice: data['totalPrice'] ?? 0.0,
      status: OrderStatus.fromString(data['status'] ?? ''),
      idDiscount: data['idDiscount'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      deliveryAddress: data['deliveryAddress'],
      isHomeDelivery: data['isHomeDelivery'] ?? false,
      discountAmount: data['discountAmount'],
      lalamoveOrderId: data['lalamoveOrderId'],
      lalamoveTrackingUrl: data['lalamoveTrackingUrl'],
      lalamoveDriverName: data['lalamoveDriverName'],
      lalamoveDriverPhone: data['lalamoveDriverPhone'],
      lalamoveStatus: data['lalamoveStatus'],
      isInitiallyVerified: data['isInitiallyVerified'] ?? false,
      isPaid: data['isPaid'] ?? false,
      isCompletelyVerified: data['isCompletelyVerified'] ?? false,
      paymentReceiptUrl: data['paymentReceiptUrl'],
    );
  }

  // Create a copy of OrderEntity with updated fields
  OrderEntity copyWith({
    String? orderID,
    String? medicineID,
    String? userUID,
    int? storeID,
    int? quantity,
    double? totalPrice,
    OrderStatus? status,
    String? idDiscount,
    DateTime? createdAt,
    String? deliveryAddress,
    bool? isHomeDelivery,
    double? discountAmount,
    String? lalamoveOrderId,
    String? lalamoveTrackingUrl,
    String? lalamoveDriverName,
    String? lalamoveDriverPhone,
    String? lalamoveStatus,
    bool? isInitiallyVerified,
    bool? isPaid,
    bool? isCompletelyVerified,
    String? paymentReceiptUrl,
  }) {
    return OrderEntity(
      orderID: orderID ?? this.orderID,
      medicineID: medicineID ?? this.medicineID,
      userUID: userUID ?? this.userUID,
      storeID: storeID ?? this.storeID,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      idDiscount: idDiscount ?? this.idDiscount,
      createdAt: createdAt ?? this.createdAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      isHomeDelivery: isHomeDelivery ?? this.isHomeDelivery,
      discountAmount: discountAmount ?? this.discountAmount,
      lalamoveOrderId: lalamoveOrderId ?? this.lalamoveOrderId,
      lalamoveTrackingUrl: lalamoveTrackingUrl ?? this.lalamoveTrackingUrl,
      lalamoveDriverName: lalamoveDriverName ?? this.lalamoveDriverName,
      lalamoveDriverPhone: lalamoveDriverPhone ?? this.lalamoveDriverPhone,
      lalamoveStatus: lalamoveStatus ?? this.lalamoveStatus,
      isInitiallyVerified: isInitiallyVerified ?? this.isInitiallyVerified,
      isPaid: isPaid ?? this.isPaid,
      isCompletelyVerified: isCompletelyVerified ?? this.isCompletelyVerified,
      paymentReceiptUrl: paymentReceiptUrl ?? this.paymentReceiptUrl,
    );
  }
}