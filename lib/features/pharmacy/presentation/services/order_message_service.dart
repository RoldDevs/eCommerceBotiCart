import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/order_message_repository.dart';
import '../../domain/entities/order_message.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/pharmacy.dart';

final orderMessageRepositoryProvider = Provider<OrderMessageRepository>((ref) {
  return OrderMessageRepository(firestore: FirebaseFirestore.instance);
});

final orderMessageServiceProvider = Provider<OrderMessageService>((ref) {
  final repository = ref.watch(orderMessageRepositoryProvider);
  return OrderMessageService(repository, ref);
});

class OrderMessageService {
  final OrderMessageRepository _repository;
  // ignore: unused_field
  final Ref _ref;

  OrderMessageService(this._repository, this._ref);

  // Create order confirmation message
  Future<void> createOrderConfirmationMessage({
    required OrderEntity order,
    required Medicine medicine,
    required Pharmacy pharmacy,
  }) async {
    final title = 'Order Confirmed - ${pharmacy.name}';
    final message = '''
Hello! Your order has been confirmed.

Product: ${medicine.medicineName}
Quantity: ${order.quantity}
Order ID: #${order.orderID}
Total Payment: ₱${order.totalPrice.toStringAsFixed(2)}

${order.isHomeDelivery ? 'Your order will be delivered to: ${order.deliveryAddress}' : 'Your order is ready for pickup at: ${pharmacy.location}'}

We are now processing your order and will notify you once it's ready.

Thank you for choosing ${pharmacy.name}!
''';

    final orderMessage = OrderMessage(
      id: '',
      orderId: order.orderID,
      userId: order.userUID,
      pharmacyId: pharmacy.id,
      pharmacyName: pharmacy.name,
      pharmacyImageUrl: pharmacy.imageUrl,
      title: title,
      message: message,
      type: OrderMessageType.orderConfirmation,
      createdAt: DateTime.now(),
      metadata: {
        'medicineName': medicine.medicineName,
        'quantity': order.quantity,
        'totalPrice': order.totalPrice,
        'isHomeDelivery': order.isHomeDelivery,
        'deliveryAddress': order.deliveryAddress,
      },
    );

    await _repository.createOrderMessage(orderMessage);
  }

  // Create in-transit message
  Future<void> createInTransitMessage({
    required OrderEntity order,
    required Medicine medicine,
    required Pharmacy pharmacy,
  }) async {
    final title = 'Order In Transit - ${pharmacy.name}';
    final message = '''
Great news! Your order is now in transit.

Product: ${medicine.medicineName}
Order ID: #${order.orderID}

${order.isHomeDelivery ? '''
Your order is on its way to: ${order.deliveryAddress}

Delivery Information:
- Your order has been verified and is now being prepared for delivery
- Our delivery partner will contact you shortly
- Estimated delivery time: 30-60 minutes
- Please ensure someone is available to receive the order

${order.lalamoveTrackingUrl != null ? 'Track your delivery: ${order.lalamoveTrackingUrl}' : ''}
''' : '''
Your order is ready for pickup at: ${pharmacy.location}

Pickup Information:
- Your order has been verified and is ready for collection
- Store hours: Please contact ${pharmacy.contact} for store hours
- Please bring a valid ID when picking up your order
'''}

Thank you for your patience!
''';

    final orderMessage = OrderMessage(
      id: '',
      orderId: order.orderID,
      userId: order.userUID,
      pharmacyId: pharmacy.id,
      pharmacyName: pharmacy.name,
      pharmacyImageUrl: pharmacy.imageUrl,
      title: title,
      message: message,
      type: OrderMessageType.inTransit,
      createdAt: DateTime.now(),
      metadata: {
        'medicineName': medicine.medicineName,
        'isHomeDelivery': order.isHomeDelivery,
        'deliveryAddress': order.deliveryAddress,
        'trackingUrl': order.lalamoveTrackingUrl,
      },
    );

    await _repository.createOrderMessage(orderMessage);
  }

  // Create payment received message
  Future<void> createPaymentReceivedMessage({
    required OrderEntity order,
    required Medicine medicine,
    required Pharmacy pharmacy,
  }) async {
    final title = 'Payment Received - ${pharmacy.name}';
    final message = '''
Payment Confirmed!

We have successfully received your payment for:

Product: ${medicine.medicineName}
Order ID: #${order.orderID}
Amount Paid: ₱${order.totalPrice.toStringAsFixed(2)}

Your order is now being processed for final verification. We will notify you once it's ready for ${order.isHomeDelivery ? 'delivery' : 'pickup'}.

Thank you for your payment!
''';

    final orderMessage = OrderMessage(
      id: '',
      orderId: order.orderID,
      userId: order.userUID,
      pharmacyId: pharmacy.id,
      pharmacyName: pharmacy.name,
      pharmacyImageUrl: pharmacy.imageUrl,
      title: title,
      message: message,
      type: OrderMessageType.paymentReceived,
      createdAt: DateTime.now(),
      metadata: {
        'medicineName': medicine.medicineName,
        'totalPrice': order.totalPrice,
      },
    );

    await _repository.createOrderMessage(orderMessage);
  }

  // Get user order messages
  Stream<List<OrderMessage>> getUserOrderMessages(String userId) {
    return _repository.getUserOrderMessages(userId);
  }

  // Get order messages for specific order
  Stream<List<OrderMessage>> getOrderMessages(String orderId) {
    return _repository.getOrderMessages(orderId);
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) {
    return _repository.markMessageAsRead(messageId);
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount(String userId) {
    return _repository.getUnreadMessageCount(userId);
  }

  // Delete order message
  Future<void> deleteOrderMessage(String messageId) {
    return _repository.deleteOrderMessage(messageId);
  }
}