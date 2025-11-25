import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../data/repositories/order_status_change_repository.dart';

/// Provider for OrderStatusChangeRepository
final orderStatusChangeRepositoryProvider =
    Provider<OrderStatusChangeRepository>((ref) {
      return OrderStatusChangeRepository();
    });

/// Provider for unread order status changes count
/// Includes both status change records and orders in verification states
final unreadOrderStatusChangesCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(orderStatusChangeRepositoryProvider);
  final userAsyncValue = ref.watch(currentUserProvider);

  return userAsyncValue.when(
    data: (user) {
      if (user == null) return Stream.value(0);

      // Combine status change records count with orders in verification state
      return Stream.multi((controller) {
        int? statusChangesCount;
        int? verificationStateCount;

        // Listen to status change records
        final statusChangesSub = repository
            .getUnreadStatusChangesCount(user.id)
            .listen((count) {
              statusChangesCount = count;
              if (verificationStateCount != null) {
                controller.add(count + verificationStateCount!);
              }
            });

        // Listen to user's orders to count those in verification state
        final ordersSub = FirebaseFirestore.instance
            .collection('orders')
            .where('userUID', isEqualTo: user.id)
            .where('isHomeDelivery', isEqualTo: true)
            .snapshots()
            .listen((snapshot) {
              int count = 0;
              for (var doc in snapshot.docs) {
                final data = doc.data();
                final isInitiallyVerified =
                    data['isInitiallyVerified'] ?? false;
                final isPaid = data['isPaid'] ?? false;
                final isCompletelyVerified =
                    data['isCompletelyVerified'] ?? false;

                // Count orders in verification state: isInitiallyVerified: True, isPaid: False, isCompletelyVerified: False
                if (isInitiallyVerified && !isPaid && !isCompletelyVerified) {
                  count++;
                }
              }

              verificationStateCount = count;
              if (statusChangesCount != null) {
                controller.add(statusChangesCount! + count);
              }
            });

        controller.onCancel = () {
          statusChangesSub.cancel();
          ordersSub.cancel();
        };
      });
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

/// Provider for checking if a specific order has unread status changes
/// Uses StreamProvider to automatically refresh when status changes
/// Also checks order verification state directly
final orderHasUnreadChangesProvider = StreamProvider.family<bool, String>((
  ref,
  orderId,
) {
  final userAsyncValue = ref.watch(currentUserProvider);

  return userAsyncValue.when(
    data: (user) {
      if (user == null) return Stream.value(false);

      // Listen to both status change records and order document
      final statusChangesStream = FirebaseFirestore.instance
          .collection('orderStatusChanges')
          .where('orderId', isEqualTo: orderId)
          .where('userId', isEqualTo: user.id)
          .where('isRead', isEqualTo: false)
          .limit(1)
          .snapshots();

      final orderStream = FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .snapshots();

      // Combine both streams using StreamZip or manual combination
      return Stream.multi((controller) {
        bool? lastStatusChange;
        bool? lastVerificationState;

        final statusChangesSub = statusChangesStream.listen((snapshot) {
          lastStatusChange = snapshot.docs.isNotEmpty;
          if (lastVerificationState != null) {
            controller.add(lastStatusChange! || lastVerificationState!);
          }
        });

        final orderSub = orderStream.listen((orderDoc) {
          if (!orderDoc.exists) {
            lastVerificationState = false;
            if (lastStatusChange != null) {
              controller.add(lastStatusChange!);
            }
            return;
          }

          final orderData = orderDoc.data() as Map<String, dynamic>;
          final isInitiallyVerified = orderData['isInitiallyVerified'] ?? false;
          final isPaid = orderData['isPaid'] ?? false;
          final isCompletelyVerified =
              orderData['isCompletelyVerified'] ?? false;
          final isHomeDelivery = orderData['isHomeDelivery'] ?? false;

          // Show indicator when: isInitiallyVerified: True, isPaid: False, isCompletelyVerified: False
          lastVerificationState =
              isHomeDelivery &&
              isInitiallyVerified &&
              !isPaid &&
              !isCompletelyVerified;

          if (lastStatusChange != null) {
            controller.add(lastStatusChange! || lastVerificationState!);
          }
        });

        controller.onCancel = () {
          statusChangesSub.cancel();
          orderSub.cancel();
        };
      });
    },
    loading: () => Stream.value(false),
    error: (_, __) => Stream.value(false),
  );
});
