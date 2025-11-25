import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/medicine.dart';

class CartRepository {
  final FirebaseFirestore _firestore;

  CartRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // Add item to cart
  Future<void> addToCart({
    required String userUID,
    required String medicineID,
    required int quantity,
  }) async {
    final cartRef = _firestore.collection('cart');
    
    // Check if item already exists in cart
    final existingItem = await cartRef
        .where('userUID', isEqualTo: userUID)
        .where('medicineID', isEqualTo: medicineID)
        .where('status', isEqualTo: 'active')
        .get();

    if (existingItem.docs.isNotEmpty) {
      // Update existing item quantity
      final doc = existingItem.docs.first;
      final currentQuantity = doc.data()['quantity'] as int;
      await doc.reference.update({
        'quantity': currentQuantity + quantity,
      });
    } else {
      // Add new item
      final docRef = cartRef.doc();
      final cartEntity = CartEntity(
        itemCartNo: docRef.id,
        userUID: userUID,
        medicineID: medicineID,
        status: 'active',
        createdAt: DateTime.now(),
        quantity: quantity,
      );
      
      await docRef.set(cartEntity.toFirestore());
    }
  }

  // Get user's cart items
  Stream<List<CartEntity>> getUserCartItems(String userUID) {
    return _firestore
        .collection('cart')
        .where('userUID', isEqualTo: userUID)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CartEntity.fromFirestore(doc)).toList();
    });
  }

  // Get medicine by ID
  Future<Medicine?> getMedicineById(String medicineID) async {
    try {
      final doc = await _firestore.collection('medicines').doc(medicineID).get();
      if (doc.exists) {
        return Medicine.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String itemCartNo) async {
    await _firestore.collection('cart').doc(itemCartNo).delete();
  }

  // Update item quantity
  Future<void> updateQuantity(String itemCartNo, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(itemCartNo);
    } else {
      await _firestore.collection('cart').doc(itemCartNo).update({
        'quantity': quantity,
      });
    }
  }

  // Remove selected items
  Future<void> removeSelectedItems(String userUID, List<String> itemCartNos) async {
    final batch = _firestore.batch();
    
    for (final itemCartNo in itemCartNos) {
      final docRef = _firestore.collection('cart').doc(itemCartNo);
      batch.delete(docRef);
    }
    
    await batch.commit();
  }

  // Clear entire cart
  Future<void> clearCart(String userUID) async {
    final cartItems = await _firestore
        .collection('cart')
        .where('userUID', isEqualTo: userUID)
        .where('status', isEqualTo: 'active')
        .get();

    final batch = _firestore.batch();
    for (final doc in cartItems.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  Future<void> updateCartStatus(String itemCartNo, String status) async {
    await _firestore.collection('cart').doc(itemCartNo).update({
      'status': status,
    });
  }
}