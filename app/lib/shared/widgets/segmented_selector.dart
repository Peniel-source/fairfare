import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class SegmentOption<T> {
  final T value;
  final String label;
  final IconData icon;

  const SegmentOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class SegmentedSelector<T> extends StatelessWidget {
  const SegmentedSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SegmentTile<T>(
              option: options[i],
              isSelected: options[i].value == selected,
              onTap: () => onChanged(options[i].value),
            ),
          ),
        ],
      ],
    );
  }
}

class _SegmentTile<T> extends StatelessWidget {
  const _SegmentTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final SegmentOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = isSelected ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      excludeSemantics: true,
      child: Material(
        color: isSelected ? scheme.primary : scheme.surfaceContainerLowest,
        borderRadius: AppRadii.fieldRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.fieldRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(option.icon, size: 20, color: foreground),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    option.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
