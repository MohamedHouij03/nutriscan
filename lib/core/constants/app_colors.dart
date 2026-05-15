// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// Centralized color palette for NutriScan NER.
/// Follows Material Design 3 color system.
class AppColors {
  AppColors._();

  // Primary brand color — deep teal/green for health/food context
  static const Color primary = Color(0xFF00897B);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color primaryDark = Color(0xFF00695C);

  // Secondary — warm amber for warnings
  static const Color secondary = Color(0xFFFF8F00);
  static const Color secondaryLight = Color(0xFFFFB300);
  static const Color secondaryDark = Color(0xFFE65100);

  // Semantic colors
  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerLight = Color(0xFFEF9A9A);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFCC80);
  static const Color success = Color(0xFF388E3C);
  static const Color successLight = Color(0xFFA5D6A7);
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFF90CAF9);

  // Neutral
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F3);
  static const Color divider = Color(0xFFE0E0E0);

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0BEC5);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Dark theme variants
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);

  // Allergen severity colors
  static const Color allergenHigh = Color(0xFFB71C1C);
  static const Color allergenMedium = Color(0xFFE65100);
  static const Color allergenLow = Color(0xFFF9A825);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [danger, Color(0xFFE57373)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF5F7FA), Color(0xFFE8F5F3)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
