class Pharmacy {
  final String id;
  final String name;
  final String location;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String backgroundImgUrl;
  final int storeID;
  final bool isFavorite;

  Pharmacy({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.backgroundImgUrl,
    required this.storeID,
    this.isFavorite = false,
  });

  factory Pharmacy.fromFirestore(Map<String, dynamic> data, String id) {
    int storeID = data['storeID'] ?? int.parse(id.substring(0, 8), radix: 16) % 100000;
    
    return Pharmacy(
      id: id,
      name: data['pharmacyName'] ?? '',
      location: data['Location'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      backgroundImgUrl: data['backgroundImgURL'] ?? '',
      imageUrl: data['imageURL'] ?? '',
      storeID: storeID,
    );
  }
}