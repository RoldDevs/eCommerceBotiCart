import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/repositories/pharmacy_repository.dart';

class PharmacyRepositoryImpl implements PharmacyRepository {
  final FirebaseFirestore _firestore;

  PharmacyRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Pharmacy>> getPharmacies() {
    return _firestore.collection('pharmacy').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Pharmacy.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Stream<Pharmacy?> getPharmacyById(String id) {
    return _firestore.collection('pharmacy').doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return Pharmacy.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  @override
  Stream<List<Pharmacy>> searchPharmacies(String query) {
    final lowercaseQuery = query.toLowerCase();

    return _firestore.collection('pharmacy').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Pharmacy.fromFirestore(doc.data(), doc.id))
          .where(
            (pharmacy) => pharmacy.name.toLowerCase().contains(lowercaseQuery),
          )
          .toList();
    });
  }

  @override
  Future<void> updatePharmacyRating(
    String pharmacyId,
    double newRating,
    int newReviewCount,
  ) async {
    await _firestore.collection('pharmacy').doc(pharmacyId).update({
      'rating': newRating,
      'reviewCount': newReviewCount,
    });
  }

  @override
  Future<void> updatePharmacyTheme(String pharmacyId, String themeId) async {
    // Get current pharmacy data to check if theme is purchased
    final pharmacyDoc = await _firestore
        .collection('pharmacy')
        .doc(pharmacyId)
        .get();

    if (!pharmacyDoc.exists) {
      throw Exception('Pharmacy not found');
    }

    final data = pharmacyDoc.data()!;
    final purchasedThemes = (data['purchasedThemes'] as List<dynamic>?) ?? [];

    // Verify the pharmacy has purchased this theme
    if (!purchasedThemes.contains(themeId)) {
      throw Exception('Pharmacy has not purchased this theme');
    }

    // Update the current theme
    await _firestore.collection('pharmacy').doc(pharmacyId).update({
      'currentThemeId': themeId,
    });
  }

  @override
  Future<void> purchaseTheme(String pharmacyId, String themeId) async {
    // Get current pharmacy data
    final pharmacyDoc = await _firestore
        .collection('pharmacy')
        .doc(pharmacyId)
        .get();

    if (!pharmacyDoc.exists) {
      throw Exception('Pharmacy not found');
    }

    final data = pharmacyDoc.data()!;
    final purchasedThemes = (data['purchasedThemes'] as List<dynamic>?) ?? [];

    // Check if theme is already purchased
    if (purchasedThemes.contains(themeId)) {
      throw Exception('Theme already purchased');
    }

    // Add theme to purchased list and set as current theme
    final updatedPurchasedThemes = [...purchasedThemes, themeId];

    await _firestore.collection('pharmacy').doc(pharmacyId).update({
      'purchasedThemes': updatedPurchasedThemes,
      'currentThemeId':
          themeId, // Automatically set as current theme when purchased
    });

    // Mark theme as available for this pharmacy in the themes collection
    // This creates/updates a document in themes/{themeId}/pharmacies/{pharmacyId}
    await _firestore
        .collection('themes')
        .doc(themeId)
        .collection('pharmacies')
        .doc(pharmacyId)
        .set({
          'pharmacyId': pharmacyId,
          'purchasedAt': FieldValue.serverTimestamp(),
          'available': true,
        });
  }
}
