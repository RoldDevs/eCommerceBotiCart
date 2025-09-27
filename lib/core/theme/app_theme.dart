import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // App colors
  static const Color primaryColor = Color(0xFF3BBFB2);
  static const Color secondaryColor = Color(0xFF2A4B8D);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF333333);

  // Text theme using Poppins font
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      color: textColor,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      color: textColor,
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 12,
      color: textColor,
    ),
  );

  // Light theme
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    textTheme: textTheme,
    fontFamily: GoogleFonts.poppins().fontFamily,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
  );
}