import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/order.dart';
import '../../../../../core/utils/responsive_utils.dart';
import 'package:intl/intl.dart';

/// Widget to track pickup order status with queue time
class PickupStatusTrackerWidget extends StatelessWidget {
  final OrderEntity order;

  const PickupStatusTrackerWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.pickupStatus ?? 'preparing';
    final estimatedMinutes = order.estimatedMinutesUntilReady ?? 0;
    final readyByTime = order.readyByTime;

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Status',
            style: GoogleFonts.poppins(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5),
          _buildStatusStep(
            context,
            'Preparing',
            Icons.restaurant_menu,
            status == 'preparing',
            status == 'preparing',
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
          _buildStatusStep(
            context,
            'Ready for Pickup',
            Icons.check_circle,
            status == 'ready',
            status == 'ready' || status == 'picked_up',
          ),
          if (readyByTime != null) ...[
            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
            ),
            Container(
              padding: EdgeInsets.all(
                ResponsiveUtils.getResponsivePadding(context) * 0.75,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF8ECAE6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: const Color(0xFF8ECAE6),
                    size: ResponsiveUtils.getResponsiveIconSize(context),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guaranteed Ready By',
                          style: GoogleFonts.poppins(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              12,
                            ),
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy • hh:mm a',
                          ).format(readyByTime),
                          style: GoogleFonts.poppins(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              14,
                            ),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8ECAE6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (estimatedMinutes > 0 && status == 'preparing') ...[
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Text(
              'Estimated time: $estimatedMinutes minutes',
              style: GoogleFonts.poppins(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (order.expressPickupLane != null) ...[
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Container(
              padding: EdgeInsets.all(
                ResponsiveUtils.getResponsivePadding(context) * 0.75,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Colors.orange,
                    size: ResponsiveUtils.getResponsiveIconSize(context),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Expanded(
                    child: Text(
                      'Express Pickup: ${order.expressPickupLane}',
                      style: GoogleFonts.poppins(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          12,
                        ),
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusStep(
    BuildContext context,
    String label,
    IconData icon,
    bool isActive,
    bool isCompleted,
  ) {
    return Row(
      children: [
        Container(
          width: ResponsiveUtils.getResponsiveIconSize(context) * 1.5,
          height: ResponsiveUtils.getResponsiveIconSize(context) * 1.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF8ECAE6)
                : (isActive ? Colors.orange : Colors.grey.shade300),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: ResponsiveUtils.getResponsiveIconSize(context) * 0.8,
          ),
        ),
        SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context)),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive || isCompleted
                  ? Colors.black87
                  : Colors.grey.shade600,
            ),
          ),
        ),
        if (isCompleted)
          Icon(
            Icons.check,
            color: const Color(0xFF8ECAE6),
            size: ResponsiveUtils.getResponsiveIconSize(context),
          ),
      ],
    );
  }
}
