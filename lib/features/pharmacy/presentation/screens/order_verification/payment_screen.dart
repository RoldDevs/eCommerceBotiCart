import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/pharmacy.dart';
import '../../services/order_verification_service.dart';
import '../../widgets/responsive_image_widget.dart';
import '../../widgets/custom_button.dart';
import 'pending_verification_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String orderId;

  const PaymentScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  File? _receiptImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
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
          'PAYMENT',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8ECAE6),
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<OrderEntity?>(
        future: orderVerificationService.getOrderById(widget.orderId),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderSnapshot.hasError || orderSnapshot.data == null) {
            return _buildErrorWidget();
          }

          final order = orderSnapshot.data!;

          return FutureBuilder<Pharmacy?>(
            future: orderVerificationService.getPharmacyByStoreId(order.storeID),
            builder: (context, pharmacySnapshot) {
              if (pharmacySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (pharmacySnapshot.hasError || pharmacySnapshot.data == null) {
                return _buildErrorWidget();
              }

              final pharmacy = pharmacySnapshot.data!;

              return _buildPaymentContent(context, order, pharmacy);
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentContent(BuildContext context, OrderEntity order, Pharmacy pharmacy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Card
          _buildOrderSummaryCard(order),
          const SizedBox(height: 20),

          // Payment Instructions Card
          _buildPaymentInstructionsCard(pharmacy, order),
          const SizedBox(height: 20),

          // GCash QR Code Card
          _buildGCashQRCard(pharmacy, order),
          const SizedBox(height: 20),

          // Receipt Upload Card
          _buildReceiptUploadCard(),
          const SizedBox(height: 32),

          // Submit Button
          _buildSubmitButton(order, pharmacy),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(OrderEntity order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ID:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF718096),
                ),
              ),
              Text(
                '#${order.orderID}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8ECAE6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              Text(
                '₱${order.totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8ECAE6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructionsCard(Pharmacy pharmacy, OrderEntity order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF8ECAE6),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Instructions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Please follow these steps to complete your payment:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'Scan the GCash QR code below'),
          _buildInstructionStep('2', 'Pay the exact amount: ₱${order.totalPrice.toStringAsFixed(2)}'),
          _buildInstructionStep('3', 'Take a screenshot of your payment confirmation'),
          _buildInstructionStep('4', 'Upload the screenshot using the button below'),
          _buildInstructionStep('5', 'Submit and wait for verification'),
        ],
      ),
    );
  }

  Widget _buildGCashQRCard(Pharmacy pharmacy, OrderEntity order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${pharmacy.name} - GCash Payment',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // QR Code Container
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: pharmacy.gcashQrCodeUrl != null && pharmacy.gcashQrCodeUrl!.isNotEmpty
                ? ResponsiveImageWidget(
                    imageUrl: pharmacy.gcashQrCodeUrl!,
                    width: 250,
                    height: 250,
                    borderRadius: 12,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'QR Code not available',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please contact the pharmacy',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            'Amount to Pay: ₱${order.totalPrice.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8ECAE6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Payment Receipt',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          
          if (_receiptImage != null) ...[
            // Show selected image
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _receiptImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.edit),
                    label: Text(
                      'Change Image',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _receiptImage = null;
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: Text(
                      'Remove',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Upload button
            InkWell(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF8ECAE6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF8ECAE6),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 40,
                      color: const Color(0xFF8ECAE6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload receipt',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8ECAE6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG files only',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton(OrderEntity order, Pharmacy pharmacy) {
    return CustomButton(
      text: _isUploading ? 'Uploading.' : 'Submit Payment Receipt',
      onPressed: _receiptImage != null && !_isUploading
          ? () => _submitPaymentReceipt(order, pharmacy)
          : null,
      isLoading: _isUploading,
      backgroundColor: const Color(0xFF8ECAE6),
      textColor: Colors.white,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading payment information',
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _submitPaymentReceipt(OrderEntity order, Pharmacy pharmacy) async {
    if (_receiptImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final orderVerificationService = ref.read(orderVerificationServiceProvider);

      // Upload receipt to Firebase Storage
      final receiptUrl = await orderVerificationService.uploadPaymentReceipt(
        receiptFile: _receiptImage!,
        pharmacyName: pharmacy.name,
        userUID: order.userUID,
        orderId: order.orderID,
      );

      // Update order payment status
      await orderVerificationService.updateOrderPaymentStatus(
        orderId: order.orderID,
        receiptUrl: receiptUrl,
      );

      // Show success message
      _showSuccessSnackBar('Payment receipt submitted successfully!');

      // Navigate back to pending screen with a delay to avoid Hero conflicts
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                PendingVerificationScreen(orderId: widget.orderId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to submit receipt: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInstructionStep(String stepNumber, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF8ECAE6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF4A5568),
              ),
            ),
          ),
        ],
      ),
    );
  }
}