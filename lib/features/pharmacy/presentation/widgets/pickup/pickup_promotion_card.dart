import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pickup_promotion.dart';
import '../../providers/pickup_provider.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Widget to display pickup-exclusive promotions
class PickupPromotionCard extends ConsumerWidget {
  final PickupPromotion promotion;
  final double orderAmount;
  final VoidCallback? onApply;

  const PickupPromotionCard({
    super.key,
    required this.promotion,
    required this.orderAmount,
    this.onApply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected =
        ref.watch(selectedPickupPromotionProvider)?.id == promotion.id;
    final discount = promotion.calculateDiscount(orderAmount);
    final isValid = promotion.isValidForOrder(orderAmount);

    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getResponsiveSpacing(context),
      ),
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF8ECAE6).withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF8ECAE6) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PICKUP EXCLUSIVE',
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      10,
                    ),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (isValid && discount > 0)
                Text(
                  'Save ₱${discount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      14,
                    ),
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
          Text(
            promotion.title,
            style: GoogleFonts.poppins(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
          Text(
            promotion.description,
            style: GoogleFonts.poppins(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              color: Colors.grey.shade600,
            ),
          ),
          if (promotion.minimumOrderAmount != null) ...[
            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
            ),
            Text(
              'Minimum order: ₱${promotion.minimumOrderAmount!.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 11),
                color: Colors.grey.shade500,
              ),
            ),
          ],
          if (isValid && onApply != null) ...[
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(selectedPickupPromotionProvider.notifier).state =
                      promotion;
                  onApply?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color(0xFF8ECAE6)
                      : Colors.grey.shade200,
                  foregroundColor: isSelected ? Colors.white : Colors.black87,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.getResponsivePadding(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isSelected ? 'Applied' : 'Apply Promotion',
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      14,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
