import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/announcement.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8ECAE6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF8ECAE6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.campaign,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'System',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8ECAE6),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    announcement.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(announcement.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTypeColor(announcement.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getTypeLabel(announcement.type),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _getTypeColor(announcement.type),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  const SizedBox(height: 16),
                  // Message content
                  Text(
                    announcement.message,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  // Image if available
                  if (announcement.imageUrl != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        announcement.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  // Expiry info if available
                  if (announcement.expiresAt != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This announcement expires on ${DateFormat('MMM d, yyyy').format(announcement.expiresAt!)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.emergency:
        return Colors.red;
      case AnnouncementType.maintenance:
        return Colors.orange;
      case AnnouncementType.promotion:
        return Colors.green;
      case AnnouncementType.update:
        return Colors.blue;
      case AnnouncementType.general:
      return const Color(0xFF8ECAE6);
    }
  }

  String _getTypeLabel(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.emergency:
        return 'EMERGENCY';
      case AnnouncementType.maintenance:
        return 'MAINTENANCE';
      case AnnouncementType.promotion:
        return 'PROMOTION';
      case AnnouncementType.update:
        return 'UPDATE';
      case AnnouncementType.general:
        return 'GENERAL';
    }
  }
}