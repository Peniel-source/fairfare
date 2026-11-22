import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/entities/report.dart';
import '../domain/entities/report_enums.dart';
import 'report_status_chip.dart';

/// One report in My reports
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.routeName,
    required this.now,
    required this.onEdit,
    required this.onDelete,
  });

  final Report report;
  final String routeName;
  final DateTime now;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = report.status == ReportStatus.pending;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(routeName, style: theme.textTheme.titleSmall),
              ),
              ReportStatusChip(status: report.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.price(report.price),
                style: AppTypography.price(context, size: 22),
              ),
              const Spacer(),
              Text(
                Formatters.date(report.createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${timeSegmentLabel(report.timeSegment)} · '
            '${weatherLabel(report.weather)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatusLine(report: report, now: now),
          if (isPending) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit price'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.report, required this.now});

  final Report report;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium;

    final text = switch (report.status) {
      ReportStatus.pending => _pendingText(),
      ReportStatus.verified =>
        'Confirmed by another passenger on '
            '${Formatters.date(report.verifiedAt ?? report.createdAt)}',
      ReportStatus.rejected =>
        report.reason ?? 'The price was far from the usual range',
      ReportStatus.expired =>
        'No one confirmed a similar price within 48 hours',
    };

    return Text(
      text,
      style: report.status == ReportStatus.rejected
          ? style?.copyWith(color: theme.colorScheme.error)
          : style,
    );
  }

  String _pendingText() {
    final left = report.createdAt
        .add(AppConstants.corroborationWindow)
        .difference(now);
    if (left <= Duration.zero) return 'Window closed, waiting for the result';
    return 'Waiting for a match. Time left: ${Formatters.countdown(left)}';
  }
}

String timeSegmentLabel(TimeSegment segment) => switch (segment) {
  TimeSegment.morning => 'Morning',
  TimeSegment.midday => 'Midday',
  TimeSegment.evening => 'Evening',
  TimeSegment.lateNight => 'Late night',
};

String weatherLabel(Weather weather) => switch (weather) {
  Weather.clear => 'Clear',
  Weather.heavyRain => 'Heavy rain',
};
