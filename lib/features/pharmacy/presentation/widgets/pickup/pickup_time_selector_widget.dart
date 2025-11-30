import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/pickup_provider.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Widget for selecting pickup time slot
class PickupTimeSelectorWidget extends ConsumerWidget {
  const PickupTimeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(pickupTimeSlotsProvider);
    final selectedSlot = ref.watch(selectedPickupTimeSlotProvider);

    return slotsAsync.when(
      data: (slots) {
        if (slots.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.all(
            ResponsiveUtils.getResponsivePadding(context),
          ),
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
                    Icons.access_time,
                    color: const Color(0xFF8ECAE6),
                    size: ResponsiveUtils.getResponsiveIconSize(context),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Text(
                    'Select Pickup Time',
                    style: GoogleFonts.poppins(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        16,
                      ),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              Text(
                'Choose when you\'d like to pick up your order',
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveHeight(context, 200),
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(
                      context,
                    ),
                    mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(
                      context,
                    ),
                    childAspectRatio: 0.8,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final isSelected =
                        selectedSlot?.startTime == slot.startTime;

                    return InkWell(
                      onTap: () {
                        ref
                                .read(selectedPickupTimeSlotProvider.notifier)
                                .state =
                            slot;
                      },
                      child: Container(
                        padding: EdgeInsets.all(
                          ResponsiveUtils.getResponsivePadding(context) * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8ECAE6)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8ECAE6)
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot.displayTime,
                              style: GoogleFonts.poppins(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  14,
                                ),
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            SizedBox(
                              height:
                                  ResponsiveUtils.getResponsiveSpacing(
                                    context,
                                  ) *
                                  0.25,
                            ),
                            Text(
                              _getDayLabel(slot.startTime),
                              style: GoogleFonts.poppins(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  10,
                                ),
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    }
  }
}
