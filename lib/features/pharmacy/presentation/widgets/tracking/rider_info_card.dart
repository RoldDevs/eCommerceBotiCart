import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RiderInfoCard extends StatelessWidget {
  final String riderName;
  final String riderPhone;
  final VoidCallback onCallPressed;

  const RiderInfoCard({
    super.key,
    required this.riderName,
    required this.riderPhone,
    required this.onCallPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rider Name',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            riderName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Rider Contact Number',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                riderPhone,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              IconButton(
                onPressed: onCallPressed,
                icon: const Icon(
                  Icons.phone,
                  color: Color(0xFF8ECAE6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}