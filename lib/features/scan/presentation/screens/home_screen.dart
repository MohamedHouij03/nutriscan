// lib/features/scan/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../../features/history/data/history_repository.dart';
import '../../../../widgets/scan_history_tile.dart';
import '../../../../widgets/stat_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final historyAsync = ref.watch(historyStreamProvider);
    final statsAsync = ref.watch(scanStatsProvider);

    final userName = authState.user?.displayName ??
        authState.user?.email.split('@').first ??
        'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $userName 👋',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan ingredients to check for allergens',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Profile / sign out
                    IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () async {
                        final confirm = await _confirmSignOut(context);

                        if (confirm == true) {
                          ref.read(authNotifierProvider.notifier).signOut();

                          if (context.mounted) {
                            context.go(AppRoutes.login);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Stats Row ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: statsAsync.when(
                loading: () => const _StatsShimmer(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Total Scans',
                        value: '${stats.totalScans}',
                        icon: Icons.document_scanner_outlined,
                        color: AppColors.primary,
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Allergens',
                        value: '${stats.totalAllergens}',
                        icon: Icons.warning_amber_outlined,
                        color: AppColors.allergenHigh,
                      )
                          .animate(delay: 100.ms)
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.3),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Additives',
                        value: '${stats.totalAdditives}',
                        icon: Icons.science_outlined,
                        color: AppColors.warning,
                      )
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Chart ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => stats.allergenCounts.isEmpty
                    ? const SizedBox.shrink()
                    : _AllergenChart(stats: stats)
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 600.ms),
              ),
            ),
          ),

          // ── Scan Button ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _ScanButton()
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
            ),
          ),

          // ── Recent History ───────────────────────────────────────────────
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Scans',
                    style: AppTextStyles.headlineMedium,
                  ),
                ],
              ),
            ),
          ),

          historyAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: _ErrorWidget(
                message: err.toString(),
              ),
            ),
            data: (scans) => scans.isEmpty
                ? const SliverToBoxAdapter(
                    child: _EmptyHistory(),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => ScanHistoryTile(
                          scan: scans[i],
                          onTap: () => context.push(
                            AppRoutes.result,
                            extra: scans[i],
                          ),
                        )
                            .animate(
                              delay: (50 * i).ms,
                            )
                            .fadeIn(
                              duration: 400.ms,
                            )
                            .slideX(
                              begin: 0.1,
                              end: 0,
                            ),
                        childCount: scans.length,
                      ),
                    ),
                  ),
          ),
        ],
      ),

      // ── FAB: Scan ───────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.scan),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.document_scanner_outlined,
        ),
        label: const Text('New Scan'),
        elevation: 4,
      ).animate(delay: 400.ms).scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
          ),
    );
  }

  Future<bool?> _confirmSignOut(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.scan),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(
                alpha: 0.35,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan Ingredients',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Take a photo or upload from gallery',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.8,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergenChart extends StatelessWidget {
  final ScanStats stats;

  const _AllergenChart({
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = stats.allergenCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sorted.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Allergens Detected',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (top5.isEmpty ? 1 : top5.first.value).toDouble() + 1,
                  barGroups: List.generate(
                    top5.length,
                    (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: top5[i].value.toDouble(),
                            color: AppColors.primary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (
                          value,
                          meta,
                        ) {
                          final i = value.toInt();

                          if (i >= top5.length) {
                            return const SizedBox.shrink();
                          }

                          return Text(
                            AppUtils.capitalize(
                              top5[i].key.split('/').first,
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  gridData: const FlGridData(
                    show: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No scans yet',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button above to scan your first ingredient list',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;

  const _ErrorWidget({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.danger,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Container(
            height: 80,
            margin: const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
