import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/entities/report_enums.dart';

class ReportStatusChip extends StatelessWidget {
  const ReportStatusChip({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warning =
        theme.extension<AppPalette>()?.priceText ?? scheme.secondary;

    final (label, icon, color) = switch (status) {
      ReportStatus.pending => ('Pending', Icons.hourglass_top, scheme.primary),
      ReportStatus.verified => (
        'Verified',
        Icons.check_circle_outline,
        scheme.primary,
      ),
      ReportStatus.rejected => (
        'Rejected',
        Icons.cancel_outlined,
        scheme.error,
      ),
      ReportStatus.expired => ('Expired', Icons.timer_off_outlined, warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
