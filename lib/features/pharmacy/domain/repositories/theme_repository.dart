import '../entities/theme.dart';

abstract class ThemeRepository {
  Stream<List<PharmacyTheme>> getThemes();
  Stream<PharmacyTheme?> getThemeById(String themeId);
  Future<bool> checkPharmacyHasTheme(String pharmacyId, String themeId);
}
