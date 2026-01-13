// Responsive Utilities for MIL Hub
// Provides helper methods for responsive UI design

import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Screen size breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  // Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return screenWidth(context) <= mobileMaxWidth;
  }

  // Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width > mobileMaxWidth && width <= tabletMaxWidth;
  }

  // Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) > tabletMaxWidth;
  }

  // Get responsive padding based on screen size
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  // Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    if (isMobile(context)) {
      return 1.0;
    } else if (isTablet(context)) {
      return 1.2;
    } else {
      return 1.4;
    }
  }

  // Get responsive card width
  static double getCardWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context) - 32; // Full width minus padding
    } else if (isTablet(context)) {
      return screenWidth(context) * 0.8; // 80% of screen width
    } else {
      return screenWidth(context) * 0.6; // 60% of screen width
    }
  }

  // Get responsive grid count for GridView
  static int getGridCount(BuildContext context) {
    if (isMobile(context)) {
      return 1; // Single column on mobile
    } else if (isTablet(context)) {
      return 2; // Two columns on tablet
    } else {
      return 3; // Three columns on desktop
    }
  }

  // Get responsive cross axis count for GridView
  static int getCrossAxisCount(
    BuildContext context, {
    double maxItemWidth = 200,
  }) {
    final width = screenWidth(context);
    final crossAxisCount = (width / maxItemWidth).floor();
    return crossAxisCount > 0 ? crossAxisCount : 1;
  }

  // Get responsive spacing
  static double getSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  // Get responsive icon size
  static double getIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 24.0;
    } else if (isTablet(context)) {
      return 32.0;
    } else {
      return 40.0;
    }
  }

  // Get responsive button padding
  static EdgeInsets getButtonPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  // Get responsive border radius
  static double getBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }
}
