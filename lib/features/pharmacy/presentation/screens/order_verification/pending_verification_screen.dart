import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/order.dart';
import '../../services/order_verification_service.dart';
import 'payment_screen.dart';

class PendingVerificationScreen extends ConsumerWidget {
  final String orderId;

  const PendingVerificationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderVerificationService = ref.read(orderVerificationServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8ECAE6)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ORDER VERIFICATION',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8ECAE6),
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<OrderEntity>(
        stream: orderVerificationService.listenToOrderVerification(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading order',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final order = snapshot.data!;

          // Navigate to payment screen if initially verified
          if (order.isInitiallyVerified && !order.isPaid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(orderId: orderId),
                ),
              );
            });
          }

          // Navigate to orders screen if completely verified
          if (order.isCompletelyVerified) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/orders', (route) => false);
            });
          }

          return _buildPendingContent(context, order);
        },
      ),
    );
  }

  Widget _buildPendingContent(BuildContext context, OrderEntity order) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF8ECAE6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty,
              size: 60,
              color: Color(0xFF8ECAE6),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            _getStatusTitle(order),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            _getStatusDescription(order),
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF718096),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Order Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Order ID', '#${order.orderID}'),
                _buildDetailRow(
                  'Total Amount',
                  '₱${order.totalPrice.toStringAsFixed(2)}',
                ),
                _buildDetailRow('Order Date', _formatDate(order.createdAt)),
                if (order.deliveryAddress != null)
                  _buildDetailRow('Delivery Address', order.deliveryAddress!),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Status Indicators
          _buildStatusIndicators(order),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF718096),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicators(OrderEntity order) {
    return Column(
      children: [
        _buildStatusStep(
          'Order Placed',
          true,
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatusConnector(true),
        _buildStatusStep(
          'Initial Verification',
          order.isInitiallyVerified,
          order.isInitiallyVerified
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          order.isInitiallyVerified ? Colors.green : Colors.grey,
        ),
        _buildStatusConnector(order.isInitiallyVerified),
        _buildStatusStep(
          'Payment Submitted',
          order.isPaid,
          order.isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
          order.isPaid ? Colors.green : Colors.grey,
        ),
        _buildStatusConnector(order.isPaid),
        _buildStatusStep(
          'Final Verification',
          order.isCompletelyVerified,
          order.isCompletelyVerified
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          order.isCompletelyVerified ? Colors.green : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStatusStep(
    String title,
    bool isCompleted,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
            color: isCompleted
                ? const Color(0xFF2D3748)
                : const Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusConnector(bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      width: 2,
      height: 20,
      color: isActive ? Colors.green : Colors.grey[300],
    );
  }

  String _getStatusTitle(OrderEntity order) {
    if (order.isPaid && !order.isCompletelyVerified) {
      return 'Awaiting Final Verification';
    } else if (!order.isInitiallyVerified) {
      return 'Order Under Review';
    }
    return 'Processing Your Order';
  }

  String _getStatusDescription(OrderEntity order) {
    if (order.isPaid && !order.isCompletelyVerified) {
      return 'Your payment has been received. Our team is reviewing your order and will complete the verification process shortly.';
    } else if (!order.isInitiallyVerified) {
      return 'Your order has been placed successfully. Our team is reviewing your order details and will verify it soon.';
    }
    return 'Your order is being processed. Please wait for further updates.';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
