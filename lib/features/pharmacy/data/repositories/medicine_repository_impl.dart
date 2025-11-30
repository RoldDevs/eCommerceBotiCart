import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';

class MedicineRepositoryImpl implements MedicineRepository {
  final FirebaseFirestore _firestore;

  MedicineRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Medicine>> searchMedicines(String query, {int? storeId}) async {
    if (query.isEmpty) {
      return getAllMedicines(storeId: storeId);
    }

    final lowercaseQuery = query.toLowerCase();

    final snapshot = await _firestore.collection('medicines').get();

    return snapshot.docs
        .map((doc) => Medicine.fromFirestore(doc.data(), doc.id))
        .where(
          (medicine) =>
              medicine.medicineName.toLowerCase().contains(lowercaseQuery) &&
              (storeId == null || medicine.storeID == storeId),
        )
        .toList();
  }

  @override
  Future<List<Medicine>> getAllMedicines({int? storeId}) async {
    final snapshot = await _firestore.collection('medicines').get();

    final medicines = snapshot.docs
        .map((doc) => Medicine.fromFirestore(doc.data(), doc.id))
        .toList();

    if (storeId != null) {
      return medicines
          .where((medicine) => medicine.storeID == storeId)
          .toList();
    }

    return medicines;
  }
}
