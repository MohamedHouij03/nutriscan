// lib/core/utils/app_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';

/// General utility functions used across the app.
class AppUtils {
  AppUtils._();

  /// Format a DateTime to a readable string.
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy • HH:mm').format(date);
  }

  /// Format a DateTime to relative time (e.g. "2 hours ago").
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  /// Show a styled SnackBar.
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final color = isError
        ? AppColors.danger
        : isSuccess
            ? AppColors.success
            : AppColors.info;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline
                    : isSuccess
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  /// Map allergen severity to color.
  static Color allergenSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppColors.allergenHigh;
      case 'medium':
        return AppColors.allergenMedium;
      case 'low':
        return AppColors.allergenLow;
      default:
        return AppColors.warning;
    }
  }

  /// Get allergen icon based on name.
  static IconData allergenIcon(String allergenName) {
    final name = allergenName.toLowerCase();
    if (name.contains('milk') || name.contains('dairy') || name.contains('lait')) {
      return Icons.local_drink;
    } else if (name.contains('gluten') || name.contains('wheat') || name.contains('blé')) {
      return Icons.grain;
    } else if (name.contains('peanut') || name.contains('arachide')) {
      return Icons.eco;
    } else if (name.contains('nut') || name.contains('noix')) {
      return Icons.park;
    } else if (name.contains('egg') || name.contains('oeuf')) {
      return Icons.egg;
    } else if (name.contains('fish') || name.contains('poisson')) {
      return Icons.set_meal;
    } else if (name.contains('soy') || name.contains('soja')) {
      return Icons.grass;
    } else if (name.contains('sesame') || name.contains('sésame')) {
      return Icons.spa;
    } else {
      return Icons.warning_amber;
    }
  }

  /// Capitalize first letter of a string.
  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// Truncate text to a max length.
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Check if a string is a valid email.
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  /// Check if a string is a valid password (min 6 chars).
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
