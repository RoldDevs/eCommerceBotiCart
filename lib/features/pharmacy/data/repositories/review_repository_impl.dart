import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<Review>> getPharmacyReviews(String pharmacyId) {
    return _firestore
        .collection('pharmacy')
        .doc(pharmacyId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> addReview(Review review) async {
    await _firestore
        .collection('pharmacy')
        .doc(review.pharmacyId)
        .collection('reviews')
        .add(review.toFirestore());
  }

  @override
  Future<void> updateReview(Review review) async {
    await _firestore
        .collection('pharmacy')
        .doc(review.pharmacyId)
        .collection('reviews')
        .doc(review.id)
        .update(review.toFirestore());
  }

  @override
  Future<void> deleteReview(String pharmacyId, String reviewId) async {
    await _firestore
        .collection('pharmacy')
        .doc(pharmacyId)
        .collection('reviews')
        .doc(reviewId)
        .delete();
  }

  @override
  Future<String> uploadReviewMedia(String filePath, String userId, String reviewId, bool isVideo) async {
    final file = File(filePath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final mediaType = isVideo ? 'videos' : 'images';
    
    final ref = _storage.ref().child('reviews/$userId/$reviewId/$mediaType/$fileName');
    
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    
    return await snapshot.ref.getDownloadURL();
  }
}