import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/medicine.dart';
import 'medicine_provider.dart';

// Provider for selected product types
final selectedProductTypesProvider =
    StateNotifierProvider<
      SelectedProductTypesNotifier,
      Set<MedicineProductType>
    >((ref) {
      return SelectedProductTypesNotifier();
    });

// Provider for selected condition types
final selectedConditionTypesProvider =
    StateNotifierProvider<
      SelectedConditionTypesNotifier,
      Set<MedicineConditionType>
    >((ref) {
      return SelectedConditionTypesNotifier();
    });

// Notifier for managing selected product types
class SelectedProductTypesNotifier
    extends StateNotifier<Set<MedicineProductType>> {
  SelectedProductTypesNotifier() : super(<MedicineProductType>{});

  void toggle(MedicineProductType type) {
    if (state.contains(type)) {
      state = Set.from(state)..remove(type);
    } else {
      state = Set.from(state)..add(type);
    }
  }

  void clear() {
    state = <MedicineProductType>{};
  }

  void selectAll() {
    state = {
      MedicineProductType.prescriptionMedicines,
      MedicineProductType.overTheCounter,
      MedicineProductType.vitaminsSupplements,
      MedicineProductType.healthEssentials,
    };
  }
}

// Notifier for managing selected condition types
class SelectedConditionTypesNotifier
    extends StateNotifier<Set<MedicineConditionType>> {
  SelectedConditionTypesNotifier() : super(<MedicineConditionType>{});

  void toggle(MedicineConditionType type) {
    if (state.contains(type)) {
      state = Set.from(state)..remove(type);
    } else {
      state = Set.from(state)..add(type);
    }
  }

  void clear() {
    state = <MedicineConditionType>{};
  }

  void selectAll() {
    state = {
      MedicineConditionType.painFever,
      MedicineConditionType.coughCold,
      MedicineConditionType.allergies,
      MedicineConditionType.digestiveHealth,
    };
  }
}

// Provider for filtered medicines based on selected filters
final filteredMedicinesByFiltersProvider = Provider<List<Medicine>>((ref) {
  final allMedicinesAsyncValue = ref.watch(allMedicinesProvider);
  final selectedProductTypes = ref.watch(selectedProductTypesProvider);
  final selectedConditionTypes = ref.watch(selectedConditionTypesProvider);
  final favorites = ref.watch(favoriteMedicinesProvider);

  return allMedicinesAsyncValue.when(
    data: (medicines) {
      List<Medicine> filteredList = medicines.map((medicine) {
        return medicine.copyWith(isFavorite: favorites.contains(medicine.id));
      }).toList();

      // Apply product type filter
      if (selectedProductTypes.isNotEmpty) {
        filteredList = filteredList.where((medicine) {
          return selectedProductTypes.contains(medicine.productType);
        }).toList();
      }

      // Apply condition type filter
      if (selectedConditionTypes.isNotEmpty) {
        filteredList = filteredList.where((medicine) {
          return selectedConditionTypes.contains(medicine.conditionType);
        }).toList();
      }

      return filteredList;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
