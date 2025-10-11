import 'package:flutter/material.dart';

/// Application color palette and theme colors
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF7B68EE); // Medium Slate Blue
  static const Color primaryDark = Color(0xFF6A5ACD); // Slate Blue
  static const Color primaryLight = Color(0xFF9370DB); // Medium Purple

  // Secondary Colors
  static const Color secondary = Color(0xFF4A86E8); // Cornflower Blue
  static const Color secondaryDark = Color(0xFF2E5FCC); // Dark Blue
  static const Color secondaryLight = Color(0xFF6BA3F5); // Light Blue

  // Accent Colors
  static const Color accent = Color(0xFFE91E63); // Pink
  static const Color accentDark = Color(0xFFC2185B); // Dark Pink
  static const Color accentLight = Color(0xFFF8BBD9); // Light Pink

  // Background Colors
  static const Color background = Color(0xFF000000); // Pure Black
  static const Color backgroundDark = Color(0xFF0D0D0D); // Very Dark Gray
  static const Color backgroundLight = Color(0xFF1A1A1A); // Dark Gray
  static const Color surface = Color(0xFF1E1E1E); // Dark Surface
  static const Color surfaceVariant = Color(0xFF2D2D2D); // Surface Variant

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFB3B3B3); // Light Gray
  static const Color textTertiary = Color(0xFF666666); // Medium Gray
  static const Color textDisabled = Color(0xFF404040); // Dark Gray

  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color successDark = Color(0xFF388E3C); // Dark Green
  static const Color successLight = Color(0xFF81C784); // Light Green

  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color warningDark = Color(0xFFF57C00); // Dark Orange
  static const Color warningLight = Color(0xFFFFB74D); // Light Orange

  static const Color error = Color(0xFFF44336); // Red
  static const Color errorDark = Color(0xFFD32F2F); // Dark Red
  static const Color errorLight = Color(0xFFE57373); // Light Red

  static const Color info = Color(0xFF2196F3); // Blue
  static const Color infoDark = Color(0xFF1976D2); // Dark Blue
  static const Color infoLight = Color(0xFF64B5F6); // Light Blue

  // Feature Colors
  static const Color learn = Color(0xFF9C27B0); // Purple
  static const Color community = Color(0xFF03A9F4); // Light Blue
  static const Color check = Color(0xFF3F51B5); // Indigo
  static const Color admin = Color(0xFFFF5722); // Deep Orange

  // Interactive Colors
  static const Color link = Color(0xFF2196F3); // Blue
  static const Color linkVisited = Color(0xFF9C27B0); // Purple
  static const Color linkHover = Color(0xFF1976D2); // Dark Blue

  // Border Colors
  static const Color border = Color(0xFF333333); // Dark Gray
  static const Color borderLight = Color(0xFF444444); // Medium Dark Gray
  static const Color borderFocus = Color(0xFF7B68EE); // Primary Color

  // Overlay Colors
  static const Color overlay = Color(0x80000000); // Semi-transparent Black
  static const Color overlayLight = Color(
    0x40000000,
  ); // Light Semi-transparent Black
  static const Color overlayDark = Color(
    0xB3000000,
  ); // Dark Semi-transparent Black

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFF2D2D2D);
  static const Color shimmerHighlight = Color(0xFF3D3D3D);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF7B68EE),
    Color(0xFF9370DB),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF4A86E8),
    Color(0xFF6BA3F5),
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFF000000),
    Color(0xFF1A1A1A),
  ];

  static const List<Color> surfaceGradient = [
    Color(0xFF1E1E1E),
    Color(0xFF2D2D2D),
  ];

  // Utility Methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static LinearGradient createGradient({
    required List<Color> colors,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(begin: begin, end: end, colors: colors);
  }
}
