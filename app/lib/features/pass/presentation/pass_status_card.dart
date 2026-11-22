// Shows where the passenger's Pass stands: none, pending, active, rejected.
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../report/domain/entities/report_enums.dart';
import '../domain/entities/subscription.dart';

class PassStatusCard extends StatelessWidget {
  const PassStatusCard({super.key, required this.subscription});

  /// Null means the passenger has never submitted a payment.
  final Subscription? subscription;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (icon, color, title, body) = _content(scheme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(body, style: text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String, String) _content(ColorScheme scheme) {
    final sub = subscription;
    if (sub == null) {
      return (
        Icons.card_membership_outlined,
        scheme.onSurfaceVariant,
        'No Pass yet',
        'Pay with mobile money, then enter the reference from your SMS.',
      );
    }
    switch (sub.status) {
      case SubscriptionStatus.pending:
        return (
          Icons.hourglass_top,
          scheme.tertiary,
          'Payment pending',
          'Reference ${sub.reference} is waiting to be verified against the '
              'MoMo statement. This updates by itself as soon as it is '
              'verified. You can leave this screen.',
        );
      case SubscriptionStatus.active:
        final ends = sub.endsAt;
        return (
          Icons.verified,
          scheme.primary,
          'Payment successful',
          ends == null
              ? 'Your Pass is active. Reference ${sub.reference}.'
              : 'Your Pass is active until ${Formatters.date(ends)}. '
                    'Reference ${sub.reference}.',
        );
      case SubscriptionStatus.rejected:
        return (
          Icons.error_outline,
          scheme.error,
          'Payment not approved',
          'We could not match reference ${sub.reference} to a payment. '
              'Check the SMS and submit the correct reference.',
        );
    }
  }
}
