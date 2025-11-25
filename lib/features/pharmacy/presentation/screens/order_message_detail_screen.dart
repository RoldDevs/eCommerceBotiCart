import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/order_message.dart';
import '../services/order_message_service.dart';

enum _MatchType { orderId, delivery, tracking }

class _MatchInfo {
  final int start;
  final int end;
  final _MatchType type;
  final String prefix;
  final String content;
  final bool isClickable;

  _MatchInfo({
    required this.start,
    required this.end,
    required this.type,
    required this.prefix,
    required this.content,
    this.isClickable = false,
  });
}

class OrderMessageDetailScreen extends ConsumerStatefulWidget {
  final OrderMessage message;

  const OrderMessageDetailScreen({super.key, required this.message});

  @override
  ConsumerState<OrderMessageDetailScreen> createState() =>
      _OrderMessageDetailScreenState();
}

class _OrderMessageDetailScreenState
    extends ConsumerState<OrderMessageDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Mark message as read when opened
    if (!widget.message.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(orderMessageServiceProvider)
            .markMessageAsRead(widget.message.id);
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
      body: Builder(
        builder: (context) {
          final bottomPadding = MediaQuery.of(context).padding.bottom;

          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 32 + bottomPadding),
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
                        color: Colors.black.withValues(alpha: 0.05),
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
                                color: const Color(
                                  0xFF8ECAE6,
                                ).withValues(alpha: 0.1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    widget.message.pharmacyImageUrl.isNotEmpty
                                    ? Image.network(
                                        widget.message.pharmacyImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
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
                                        _getMessageTypeIcon(
                                          widget.message.type,
                                        ),
                                        size: 16,
                                        color: _getMessageTypeColor(
                                          widget.message.type,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDateTime(
                                          widget.message.createdAt,
                                        ),
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
                          child: _buildMessageWithLinks(widget.message.message),
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
              ],
            ),
          );
        },
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
            _buildDetailRow(
              'Total',
              '₱${(metadata['totalPrice'] as double).toStringAsFixed(2)}',
            ),

          _buildDetailRow(
            'Order ID',
            '#${widget.message.orderId}',
            valueColor: const Color(0xFF8ECAE6),
          ),

          if (metadata['deliveryAddress'] != null)
            _buildDetailRow(
              metadata['isHomeDelivery'] == true
                  ? 'Delivery Address'
                  : 'Pickup Location',
              metadata['deliveryAddress'],
              valueColor: const Color(0xFF8ECAE6),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
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
                color: valueColor ?? const Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWithLinks(String message) {
    final baseStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: const Color(0xFF4A5568),
      height: 1.6,
    );

    final blueStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: const Color(0xFF8ECAE6),
      height: 1.6,
    );

    final linkStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: const Color(0xFF8ECAE6),
      decoration: TextDecoration.underline,
      height: 1.6,
    );

    final List<TextSpan> spans = [];
    int lastIndex = 0;

    // Pattern for Order ID: "Order ID: #..." or "Order ID: #..."
    final orderIdPattern = RegExp(
      r'(Order ID:\s*)(#[A-Za-z0-9]+)',
      caseSensitive: false,
    );

    // Pattern for delivery address: "delivered to: ...", "will be delivered to: ...", or "is on its way to: ..."
    final deliveryPattern = RegExp(
      r'((?:will be )?delivered to:\s*|is on its way to:\s*)([^\n]+?)(?:\n|$)',
      caseSensitive: false,
    );

    // Pattern for tracking URL: "Track your delivery: URL"
    final trackingUrlPattern = RegExp(
      r'(Track your delivery:\s*)(https?://[^\s]+)',
      caseSensitive: false,
    );

    // Find all matches and their positions
    final List<_MatchInfo> matches = [];

    // Find Order ID matches
    for (final match in orderIdPattern.allMatches(message)) {
      matches.add(
        _MatchInfo(
          start: match.start,
          end: match.end,
          type: _MatchType.orderId,
          prefix: match.group(1)!,
          content: match.group(2)!,
        ),
      );
    }

    // Find delivery address matches
    for (final match in deliveryPattern.allMatches(message)) {
      matches.add(
        _MatchInfo(
          start: match.start,
          end: match.end,
          type: _MatchType.delivery,
          prefix: match.group(1)!,
          content: match.group(2)!.trim(),
        ),
      );
    }

    // Find tracking URL matches
    for (final match in trackingUrlPattern.allMatches(message)) {
      matches.add(
        _MatchInfo(
          start: match.start,
          end: match.end,
          type: _MatchType.tracking,
          prefix: match.group(1)!,
          content: match.group(2)!,
          isClickable: true,
        ),
      );
    }

    // Sort matches by position
    matches.sort((a, b) => a.start.compareTo(b.start));

    // Remove overlapping matches (keep the first one)
    final List<_MatchInfo> nonOverlappingMatches = [];
    for (int i = 0; i < matches.length; i++) {
      if (i == 0 || matches[i].start >= nonOverlappingMatches.last.end) {
        nonOverlappingMatches.add(matches[i]);
      }
    }

    // Build text spans
    for (final match in nonOverlappingMatches) {
      // Add text before match
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: message.substring(lastIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      // Add prefix in base style
      spans.add(TextSpan(text: match.prefix, style: baseStyle));

      // Add content in blue style (or clickable for tracking)
      if (match.isClickable) {
        spans.add(
          TextSpan(
            text: match.content,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchTrackingUrl(match.content),
          ),
        );
      } else {
        spans.add(TextSpan(text: match.content, style: blueStyle));
      }

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < message.length) {
      spans.add(TextSpan(text: message.substring(lastIndex), style: baseStyle));
    }

    // If no matches found, return simple text
    if (spans.isEmpty) {
      return Text(message, style: baseStyle);
    }

    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _launchTrackingUrl(String url) async {
    if (!mounted) return;

    try {
      // Clean and validate URL
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final Uri uri = Uri.parse(cleanUrl);

      // Launch URL directly - use externalApplication to open in browser
      // Don't use canLaunchUrl check as it can hang
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        // If external application fails, try platform default
        final launched2 = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );

        if (!launched2 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not open tracking URL. Please try again.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error opening URL. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
