import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/pharmacy_repository_impl.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/repositories/pharmacy_repository.dart';

final pharmacyRepositoryProvider = Provider<PharmacyRepository>((ref) {
  return PharmacyRepositoryImpl(firestore: FirebaseFirestore.instance);
});

final pharmaciesStreamProvider = StreamProvider<List<Pharmacy>>((ref) {
  final repository = ref.watch(pharmacyRepositoryProvider);
  return repository.getPharmacies();
});

final pharmacyByIdProvider = StreamProvider.family<Pharmacy?, String>((
  ref,
  id,
) {
  final repository = ref.watch(pharmacyRepositoryProvider);
  return repository.getPharmacyById(id);
});

final favoritesProvider = StateProvider<List<String>>((ref) => []);

// Add a provider to track the currently selected pharmacy's storeID
final selectedPharmacyStoreIdProvider = StateProvider<int?>((ref) => null);

// Add a provider for pharmacy search query
final pharmacySearchQueryProvider = StateProvider<String>((ref) => '');

// Add a provider for pharmacy search results
final pharmacySearchResultsProvider = StreamProvider<List<Pharmacy>>((ref) {
  final repository = ref.watch(pharmacyRepositoryProvider);
  final searchQuery = ref.watch(pharmacySearchQueryProvider);

  if (searchQuery.isEmpty) {
    return repository.getPharmacies();
  }

  return repository.searchPharmacies(searchQuery);
});
