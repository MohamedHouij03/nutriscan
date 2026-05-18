// lib/features/history/presentation/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../features/history/data/history_repository.dart';
import '../../../../models/scan_result_model.dart';
import '../../../../widgets/scan_history_tile.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _filter = 'all'; // 'all' | 'allergens' | 'additives' | 'safe'

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
        data: (scans) {
          final filtered = _applyFilter(scans);
          if (filtered.isEmpty) return _EmptyState(filter: _filter);

          return Column(
            children: [
              // Filter chips
              _FilterBar(
                current: _filter,
                onChanged: (f) => setState(() => _filter = f),
                counts: _getCounts(scans),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => ScanHistoryTile(
                    scan: filtered[i],
                    showDeleteButton: true,
                    onTap: () => context.push(
                      AppRoutes.result,
                      extra: filtered[i],
                    ),
                    onDelete: () => _confirmDelete(context, filtered[i]),
                  )
                      .animate(delay: (40 * i).ms)
                      .fadeIn(duration: 350.ms)
                      .slideX(begin: 0.08, end: 0),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<ScanResultModel> _applyFilter(List<ScanResultModel> scans) {
    switch (_filter) {
      case 'allergens':
        return scans.where((s) => s.allergens.isNotEmpty).toList();
      case 'additives':
        return scans.where((s) => s.additives.isNotEmpty).toList();
      case 'safe':
        return scans.where((s) => !s.hasIssues).toList();
      default:
        return scans;
    }
  }

  Map<String, int> _getCounts(List<ScanResultModel> scans) {
    return {
      'all': scans.length,
      'allergens': scans.where((s) => s.allergens.isNotEmpty).length,
      'additives': scans.where((s) => s.additives.isNotEmpty).length,
      'safe': scans.where((s) => !s.hasIssues).length,
    };
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Scans', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            ...[
              ('all', 'All Scans', Icons.list_alt),
              ('allergens', 'Has Allergens', Icons.warning_amber_outlined),
              ('additives', 'Has Additives', Icons.science_outlined),
              ('safe', 'Safe Scans', Icons.check_circle_outline),
            ].map(
              (item) => ListTile(
                leading: Icon(
                  item.$3,
                  color: _filter == item.$1
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                title: Text(item.$2),
                selected: _filter == item.$1,
                selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  setState(() => _filter = item.$1);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ScanResultModel scan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scan'),
        content: const Text('Remove this scan from history?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result =
          await ref.read(historyRepositoryProvider).deleteScan(scan.id);

      if (!mounted) return;

      result.fold(
        (f) => AppUtils.showSnackBar(
          context,
          message: f.message,
          isError: true,
        ),
        (_) => AppUtils.showSnackBar(
          context,
          message: 'Scan deleted',
          isSuccess: true,
        ),
      );
    }
  }
}

class _FilterBar extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  final Map<String, int> counts;

  const _FilterBar({
    required this.current,
    required this.onChanged,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'All'),
      ('allergens', 'Allergens'),
      ('additives', 'Additives'),
      ('safe', 'Safe'),
    ];

    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: filters.map((f) {
          final selected = current == f.$1;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${f.$2} (${counts[f.$1] ?? 0})'),
              selected: selected,
              onSelected: (_) => onChanged(f.$1),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 72,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            filter == 'all' ? 'No scans yet' : 'No matching scans',
            style: AppTextStyles.headlineMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            filter == 'all'
                ? 'Your scan history will appear here'
                : 'Try a different filter',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Failed to load history',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
