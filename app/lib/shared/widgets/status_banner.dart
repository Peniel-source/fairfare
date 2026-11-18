import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum StatusTone { info, success, warning, error }

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.icon,
    this.tag,
    this.child,
  });

  final StatusTone tone;
  final String title;
  final String? message;

  final IconData? icon;

  /// Pill under the title
  final String? tag;

  /// Extra content under the message
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = switch (tone) {
      StatusTone.info => scheme.primary,
      StatusTone.success => scheme.primary,
      StatusTone.warning =>
        theme.extension<AppPalette>()?.priceText ?? scheme.secondary,
      StatusTone.error => scheme.error,
    };
    final defaultIcon = switch (tone) {
      StatusTone.info => Icons.info_outline,
      StatusTone.success => Icons.check_circle_outline,
      StatusTone.warning => Icons.warning_amber_rounded,
      StatusTone.error => Icons.error_outline,
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon ?? defaultIcon, color: accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      if (tag != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _Tag(label: tag!, color: accent),
                      ],
                      if (message != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(message!, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: AppSpacing.md),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
