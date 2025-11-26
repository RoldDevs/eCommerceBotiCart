import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/pickup_service.dart';
import '../models/pickup_time_slot.dart';
import '../models/pickup_promotion.dart';

/// Provider for PickupService
final pickupServiceProvider = Provider<PickupService>((ref) {
  return PickupService();
});

/// Provider for available pickup time slots
final pickupTimeSlotsProvider = FutureProvider<List<PickupTimeSlot>>((
  ref,
) async {
  final service = ref.read(pickupServiceProvider);
  return service.generatePickupTimeSlots();
});

/// Provider for active pickup promotions
final pickupPromotionsProvider = FutureProvider<List<PickupPromotion>>((
  ref,
) async {
  final service = ref.read(pickupServiceProvider);
  return service.getActivePickupPromotions();
});

/// Provider for selected pickup time slot
final selectedPickupTimeSlotProvider = StateProvider<PickupTimeSlot?>(
  (ref) => null,
);

/// Provider for curbside pickup option
final isCurbsidePickupProvider = StateProvider<bool>((ref) => false);

/// Provider for pickup instructions
final pickupInstructionsProvider = StateProvider<String?>((ref) => null);

/// Provider for selected pickup promotion
final selectedPickupPromotionProvider = StateProvider<PickupPromotion?>(
  (ref) => null,
);
