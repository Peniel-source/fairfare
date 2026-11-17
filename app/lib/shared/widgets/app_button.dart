// Pill shaped button used across the app (D1). Shape, colors and the 48 dp
// minimum height come from the button themes in app_theme.dart.
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

enum AppButtonVariant {
  /// Filled terracotta: the one main action on a screen.
  primary,

  /// Outlined: a second action next to a primary one.
  secondary,

  /// Text only: low emphasis actions such as "Cancel".
  text,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// Shows a spinner and blocks taps while an action runs.
  final bool isLoading;

  /// Stretch to the full width of the parent.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final action = isLoading ? null : onPressed;
    final child = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label, overflow: TextOverflow.ellipsis);
    final leading = isLoading || icon == null ? null : Icon(icon, size: 20);

    final Widget button = switch (variant) {
      AppButtonVariant.primary =>
        leading == null
            ? FilledButton(onPressed: action, child: child)
            : FilledButton.icon(onPressed: action, icon: leading, label: child),
      AppButtonVariant.secondary =>
        leading == null
            ? OutlinedButton(onPressed: action, child: child)
            : OutlinedButton.icon(
                onPressed: action,
                icon: leading,
                label: child,
              ),
      AppButtonVariant.text =>
        leading == null
            ? TextButton(onPressed: action, child: child)
            : TextButton.icon(onPressed: action, icon: leading, label: child),
    };

    return Semantics(
      button: true,
      label: isLoading ? '$label, loading' : null,
      excludeSemantics: isLoading,
      child: expand
          ? SizedBox(
              width: double.infinity,
              height: AppSpacing.minTapTarget,
              child: button,
            )
          : button,
    );
  }
}
