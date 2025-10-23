import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/pharmacy.dart';
import '../providers/review_provider.dart';
import '../../../auth/presentation/providers/user_provider.dart';

class RateStoreScreen extends ConsumerStatefulWidget {
  final Pharmacy pharmacy;

  const RateStoreScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  ConsumerState<RateStoreScreen> createState() => _RateStoreScreenState();
}

class _RateStoreScreenState extends ConsumerState<RateStoreScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  List<File> _selectedVideos = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewFormState = ref.watch(reviewFormProvider);
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPharmacyInfo(),
                    const SizedBox(height: 24),
                    _buildRatingSection(reviewFormState),
                    const SizedBox(height: 24),
                    _buildCommentSection(),
                    const SizedBox(height: 24),
                    _buildMediaSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(reviewFormState, user),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8ECAE6).withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF8ECAE6),
            ),
          ),
          Expanded(
            child: Text(
              'RATE STORE',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A4B8D),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPharmacyInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F3F8).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8ECAE6).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF8ECAE6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: widget.pharmacy.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.pharmacy.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_pharmacy,
                          color: Colors.white,
                          size: 30,
                        );
                      },
                    )
                  : const Icon(
                      Icons.local_pharmacy,
                      color: Colors.white,
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pharmacy.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A4B8D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.pharmacy.location,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(ReviewFormState reviewFormState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rate Store',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2A4B8D),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                ref.read(reviewFormProvider.notifier).updateRating((index + 1).toDouble());
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  index < reviewFormState.rating
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            );
          }),
        ),
        if (reviewFormState.rating > 0)
          Center(
            child: Text(
              '${reviewFormState.rating.toInt()} star${reviewFormState.rating > 1 ? 's' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Write 150 characters',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 5,
            maxLength: 150,
            onChanged: (value) {
              ref.read(reviewFormProvider.notifier).updateComment(value);
            },
            decoration: InputDecoration(
              hintText: 'Tell us about your experience to assist fellow shoppers.',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add 1 photo or video',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2A4B8D),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMediaButton(
                icon: Icons.photo_camera_outlined,
                label: 'Photo',
                onTap: _pickImage,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMediaButton(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: _pickVideo,
              ),
            ),
          ],
        ),
        if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSelectedMedia(),
        ],
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty) ...[
          Text(
            'Selected Images:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2A4B8D),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedImages.map((image) {
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.remove(image);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
        if (_selectedVideos.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Selected Videos:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2A4B8D),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedVideos.map((video) {
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    child: const Icon(
                      Icons.play_circle_outline,
                      size: 32,
                      color: Colors.grey,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedVideos.remove(video);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(ReviewFormState reviewFormState, user) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: reviewFormState.isLoading || reviewFormState.rating == 0.0
            ? null
            : () => _submitReview(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8ECAE6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: reviewFormState.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Submit',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedVideos.add(File(video.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e')),
      );
    }
  }

  Future<void> _submitReview(user) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review')),
      );
      return;
    }

    try {
      // Upload media files first
      final reviewId = DateTime.now().millisecondsSinceEpoch.toString();
      
      for (final image in _selectedImages) {
        final url = await ref.read(reviewFormProvider.notifier)
            .uploadMedia(image.path, user.uid, reviewId, false);
        ref.read(reviewFormProvider.notifier).addImageUrl(url);
      }

      for (final video in _selectedVideos) {
        final url = await ref.read(reviewFormProvider.notifier)
            .uploadMedia(video.path, user.uid, reviewId, true);
        ref.read(reviewFormProvider.notifier).addVideoUrl(url);
      }

      // Submit the review
      await ref.read(reviewFormProvider.notifier).submitReview(
        pharmacyId: widget.pharmacy.id,
        userId: user.uid,
        userName: user.firstName ?? 'Anonymous',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    }
  }
}