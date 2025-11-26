import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/pickup_provider.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Widget for curbside/drive-up pickup option
class CurbsidePickupWidget extends ConsumerWidget {
  const CurbsidePickupWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurbside = ref.watch(isCurbsidePickupProvider);

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
          Row(
            children: [
              Icon(
                Icons.directions_car,
                color: const Color(0xFF8ECAE6),
                size: ResponsiveUtils.getResponsiveIconSize(context),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context)),
              Text(
                'Curbside Pickup',
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Switch(
                value: isCurbside,
                onChanged: (value) {
                  ref.read(isCurbsidePickupProvider.notifier).state = value;
                },
                activeThumbColor: const Color(
                  0xFF8ECAE6,
                ).withValues(alpha: 0.8),
              ),
            ],
          ),
          if (isCurbside) ...[
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
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
                    Icons.info_outline,
                    color: const Color(0xFF8ECAE6),
                    size: ResponsiveUtils.getResponsiveIconSize(context) * 0.8,
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Expanded(
                    child: Text(
                      'Tap "I\'m here" when you arrive and our staff will bring your order to your car.',
                      style: GoogleFonts.poppins(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          12,
                        ),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Text(
              'Special Instructions (Optional)',
              style: GoogleFonts.poppins(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
            ),
            TextField(
              onChanged: (value) {
                ref.read(pickupInstructionsProvider.notifier).state =
                    value.isEmpty ? null : value;
              },
              decoration: InputDecoration(
                hintText: 'e.g., Car color, parking spot number, etc.',
                hintStyle: GoogleFonts.poppins(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                  color: Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8ECAE6),
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.all(
                  ResponsiveUtils.getResponsivePadding(context),
                ),
              ),
              maxLines: 2,
              style: GoogleFonts.poppins(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
