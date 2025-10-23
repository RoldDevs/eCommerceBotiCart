class Pharmacy {
  final String id;
  final String name;
  final String location;
  final double rating;
  final int reviewCount;
  final String contact;
  final String imageUrl;
  final String backgroundImgUrl;
  final String description;
  final int storeID;
  final bool isFavorite;
  final String? gcashQrCodeUrl;
  final double? amount;
  final String? status;
  final String? invoiceId;
  final String? remittanceId;
  final String? receiptImageURL;
  final DateTime? billingStart;
  final DateTime? billingEnd;

  Pharmacy({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.contact,
    required this.imageUrl,
    required this.backgroundImgUrl,
    required this.description,
    required this.storeID,
    this.isFavorite = false,
    this.gcashQrCodeUrl,
    this.amount,
    this.status,
    this.invoiceId,
    this.remittanceId,
    this.receiptImageURL,
    this.billingStart,
    this.billingEnd,
  });

  factory Pharmacy.fromFirestore(Map<String, dynamic> data, String id) {
    int storeID = data['storeID'] ?? int.parse(id.substring(0, 8), radix: 16) % 100000;
    
    return Pharmacy(
      id: id,
      name: data['pharmacyName'] ?? '',
      location: data['Location'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      contact: data['contact'] ?? '',
      backgroundImgUrl: data['backgroundImgURL'] ?? '',
      imageUrl: data['imageURL'] ?? '',
      description: data['description'] ?? '',
      storeID: storeID,
      gcashQrCodeUrl: data['gcashQrCodeUrl'],
      amount: data['amount']?.toDouble(),
      status: data['status'],
      invoiceId: data['invoiceId'],
      remittanceId: data['remittanceId'],
      receiptImageURL: data['receiptImageURL'],
      billingStart: data['billingStart'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['billingStart']) 
          : null,
      billingEnd: data['billingEnd'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['billingEnd']) 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pharmacyName': name,
      'Location': location,
      'rating': rating,
      'reviewCount': reviewCount,
      'contact': contact,
      'backgroundImgURL': backgroundImgUrl,
      'imageURL': imageUrl,
      'description': description,
      'storeID': storeID,
      'gcashQrCodeUrl': gcashQrCodeUrl,
      'amount': amount,
      'status': status,
      'invoiceId': invoiceId,
      'remittanceId': remittanceId,
      'receiptImageURL': receiptImageURL,
      'billingStart': billingStart?.millisecondsSinceEpoch,
      'billingEnd': billingEnd?.millisecondsSinceEpoch,
    };
  }

  Pharmacy copyWith({
    String? id,
    String? name,
    String? location,
    double? rating,
    int? reviewCount,
    String? contact,
    String? imageUrl,
    String? backgroundImgUrl,
    String? description,
    int? storeID,
    bool? isFavorite,
    String? gcashQrCodeUrl,
    double? amount,
    String? status,
    String? invoiceId,
    String? remittanceId,
    String? receiptImageURL,
    DateTime? billingStart,
    DateTime? billingEnd,
  }) {
    return Pharmacy(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      contact: contact ?? this.contact,
      imageUrl: imageUrl ?? this.imageUrl,
      backgroundImgUrl: backgroundImgUrl ?? this.backgroundImgUrl,
      description: description ?? this.description,
      storeID: storeID ?? this.storeID,
      isFavorite: isFavorite ?? this.isFavorite,
      gcashQrCodeUrl: gcashQrCodeUrl ?? this.gcashQrCodeUrl,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      invoiceId: invoiceId ?? this.invoiceId,
      remittanceId: remittanceId ?? this.remittanceId,
      receiptImageURL: receiptImageURL ?? this.receiptImageURL,
      billingStart: billingStart ?? this.billingStart,
      billingEnd: billingEnd ?? this.billingEnd,
    );
  }
}