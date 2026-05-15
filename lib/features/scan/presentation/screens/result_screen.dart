// lib/features/scan/presentation/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../models/scan_result_model.dart';
import '../../../../widgets/allergen_card.dart';
import '../../../../widgets/additive_card.dart';
import '../../../../widgets/result_summary_banner.dart';

class ResultScreen extends ConsumerWidget {
  final ScanResultModel result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar ───────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: result.hasIssues ? AppColors.danger : AppColors.success,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () => context.push(AppRoutes.history),
                tooltip: 'View history',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: result.hasIssues
                        ? [AppColors.danger, AppColors.warning]
                        : [AppColors.success, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),
                        Text(
                          'Scan Results',
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          AppUtils.formatDate(result.timestamp),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Summary Banner ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ResultSummaryBanner(result: result)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),
            ),
          ),

          // ── Allergens Section ────────────────────────────────────────────
          if (result.allergens.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  icon: Icons.warning_amber_outlined,
                  label: 'Allergens Detected',
                  count: result.allergens.length,
                  color: AppColors.danger,
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => AllergenCard(allergen: result.allergens[i])
                      .animate(delay: (100 + 60 * i).ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.1, end: 0),
                  childCount: result.allergens.length,
                ),
              ),
            ),
          ],

          // ── Additives Section ────────────────────────────────────────────
          if (result.additives.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  icon: Icons.science_outlined,
                  label: 'Harmful Additives',
                  count: result.additives.length,
                  color: AppColors.warning,
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => AdditiveCard(additive: result.additives[i])
                      .animate(delay: (200 + 60 * i).ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.1, end: 0),
                  childCount: result.additives.length,
                ),
              ),
            ),
          ],

          // ── Clean bill ────────────────────────────────────────────────────
          if (!result.hasIssues)
            SliverToBoxAdapter(
              child: _CleanResult()
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
            ),

          // ── Extracted Text ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _ExtractedTextCard(text: result.extractedText)
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 400.ms),
            ),
          ),

          // ── Confidence ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverToBoxAdapter(
              child: _ConfidenceIndicator(confidence: result.confidence)
                  .animate(delay: 350.ms)
                  .fadeIn(duration: 400.ms),
            ),
          ),

          // ── Actions ───────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.scan),
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: const Text('New Scan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.history),
                      icon: const Icon(Icons.history),
                      label: const Text('History'),
                    ),
                  ),
                ],
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.headlineMedium),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count found',
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CleanResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.successLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Issues Detected! ✅',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No known allergens or harmful additives were found in this ingredient list.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ExtractedTextCard extends StatefulWidget {
  final String text;
  const _ExtractedTextCard({required this.text});

  @override
  State<_ExtractedTextCard> createState() => _ExtractedTextCardState();
}

class _ExtractedTextCardState extends State<_ExtractedTextCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.text_snippet_outlined, color: AppColors.info),
            title: const Text('Extracted Text', style: AppTextStyles.titleLarge),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.text,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConfidenceIndicator extends StatelessWidget {
  final double confidence;
  const _ConfidenceIndicator({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toInt();
    final color = confidence >= 0.8
        ? AppColors.success
        : confidence >= 0.6
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          const Text('AI Confidence', style: AppTextStyles.titleMedium),
          const Spacer(),
          Text(
            '$pct%',
            style: AppTextStyles.titleLarge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
