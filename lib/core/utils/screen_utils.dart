import 'package:flutter/material.dart';

class ScreenUtils {
  // Height of the bottom navigation bar
  static const double bottomNavBarHeight = 70.0;
  
  // Additional padding to ensure content doesn't get hidden behind the nav bar
  static const double additionalBottomPadding = 16.0;
  
  /// Returns the total bottom padding needed for screens with bottom navigation
  /// Includes the nav bar height + system nav bar height + additional padding
  static double getBottomPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return bottomNavBarHeight + mediaQuery.padding.bottom + additionalBottomPadding;
  }
  
  /// Returns EdgeInsets with proper bottom padding for screens with bottom navigation
  static EdgeInsets getBottomPaddingInsets(BuildContext context) {
    return EdgeInsets.only(bottom: getBottomPadding(context));
  }
  
  /// Returns EdgeInsets with horizontal and bottom padding for screens with bottom navigation
  static EdgeInsets getHorizontalAndBottomPadding(BuildContext context, {double horizontal = 16.0}) {
    return EdgeInsets.only(
      left: horizontal,
      right: horizontal,
      bottom: getBottomPadding(context),
    );
  }
  
  /// Returns EdgeInsets with all sides padding for screens with bottom navigation
  static EdgeInsets getAllPaddingWithBottom(BuildContext context, {
    double horizontal = 16.0,
    double top = 16.0,
  }) {
    return EdgeInsets.only(
      left: horizontal,
      right: horizontal,
      top: top,
      bottom: getBottomPadding(context),
    );
  }
}

