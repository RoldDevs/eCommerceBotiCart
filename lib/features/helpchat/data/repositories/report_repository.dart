import 'package:cloud_firestore/cloud_firestore.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;

  ReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new report
  Future<String> createReport({
    required String storeID,
    required String pharmacyID,
    required String reportedBy,
    required String violation,
    String? additionalComments,
  }) async {
    try {
      final reportDoc = await _firestore.collection('reports').add({
        'storeID': storeID,
        'pharmacyID': pharmacyID,
        'reportedBy': reportedBy,
        'violation': violation,
        'additionalComments': additionalComments ?? '',
        'acknowledgeByPharmacy': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return reportDoc.id;
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  /// Get all reports for a user
  Stream<List<Map<String, dynamic>>> getUserReports(String userUID) {
    return _firestore
        .collection('reports')
        .where('reportedBy', isEqualTo: userUID)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {'id': doc.id, ...data};
          }).toList();
        });
  }

  /// Get all reports for a pharmacy
  Stream<List<Map<String, dynamic>>> getPharmacyReports(String pharmacyID) {
    return _firestore
        .collection('reports')
        .where('pharmacyID', isEqualTo: pharmacyID)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {'id': doc.id, ...data};
          }).toList();
        });
  }
}
