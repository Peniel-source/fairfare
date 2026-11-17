// Shows where the passenger's Pass stands: none, pending, active, rejected.
import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: 4),
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
          'Payment being checked',
          'Reference ${sub.reference}. Your Pass turns on as soon as the '
              'payment is approved. You can leave this screen.',
        );
      case SubscriptionStatus.active:
        final ends = sub.endsAt;
        return (
          Icons.verified,
          scheme.primary,
          'Pass active',
          ends == null
              ? 'Reference ${sub.reference}.'
              : 'Active until ${Formatters.date(ends)}.',
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
