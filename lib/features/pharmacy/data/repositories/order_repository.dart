import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/order.dart';
import '../services/lalamove_service.dart';
import 'order_status_change_repository.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;
  final LalamoveService _lalamoveService;

  OrderRepository({
    required FirebaseFirestore firestore,
    required LalamoveService lalamoveService,
  }) : _firestore = firestore,
       _lalamoveService = lalamoveService;

  // Create a new order
  Future<String> createOrder(OrderEntity order) async {
    try {
      final docRef = _firestore.collection('orders').doc();
      final orderWithId = order.copyWith(orderID: docRef.id);

      await docRef.set(orderWithId.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Create order items subcollection
  Future<void> createOrderItems(
    String orderId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final batch = _firestore.batch();
      for (final item in items) {
        final itemRef = _firestore
            .collection('orders')
            .doc(orderId)
            .collection('orderItems')
            .doc();
        batch.set(itemRef, item);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create order items: $e');
    }
  }

  // Get order items for an order
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('orderItems')
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      throw Exception('Failed to get order items: $e');
    }
  }

  // Create delivery with Lalamove for an order
  Future<void> createLalamoveDelivery({
    required String orderId,
    required String pickupAddress,
    required String deliveryAddress,
    required String customerPhone,
    required String customerName,
    String pharmacyName = 'Unknown',
    String pharmacyPhone = '',
    LatLng? pickupCoordinates,
    LatLng? deliveryCoordinates,
  }) async {
    try {
      final response = await _lalamoveService.createDeliveryOrder(
        orderId: orderId,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        customerPhone: customerPhone,
        customerName: customerName,
        pharmacyName: pharmacyName,
        pharmacyPhone: pharmacyPhone,
        pickupCoordinates: pickupCoordinates,
        deliveryCoordinates: deliveryCoordinates,
      );

      // Extract Lalamove order details
      final lalamoveOrderId = response['data']['orderId'];
      final lalamoveTrackingUrl = response['data']['shareLink'];

      // Update order with Lalamove information
      await _firestore.collection('orders').doc(orderId).update({
        'lalamoveOrderId': lalamoveOrderId,
        'lalamoveTrackingUrl': lalamoveTrackingUrl,
        'lalamoveStatus': '',
        'status': OrderStatus.inTransit.displayName,
      });
    } catch (e) {
      throw Exception('Failed to create Lalamove delivery: $e');
    }
  }

  // Update Lalamove delivery status
  Future<void> updateLalamoveDeliveryStatus(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final lalamoveOrderId = orderData['lalamoveOrderId'];

      if (lalamoveOrderId == null) {
        throw Exception('No Lalamove order associated with this order');
      }

      // Get current order to track status change
      final currentOrder = await getOrderById(orderId);
      final oldStatus = currentOrder?.status.displayName ?? '';

      final response = await _lalamoveService.getDeliveryStatus(
        lalamoveOrderId,
      );
      final status = response['data']['status'];

      // Update driver information if available
      String? driverName;
      String? driverPhone;

      if (response['data']['driver'] != null) {
        driverName = response['data']['driver']['name'];
        driverPhone = response['data']['driver']['phone'];
      }

      // Map Lalamove status to app status
      OrderStatus orderStatus;
      switch (status) {
        case 'COMPLETED':
          orderStatus = OrderStatus.completed;
          break;
        case 'CANCELED':
          orderStatus = OrderStatus.cancelled;
          break;
        default:
          orderStatus = OrderStatus.inTransit;
          break;
      }

      // Update order with latest status
      await _firestore.collection('orders').doc(orderId).update({
        'lalamoveStatus': status,
        'lalamoveDriverName': driverName,
        'lalamoveDriverPhone': driverPhone,
        'status': orderStatus.displayName,
      });

      // Create status change record if status actually changed
      if (currentOrder != null && oldStatus != orderStatus.displayName) {
        final statusChangeRepo = OrderStatusChangeRepository(
          firestore: _firestore,
        );
        await statusChangeRepo.createStatusChange(
          orderId: orderId,
          userId: currentOrder.userUID,
          oldStatus: oldStatus,
          newStatus: orderStatus.displayName,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      throw Exception('Failed to update Lalamove delivery status: $e');
    }
  }

  // Get user's orders
  Stream<List<OrderEntity>> getUserOrders(String userUID) {
    return _firestore
        .collection('orders')
        .where('userUID', isEqualTo: userUID)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderEntity.fromFirestore(doc))
              .toList();
        });
  }

  // Get orders by status
  Stream<List<OrderEntity>> getUserOrdersByStatus(
    String userUID,
    OrderStatus status,
  ) {
    return _firestore
        .collection('orders')
        .where('userUID', isEqualTo: userUID)
        .where('status', isEqualTo: status.displayName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderEntity.fromFirestore(doc))
              .toList();
        });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderID, OrderStatus newStatus) async {
    try {
      // Get current order to track status change
      final currentOrder = await getOrderById(orderID);
      final oldStatus = currentOrder?.status.displayName ?? '';

      // Update order status
      await _firestore.collection('orders').doc(orderID).update({
        'status': newStatus.displayName,
      });

      // Create status change record if status actually changed
      if (currentOrder != null && oldStatus != newStatus.displayName) {
        final statusChangeRepo = OrderStatusChangeRepository(
          firestore: _firestore,
        );
        await statusChangeRepo.createStatusChange(
          orderId: orderID,
          userId: currentOrder.userUID,
          oldStatus: oldStatus,
          newStatus: newStatus.displayName,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get order by ID
  Future<OrderEntity?> getOrderById(String orderID) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderID).get();
      if (doc.exists) {
        return OrderEntity.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderID) async {
    try {
      final order = await getOrderById(orderID);
      if (order != null && order.lalamoveOrderId != null) {
        // TODO: Add Lalamove order cancellation when needed
      }
      await updateOrderStatus(orderID, OrderStatus.cancelled);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }
}
