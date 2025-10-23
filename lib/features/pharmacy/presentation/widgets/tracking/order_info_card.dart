import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderInfoCard extends StatelessWidget {
  final String medicineName;
  final String medicineDetails;
  final String imageUrl;
  final double totalPrice;
  final int quantity;

  const OrderInfoCard({
    super.key,
    required this.medicineName,
    required this.medicineDetails,
    required this.imageUrl,
    required this.totalPrice,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF8ECAE6).withOpacity(0.1),
                          child: const Icon(
                            Icons.medication,
                            color: Color(0xFF8ECAE6),
                            size: 24,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF8ECAE6).withOpacity(0.1),
                      child: const Icon(
                        Icons.medication,
                        color: Color(0xFF8ECAE6),
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Medicine details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  medicineDetails,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total $quantity item:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₱ ${totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8ECAE6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}