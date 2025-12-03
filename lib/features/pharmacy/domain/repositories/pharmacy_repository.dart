import '../entities/pharmacy.dart';

abstract class PharmacyRepository {
  Stream<List<Pharmacy>> getPharmacies();
  Stream<Pharmacy?> getPharmacyById(String id);
  Stream<List<Pharmacy>> searchPharmacies(String query);
  Future<void> updatePharmacyRating(
    String pharmacyId,
    double newRating,
    int newReviewCount,
  );
  Future<void> updatePharmacyTheme(String pharmacyId, String themeId);
  Future<void> purchaseTheme(String pharmacyId, String themeId);
}
