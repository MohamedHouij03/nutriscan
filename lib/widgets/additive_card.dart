// lib/widgets/additive_card.dart
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/additive_model.dart';

/// Card displaying a single detected harmful additive (E-number).
class AdditiveCard extends StatefulWidget {
  final AdditiveModel additive;

  const AdditiveCard({super.key, required this.additive});

  @override
  State<AdditiveCard> createState() => _AdditiveCardState();
}

class _AdditiveCardState extends State<AdditiveCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // E-number badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.additive.code,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: color,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.additive.name,
                        style: AppTextStyles.titleMedium,
                      ),
                      if (widget.additive.rawText.isNotEmpty)
                        Text(
                          'Found as: "${widget.additive.rawText}"',
                          style: AppTextStyles.bodySmall,
                        ),
                    ],
                  ),
                ),

                // Expand button
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.info_outline,
                    color: color,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),

          // Expanded concern
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.additive.concern,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
