import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../../data/repositories/review_repository_impl.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl();
});

final pharmacyReviewsProvider = StreamProvider.family<List<Review>, String>((
  ref,
  pharmacyId,
) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getPharmacyReviews(pharmacyId);
});

final reviewFormProvider =
    StateNotifierProvider<ReviewFormNotifier, ReviewFormState>((ref) {
      return ReviewFormNotifier(ref.watch(reviewRepositoryProvider));
    });

class ReviewFormState {
  final double rating;
  final String comment;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final List<String> imagePaths;
  final List<String> videoPaths;
  final bool isLoading;
  final String? error;

  ReviewFormState({
    this.rating = 0.0,
    this.comment = '',
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.imagePaths = const [],
    this.videoPaths = const [],
    this.isLoading = false,
    this.error,
  });

  ReviewFormState copyWith({
    double? rating,
    String? comment,
    List<String>? imageUrls,
    List<String>? videoUrls,
    List<String>? imagePaths,
    List<String>? videoPaths,
    bool? isLoading,
    String? error,
  }) {
    return ReviewFormState(
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      imagePaths: imagePaths ?? this.imagePaths,
      videoPaths: videoPaths ?? this.videoPaths,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ReviewFormNotifier extends StateNotifier<ReviewFormState> {
  final ReviewRepository _repository;

  ReviewFormNotifier(this._repository) : super(ReviewFormState());

  void updateRating(double rating) {
    state = state.copyWith(rating: rating);
  }

  void updateComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  void addImageUrl(String url) {
    final updatedImages = [...state.imageUrls, url];
    state = state.copyWith(imageUrls: updatedImages);
  }

  void addVideoUrl(String url) {
    final updatedVideos = [...state.videoUrls, url];
    state = state.copyWith(videoUrls: updatedVideos);
  }

  void addImage(String path) {
    final updatedPaths = [...state.imagePaths, path];
    state = state.copyWith(imagePaths: updatedPaths);
  }

  void addVideo(String path) {
    final updatedPaths = [...state.videoPaths, path];
    state = state.copyWith(videoPaths: updatedPaths);
  }

  void removeImageUrl(String url) {
    final updatedImages = state.imageUrls
        .where((image) => image != url)
        .toList();
    state = state.copyWith(imageUrls: updatedImages);
  }

  void removeVideoUrl(String url) {
    final updatedVideos = state.videoUrls
        .where((video) => video != url)
        .toList();
    state = state.copyWith(videoUrls: updatedVideos);
  }

  void removeImage(String path) {
    final updatedPaths = state.imagePaths
        .where((image) => image != path)
        .toList();
    state = state.copyWith(imagePaths: updatedPaths);
  }

  void removeVideo(String path) {
    final updatedPaths = state.videoPaths
        .where((video) => video != path)
        .toList();
    state = state.copyWith(videoPaths: updatedPaths);
  }

  Future<void> submitReview({
    required String pharmacyId,
    required String userId,
    required String userName,
  }) async {
    if (state.rating == 0.0) {
      state = state.copyWith(error: 'Please provide a rating');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Upload media files first
      List<String> uploadedImageUrls = [];
      List<String> uploadedVideoUrls = [];

      // Generate a temporary review ID for media upload
      final tempReviewId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload images
      for (String imagePath in state.imagePaths) {
        final url = await _repository.uploadReviewMedia(
          imagePath,
          userId,
          tempReviewId,
          false,
        );
        uploadedImageUrls.add(url);
      }

      // Upload videos
      for (String videoPath in state.videoPaths) {
        final url = await _repository.uploadReviewMedia(
          videoPath,
          userId,
          tempReviewId,
          true,
        );
        uploadedVideoUrls.add(url);
      }

      final review = Review(
        id: '',
        pharmacyId: pharmacyId,
        userId: userId,
        userName: userName,
        rating: state.rating,
        comment: state.comment,
        imageUrls: uploadedImageUrls,
        videoUrls: uploadedVideoUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.addReview(review);

      // Successfully submitted - reset form and clear loading state
      state = ReviewFormState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit review: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<String> uploadMedia(
    String filePath,
    String userId,
    String reviewId,
    bool isVideo,
  ) async {
    try {
      return await _repository.uploadReviewMedia(
        filePath,
        userId,
        reviewId,
        isVideo,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to upload media: ${e.toString()}');
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = ReviewFormState();
  }
}
