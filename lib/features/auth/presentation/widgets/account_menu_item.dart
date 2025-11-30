import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountMenuItem extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback onTap;
  final TextStyle? titleStyle;

  const AccountMenuItem({
    super.key,
    required this.title,
    this.icon,
    required this.onTap,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style:
                  titleStyle ??
                  GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Icon(
              icon ?? Icons.keyboard_arrow_right,
              color: const Color(0xFF8ECAE6),
            ),
          ],
        ),
      ),
    );
  }
}
