import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/review.dart';

class ReviewItemWidget extends StatelessWidget {
  final Review review;
  final EdgeInsetsGeometry? margin;

  const ReviewItemWidget({
    super.key,
    required this.review,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoWithRating(),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildComment(),
          ],
          if (review.imageUrls.isNotEmpty || review.videoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMedia(context),
          ],
          const SizedBox(height: 12),
          _buildDate(),
        ],
      ),
    );
  }

  Widget _buildUserInfoWithRating() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF8ECAE6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              review.userName.isNotEmpty 
                  ? review.userName[0].toUpperCase()
                  : 'U',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.userName.isNotEmpty ? review.userName : 'Anonymous User',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8ECAE6),
                ),
              ),
              const SizedBox(height: 4),
              _buildDate(),
            ],
          ),
        ),
        _buildRatingStars(),
      ],
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < review.rating.floor()
              ? Icons.star
              : index < review.rating
                  ? Icons.star_half
                  : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildComment() {
    return Text(
      review.comment,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    List<Widget> mediaWidgets = [];
    
    // Add images
    for (int i = 0; i < review.imageUrls.length; i++) {
      String imageUrl = review.imageUrls[i];
      mediaWidgets.add(
        GestureDetector(
          onTap: () => _showImageModal(context, imageUrl, review.imageUrls, i),
          child: Container(
            margin: const EdgeInsets.only(right: 8, bottom: 8),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    }
    
    // Add videos
    for (String videoUrl in review.videoUrls) {
      mediaWidgets.add(
        GestureDetector(
          onTap: () => _showVideoModal(context, videoUrl),
          child: Container(
            margin: const EdgeInsets.only(right: 8, bottom: 8),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  size: 32,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Wrap(
      children: mediaWidgets,
    );
  }

  void _showImageModal(BuildContext context, String initialImageUrl, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ImageViewerModal(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        );
      },
    );
  }

  void _showVideoModal(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return VideoPlayerModal(videoUrl: videoUrl);
      },
    );
  }

  Widget _buildDate() {
    final now = DateTime.now();
    final difference = now.difference(review.createdAt);
    
    // ignore: unused_local_variable
    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      timeAgo = 'Just now';
    }

    final formattedDate = '${_getMonthName(review.createdAt.month)} ${review.createdAt.day.toString().padLeft(2, '0')} ${review.createdAt.year}';

    return Text(
      formattedDate,
      style: GoogleFonts.poppins(
        fontSize: 12,
        color: Colors.grey[500],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

// Image Viewer Modal Widget
class ImageViewerModal extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageViewerModal({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<ImageViewerModal> createState() => _ImageViewerModalState();
}

class _ImageViewerModalState extends State<ImageViewerModal> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.black87,
        child: Stack(
          children: [
            // Image PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFF8ECAE6),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 64,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            // Close button
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Image counter
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Video Player Modal Widget
class VideoPlayerModal extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerModal({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.black87,
        child: Stack(
          children: [
            // Video Player
            Center(
              child: _hasError
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error loading video',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    )
                  : _isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : const CircularProgressIndicator(
                          color: Color(0xFF8ECAE6),
                        ),
            ),
            // Video Controls
            if (_isInitialized && !_hasError)
              Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                        child: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFF8ECAE6),
                            bufferedColor: Colors.grey,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Close button
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}