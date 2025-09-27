import '../entities/medicine.dart';

abstract class MedicineRepository {
  Future<List<Medicine>> searchMedicines(String query, {int? storeId});
  Future<List<Medicine>> getAllMedicines({int? storeId});
}