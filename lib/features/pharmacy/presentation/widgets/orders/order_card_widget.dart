import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boticart/features/auth/presentation/providers/user_provider.dart';
import 'package:boticart/features/pharmacy/domain/entities/order.dart';
import 'package:boticart/features/pharmacy/presentation/providers/order_status_change_provider.dart';

/// Reusable order card widget with unread status change indicator
class OrderCardWidget extends ConsumerWidget {
  final OrderEntity order;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;

  const OrderCardWidget({
    super.key,
    required this.order,
    this.onTap,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final hasUnreadChangesAsync = user != null
        ? ref.watch(orderHasUnreadChangesProvider(order.orderID))
        : const AsyncValue.data(false);

    final hasUnreadChanges = hasUnreadChangesAsync.when(
      data: (value) => value,
      loading: () => false,
      error: (_, __) => false,
    );

    // Determine display status
    final displayStatus = _getDisplayStatus(order);
    final statusColor = _getStatusColor(displayStatus);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: hasUnreadChanges
              ? const Color(0xFF8ECAE6).withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: hasUnreadChanges
              ? Border.all(
                  color: const Color(0xFF8ECAE6).withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '#${order.orderID}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: hasUnreadChanges
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: const Color(0xFF8ECAE6),
                          ),
                        ),
                        if (hasUnreadChanges) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      displayStatus,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ordered on: ${_formatDate(order.createdAt)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: hasUnreadChanges ? Colors.black87 : Colors.grey[600],
                  fontWeight: hasUnreadChanges
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              // Order items
              _buildOrderItems(context),
              const SizedBox(height: 12),
              // Footer with address and view details button
              _buildFooter(context, hasUnreadChanges),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .doc(order.orderID)
          .collection('orderItems')
          .get(),
      builder: (context, itemsSnapshot) {
        if (itemsSnapshot.hasData && itemsSnapshot.data!.docs.isNotEmpty) {
          final orderItems = itemsSnapshot.data!.docs;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products (${orderItems.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total: ₱${order.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8ECAE6),
                        ),
                      ),
                      if (order.discountAmount != null &&
                          order.discountAmount! > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Discount: -₱${order.discountAmount!.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...orderItems.map((itemDoc) {
                final item = itemDoc.data() as Map<String, dynamic>;
                return _buildOrderItem(item);
              }),
              if (order.isHomeDelivery) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 16,
                      color: Color(0xFF8ECAE6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Home Delivery',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        }

        // Fallback to single item display
        return _buildSingleItemDisplay(context);
      },
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final medicineName = item['medicineName'] as String? ?? 'Medicine';
    final quantity = item['quantity'] as int? ?? 1;
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final itemTotal = price * quantity;
    final imageURL = item['imageURL'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          _buildMedicineImage(imageURL),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Qty: $quantity',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₱${itemTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleItemDisplay(BuildContext context) {
    return Row(
      children: [
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('medicines')
              .doc(order.medicineID)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildMedicineImage(null);
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists) {
              return _buildMedicineImage(null);
            }

            final medicineData = snapshot.data!.data() as Map<String, dynamic>;
            final imageURL = medicineData['imageURL'] as String?;

            return _buildMedicineImage(imageURL);
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medicine Order',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Qty: ${order.quantity}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (order.isHomeDelivery) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 14,
                      color: Color(0xFF8ECAE6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Home Delivery',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Total: ₱${order.totalPrice.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8ECAE6),
              ),
            ),
            if (order.discountAmount != null && order.discountAmount! > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Discount: -₱${order.discountAmount!.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.green),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMedicineImage(String? imageURL) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageURL != null && imageURL.isNotEmpty
            ? Image.network(
                imageURL,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF8ECAE6).withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.medication,
                      color: Color(0xFF8ECAE6),
                      size: 24,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFF8ECAE6).withValues(alpha: 0.1),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF8ECAE6),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: const Color(0xFF8ECAE6).withValues(alpha: 0.1),
                child: const Icon(
                  Icons.medication,
                  color: Color(0xFF8ECAE6),
                  size: 24,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool hasUnreadChanges) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (order.deliveryAddress != null &&
            order.deliveryAddress!.isNotEmpty) ...[
          Expanded(
            child: Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: hasUnreadChanges
                          ? Colors.black87
                          : Colors.grey[600],
                      fontWeight: hasUnreadChanges
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        TextButton(
          onPressed: onViewDetails,
          child: Text(
            'View Details',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF8ECAE6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getDisplayStatus(OrderEntity order) {
    if (order.isHomeDelivery && !order.isCompletelyVerified) {
      return 'To Process';
    }
    return order.status.displayName;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'To Process':
        return Colors.orange;
      case 'To Receive':
        return Colors.blue;
      case 'To Ship':
        return Colors.purple;
      case 'To Pickup':
        return Colors.amber;
      case 'In Transit':
        return Colors.indigo;
      case 'Completed':
        return Colors.green;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
