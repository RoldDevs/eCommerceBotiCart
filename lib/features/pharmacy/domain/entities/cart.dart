import 'package:cloud_firestore/cloud_firestore.dart';

enum CartStatus {
  toProcess('To Process'),
  toReceive('To Receive'),
  toShip('To Ship'),
  toPickup('To Pickup'),
  inTransit('In Transit'),
  completed('Completed');

  const CartStatus(this.displayName);
  final String displayName;

  static CartStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'to receive':
        return CartStatus.toReceive;
      case 'to ship':
        return CartStatus.toShip;
      case 'to pickup':
        return CartStatus.toPickup;
      case 'in transit':
        return CartStatus.inTransit;
      case 'completed':
        return CartStatus.completed;
      case 'to process':
      default:
        return CartStatus.toProcess;
    }
  }
}

class CartEntity {
  final String itemCartNo;
  final String userUID;
  final String medicineID;
  final String status;
  final DateTime createdAt;
  final int quantity;

  CartEntity({
    required this.itemCartNo,
    required this.userUID,
    required this.medicineID,
    required this.status,
    required this.createdAt,
    this.quantity = 1,
  });

  // Get status as enum
  CartStatus get statusEnum => CartStatus.fromString(status);

  // Convert CartEntity to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'itemCartNo': itemCartNo,
      'userUID': userUID,
      'medicineID': medicineID,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'quantity': quantity,
    };
  }

  // Create CartEntity from Firestore document
  factory CartEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartEntity(
      itemCartNo: doc.id,
      userUID: data['userUID'] ?? '',
      medicineID: data['medicineID'] ?? '',
      status: data['status'] ?? CartStatus.toProcess.displayName,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      quantity: data['quantity'] ?? 1,
    );
  }

  // Create CartEntity from Map
  factory CartEntity.fromMap(Map<String, dynamic> data, String id) {
    return CartEntity(
      itemCartNo: id,
      userUID: data['userUID'] ?? '',
      medicineID: data['medicineID'] ?? '',
      status: data['status'] ?? CartStatus.toProcess.displayName,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      quantity: data['quantity'] ?? 1,
    );
  }

  CartEntity copyWith({
    String? itemCartNo,
    String? userUID,
    String? medicineID,
    String? status,
    DateTime? createdAt,
    int? quantity,
  }) {
    return CartEntity(
      itemCartNo: itemCartNo ?? this.itemCartNo,
      userUID: userUID ?? this.userUID,
      medicineID: medicineID ?? this.medicineID,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      quantity: quantity ?? this.quantity,
    );
  }
}