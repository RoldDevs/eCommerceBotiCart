import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationResultItem extends StatelessWidget {
  final String mainAddress;
  final String subAddress;
  final VoidCallback onTap;

  const LocationResultItem({
    super.key,
    required this.mainAddress,
    required this.subAddress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined, color: Color(0xFF8ECAE6)),
      title: Text(
        mainAddress,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subAddress,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
      ),
      onTap: onTap,
    );
  }
}
