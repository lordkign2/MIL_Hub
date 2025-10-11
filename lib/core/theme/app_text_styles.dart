import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Application text styles and typography
class AppTextStyles {
  // Base text style
  static const TextStyle _baseTextStyle = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    fontWeight: FontWeight.normal,
  );

  // Display Styles (Largest)
  static final TextStyle displayLarge = _baseTextStyle.copyWith(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static final TextStyle displayMedium = _baseTextStyle.copyWith(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static final TextStyle displaySmall = _baseTextStyle.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // Headline Styles
  static final TextStyle headlineLarge = _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );

  static final TextStyle headlineMedium = _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
  );

  static final TextStyle headlineSmall = _baseTextStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );

  // Title Styles
  static final TextStyle titleLarge = _baseTextStyle.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.27,
  );

  static final TextStyle titleMedium = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static final TextStyle titleSmall = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.10,
    height: 1.43,
  );

  // Label Styles
  static final TextStyle labelLarge = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.10,
    height: 1.43,
  );

  static final TextStyle labelMedium = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.50,
    height: 1.33,
  );

  static final TextStyle labelSmall = _baseTextStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.50,
    height: 1.45,
  );

  // Body Styles
  static final TextStyle bodyLarge = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.50,
    height: 1.50,
  );

  static final TextStyle bodyMedium = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static final TextStyle bodySmall = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.40,
    height: 1.33,
  );

  // Custom App Styles
  static final TextStyle appBarTitle = titleLarge.copyWith(
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle buttonText = labelLarge.copyWith(
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle cardTitle = titleMedium.copyWith(
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle cardSubtitle = bodySmall.copyWith(
    color: AppColors.textSecondary,
  );

  static final TextStyle sectionHeader = headlineSmall.copyWith(
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle inputLabel = labelMedium.copyWith(
    color: AppColors.textSecondary,
  );

  static final TextStyle inputText = bodyLarge.copyWith(
    color: AppColors.textPrimary,
  );

  static final TextStyle hintText = bodyMedium.copyWith(
    color: AppColors.textTertiary,
  );

  static final TextStyle errorText = bodySmall.copyWith(
    color: AppColors.error,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle successText = bodySmall.copyWith(
    color: AppColors.success,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle warningText = bodySmall.copyWith(
    color: AppColors.warning,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle linkText = bodyMedium.copyWith(
    color: AppColors.link,
    decoration: TextDecoration.underline,
  );

  static final TextStyle captionText = bodySmall.copyWith(
    color: AppColors.textTertiary,
    fontStyle: FontStyle.italic,
  );

  // Method to create text style with custom color
  static TextStyle withColor(TextStyle baseStyle, Color color) {
    return baseStyle.copyWith(color: color);
  }

  // Method to create bold variant
  static TextStyle toBold(TextStyle baseStyle) {
    return baseStyle.copyWith(fontWeight: FontWeight.bold);
  }

  // Method to create italic variant
  static TextStyle toItalic(TextStyle baseStyle) {
    return baseStyle.copyWith(fontStyle: FontStyle.italic);
  }
}
