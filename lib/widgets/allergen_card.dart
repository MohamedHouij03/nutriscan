// lib/widgets/allergen_card.dart
import 'package:flutter/material.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/app_utils.dart';
import '../models/allergen_model.dart';

/// Card displaying a single detected allergen with severity badge.
class AllergenCard extends StatelessWidget {
  final AllergenModel allergen;

  const AllergenCard({super.key, required this.allergen});

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.allergenSeverityColor(allergen.severity);
    final icon = AppUtils.allergenIcon(allergen.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          // Name + raw text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppUtils.capitalize(allergen.name),
                  style: AppTextStyles.titleMedium.copyWith(color: color),
                ),
                if (allergen.rawText.isNotEmpty)
                  Text(
                    'Found as: "${allergen.rawText}"',
                    style: AppTextStyles.bodySmall,
                  ),
              ],
            ),
          ),

          // Severity badge
          _SeverityBadge(severity: allergen.severity, color: color),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final Color color;

  const _SeverityBadge({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            AppUtils.capitalize(severity),
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
