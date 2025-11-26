import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/medicine.dart';
import '../../providers/pickup_provider.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Widget to show real-time inventory availability
class InventoryAvailabilityWidget extends ConsumerWidget {
  final List<Medicine> medicines;

  const InventoryAvailabilityWidget({super.key, required this.medicines});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(pickupServiceProvider);
    final medicineIds = medicines.map((m) => m.id).toList();

    return FutureBuilder<Map<String, bool>>(
      future: service.checkInventoryAvailability(medicineIds: medicineIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final availability = snapshot.data!;
        final allAvailable = availability.values.every(
          (available) => available,
        );

        if (allAvailable) {
          return Container(
            padding: EdgeInsets.all(
              ResponsiveUtils.getResponsivePadding(context),
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: ResponsiveUtils.getResponsiveIconSize(context),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context)),
                Expanded(
                  child: Text(
                    'All items are in stock and reserved for your order',
                    style: GoogleFonts.poppins(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        12,
                      ),
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.all(
            ResponsiveUtils.getResponsivePadding(context),
          ),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: ResponsiveUtils.getResponsiveIconSize(context),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Text(
                    'Inventory Alert',
                    style: GoogleFonts.poppins(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        14,
                      ),
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
              ),
              ...medicines
                  .where((m) => !(availability[m.id] ?? true))
                  .map(
                    (medicine) => Padding(
                      padding: EdgeInsets.only(
                        top:
                            ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                      ),
                      child: Text(
                        '• ${medicine.medicineName} - Out of stock',
                        style: GoogleFonts.poppins(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            12,
                          ),
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
