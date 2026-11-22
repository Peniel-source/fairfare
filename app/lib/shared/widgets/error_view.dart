// Error state shared by every screen (D1): a polite message and a retry.
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'app_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.message = 'Something went wrong. Check your connection and try again.',
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;

  /// Smaller version for a failed section inside a scrolling screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: compact ? 32 : 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Try again',
            icon: Icons.refresh,
            onPressed: onRetry,
            variant: AppButtonVariant.secondary,
          ),
        ],
      ],
    );

    final padded = Padding(
      padding: compact
          ? const EdgeInsets.symmetric(vertical: AppSpacing.lg)
          : AppSpacing.screen,
      child: content,
    );
    return compact ? padded : Center(child: padded);
  }
}
