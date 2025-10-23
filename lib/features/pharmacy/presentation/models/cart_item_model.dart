import '../../domain/entities/medicine.dart';
import '../../domain/entities/cart.dart';

class CartItemModel {
  final CartEntity cartEntity;
  final Medicine medicine;
  final bool isSelected;

  CartItemModel({
    required this.cartEntity,
    required this.medicine,
    this.isSelected = false,
  });

  CartItemModel copyWith({
    CartEntity? cartEntity,
    Medicine? medicine,
    bool? isSelected,
  }) {
    return CartItemModel(
      cartEntity: cartEntity ?? this.cartEntity,
      medicine: medicine ?? this.medicine,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  double get totalPrice => medicine.price * cartEntity.quantity;
  int get quantity => cartEntity.quantity;
  String get itemCartNo => cartEntity.itemCartNo;
  String get medicineId => medicine.id;
  String get userUID => cartEntity.userUID;
  String get status => cartEntity.status;
  CartStatus get statusEnum => cartEntity.statusEnum;
  DateTime get createdAt => cartEntity.createdAt;
  
  // Helper methods for UI
  String get formattedPrice => '₱${medicine.price.toStringAsFixed(2)}';
  String get formattedTotalPrice => '₱${totalPrice.toStringAsFixed(2)}';
  String get quantityText => 'Qty: $quantity';
  String get statusDisplayName => statusEnum.displayName;
  
  // Status check methods
  bool get isToProcess => statusEnum == CartStatus.toProcess;
  bool get isToReceive => statusEnum == CartStatus.toReceive;
  bool get isToShip => statusEnum == CartStatus.toShip;
  bool get isToPickup => statusEnum == CartStatus.toPickup;
  bool get isInTransit => statusEnum == CartStatus.inTransit;
  bool get isCompleted => statusEnum == CartStatus.completed;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItemModel &&
        other.itemCartNo == itemCartNo &&
        other.medicineId == medicineId;
  }
  
  @override
  int get hashCode => itemCartNo.hashCode ^ medicineId.hashCode;
  
  @override
  String toString() {
    return 'CartItemModel(itemCartNo: $itemCartNo, medicine: ${medicine.medicineName}, quantity: $quantity, totalPrice: $totalPrice)';
  }
}