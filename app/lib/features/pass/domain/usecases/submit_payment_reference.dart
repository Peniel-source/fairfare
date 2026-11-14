// Submit a payment reference for Pass subscription.
import '../repositories/subscription_repository.dart';

class SubmitPaymentReference {
  final SubscriptionRepository repository;

  SubmitPaymentReference(this.repository);

  Future<void> call(String reference, int amount) {
    return repository.submitReference(reference, amount);
  }
}
