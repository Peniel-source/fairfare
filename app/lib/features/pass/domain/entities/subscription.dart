// A rider's Pass subscription.
import '../../../report/domain/entities/report_enums.dart';

class Subscription {
  final String reference;
  final int amount;
  final SubscriptionStatus status;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const Subscription({
    required this.reference,
    required this.amount,
    required this.status,
    this.startsAt,
    this.endsAt,
  });
}
