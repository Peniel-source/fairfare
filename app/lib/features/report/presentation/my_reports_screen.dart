import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../corridors/domain/entities/corridor.dart';
import '../../corridors/presentation/corridor_providers.dart';
import '../domain/entities/report.dart';
import 'edit_price_sheet.dart';
import 'report_banners.dart';
import 'report_card.dart';
import 'report_form_controller.dart';
import 'report_providers.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(myReportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My reports')),
      body: reports.when(
        loading: () => const LoadingView(message: 'Loading your reports…'),
        error: (error, _) => ErrorView(
          message: reportErrorMessage(error),
          onRetry: () => ref.invalidate(myReportsProvider),
        ),
        data: (reports) => reports.isEmpty
            ? EmptyView(
                title: 'No reports yet',
                message:
                    'After a ride, report the price you paid and it shows '
                    'up here.',
                icon: Icons.receipt_long_outlined,
                actionLabel: 'Report a ride',
                onAction: () => context.go('/home/report'),
              )
            : _ReportList(reports: reports),
      ),
    );
  }
}

class _ReportList extends ConsumerWidget {
  const _ReportList({required this.reports});

  final List<Report> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corridors = ref.watch(popularCorridorsProvider).value ?? const [];
    final names = {for (final c in corridors) c.id: _routeName(c)};
    final now = ref.watch(minuteClockProvider).value ?? DateTime.now();
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: ListView.separated(
          padding: AppSpacing.screen,
          itemCount: reports.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                'You can edit or delete a report while it is pending.',
                style: theme.textTheme.bodySmall,
              );
            }
            final report = reports[index - 1];
            final routeName = names[report.corridorId] ?? 'Unknown route';
            return ReportCard(
              key: ValueKey(report.id),
              report: report,
              routeName: routeName,
              now: now,
              onEdit: () => _edit(context, report, routeName),
              onDelete: () => _delete(context, ref, report),
            );
          },
        ),
      ),
    );
  }

  String _routeName(Corridor c) => '${c.fromArea} → ${c.toArea}';

  Future<void> _edit(
    BuildContext context,
    Report report,
    String routeName,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showEditPriceSheet(
      context,
      report: report,
      routeName: routeName,
    );
    if (saved == true) {
      messenger.showSnackBar(const SnackBar(content: Text('Price updated')));
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Report report,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(deletePendingReportProvider).call(report.id);
      messenger.showSnackBar(const SnackBar(content: Text('Report deleted')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(reportErrorMessage(error))),
      );
    }
  }
}
