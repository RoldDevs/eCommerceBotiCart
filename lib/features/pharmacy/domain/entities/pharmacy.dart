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

  // Owner information
  final String? ownerFirstName;
  final String? ownerLastName;

  // Business address details
  final String? region;
  final String? province;
  final String? cityMunicipality;
  final String? barangay;
  final String? street;

  // Operating hours
  final String? operatingHours;

  // Regulatory compliance documents
  final String? fdaLicenseUrl;
  final String? businessPermitUrl;
  final String? ownerGovernmentIdFrontUrl;
  final String? drugstorePictureUrl;
  final String? paymentQrCodeUrl;

  // Theme information
  final String?
  currentThemeId; // The theme ID currently active for this pharmacy
  final List<String>
  purchasedThemes; // List of theme IDs the pharmacy has purchased

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
    this.ownerFirstName,
    this.ownerLastName,
    this.region,
    this.province,
    this.cityMunicipality,
    this.barangay,
    this.street,
    this.operatingHours,
    this.fdaLicenseUrl,
    this.businessPermitUrl,
    this.ownerGovernmentIdFrontUrl,
    this.drugstorePictureUrl,
    this.paymentQrCodeUrl,
    this.currentThemeId,
    this.purchasedThemes = const [],
  });

  factory Pharmacy.fromFirestore(Map<String, dynamic> data, String id) {
    int storeID =
        data['storeID'] ?? int.parse(id.substring(0, 8), radix: 16) % 100000;

    // Helper function to safely extract String from Firestore data
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is Map) return null; // Skip Map values, return null instead
      return value.toString();
    }

    // Helper function to safely extract List<String> from Firestore data
    List<String> safeStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.whereType<String>().map((item) => item as String).toList();
      }
      return [];
    }

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
      gcashQrCodeUrl: safeString(data['gcashQrCodeUrl']),
      amount: data['amount']?.toDouble(),
      status: safeString(data['status']),
      invoiceId: safeString(data['invoiceId']),
      remittanceId: safeString(data['remittanceId']),
      receiptImageURL: safeString(data['receiptImageURL']),
      billingStart: data['billingStart'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['billingStart'])
          : null,
      billingEnd: data['billingEnd'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['billingEnd'])
          : null,
      ownerFirstName: safeString(data['ownerFirstName']),
      ownerLastName: safeString(data['ownerLastName']),
      region: safeString(data['region']),
      province: safeString(data['province']),
      cityMunicipality: safeString(data['cityMunicipality']),
      barangay: safeString(data['barangay']),
      street: safeString(data['street']),
      operatingHours: safeString(data['operatingHours']),
      fdaLicenseUrl: safeString(data['fdaLicenseUrl']),
      businessPermitUrl: safeString(data['businessPermitUrl']),
      ownerGovernmentIdFrontUrl: safeString(data['ownerGovernmentIdFrontUrl']),
      drugstorePictureUrl: safeString(data['drugstorePictureUrl']),
      paymentQrCodeUrl: safeString(data['paymentQrCodeUrl']),
      currentThemeId: safeString(data['currentThemeId']),
      purchasedThemes: safeStringList(data['purchasedThemes']),
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
      'ownerFirstName': ownerFirstName,
      'ownerLastName': ownerLastName,
      'region': region,
      'province': province,
      'cityMunicipality': cityMunicipality,
      'barangay': barangay,
      'street': street,
      'operatingHours': operatingHours,
      'fdaLicenseUrl': fdaLicenseUrl,
      'businessPermitUrl': businessPermitUrl,
      'ownerGovernmentIdFrontUrl': ownerGovernmentIdFrontUrl,
      'drugstorePictureUrl': drugstorePictureUrl,
      'paymentQrCodeUrl': paymentQrCodeUrl,
      'currentThemeId': currentThemeId,
      'purchasedThemes': purchasedThemes,
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
    String? ownerFirstName,
    String? ownerLastName,
    String? region,
    String? province,
    String? cityMunicipality,
    String? barangay,
    String? street,
    String? operatingHours,
    String? fdaLicenseUrl,
    String? businessPermitUrl,
    String? ownerGovernmentIdFrontUrl,
    String? drugstorePictureUrl,
    String? paymentQrCodeUrl,
    String? currentThemeId,
    List<String>? purchasedThemes,
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
      ownerFirstName: ownerFirstName ?? this.ownerFirstName,
      ownerLastName: ownerLastName ?? this.ownerLastName,
      region: region ?? this.region,
      province: province ?? this.province,
      cityMunicipality: cityMunicipality ?? this.cityMunicipality,
      barangay: barangay ?? this.barangay,
      street: street ?? this.street,
      operatingHours: operatingHours ?? this.operatingHours,
      fdaLicenseUrl: fdaLicenseUrl ?? this.fdaLicenseUrl,
      businessPermitUrl: businessPermitUrl ?? this.businessPermitUrl,
      ownerGovernmentIdFrontUrl:
          ownerGovernmentIdFrontUrl ?? this.ownerGovernmentIdFrontUrl,
      drugstorePictureUrl: drugstorePictureUrl ?? this.drugstorePictureUrl,
      paymentQrCodeUrl: paymentQrCodeUrl ?? this.paymentQrCodeUrl,
      currentThemeId: currentThemeId ?? this.currentThemeId,
      purchasedThemes: purchasedThemes ?? this.purchasedThemes,
    );
  }
}
