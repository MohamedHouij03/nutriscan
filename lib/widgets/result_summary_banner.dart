// lib/widgets/result_summary_banner.dart
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/scan_result_model.dart';

/// Large banner at top of result screen summarizing the scan outcome.
class ResultSummaryBanner extends StatelessWidget {
  final ScanResultModel result;

  const ResultSummaryBanner({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final severity = result.overallSeverity;
    final config = _severityConfig(severity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: config.borderColor,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: config.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              config.icon,
              color: config.iconColor,
              size: 32,
            ),
          ),

          const SizedBox(width: 16),

          // Text summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  config.subtitle,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),

          // Issue count
          if (result.hasIssues)
            Column(
              children: [
                Text(
                  '${result.issueCount}',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: config.iconColor,
                    fontSize: 28,
                  ),
                ),
                Text(
                  result.issueCount == 1 ? 'issue' : 'issues',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
        ],
      ),
    );
  }

  _SeverityConfig _severityConfig(String severity) {
    switch (severity) {
      case 'high':
        return _SeverityConfig(
          bgColor: AppColors.dangerLight.withValues(alpha: 0.2),
          borderColor: AppColors.danger.withValues(alpha: 0.4),
          icon: Icons.dangerous_outlined,
          iconBg: AppColors.dangerLight.withValues(alpha: 0.4),
          iconColor: AppColors.danger,
          title: '⚠️ High Risk Detected',
          subtitle: 'Serious allergens found. Do not consume if sensitive.',
        );

      case 'medium':
        return _SeverityConfig(
          bgColor: AppColors.warningLight.withValues(alpha: 0.2),
          borderColor: AppColors.warning.withValues(alpha: 0.4),
          icon: Icons.warning_amber_outlined,
          iconBg: AppColors.warningLight.withValues(alpha: 0.4),
          iconColor: AppColors.warning,
          title: '⚠️ Caution Advised',
          subtitle: 'Moderate allergens or additives detected.',
        );

      case 'low':
        return _SeverityConfig(
          bgColor: AppColors.infoLight.withValues(alpha: 0.2),
          borderColor: AppColors.info.withValues(alpha: 0.4),
          icon: Icons.info_outline,
          iconBg: AppColors.infoLight.withValues(alpha: 0.4),
          iconColor: AppColors.info,
          title: 'Low Risk',
          subtitle: 'Minor issues found. Check details below.',
        );

      default:
        return _SeverityConfig(
          bgColor: AppColors.successLight.withValues(alpha: 0.2),
          borderColor: AppColors.success.withValues(alpha: 0.4),
          icon: Icons.check_circle_outline,
          iconBg: AppColors.successLight.withValues(alpha: 0.4),
          iconColor: AppColors.success,
          title: '✅ All Clear',
          subtitle: 'No known allergens or harmful additives found.',
        );
    }
  }
}

class _SeverityConfig {
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SeverityConfig({
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}
