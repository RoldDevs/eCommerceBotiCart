import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../features/auth/presentation/providers/user_provider.dart';

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  final FirebaseFirestore _firestore;
  final String? _userUID;

  SearchHistoryNotifier(this._firestore, this._userUID) : super([]) {
    if (_userUID != null) {
      _loadSearches();
    }
  }

  Future<void> _loadSearches() async {
    try {
      final doc = await _firestore.collection('searches').doc(_userUID).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['recentSearches'] != null) {
          state = List<String>.from(data['recentSearches']);
        }
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty || _userUID == null) return;

    // Remove if already exists to avoid duplicates
    final newState = state.where((item) => item != query).toList();

    // Add to the beginning of the list
    newState.insert(0, query);

    // Limit to 10 recent searches
    final limitedState = newState.length > 10
        ? newState.sublist(0, 10)
        : newState;

    // Update state
    state = limitedState;

    // Update Firestore
    try {
      await _firestore.collection('searches').doc(_userUID).set({
        'recentSearches': limitedState,
        'updatedAt': FieldValue.serverTimestamp(),
        'userUID': _userUID,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> clearHistory() async {
    if (_userUID == null) return;

    // Clear local state
    state = [];

    // Clear Firestore
    try {
      await _firestore.collection('searches').doc(_userUID).update({
        'recentSearches': [],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // ignore: empty_catches
    } catch (e) {}
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
      final firestore = FirebaseFirestore.instance;
      final userAsyncValue = ref.watch(currentUserProvider);

      return userAsyncValue.when(
        data: (user) => SearchHistoryNotifier(firestore, user?.id),
        loading: () => SearchHistoryNotifier(firestore, null),
        error: (_, __) => SearchHistoryNotifier(firestore, null),
      );
    });

// For demonstration purposes, let's add some initial searches
final initialSearchesProvider = Provider<List<String>>((ref) {
  final searchHistory = ref.watch(searchHistoryProvider);
  return searchHistory.isEmpty
      ? ['Potencee with zinc', 'Ibuprofen', 'Bioflu', 'Neurobion']
      : searchHistory;
});
