import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/theme_repository_impl.dart';
import '../../domain/entities/theme.dart';
import '../../domain/entities/pharmacy.dart';
import 'pharmacy_providers.dart';

final themeRepositoryProvider = Provider<ThemeRepositoryImpl>((ref) {
  return ThemeRepositoryImpl();
});

// Helper function to convert hex string to Color
Color hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

// Provider to get the current pharmacy's theme
final currentPharmacyThemeProvider = StreamProvider.autoDispose<PharmacyTheme?>(
  (ref) {
    final selectedStoreId = ref.watch(selectedPharmacyStoreIdProvider);
    final pharmaciesAsyncValue = ref.watch(pharmaciesStreamProvider);
    final themeRepository = ref.watch(themeRepositoryProvider);

    return pharmaciesAsyncValue.when(
      data: (pharmacies) {
        if (selectedStoreId == null) return Stream.value(null);

        try {
          final selectedPharmacy = pharmacies.firstWhere(
            (p) => p.storeID == selectedStoreId,
          );

          if (selectedPharmacy.currentThemeId == null ||
              selectedPharmacy.currentThemeId!.isEmpty) {
            return Stream.value(null);
          }

          return themeRepository.getThemeById(selectedPharmacy.currentThemeId!);
        } catch (e) {
          return Stream.value(null);
        }
      },
      loading: () => Stream.value(null),
      error: (_, __) => Stream.value(null),
    );
  },
);

// Provider to get theme colors for a specific pharmacy
final pharmacyThemeColorsProvider =
    StreamProvider.family<ThemeColors?, Pharmacy>((ref, pharmacy) {
      if (pharmacy.currentThemeId == null || pharmacy.currentThemeId!.isEmpty) {
        return Stream.value(null);
      }

      final themeRepository = ref.watch(themeRepositoryProvider);
      return themeRepository
          .getThemeById(pharmacy.currentThemeId!)
          .map((theme) => theme?.colors);
    });

// Default theme colors (fallback)
final defaultThemeColors = ThemeColors(
  primary: '#0D1B2A',
  secondary: '#1B263B',
  accent: '#F4A261',
  background: '#415A77',
  card: '#778DA9',
  text: '#E0E1DD',
);

// Default app colors (current hardcoded colors)
final defaultAppColors = {
  'primary': const Color(0xFF8ECAE6),
  'secondary': const Color(0xFF2A4B8D),
  'accent': const Color(0xFF8ECAE6),
  'background': Colors.white,
  'card': const Color(0xFFE6F3F8),
  'text': const Color(0xFF333333),
};
