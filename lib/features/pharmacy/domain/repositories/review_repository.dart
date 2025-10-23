import '../entities/review.dart';

abstract class ReviewRepository {
  Stream<List<Review>> getPharmacyReviews(String pharmacyId);
  Future<void> addReview(Review review);
  Future<void> updateReview(Review review);
  Future<void> deleteReview(String pharmacyId, String reviewId);
  Future<String> uploadReviewMedia(String filePath, String userId, String reviewId, bool isVideo);
}