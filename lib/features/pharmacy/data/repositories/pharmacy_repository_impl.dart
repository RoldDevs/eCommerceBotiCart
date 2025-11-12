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
        .where((pharmacy) => 
          pharmacy.name.toLowerCase().contains(lowercaseQuery))
        .toList();
    });
  }

  @override
  Future<void> updatePharmacyRating(String pharmacyId, double newRating, int newReviewCount) async {
    await _firestore.collection('pharmacy').doc(pharmacyId).update({
      'rating': newRating,
      'reviewCount': newReviewCount,
    });
  }
}