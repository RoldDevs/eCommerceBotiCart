// FOR RENDERING THE OTP INPUT FIELD

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool autoFocus;
  final Function(String) onChanged;

  const OtpInputField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.autoFocus = false,
    required bool nextFocus,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 50,
      child: TextField(
        autofocus: autoFocus,
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
        maxLength: 1,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF5F9FC),
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.length == 1) {
            FocusScope.of(context).nextFocus();
            onChanged(value);
          }
        },
      ),
    );
  }
}
