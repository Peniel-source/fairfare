// Icon + label + short description row (roadmap 3.3), built once and reused:
// feature rows on Landing, settings rows, wallet history lines.
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class IconLabelRow extends StatelessWidget {
  const IconLabelRow({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? description;

  /// Optional widget on the right (a value, a chip, a chevron).
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        theme.extension<AppPalette>()?.accent ?? theme.colorScheme.primary;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.textTheme.titleSmall),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(description!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.fieldRadius,
      child: row,
    );
  }
}
