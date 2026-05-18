// lib/widgets/scan_history_tile.dart
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/app_utils.dart';
import '../models/scan_result_model.dart';

/// List tile displaying a past scan in the history list.
class ScanHistoryTile extends StatelessWidget {
  final ScanResultModel scan;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool showDeleteButton;

  const ScanHistoryTile({
    super.key,
    required this.scan,
    required this.onTap,
    this.onDelete,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(scan.overallSeverity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              // Severity indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _severityIcon(scan.overallSeverity),
                  color: severityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text preview
                    Text(
                      AppUtils.truncate(
                        scan.extractedText.replaceAll('\n', ' '),
                        50,
                      ),
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Tags row
                    Row(
                      children: [
                        if (scan.allergens.isNotEmpty)
                          _Tag(
                            label:
                                '${scan.allergens.length} allergen${scan.allergens.length > 1 ? 's' : ''}',
                            color: AppColors.danger,
                          ),
                        if (scan.allergens.isNotEmpty &&
                            scan.additives.isNotEmpty)
                          const SizedBox(width: 6),
                        if (scan.additives.isNotEmpty)
                          _Tag(
                            label:
                                '${scan.additives.length} additive${scan.additives.length > 1 ? 's' : ''}',
                            color: AppColors.warning,
                          ),
                        if (!scan.hasIssues)
                          const _Tag(
                            label: 'Safe',
                            color: AppColors.success,
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      AppUtils.timeAgo(scan.timestamp),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              // Delete or arrow
              if (showDeleteButton && onDelete != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: onDelete,
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'high':
        return Icons.dangerous_outlined;
      case 'medium':
        return Icons.warning_amber_outlined;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
