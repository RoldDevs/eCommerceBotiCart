import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order_message.dart';
import '../services/order_message_service.dart';

class OrderMessageItem extends ConsumerWidget {
  final OrderMessage message;
  final VoidCallback? onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  const OrderMessageItem({
    super.key,
    required this.message,
    this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: message.isRead ? Colors.white : const Color(0xFF8ECAE6).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.isRead ? Colors.grey.shade200 : const Color(0xFF8ECAE6).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          if (isSelectionMode) {
            onSelectionToggle?.call();
          } else {
            if (!message.isRead) {
              await ref.read(orderMessageServiceProvider).markMessageAsRead(message.id);
            }
            onTap?.call();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection checkbox (only show in selection mode)
              if (isSelectionMode) ...[
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12, top: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF8ECAE6) : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFF8ECAE6) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
              // Pharmacy Image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF8ECAE6).withValues(alpha: 0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: message.pharmacyImageUrl.isNotEmpty
                      ? Image.network(
                          message.pharmacyImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.local_pharmacy,
                              color: Color(0xFF8ECAE6),
                              size: 24,
                            );
                          },
                        )
                      : const Icon(
                          Icons.local_pharmacy,
                          color: Color(0xFF8ECAE6),
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: message.isRead ? FontWeight.w500 : FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!message.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8ECAE6),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Pharmacy Name
                    Text(
                      message.pharmacyName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8ECAE6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Message Preview
                    Text(
                      message.message,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF718096),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Time and Type
                    Row(
                      children: [
                        Icon(
                          _getMessageTypeIcon(message.type),
                          size: 14,
                          color: _getMessageTypeColor(message.type),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(message.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
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
        ),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}