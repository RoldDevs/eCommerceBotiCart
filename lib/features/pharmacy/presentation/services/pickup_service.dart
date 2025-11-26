import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pickup_time_slot.dart';
import '../models/pickup_promotion.dart';

/// Service for managing pickup-related operations
class PickupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate available pickup time slots
  List<PickupTimeSlot> generatePickupTimeSlots({
    DateTime? startFrom,
    int daysAhead = 7,
    int slotsPerDay = 8,
  }) {
    final now = DateTime.now();
    final start = startFrom ?? now.add(const Duration(minutes: 30));
    final slots = <PickupTimeSlot>[];

    for (int day = 0; day < daysAhead; day++) {
      final currentDay = DateTime(start.year, start.month, start.day + day);

      // Skip if it's in the past
      if (day == 0 && currentDay.day == now.day) {
        // Only add slots after current time for today
        final firstSlotHour = now.hour + 1;
        if (firstSlotHour >= 22) continue; // Store closes at 10 PM
      }

      // Generate slots from 8 AM to 10 PM
      for (int slot = 0; slot < slotsPerDay; slot++) {
        final hour = 8 + (slot * 2); // Every 2 hours starting from 8 AM
        if (hour >= 22) break; // Don't go past 10 PM

        final slotStart = DateTime(
          currentDay.year,
          currentDay.month,
          currentDay.day,
          hour,
        );

        final slotEnd = slotStart.add(const Duration(hours: 2));

        // Skip if slot is in the past
        if (slotStart.isBefore(now)) continue;

        slots.add(
          PickupTimeSlot(
            startTime: slotStart,
            endTime: slotEnd,
            isAvailable: true,
            expressLane: slot < 2
                ? 'Express Lane A'
                : null, // First 2 slots are express
          ),
        );
      }
    }

    return slots;
  }

  /// Calculate ready-by time based on order complexity
  Future<DateTime> calculateReadyByTime({
    required int itemCount,
    required int totalQuantity,
    DateTime? scheduledPickupTime,
  }) async {
    // Base time: 15 minutes
    // Additional time per item: 2 minutes
    // Additional time per quantity unit: 1 minute
    final baseMinutes = 15;
    final itemMinutes = itemCount * 2;
    final quantityMinutes = totalQuantity;
    final totalMinutes = baseMinutes + itemMinutes + quantityMinutes;

    final readyTime = (scheduledPickupTime ?? DateTime.now()).add(
      Duration(minutes: totalMinutes),
    );

    return readyTime;
  }

  /// Reserve items for pickup (prevent stock from being sold to walk-ins)
  Future<void> reserveItemsForPickup({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final item in items) {
        final medicineId = item['medicineID'] as String;
        final quantity = item['quantity'] as int;

        final medicineRef = _firestore.collection('medicines').doc(medicineId);
        final medicineDoc = await medicineRef.get();

        if (medicineDoc.exists) {
          final reservedStock = medicineDoc.data()?['reservedStock'] ?? 0;

          // Reserve the quantity
          batch.update(medicineRef, {
            'reservedStock': reservedStock + quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to reserve items: $e');
    }
  }

  /// Release reserved items (if order is cancelled)
  Future<void> releaseReservedItems({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final item in items) {
        final medicineId = item['medicineID'] as String;
        final quantity = item['quantity'] as int;

        final medicineRef = _firestore.collection('medicines').doc(medicineId);
        final medicineDoc = await medicineRef.get();

        if (medicineDoc.exists) {
          final reservedStock = medicineDoc.data()?['reservedStock'] ?? 0;
          final newReservedStock = (reservedStock - quantity)
              .clamp(0, double.infinity)
              .toInt();

          batch.update(medicineRef, {
            'reservedStock': newReservedStock,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to release reserved items: $e');
    }
  }

  /// Get active pickup promotions
  Future<List<PickupPromotion>> getActivePickupPromotions() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('pickupPromotions')
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PickupPromotion(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
          fixedDiscountAmount: data['fixedDiscountAmount']?.toDouble(),
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate: (data['endDate'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
          promoCode: data['promoCode'],
          minimumOrderAmount: data['minimumOrderAmount'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Update pickup status
  Future<void> updatePickupStatus({
    required String orderId,
    required String status, // 'preparing', 'ready', 'picked_up'
    int? estimatedMinutesUntilReady,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'pickupStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (estimatedMinutesUntilReady != null) {
        updateData['estimatedMinutesUntilReady'] = estimatedMinutesUntilReady;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update pickup status: $e');
    }
  }

  /// Check real-time inventory availability
  Future<Map<String, bool>> checkInventoryAvailability({
    required List<String> medicineIds,
  }) async {
    try {
      final availability = <String, bool>{};

      for (final medicineId in medicineIds) {
        final doc = await _firestore
            .collection('medicines')
            .doc(medicineId)
            .get();

        if (doc.exists) {
          final stock = doc.data()?['stock'] ?? 0;
          final reservedStock = doc.data()?['reservedStock'] ?? 0;
          final availableStock = stock - reservedStock;
          availability[medicineId] = availableStock > 0;
        } else {
          availability[medicineId] = false;
        }
      }

      return availability;
    } catch (e) {
      throw Exception('Failed to check inventory: $e');
    }
  }

  /// Notify store that customer has arrived for curbside pickup
  Future<void> notifyCustomerArrived({
    required String orderId,
    String? additionalInfo,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'curbsideArrivalNotified': true,
        'curbsideArrivalTime': FieldValue.serverTimestamp(),
        'curbsideArrivalInfo': additionalInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also create a notification message for the store
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data()!;
        final userUID = orderData['userUID'] as String;

        // Create a message in the order messages collection
        await _firestore
            .collection('orders')
            .doc(orderId)
            .collection('messages')
            .add({
              'message':
                  'Customer has arrived for curbside pickup. ${additionalInfo != null ? "Info: $additionalInfo" : ""}',
              'senderUID': userUID,
              'senderType': 'customer',
              'messageType': 'curbside_arrival',
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
            });
      }
    } catch (e) {
      throw Exception('Failed to notify arrival: $e');
    }
  }

  /// Check if customer has already notified arrival
  Future<bool> hasNotifiedArrival(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) return false;
      return doc.data()?['curbsideArrivalNotified'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
