import 'package:cloud_firestore/cloud_firestore.dart';

enum MedicineMajorType {
  generic,
  branded
}

enum MedicineProductType {
  prescriptionMedicines,
  overTheCounter,
  vitaminsSupplements,
  healthEssentials
}

enum MedicineConditionType {
  painFever,
  coughCold,
  allergies,
  digestiveHealth,
  other
}

class Medicine {
  final String id;
  final String medicineName;
  final double price;
  final String imageURL;
  final String productDescription;
  final List<String> productOffering;
  final int storeID;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final MedicineMajorType majorType;
  final MedicineProductType productType;
  final MedicineConditionType conditionType;
  final int stock;

  Medicine({
    required this.id,
    required this.medicineName,
    required this.price,
    required this.imageURL,
    required this.productDescription,
    required this.productOffering,
    required this.storeID,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    required this.majorType,
    required this.productType,
    required this.conditionType,
    required this.stock,
  });

  factory Medicine.fromFirestore(Map<String, dynamic> data, String id) {
    List<String> offerings = [];
    if (data['productOffering'] is List) {
      offerings = List<String>.from(data['productOffering']);
    } else if (data['productOffering'] is String) {
      offerings = [data['productOffering']];
    }

    MedicineMajorType majorType = MedicineMajorType.generic;
    if (data['majorType'] != null) {
      if (data['majorType'] == 'branded') {
        majorType = MedicineMajorType.branded;
      }
    }

    // Parse product type
    MedicineProductType productType = MedicineProductType.overTheCounter;
    if (data['productType'] != null) {
      switch (data['productType']) {
        case 'prescriptionMedicines':
          productType = MedicineProductType.prescriptionMedicines;
          break;
        case 'vitaminsSupplements':
          productType = MedicineProductType.vitaminsSupplements;
          break;
        case 'healthEssentials':
          productType = MedicineProductType.healthEssentials;
          break;
        default:
          productType = MedicineProductType.overTheCounter;
      }
    }

    // Parse condition type
    MedicineConditionType conditionType = MedicineConditionType.other;
    if (data['conditionType'] != null) {
      switch (data['conditionType']) {
        case 'painFever':
          conditionType = MedicineConditionType.painFever;
          break;
        case 'coughCold':
          conditionType = MedicineConditionType.coughCold;
          break;
        case 'allergies':
          conditionType = MedicineConditionType.allergies;
          break;
        case 'digestiveHealth':
          conditionType = MedicineConditionType.digestiveHealth;
          break;
        default:
          conditionType = MedicineConditionType.other;
      }
    }

    return Medicine(
      id: id,
      medicineName: data['medicineName'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageURL: data['imageURL'] ?? '',
      productDescription: data['productDescription'] ?? '',
      productOffering: offerings,
      storeID: data['storeID'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      majorType: majorType,
      productType: productType,
      conditionType: conditionType,
      stock: data['stock'] ?? 0,
    );
  }
  
  // Helper method to convert enum to string for Firestore
  static String majorTypeToString(MedicineMajorType type) {
    return type.toString().split('.').last;
  }
  
  static String productTypeToString(MedicineProductType type) {
    return type.toString().split('.').last;
  }
  
  static String conditionTypeToString(MedicineConditionType type) {
    return type.toString().split('.').last;
  }
  
  // Convert Medicine object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'medicineName': medicineName,
      'price': price,
      'imageURL': imageURL,
      'productDescription': productDescription,
      'productOffering': productOffering,
      'storeID': storeID,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'majorType': majorTypeToString(majorType),
      'productType': productTypeToString(productType),
      'conditionType': conditionTypeToString(conditionType),
      'stock': stock,
    };
  }
  
  // Add this method to the Medicine class
  Medicine copyWith({
    String? id,
    String? medicineName,
    double? price,
    String? imageURL,
    String? productDescription,
    List<String>? productOffering,
    int? storeID,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    MedicineMajorType? majorType,
    MedicineProductType? productType,
    MedicineConditionType? conditionType,
    int? stock,
  }) {
    return Medicine(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      price: price ?? this.price,
      imageURL: imageURL ?? this.imageURL,
      productDescription: productDescription ?? this.productDescription,
      productOffering: productOffering ?? this.productOffering,
      storeID: storeID ?? this.storeID,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      majorType: majorType ?? this.majorType,
      productType: productType ?? this.productType,
      conditionType: conditionType ?? this.conditionType,
      stock: stock ?? this.stock,
    );
  }
  
  // Helper method to get display name for product type
  String get productTypeDisplayName {
    switch (productType) {
      case MedicineProductType.prescriptionMedicines:
        return 'Prescription Medicines';
      case MedicineProductType.overTheCounter:
        return 'Over-The-Counter (OTC)';
      case MedicineProductType.vitaminsSupplements:
        return 'Vitamins & Supplements';
      case MedicineProductType.healthEssentials:
        return 'Health Essentials';
    }
  }
  
  // Helper method to get display name for condition type
  String get conditionTypeDisplayName {
    switch (conditionType) {
      case MedicineConditionType.painFever:
        return 'Pain & Fever';
      case MedicineConditionType.coughCold:
        return 'Cough & Cold';
      case MedicineConditionType.allergies:
        return 'Allergies';
      case MedicineConditionType.digestiveHealth:
        return 'Digestive Health';
      case MedicineConditionType.other:
        return 'Other';
    }
  }
  
  // Helper method to get display name for major type
  String get majorTypeDisplayName {
    return majorType == MedicineMajorType.branded ? 'Branded' : 'Generic';
  }
  
  // Method to decrease stock for checkout
  Medicine decreaseStock(int quantity) {
    if (stock < quantity) {
      throw Exception('Insufficient stock. Available: $stock, Requested: $quantity');
    }
    
    return copyWith(
      stock: stock - quantity,
      updatedAt: DateTime.now(),
    );
  }
  
  // Method to check if there's sufficient stock
  bool hasSufficientStock(int requestedQuantity) {
    return stock >= requestedQuantity;
  }
}