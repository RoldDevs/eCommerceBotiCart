import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/repositories/pharmacy_repository.dart';
import 'pharmacy_repository_impl.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late final PharmacyRepository _pharmacyRepository;

  ReviewRepositoryImpl() {
    _pharmacyRepository = PharmacyRepositoryImpl();
  }

  @override
  Stream<List<Review>> getPharmacyReviews(String pharmacyId) {
    return _firestore
        .collection('pharmacy')
        .doc(pharmacyId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Review.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<void> addReview(Review review) async {
    await _firestore
        .collection('pharmacy')
        .doc(review.pharmacyId)
        .collection('reviews')
        .add(review.toFirestore());

    // Update pharmacy rating after adding review
    await updatePharmacyRatingAfterReviewChange(review.pharmacyId);
  }

  @override
  Future<void> updateReview(Review review) async {
    await _firestore
        .collection('pharmacy')
        .doc(review.pharmacyId)
        .collection('reviews')
        .doc(review.id)
        .update(review.toFirestore());

    // Update pharmacy rating after updating review
    await updatePharmacyRatingAfterReviewChange(review.pharmacyId);
  }

  @override
  Future<void> deleteReview(String pharmacyId, String reviewId) async {
    await _firestore
        .collection('pharmacy')
        .doc(pharmacyId)
        .collection('reviews')
        .doc(reviewId)
        .delete();

    // Update pharmacy rating after deleting review
    await updatePharmacyRatingAfterReviewChange(pharmacyId);
  }

  @override
  Future<String> uploadReviewMedia(
    String filePath,
    String userId,
    String reviewId,
    bool isVideo,
  ) async {
    final file = File(filePath);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final mediaType = isVideo ? 'videos' : 'images';

    final ref = _storage.ref().child(
      'reviews/$userId/$reviewId/$mediaType/$fileName',
    );

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  @override
  Future<void> updatePharmacyRatingAfterReviewChange(String pharmacyId) async {
    try {
      // Get all reviews for this pharmacy
      final reviewsSnapshot = await _firestore
          .collection('pharmacy')
          .doc(pharmacyId)
          .collection('reviews')
          .get();

      final reviews = reviewsSnapshot.docs
          .map((doc) => Review.fromFirestore(doc.data(), doc.id))
          .toList();

      // Calculate new rating and review count
      final reviewCount = reviews.length;
      double averageRating = 0.0;

      if (reviewCount > 0) {
        final totalRating = reviews.fold<double>(
          0.0,
          (sum, review) => sum + review.rating,
        );
        averageRating = totalRating / reviewCount;
        // Round to 1 decimal place
        averageRating = double.parse(averageRating.toStringAsFixed(1));
      }

      // Update pharmacy document with new rating and review count
      await _pharmacyRepository.updatePharmacyRating(
        pharmacyId,
        averageRating,
        reviewCount,
      );
    } catch (e) {
      // Don't throw error to avoid breaking review operations
    }
  }
}
