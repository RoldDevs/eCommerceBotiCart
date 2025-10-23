import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          _buildUserInfo(),
          const SizedBox(height: 12),
          _buildRating(),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildComment(),
          ],
          if (review.imageUrls.isNotEmpty || review.videoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMedia(),
          ],
          const SizedBox(height: 8),
          _buildDate(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
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
          child: Text(
            review.userName.isNotEmpty ? review.userName : 'Anonymous User',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2A4B8D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < review.rating.floor()
                ? Icons.star
                : index < review.rating
                    ? Icons.star_half
                    : Icons.star_border,
            color: Colors.amber,
            size: 16,
          );
        }),
        const SizedBox(width: 8),
        Text(
          review.rating.toStringAsFixed(1),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
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

  Widget _buildMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (review.imageUrls.isNotEmpty) ...[
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: review.imageUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(review.imageUrls[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (review.videoUrls.isNotEmpty) ...[
          if (review.imageUrls.isNotEmpty) const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: review.videoUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
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
                        Icons.play_circle_outline,
                        size: 32,
                        color: Colors.grey,
                      ),
                      // You can add video thumbnail here if needed
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDate() {
    final now = DateTime.now();
    final difference = now.difference(review.createdAt);
    
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

    return Text(
      timeAgo,
      style: GoogleFonts.poppins(
        fontSize: 12,
        color: Colors.grey[500],
      ),
    );
  }
}