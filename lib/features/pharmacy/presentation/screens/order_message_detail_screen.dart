import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order_message.dart';
import '../services/order_message_service.dart';

class OrderMessageDetailScreen extends ConsumerStatefulWidget {
  final OrderMessage message;

  const OrderMessageDetailScreen({
    super.key,
    required this.message,
  });

  @override
  ConsumerState<OrderMessageDetailScreen> createState() => _OrderMessageDetailScreenState();
}

class _OrderMessageDetailScreenState extends ConsumerState<OrderMessageDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Mark message as read when opened
    if (!widget.message.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(orderMessageServiceProvider).markMessageAsRead(widget.message.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Order Message',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8ECAE6),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // Message Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        // Pharmacy Image
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF8ECAE6).withOpacity(0.1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: widget.message.pharmacyImageUrl.isNotEmpty
                                ? Image.network(
                                    widget.message.pharmacyImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.local_pharmacy,
                                        color: Color(0xFF8ECAE6),
                                        size: 28,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.local_pharmacy,
                                    color: Color(0xFF8ECAE6),
                                    size: 28,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.message.pharmacyName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _getMessageTypeIcon(widget.message.type),
                                    size: 16,
                                    color: _getMessageTypeColor(widget.message.type),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDateTime(widget.message.createdAt),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      widget.message.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Message Content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.message.message,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF4A5568),
                          height: 1.6,
                        ),
                      ),
                    ),
                    
                    // Order Details (if available)
                    if (widget.message.metadata != null) ...[
                      const SizedBox(height: 20),
                      _buildOrderDetails(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/orders');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8ECAE6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'View Order Details',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    final metadata = widget.message.metadata!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8ECAE6).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Information',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          
          if (metadata['medicineName'] != null)
            _buildDetailRow('Product', metadata['medicineName']),
          
          if (metadata['quantity'] != null)
            _buildDetailRow('Quantity', '${metadata['quantity']}'),
          
          if (metadata['totalPrice'] != null)
            _buildDetailRow('Total', '₱${(metadata['totalPrice'] as double).toStringAsFixed(2)}'),
          
          _buildDetailRow('Order ID', '#${widget.message.orderId}'),
          
          if (metadata['deliveryAddress'] != null)
            _buildDetailRow(
              metadata['isHomeDelivery'] == true ? 'Delivery Address' : 'Pickup Location',
              metadata['deliveryAddress'],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMessageTypeIcon(OrderMessageType type) {
    switch (type) {
      case OrderMessageType.orderConfirmation:
        return Icons.check_circle_outline;
      case OrderMessageType.inTransit:
        return Icons.local_shipping_outlined;
      case OrderMessageType.delivered:
        return Icons.done_all;
      case OrderMessageType.cancelled:
        return Icons.cancel_outlined;
      case OrderMessageType.paymentReceived:
        return Icons.payment;
      case OrderMessageType.verificationComplete:
        return Icons.verified_outlined;
    }
  }

  Color _getMessageTypeColor(OrderMessageType type) {
    switch (type) {
      case OrderMessageType.orderConfirmation:
        return Colors.blue;
      case OrderMessageType.inTransit:
        return Colors.orange;
      case OrderMessageType.delivered:
        return Colors.green;
      case OrderMessageType.cancelled:
        return Colors.red;
      case OrderMessageType.paymentReceived:
        return Colors.purple;
      case OrderMessageType.verificationComplete:
        return const Color(0xFF8ECAE6);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}