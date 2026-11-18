import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';

class PriceStepper extends StatefulWidget {
  const PriceStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 100,
    this.max = 99999,
    this.quickValues = const [],
    this.errorText,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  /// Plus and minus step
  final int step;

  final int max;

  /// Quick price chips
  final List<int> quickValues;
  final String? errorText;

  @override
  State<PriceStepper> createState() => _PriceStepperState();
}

class _PriceStepperState extends State<PriceStepper> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );

  @override
  void didUpdateWidget(PriceStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync when the value changes from outside
    if (int.tryParse(_controller.text) != widget.value) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _stepBy(int delta) {
    final next = ((widget.value ?? 0) + delta).clamp(0, widget.max);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceStyle = AppTypography.price(context, size: 34);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: AppRadii.cardRadius,
            border: widget.errorText == null
                ? null
                : Border.all(color: theme.colorScheme.error),
          ),
          child: Row(
            children: [
              Text('RWF', style: priceStyle.copyWith(fontSize: 22)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      widget.max.toString().length,
                    ),
                  ],
                  style: priceStyle,
                  decoration: const InputDecoration(
                    hintText: '0',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (text) => widget.onChanged(int.tryParse(text)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Add ${widget.step} RWF',
                    icon: const Icon(Icons.add),
                    onPressed: () => _stepBy(widget.step),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Remove ${widget.step} RWF',
                    icon: const Icon(Icons.remove),
                    onPressed: (widget.value ?? 0) > 0
                        ? () => _stepBy(-widget.step)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (widget.quickValues.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < widget.quickValues.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickPriceChip(
                    amount: widget.quickValues[i],
                    isSelected: widget.quickValues[i] == widget.value,
                    onTap: () => widget.onChanged(widget.quickValues[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _QuickPriceChip extends StatelessWidget {
  const _QuickPriceChip({
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  final int amount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = Formatters.price(amount).replaceAll(' RWF', '');

    return Semantics(
      button: true,
      selected: isSelected,
      label: Formatters.price(amount),
      excludeSemantics: true,
      child: Material(
        color: isSelected
            ? scheme.primary.withValues(alpha: 0.16)
            : scheme.surfaceContainerLowest,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? scheme.primary : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: AppSpacing.minTapTarget,
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
