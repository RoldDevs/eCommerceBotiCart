import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final bool showClearButton;

  const LocationSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.showClearButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF8ECAE6)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search location',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: onChanged,
            ),
          ),
          if (showClearButton && controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}