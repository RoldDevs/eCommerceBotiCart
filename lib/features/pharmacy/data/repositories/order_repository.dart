import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/order.dart';
import '../services/lalamove_service.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;
  final LalamoveService _lalamoveService;

  OrderRepository({
    required FirebaseFirestore firestore,
    required LalamoveService lalamoveService,
  }) : _firestore = firestore,
       _lalamoveService = lalamoveService;

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

      final lalamoveOrderId = response['data']['orderId'];
      final lalamoveTrackingUrl = response['data']['shareLink'];
      
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
      
      final response = await _lalamoveService.getDeliveryStatus(lalamoveOrderId);
      final status = response['data']['status'];
      
      String? driverName;
      String? driverPhone;
      
      if (response['data']['driver'] != null) {
        driverName = response['data']['driver']['name'];
        driverPhone = response['data']['driver']['phone'];
      }
      
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
      
      await _firestore.collection('orders').doc(orderId).update({
        'lalamoveStatus': status,
        'lalamoveDriverName': driverName,
        'lalamoveDriverPhone': driverPhone,
        'status': orderStatus.displayName,
      });
    } catch (e) {
      throw Exception('Failed to update Lalamove delivery status: $e');
    }
  }

  Stream<List<OrderEntity>> getUserOrders(String userUID) {
    return _firestore
        .collection('orders')
        .where('userUID', isEqualTo: userUID)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderEntity.fromFirestore(doc)).toList();
    });
  }

  Stream<List<OrderEntity>> getUserOrdersByStatus(String userUID, OrderStatus status) {
    return _firestore
        .collection('orders')
        .where('userUID', isEqualTo: userUID)
        .where('status', isEqualTo: status.displayName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderEntity.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateOrderStatus(String orderID, OrderStatus newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderID).update({
        'status': newStatus.displayName,
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

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