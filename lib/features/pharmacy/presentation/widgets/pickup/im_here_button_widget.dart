import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/pickup_provider.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Widget for "I'm here" button for curbside pickup
class ImHereButtonWidget extends ConsumerStatefulWidget {
  final String orderId;
  final String? pickupInstructions;
  final String pickupStatus;

  const ImHereButtonWidget({
    super.key,
    required this.orderId,
    this.pickupInstructions,
    this.pickupStatus = 'preparing',
  });

  @override
  ConsumerState<ImHereButtonWidget> createState() => _ImHereButtonWidgetState();
}

class _ImHereButtonWidgetState extends ConsumerState<ImHereButtonWidget> {
  bool _isNotifying = false;
  bool _hasNotified = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final service = ref.read(pickupServiceProvider);
    final notified = await service.hasNotifiedArrival(widget.orderId);
    if (mounted) {
      setState(() {
        _hasNotified = notified;
      });
    }
  }

  Future<void> _notifyArrival() async {
    if (_isNotifying || _hasNotified || widget.pickupStatus != 'ready') return;

    setState(() {
      _isNotifying = true;
    });

    try {
      final service = ref.read(pickupServiceProvider);
      await service.notifyCustomerArrived(
        orderId: widget.orderId,
        additionalInfo: widget.pickupInstructions,
      );

      if (mounted) {
        setState(() {
          _hasNotified = true;
          _isNotifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Store has been notified! Staff will bring your order shortly.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNotifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to notify store. Please try again.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
              Expanded(
                child: Text(
                  'Curbside Pickup',
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      16,
                    ),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
          Text(
            _hasNotified
                ? 'You have notified the store. Staff will bring your order to your car shortly.'
                : 'Tap the button below when you arrive at the store and our staff will bring your order to your car.',
            style: GoogleFonts.poppins(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (_hasNotified ||
                      _isNotifying ||
                      widget.pickupStatus != 'ready')
                  ? null
                  : _notifyArrival,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (_hasNotified || widget.pickupStatus != 'ready')
                    ? Colors.grey.shade300
                    : const Color(0xFF8ECAE6),
                foregroundColor:
                    (_hasNotified || widget.pickupStatus != 'ready')
                    ? Colors.grey.shade600
                    : Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.getResponsivePadding(context) * 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: (_hasNotified || widget.pickupStatus != 'ready')
                    ? 0
                    : 2,
              ),
              icon: _isNotifying
                  ? SizedBox(
                      width:
                          ResponsiveUtils.getResponsiveIconSize(context) * 0.8,
                      height:
                          ResponsiveUtils.getResponsiveIconSize(context) * 0.8,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _hasNotified ? Icons.check_circle : Icons.location_on,
                      size: ResponsiveUtils.getResponsiveIconSize(context),
                    ),
              label: Text(
                _isNotifying
                    ? 'Notifying...'
                    : (_hasNotified ? 'Notified ✓' : 'I\'m Here'),
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (widget.pickupInstructions != null &&
              widget.pickupInstructions!.isNotEmpty) ...[
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF8ECAE6),
                    size: ResponsiveUtils.getResponsiveIconSize(context) * 0.8,
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Instructions:',
                          style: GoogleFonts.poppins(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              11,
                            ),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8ECAE6),
                          ),
                        ),
                        SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(context) *
                              0.25,
                        ),
                        Text(
                          widget.pickupInstructions!,
                          style: GoogleFonts.poppins(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              12,
                            ),
                            color: Colors.black87,
                          ),
                        ),
                      ],
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
}
