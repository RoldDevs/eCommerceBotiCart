import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StockBadge extends StatelessWidget {
  final int stock;
  final double fontSize;
  final EdgeInsets padding;
  final bool isOverlay;

  const StockBadge({
    super.key,
    required this.stock,
    this.fontSize = 9,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    this.isOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String text;

    if (stock <= 0) {
      backgroundColor = Colors.red.shade600;
      text = 'Out of Stock';
    } else if (stock <= 5) {
      backgroundColor = Colors.orange.shade600;
      text = '$stock left';
    } else {
      backgroundColor = Colors.green.shade600;
      text = '$stock in stock';
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isOverlay ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}