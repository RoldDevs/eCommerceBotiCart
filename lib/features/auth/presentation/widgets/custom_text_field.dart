import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool hasError;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFE6F2FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: hasError 
              ? const BorderSide(color: Colors.red, width: 1.0)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: hasError 
              ? const BorderSide(color: Colors.red, width: 1.0)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: hasError 
              ? const BorderSide(color: Colors.red, width: 1.0)
              : BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        suffixIcon: suffixIcon,
      ),
      style: TextStyle(
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
    );
  }
}