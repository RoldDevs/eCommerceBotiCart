import 'package:flutter/material.dart';

/// Utility class for responsive design across all Android screen sizes
class ResponsiveUtils {
  /// Get responsive padding based on screen width
  static double getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 8.0; // Small phones
    if (width < 480) return 12.0; // Medium phones
    if (width < 720) return 16.0; // Large phones
    return 20.0; // Tablets
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 8.0;
    if (width < 480) return 12.0;
    if (width < 720) return 16.0;
    return 20.0;
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    final scaleFactor = width < 360 ? 0.85 : (width < 480 ? 0.9 : (width < 720 ? 1.0 : 1.1));
    return baseSize * scaleFactor;
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 18.0;
    if (width < 480) return 20.0;
    if (width < 720) return 24.0;
    return 28.0;
  }

  /// Get responsive height
  static double getResponsiveHeight(BuildContext context, double baseHeight) {
    final height = MediaQuery.of(context).size.height;
    final scaleFactor = height < 600 ? 0.8 : (height < 800 ? 0.9 : 1.0);
    return baseHeight * scaleFactor;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 720;
  }

  /// Check if device is small phone
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Get responsive grid cross axis count
  static int getGridCrossAxisCount(BuildContext context, {int defaultCount = 2}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 1;
    if (width < 480) return 2;
    if (width < 720) return 2;
    return 3;
  }
}

