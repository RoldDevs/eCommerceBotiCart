import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory Medicine.fromFirestore(Map<String, dynamic> data, String id) {
    List<String> offerings = [];
    if (data['productOffering'] is List) {
      offerings = List<String>.from(data['productOffering']);
    } else if (data['productOffering'] is String) {
      offerings = [data['productOffering']];
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
    );
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
    );
  }
}