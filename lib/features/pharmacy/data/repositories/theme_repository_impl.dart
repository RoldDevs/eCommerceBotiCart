import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/theme.dart';
import '../../domain/repositories/theme_repository.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  final FirebaseFirestore _firestore;

  ThemeRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<PharmacyTheme>> getThemes() {
    return _firestore.collection('themes').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PharmacyTheme.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Stream<PharmacyTheme?> getThemeById(String themeId) {
    return _firestore.collection('themes').doc(themeId).snapshots().map((doc) {
      if (doc.exists) {
        return PharmacyTheme.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  @override
  Future<bool> checkPharmacyHasTheme(String pharmacyId, String themeId) async {
    try {
      final pharmacyDoc = await _firestore
          .collection('pharmacy')
          .doc(pharmacyId)
          .get();

      if (!pharmacyDoc.exists) return false;

      final data = pharmacyDoc.data()!;
      final purchasedThemes = data['purchasedThemes'] as List<dynamic>?;

      if (purchasedThemes == null) return false;

      return purchasedThemes.contains(themeId);
    } catch (e) {
      return false;
    }
  }
}
