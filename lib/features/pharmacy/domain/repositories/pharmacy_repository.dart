import '../entities/pharmacy.dart';

abstract class PharmacyRepository {
  Stream<List<Pharmacy>> getPharmacies();
  Stream<Pharmacy?> getPharmacyById(String id);
  Stream<List<Pharmacy>> searchPharmacies(String query);
}