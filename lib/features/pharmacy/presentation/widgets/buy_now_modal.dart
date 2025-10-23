import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/medicine.dart';

class BuyNowModal extends StatefulWidget {
  final Medicine medicine;
  final Function(int) onQuantityChanged;
  final VoidCallback onBuyNow;
  final String buttonText; 

  const BuyNowModal({
    super.key,
    required this.medicine,
    required this.onQuantityChanged,
    required this.onBuyNow,
    this.buttonText = 'BUY NOW',
  });

  @override
  State<BuyNowModal> createState() => _BuyNowModalState();
}

class _BuyNowModalState extends State<BuyNowModal> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.medicine.imageURL,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.medicine.medicineName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Major Type
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8ECAE6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.medicine.majorTypeDisplayName,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2A4B8D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Product Type
                      Text(
                        widget.medicine.productTypeDisplayName,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${widget.medicine.price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8ECAE6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Quantity selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantity',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    // Minus button
                    InkWell(
                      onTap: () {
                        if (quantity > 1) {
                          setState(() {
                            quantity--;
                          });
                          widget.onQuantityChanged(quantity);
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    // Quantity display
                    Container(
                      width: 40,
                      height: 28,
                      alignment: Alignment.center,
                      child: Text(
                        quantity.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Plus button
                    InkWell(
                      onTap: () {
                        if (quantity < widget.medicine.stock) {
                          setState(() {
                            quantity++;
                          });
                          widget.onQuantityChanged(quantity);
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.add, 
                          size: 16,
                          color: quantity >= widget.medicine.stock ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Action button with dynamic text
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onBuyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8ECAE6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.buttonText,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}