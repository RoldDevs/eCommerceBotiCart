import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/medicine_repository_impl.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';
import 'pharmacy_providers.dart';

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  return MedicineRepositoryImpl(
    firestore: FirebaseFirestore.instance,
  );
});

final medicineSearchProvider = FutureProvider.family<List<Medicine>, String>((ref, query) {
  final repository = ref.watch(medicineRepositoryProvider);
  final selectedStoreId = ref.watch(selectedPharmacyStoreIdProvider);
  return repository.searchMedicines(query, storeId: selectedStoreId);
});

final allMedicinesProvider = FutureProvider<List<Medicine>>((ref) {
  final repository = ref.watch(medicineRepositoryProvider);
  final selectedStoreId = ref.watch(selectedPharmacyStoreIdProvider);
  return repository.getAllMedicines(storeId: selectedStoreId);
});

// Provider to store favorite medicine IDs
final favoriteMedicinesProvider = StateNotifierProvider<FavoriteMedicinesNotifier, Set<String>>((ref) {
  return FavoriteMedicinesNotifier();
});

// Filter type enum
enum MedicineFilterType {
  relevance,
  latest,
  price,
  favorites
}

// Selected filter provider
final selectedFilterProvider = StateProvider<MedicineFilterType>((ref) {
  return MedicineFilterType.relevance;
});

// Filtered medicines provider
final filteredMedicinesProvider = Provider<List<Medicine>>((ref) {
  final allMedicinesAsyncValue = ref.watch(allMedicinesProvider);
  final filterType = ref.watch(selectedFilterProvider);
  final favorites = ref.watch(favoriteMedicinesProvider);
  
  return allMedicinesAsyncValue.when(
    data: (medicines) {
      List<Medicine> filteredList = medicines.map((medicine) {
        return medicine.copyWith(
          isFavorite: favorites.contains(medicine.id)
        );
      }).toList();
      
      switch (filterType) {
        case MedicineFilterType.relevance:
          filteredList.sort((a, b) => a.medicineName.compareTo(b.medicineName));
          break;
        case MedicineFilterType.latest:
          filteredList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case MedicineFilterType.price:
          filteredList.sort((a, b) => b.price.compareTo(a.price));
          break;
        case MedicineFilterType.favorites:
          filteredList = filteredList.where((medicine) => favorites.contains(medicine.id)).toList();
          break;
      }
      
      return filteredList;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

class FavoriteMedicinesNotifier extends StateNotifier<Set<String>> {
  FavoriteMedicinesNotifier() : super({});
  
  void toggleFavorite(String medicineId) {
    if (state.contains(medicineId)) {
      state = {...state}..remove(medicineId);
    } else {
      state = {...state, medicineId};
    }
  }
  
  bool isFavorite(String medicineId) {
    return state.contains(medicineId);
  }
}
