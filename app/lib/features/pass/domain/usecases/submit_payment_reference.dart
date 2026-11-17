// Submit a payment reference for a Pass subscription.
import '../../../../core/errors/failures.dart';
import '../payment_reference.dart';
import '../repositories/subscription_repository.dart';

class SubmitPaymentReference {
  final SubscriptionRepository repository;

  SubmitPaymentReference(this.repository);

  /// Validates and normalizes the reference, then submits it.
  ///
  /// Throws [ValidationFailure] for a bad reference, and passes on
  /// [DuplicateReferenceFailure] from the repository.
  Future<void> call(String reference, int amount) async {
    final error = validatePaymentReference(reference);
    if (error != null) throw ValidationFailure(error);
    return repository.submitReference(
      normalizePaymentReference(reference),
      amount,
    );
  }
}
