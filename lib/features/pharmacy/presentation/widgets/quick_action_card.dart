import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? svgPath;
  final VoidCallback onTap;
  final Color iconColor;

  const QuickActionCard({
    super.key,
    required this.title,
    this.icon,
    this.svgPath,
    required this.onTap,
    this.iconColor = const Color(0xFF8ECAE6),
  }) : assert(
         icon != null || svgPath != null,
         'Either icon or svgPath must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            if (icon != null)
              Icon(icon, color: iconColor, size: 24)
            else if (svgPath != null)
              SvgPicture.asset(
                svgPath!,
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
