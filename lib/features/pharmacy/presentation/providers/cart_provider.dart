import 'package:boticart/features/auth/presentation/providers/user_provider.dart';
import 'package:boticart/features/pharmacy/domain/entities/cart.dart';
import 'package:boticart/features/pharmacy/presentation/providers/medicine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/medicine.dart';
import '../../data/repositories/cart_repository.dart';

// Cart Repository Provider
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(firestore: FirebaseFirestore.instance);
});

class CartItem {
  final Medicine medicine;
  final int quantity;
  final bool isSelected;

  CartItem({
    required this.medicine,
    required this.quantity,
    this.isSelected = false,
  });

  CartItem copyWith({Medicine? medicine, int? quantity, bool? isSelected}) {
    return CartItem(
      medicine: medicine ?? this.medicine,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  double get totalPrice => medicine.price * quantity;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  final CartRepository _cartRepository;
  final Ref _ref;

  CartNotifier(this._cartRepository, this._ref) : super([]);

  Future<void> addToCart(Medicine medicine, int quantity) async {
    // Get current user
    final userAsyncValue = _ref.read(currentUserProvider);
    final user = userAsyncValue.value;

    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Add to Firestore
      await _cartRepository.addToCart(
        userUID: user.id,
        medicineID: medicine.id,
        quantity: quantity,
      );

      // Update local state
      final existingIndex = state.indexWhere(
        (item) => item.medicine.id == medicine.id,
      );

      if (existingIndex >= 0) {
        // Update quantity if item already exists
        final updatedItems = [...state];
        updatedItems[existingIndex] = CartItem(
          medicine: medicine,
          quantity: state[existingIndex].quantity + quantity,
          isSelected: state[existingIndex].isSelected,
        );
        state = updatedItems;
      } else {
        // Add new item
        state = [...state, CartItem(medicine: medicine, quantity: quantity)];
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  Future<void> removeFromCart(String medicineId) async {
    // Get current user
    final userAsyncValue = _ref.read(currentUserProvider);
    final user = userAsyncValue.value;

    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Find the cart item to get the itemCartNo
      // Since we don't have itemCartNo in the current CartItem model,
      // we'll need to query Firestore to find and delete the item
      final cartItems = await FirebaseFirestore.instance
          .collection('cart')
          .where('userUID', isEqualTo: user.id)
          .where('medicineID', isEqualTo: medicineId)
          .where('status', isEqualTo: 'active')
          .get();

      // Delete all matching items (should be only one)
      for (final doc in cartItems.docs) {
        await _cartRepository.removeFromCart(doc.id);
      }

      // Update local state
      state = state.where((item) => item.medicine.id != medicineId).toList();
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  Future<void> removeSelectedItems() async {
    // Get current user
    final userAsyncValue = _ref.read(currentUserProvider);
    final user = userAsyncValue.value;

    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      final selectedItems = state.where((item) => item.isSelected).toList();
      final selectedMedicineIds = selectedItems
          .map((item) => item.medicine.id)
          .toList();

      // Get all cart items for selected medicines
      for (final medicineId in selectedMedicineIds) {
        final cartItems = await FirebaseFirestore.instance
            .collection('cart')
            .where('userUID', isEqualTo: user.id)
            .where('medicineID', isEqualTo: medicineId)
            .where('status', isEqualTo: 'active')
            .get();

        // Delete all matching items
        for (final doc in cartItems.docs) {
          await _cartRepository.removeFromCart(doc.id);
        }
      }

      // Update local state
      state = state.where((item) => !item.isSelected).toList();
    } catch (e) {
      throw Exception('Failed to remove selected items from cart: $e');
    }
  }

  void clearCart() {
    state = [];
  }

  void toggleItemSelection(String medicineId) {
    final updatedItems = [...state];
    final index = updatedItems.indexWhere(
      (item) => item.medicine.id == medicineId,
    );
    if (index >= 0) {
      updatedItems[index] = updatedItems[index].copyWith(
        isSelected: !updatedItems[index].isSelected,
      );
      state = updatedItems;
    }
  }

  void selectAll(bool select) {
    state = state.map((item) => item.copyWith(isSelected: select)).toList();
  }

  void clearAllSelections() {
    selectAll(false);
  }

  double get totalAmount {
    return state.fold(0, (total, item) => total + item.totalPrice);
  }

  double get selectedItemsTotal {
    return state
        .where((item) => item.isSelected)
        .fold(0, (total, item) => total + item.totalPrice);
  }

  int get selectedItemsCount {
    return state.where((item) => item.isSelected).length;
  }

  bool get hasSelectedItems {
    return state.any((item) => item.isSelected);
  }

  Future<void> updateItemQuantity(String medicineId, int newQuantity) async {
    if (newQuantity < 1) return;

    // Get current user
    final userAsyncValue = _ref.read(currentUserProvider);
    final user = userAsyncValue.value;

    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Find the cart item in Firestore and update quantity
      final cartItems = await FirebaseFirestore.instance
          .collection('cart')
          .where('userUID', isEqualTo: user.id)
          .where('medicineID', isEqualTo: medicineId)
          .where('status', isEqualTo: 'active')
          .get();

      // Update quantity in Firestore
      for (final doc in cartItems.docs) {
        await FirebaseFirestore.instance.collection('cart').doc(doc.id).update({
          'quantity': newQuantity,
        });
      }

      // Update local state
      final updatedItems = [...state];
      final index = updatedItems.indexWhere(
        (item) => item.medicine.id == medicineId,
      );
      if (index >= 0) {
        updatedItems[index] = updatedItems[index].copyWith(
          quantity: newQuantity,
        );
        state = updatedItems;
      }
    } catch (e) {
      throw Exception('Failed to update item quantity: $e');
    }
  }

  Future<void> incrementQuantity(String medicineId) async {
    final item = state.firstWhere((item) => item.medicine.id == medicineId);
    await updateItemQuantity(medicineId, item.quantity + 1);
  }

  Future<void> decrementQuantity(String medicineId) async {
    final item = state.firstWhere((item) => item.medicine.id == medicineId);
    if (item.quantity > 1) {
      await updateItemQuantity(medicineId, item.quantity - 1);
    }
  }

  Future<void> updateCartStatus(String medicineId, CartStatus newStatus) async {
    try {
      // Get the user to find the cart document
      final userAsyncValue = _ref.read(currentUserProvider);
      final user = userAsyncValue.value;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Find the cart document in Firestore
      final cartQuery = await FirebaseFirestore.instance
          .collection('cart')
          .where('userUID', isEqualTo: user.id)
          .where('medicineID', isEqualTo: medicineId)
          .get();

      if (cartQuery.docs.isNotEmpty) {
        final cartDoc = cartQuery.docs.first;
        await _cartRepository.updateCartStatus(
          cartDoc.id,
          newStatus.displayName,
        );
      }

      // Note: Local state doesn't need to be updated since CartItem doesn't store status
      // Status is managed at the Firestore level
    } catch (e) {
      print('Error updating cart status: $e');
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final cartRepository = ref.watch(cartRepositoryProvider);
  return CartNotifier(cartRepository, ref);
});

// Provider to track if we're in selection mode
final selectionModeProvider = StateProvider<bool>((ref) => false);

// Provider to track if all items are selected
final selectAllProvider = StateProvider<bool>((ref) => false);

// Provider to track search query
final cartSearchProvider = StateProvider<String>((ref) => '');

// Provider for filtered cart items based on search query
final filteredCartProvider = Provider<List<CartItem>>((ref) {
  final cartItems = ref.watch(cartProvider);
  final searchQuery = ref.watch(cartSearchProvider);
  final favorites = ref.watch(favoriteMedicinesProvider);

  List<CartItem> filteredItems;

  if (searchQuery.isEmpty) {
    filteredItems = cartItems;
  } else {
    filteredItems = cartItems.where((item) {
      return item.medicine.medicineName.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
    }).toList();
  }

  // Sort items: favorites first, then non-favorites
  filteredItems.sort((a, b) {
    final aIsFavorite = favorites.contains(a.medicine.id);
    final bIsFavorite = favorites.contains(b.medicine.id);

    if (aIsFavorite && !bIsFavorite) return -1;
    if (!aIsFavorite && bIsFavorite) return 1;
    return 0; // Keep original order for items with same favorite status
  });

  return filteredItems;
});
